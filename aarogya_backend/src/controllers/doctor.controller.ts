import { Request, Response, NextFunction } from 'express';
import { Prisma, VerificationStatus, AvailabilityStatus, AppointmentStatus } from '@prisma/client';
import { prisma } from '../config/prisma';
import { NotFoundError, ConflictError, BadRequestError } from '../utils/AppError';
import { doctorService } from '../services/doctor.service';

export const doctorController = {
  /**
   * Retrieves the authenticated doctor's own professional profile and user context.
   */
  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.doctorProfile.findUnique({
        where: { userId },
        include: {
          user: {
            select: {
              id: true,
              email: true,
              phone: true,
              role: true,
              verificationStatus: true,
              isActive: true,
              createdAt: true,
            },
          },
          _count: {
            select: {
              availabilities: true,
            },
          },
        },
      });

      if (!profile) {
        throw new NotFoundError('Doctor profile not found');
      }

      res.status(200).json({
        success: true,
        data: {
          profile,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Updates permitted professional fields on the authenticated doctor's profile.
   * Privileged fields (role, verificationStatus, verifiedAt, verifiedBy) cannot be modified.
   */
  async updateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const existingProfile = await prisma.doctorProfile.findUnique({
        where: { userId },
      });

      if (!existingProfile) {
        throw new NotFoundError('Doctor profile not found');
      }

      const {
        fullName,
        phone,
        specialization,
        qualifications,
        experienceYears,
        consultationFee,
        bio,
        languages,
        consultationModes,
        clinicAddress,
        hospitalAffiliation,
        isOnline,
        status,
      } = req.body;

      if (phone !== undefined && phone !== null) {
        const existingPhone = await prisma.user.findFirst({
          where: {
            phone,
            NOT: { id: userId },
          },
        });

        if (existingPhone) {
          throw new ConflictError('This phone number is already registered to another account');
        }
      }

      const updatedProfile = await prisma.$transaction(async (tx) => {
        if (phone !== undefined) {
          await tx.user.update({
            where: { id: userId },
            data: { phone },
          });
        }

        return tx.doctorProfile.update({
          where: { userId },
          data: {
            ...(fullName !== undefined ? { fullName } : {}),
            ...(specialization !== undefined ? { specialization } : {}),
            ...(qualifications !== undefined ? { qualifications } : {}),
            ...(experienceYears !== undefined ? { experienceYears } : {}),
            ...(consultationFee !== undefined ? { consultationFee } : {}),
            ...(bio !== undefined ? { bio } : {}),
            ...(languages !== undefined ? { languages } : {}),
            ...(consultationModes !== undefined ? { consultationModes } : {}),
            ...(clinicAddress !== undefined ? { clinicAddress } : {}),
            ...(hospitalAffiliation !== undefined ? { hospitalAffiliation } : {}),
            ...(isOnline !== undefined ? { isOnline } : {}),
            ...(status !== undefined ? { status } : {}),
          },
          include: {
            user: {
              select: {
                id: true,
                email: true,
                phone: true,
                role: true,
                verificationStatus: true,
                createdAt: true,
              },
            },
          },
        });
      });

      if (isOnline === true) {
        await doctorService.ensureDutySlotsForDoctor(updatedProfile.id);
      }

      res.status(200).json({
        success: true,
        message: 'Doctor profile updated successfully',
        data: {
          profile: updatedProfile,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Public listing of verified, eligible doctors with safe professional metadata.
   */
  async listPublicDoctors(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { specialization, consultationMode, search, limit = 20, offset = 0 } = req.query as any;

      const where: Prisma.DoctorProfileWhereInput = {
        user: {
          verificationStatus: VerificationStatus.VERIFIED,
          isActive: true,
        },
        ...(specialization
          ? {
              specialization: {
                contains: specialization,
                mode: 'insensitive',
              },
            }
          : {}),
        ...(consultationMode
          ? {
              consultationModes: {
                has: consultationMode,
              },
            }
          : {}),
        ...(search
          ? {
              OR: [
                { fullName: { contains: search, mode: 'insensitive' } },
                { specialization: { contains: search, mode: 'insensitive' } },
              ],
            }
          : {}),
      };

      const [doctors, total] = await Promise.all([
        prisma.doctorProfile.findMany({
          where,
          select: {
            id: true,
            fullName: true,
            specialization: true,
            qualifications: true,
            experienceYears: true,
            consultationFee: true,
            bio: true,
            languages: true,
            consultationModes: true,
            clinicAddress: true,
            hospitalAffiliation: true,
            verifiedAt: true,
          },
          orderBy: {
            experienceYears: 'desc',
          },
          take: Number(limit),
          skip: Number(offset),
        }),
        prisma.doctorProfile.count({ where }),
      ]);

      res.status(200).json({
        success: true,
        data: {
          doctors,
          pagination: {
            total,
            limit: Number(limit),
            offset: Number(offset),
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Public retrieval of a single verified, eligible doctor's profile.
   */
  async getPublicDoctorById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);

      const doctor = await prisma.doctorProfile.findFirst({
        where: {
          OR: [{ id }, { userId: id }],
          user: {
            verificationStatus: VerificationStatus.VERIFIED,
            isActive: true,
          },
        },
        select: {
          id: true,
          fullName: true,
          specialization: true,
          qualifications: true,
          experienceYears: true,
          consultationFee: true,
          bio: true,
          languages: true,
          consultationModes: true,
          clinicAddress: true,
          hospitalAffiliation: true,
          verifiedAt: true,
        },
      });

      if (!doctor) {
        throw new NotFoundError('Doctor profile not found');
      }

      res.status(200).json({
        success: true,
        data: {
          doctor,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves availability schedule for the authenticated doctor.
   */
  async getMyAvailability(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.doctorProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile) {
        throw new NotFoundError('Doctor profile not found');
      }

      const { from, to, status } = req.query as any;

      const availabilities = await prisma.doctorAvailability.findMany({
        where: {
          doctorProfileId: profile.id,
          ...(status ? { status } : {}),
          ...(from || to
            ? {
                AND: [
                  ...(from ? [{ startTime: { gte: new Date(from) } }] : []),
                  ...(to ? [{ endTime: { lte: new Date(to) } }] : []),
                ],
              }
            : {}),
        },
        orderBy: {
          startTime: 'asc',
        },
      });

      res.status(200).json({
        success: true,
        data: {
          availabilities,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Creates an availability window for the authenticated doctor with overlap prevention.
   */
  async createMyAvailability(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.doctorProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile) {
        throw new NotFoundError('Doctor profile not found');
      }

      const { startTime, endTime, timeZone, status, isRecurring, dayOfWeek } = req.body;

      // Overlap check against existing active entries
      const overlap = await prisma.doctorAvailability.findFirst({
        where: {
          doctorProfileId: profile.id,
          status: { not: AvailabilityStatus.UNAVAILABLE },
          AND: [
            { startTime: { lt: endTime } },
            { endTime: { gt: startTime } },
          ],
        },
      });

      if (overlap) {
        throw new ConflictError('This availability window overlaps with an existing active availability entry');
      }

      const availability = await prisma.doctorAvailability.create({
        data: {
          doctorProfileId: profile.id,
          startTime,
          endTime,
          timeZone: timeZone || 'Asia/Kolkata',
          status: status || AvailabilityStatus.AVAILABLE,
          isRecurring: isRecurring || false,
          dayOfWeek,
        },
      });

      res.status(201).json({
        success: true,
        message: 'Availability created successfully',
        data: {
          availability,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Updates an existing availability window owned by the authenticated doctor.
   */
  async updateMyAvailability(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const id = String(req.params.id);

      const existing = await prisma.doctorAvailability.findFirst({
        where: {
          id,
          doctorProfile: {
            userId,
          },
        },
      });

      if (!existing) {
        throw new NotFoundError('Availability entry not found');
      }

      const { startTime, endTime, timeZone, status, isRecurring, dayOfWeek } = req.body;

      const effectiveStart = startTime || existing.startTime;
      const effectiveEnd = endTime || existing.endTime;

      if (effectiveEnd <= effectiveStart) {
        throw new ConflictError('endTime must be strictly later than startTime');
      }

      // Check for overlapping intervals excluding the current entry
      const overlap = await prisma.doctorAvailability.findFirst({
        where: {
          doctorProfileId: existing.doctorProfileId,
          id: { not: id },
          status: { not: AvailabilityStatus.UNAVAILABLE },
          AND: [
            { startTime: { lt: effectiveEnd } },
            { endTime: { gt: effectiveStart } },
          ],
        },
      });

      if (overlap) {
        throw new ConflictError('Updated time window overlaps with an existing active availability entry');
      }

      const updated = await prisma.doctorAvailability.update({
        where: { id },
        data: {
          ...(startTime ? { startTime } : {}),
          ...(endTime ? { endTime } : {}),
          ...(timeZone ? { timeZone } : {}),
          ...(status ? { status } : {}),
          ...(isRecurring !== undefined ? { isRecurring } : {}),
          ...(dayOfWeek !== undefined ? { dayOfWeek } : {}),
        },
      });

      res.status(200).json({
        success: true,
        message: 'Availability updated successfully',
        data: {
          availability: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Deletes an availability window owned by the authenticated doctor.
   */
  async deleteMyAvailability(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const id = String(req.params.id);

      const existing = await prisma.doctorAvailability.findFirst({
        where: {
          id,
          doctorProfile: {
            userId,
          },
        },
      });

      if (!existing) {
        throw new NotFoundError('Availability entry not found');
      }

      await prisma.doctorAvailability.delete({
        where: { id },
      });

      res.status(200).json({
        success: true,
        message: 'Availability entry deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Updates authenticated doctor's real-time duty status (On Duty vs Off Duty).
   * When going ON DUTY, automatically ensures active consultation slots for today & tomorrow.
   */
  async updateDutyStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const { isOnline } = req.body;

      if (typeof isOnline !== 'boolean') {
        throw new BadRequestError('isOnline boolean is required');
      }

      const profile = await prisma.doctorProfile.findUnique({
        where: { userId },
        select: { id: true, fullName: true, status: true },
      });

      if (!profile) {
        throw new NotFoundError('Doctor profile not found');
      }

      const updated = await prisma.doctorProfile.update({
        where: { userId },
        data: { isOnline },
        select: {
          id: true,
          fullName: true,
          isOnline: true,
          status: true,
        },
      });

      let slotsCount = 0;
      if (isOnline) {
        slotsCount = await doctorService.ensureDutySlotsForDoctor(profile.id);
      }

      res.status(200).json({
        success: true,
        message: isOnline
          ? `Doctor is now ON DUTY. ${slotsCount} consultation slots active.`
          : 'Doctor is now OFF DUTY.',
        data: {
          doctor: updated,
          slotsCount,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Public retrieval of upcoming available slots for a verified, eligible doctor.
   */
  async getPublicDoctorAvailability(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);

      const doctor = await prisma.doctorProfile.findFirst({
        where: {
          OR: [{ id }, { userId: id }],
          user: {
            verificationStatus: VerificationStatus.VERIFIED,
            isActive: true,
          },
        },
        select: {
          id: true,
          isOnline: true,
          status: true,
        },
      });

      if (!doctor) {
        throw new NotFoundError('Doctor profile not found');
      }

      // If doctor is on duty or active, ensure standard consultation slots exist
      if (doctor.isOnline && doctor.status === 'ACTIVE') {
        await doctorService.ensureDutySlotsForDoctor(doctor.id);
      }

      const availabilities = await prisma.doctorAvailability.findMany({
        where: {
          doctorProfileId: doctor.id,
          status: AvailabilityStatus.AVAILABLE,
          endTime: {
            gte: new Date(),
          },
        },
        select: {
          id: true,
          startTime: true,
          endTime: true,
          timeZone: true,
          status: true,
        },
        orderBy: {
          startTime: 'asc',
        },
      });

      // Fetch active/confirmed appointments to exclude any booked times
      const activeAppointments = await prisma.appointment.findMany({
        where: {
          doctorProfileId: doctor.id,
          status: { in: [AppointmentStatus.REQUESTED, AppointmentStatus.CONFIRMED] },
          endTime: { gte: new Date() },
        },
        select: {
          startTime: true,
          endTime: true,
        },
      });

      const freeSlots = availabilities.filter((slot) => {
        return !activeAppointments.some(
          (appt) => appt.startTime < slot.endTime && appt.endTime > slot.startTime
        );
      });

      res.status(200).json({
        success: true,
        data: {
          availabilities: freeSlots,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Authoritative administrator endpoint to transition a doctor's verification status.
   * Strictly gated by requireRoles(Role.PLATFORM_ADMIN).
   */
  async adminVerifyDoctor(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const adminUserId = req.user!.id;
      const { status } = req.body;

      const doctor = await prisma.doctorProfile.findFirst({
        where: {
          OR: [{ id }, { userId: id }],
        },
        include: {
          user: true,
        },
      });

      if (!doctor) {
        throw new NotFoundError('Doctor profile not found');
      }

      const updated = await prisma.$transaction(async (tx) => {
        await tx.user.update({
          where: { id: doctor.userId },
          data: { verificationStatus: status },
        });

        return tx.doctorProfile.update({
          where: { id: doctor.id },
          data: {
            verifiedAt: status === VerificationStatus.VERIFIED ? new Date() : null,
            verifiedBy: status === VerificationStatus.VERIFIED ? adminUserId : null,
          },
          include: {
            user: {
              select: {
                id: true,
                email: true,
                role: true,
                verificationStatus: true,
              },
            },
          },
        });
      });

      res.status(200).json({
        success: true,
        message: `Doctor verification status updated to ${status}`,
        data: {
          doctor: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },
};
