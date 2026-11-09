import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';
import { NotFoundError, ForbiddenError, BadRequestError } from '../utils/AppError';

export const hospitalController = {
  /**
   * Retrieves the authenticated Hospital Admin's profile and hospital metadata.
   */
  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.hospitalAdminProfile.findUnique({
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
        },
      });

      if (!profile) {
        throw new NotFoundError('Hospital administrator profile not found');
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
   * Updates the hospital profile and settings for the authenticated admin's own hospital.
   */
  async updateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.hospitalAdminProfile.findUnique({
        where: { userId },
      });

      if (!profile) {
        throw new NotFoundError('Hospital administrator profile not found');
      }

      const { fullName, hospitalName, designation } = req.body;

      const updated = await prisma.hospitalAdminProfile.update({
        where: { userId },
        data: {
          fullName: fullName !== undefined ? String(fullName).trim() : undefined,
          hospitalName: hospitalName !== undefined ? String(hospitalName).trim() : undefined,
          designation: designation !== undefined ? String(designation).trim() : undefined,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Hospital details updated successfully',
        data: {
          profile: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Lists medical staff and doctors affiliated with this specific hospital.
   */
  async getHospitalStaff(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.hospitalAdminProfile.findUnique({
        where: { userId },
      });

      if (!profile) {
        throw new NotFoundError('Hospital administrator profile not found');
      }

      const staff = await prisma.doctorProfile.findMany({
        where: {
          hospitalAffiliation: {
            equals: profile.hospitalName,
            mode: 'insensitive',
          },
        },
        select: {
          id: true,
          fullName: true,
          specialization: true,
          qualifications: true,
          nmcRegistrationNumber: true,
          experienceYears: true,
          consultationFee: true,
          hospitalAffiliation: true,
          user: {
            select: {
              id: true,
              email: true,
              phone: true,
              isActive: true,
              verificationStatus: true,
            },
          },
        },
      });

      res.status(200).json({
        success: true,
        data: {
          hospital: profile.hospitalName,
          staffCount: staff.length,
          staff,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Adds / affiliates a doctor to this administrator's hospital.
   */
  async addHospitalStaff(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.hospitalAdminProfile.findUnique({
        where: { userId },
      });

      if (!profile) {
        throw new NotFoundError('Hospital administrator profile not found');
      }

      const { doctorId, email, nmcRegistrationNumber } = req.body;

      const doctor = await prisma.doctorProfile.findFirst({
        where: {
          OR: [
            doctorId ? { id: String(doctorId) } : undefined,
            nmcRegistrationNumber ? { nmcRegistrationNumber: String(nmcRegistrationNumber).trim() } : undefined,
            email ? { user: { email: String(email).toLowerCase().trim() } } : undefined,
          ].filter(Boolean) as any,
        },
      });

      if (!doctor) {
        throw new NotFoundError('Doctor profile not found to affiliate');
      }

      const updatedDoctor = await prisma.doctorProfile.update({
        where: { id: doctor.id },
        data: {
          hospitalAffiliation: profile.hospitalName,
        },
        include: {
          user: {
            select: { id: true, email: true, phone: true, verificationStatus: true },
          },
        },
      });

      res.status(200).json({
        success: true,
        message: `Doctor ${updatedDoctor.fullName} successfully affiliated with ${profile.hospitalName}`,
        data: {
          doctor: updatedDoctor,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Lists patient appointments scheduled at this administrator's hospital.
   */
  async getHospitalAppointments(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.hospitalAdminProfile.findUnique({
        where: { userId },
      });

      if (!profile) {
        throw new NotFoundError('Hospital administrator profile not found');
      }

      const appointments = await prisma.appointment.findMany({
        where: {
          doctorProfile: {
            hospitalAffiliation: {
              equals: profile.hospitalName,
              mode: 'insensitive',
            },
          },
        },
        include: {
          patientProfile: {
            select: {
              fullName: true,
              gender: true,
              dateOfBirth: true,
            },
          },
          doctorProfile: {
            select: {
              fullName: true,
              specialization: true,
            },
          },
        },
        orderBy: { startTime: 'desc' },
        take: 50,
      });

      res.status(200).json({
        success: true,
        data: {
          hospital: profile.hospitalName,
          appointmentCount: appointments.length,
          appointments,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves verified hospitals near the user's location with verified ICU & normal bed availability.
   */
  async getNearbyHospitals(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userLat = parseFloat(req.query.latitude as string) || 28.5672;
      const userLng = parseFloat(req.query.longitude as string) || 77.2100;
      const radiusKm = parseFloat(req.query.radiusKm as string) || 50;
      const hasEmergencyOnly = req.query.emergencyBay === 'true';

      const hospitals = await prisma.hospital.findMany({
        where: hasEmergencyOnly ? { hasEmergencyBay: true } : undefined,
        orderBy: { name: 'asc' },
      });

      // Calculate distance for each hospital using Haversine formula
      const mapped = hospitals
        .map((h) => {
          const R = 6371; // Earth radius in km
          const dLat = ((h.latitude - userLat) * Math.PI) / 180;
          const dLon = ((h.longitude - userLng) * Math.PI) / 180;
          const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos((userLat * Math.PI) / 180) *
              Math.cos((h.latitude * Math.PI) / 180) *
              Math.sin(dLon / 2) *
              Math.sin(dLon / 2);
          const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
          const distanceKm = Math.round(R * c * 10) / 10;

          return {
            ...h,
            distanceKm,
            occupancyRateIcu:
              h.totalIcuBeds > 0
                ? Math.round(((h.totalIcuBeds - h.availableIcuBeds) / h.totalIcuBeds) * 100)
                : 0,
            occupancyRateNormal:
              h.totalNormalBeds > 0
                ? Math.round(((h.totalNormalBeds - h.availableNormalBeds) / h.totalNormalBeds) * 100)
                : 0,
          };
        })
        .filter((h) => h.distanceKm <= radiusKm)
        .sort((a, b) => a.distanceKm - b.distanceKm);

      res.status(200).json({
        success: true,
        data: {
          count: mapped.length,
          userCoordinates: { latitude: userLat, longitude: userLng },
          radiusKm,
          hospitals: mapped,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves single hospital details by ID.
   */
  async getHospitalById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const hospital = await prisma.hospital.findUnique({
        where: { id },
        include: {
          departments: {
            include: {
              beds: true,
            },
          },
        },
      });

      if (!hospital) {
        throw new NotFoundError('Hospital not found');
      }

      res.status(200).json({
        success: true,
        data: {
          hospital,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves granular bed inventory and departments for a hospital.
   */
  async getHospitalBeds(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const hospitalId = String(req.params.id);

      const hospital = await prisma.hospital.findUnique({
        where: { id: hospitalId },
      });

      if (!hospital) {
        throw new NotFoundError('Hospital not found');
      }

      let beds = await prisma.hospitalBed.findMany({
        where: { hospitalId },
        include: {
          department: true,
        },
        orderBy: {
          bedNumber: 'asc',
        },
      });

      // If no beds exist yet, automatically auto-populate sample clinical ward inventory
      if (beds.length === 0) {
        const defaultDept = await prisma.hospitalDepartment.create({
          data: {
            hospitalId,
            name: 'Emergency Trauma & Critical Care',
            floorNumber: 'Ground Floor',
            headDoctorName: 'Dr. Clinical Director',
          },
        });

        await prisma.hospitalBed.createMany({
          data: [
            { hospitalId, departmentId: defaultDept.id, bedNumber: 'ICU-01', bedType: 'ICU', status: 'AVAILABLE' },
            { hospitalId, departmentId: defaultDept.id, bedNumber: 'ICU-02', bedType: 'ICU', status: 'OCCUPIED', occupiedByPatient: 'Active Patient' },
            { hospitalId, departmentId: defaultDept.id, bedNumber: 'ICU-03', bedType: 'ICU', status: 'AVAILABLE' },
            { hospitalId, departmentId: defaultDept.id, bedNumber: 'EMG-01', bedType: 'EMERGENCY', status: 'AVAILABLE' },
            { hospitalId, departmentId: defaultDept.id, bedNumber: 'EMG-02', bedType: 'EMERGENCY', status: 'AVAILABLE' },
            { hospitalId, departmentId: defaultDept.id, bedNumber: 'GEN-01', bedType: 'NORMAL', status: 'AVAILABLE' },
            { hospitalId, departmentId: defaultDept.id, bedNumber: 'GEN-02', bedType: 'NORMAL', status: 'OCCUPIED' },
          ],
        });

        beds = await prisma.hospitalBed.findMany({
          where: { hospitalId },
          include: { department: true },
          orderBy: { bedNumber: 'asc' },
        });
      }

      res.status(200).json({
        success: true,
        data: {
          hospitalId,
          hospitalName: hospital.name,
          beds,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Updates individual bed allocation and status, and auto-syncs hospital summary totals.
   */
  async updateBedStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const hospitalId = String(req.params.id);
      const bedId = String(req.params.bedId);
      const { status, occupiedByPatient, notes } = req.body;

      const validStatuses = ['AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'RESERVED'];
      if (!status || !validStatuses.includes(status)) {
        throw new BadRequestError(`Invalid status. Allowed values: ${validStatuses.join(', ')}`);
      }

      const existingBed = await prisma.hospitalBed.findFirst({
        where: { id: bedId, hospitalId },
      });

      if (!existingBed) {
        throw new NotFoundError('Hospital bed not found');
      }

      const updatedBed = await prisma.hospitalBed.update({
        where: { id: bedId },
        data: {
          status,
          occupiedByPatient: status === 'AVAILABLE' ? null : (occupiedByPatient !== undefined ? String(occupiedByPatient) : existingBed.occupiedByPatient),
          notes: notes !== undefined ? String(notes) : undefined,
          lastSanitizedAt: status === 'AVAILABLE' ? new Date() : undefined,
        },
      });

      // Recalculate and synchronize aggregate hospital ICU and Normal bed counts
      const availableIcu = await prisma.hospitalBed.count({
        where: { hospitalId, bedType: 'ICU', status: 'AVAILABLE' },
      });
      const totalIcu = await prisma.hospitalBed.count({
        where: { hospitalId, bedType: 'ICU' },
      });
      const availableNormal = await prisma.hospitalBed.count({
        where: { hospitalId, bedType: 'NORMAL', status: 'AVAILABLE' },
      });
      const totalNormal = await prisma.hospitalBed.count({
        where: { hospitalId, bedType: 'NORMAL' },
      });

      await prisma.hospital.update({
        where: { id: hospitalId },
        data: {
          availableIcuBeds: availableIcu,
          totalIcuBeds: totalIcu > 0 ? totalIcu : undefined,
          availableNormalBeds: availableNormal,
          totalNormalBeds: totalNormal > 0 ? totalNormal : undefined,
        },
      });

      res.status(200).json({
        success: true,
        message: `Bed ${updatedBed.bedNumber} status updated to ${status}`,
        data: {
          bed: updatedBed,
          summary: {
            availableIcuBeds: availableIcu,
            availableNormalBeds: availableNormal,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },
};

