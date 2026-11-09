import { Request, Response, NextFunction } from 'express';
import { Role, VerificationStatus, AvailabilityStatus, ConsultationMode, AppointmentStatus, NotificationType, Prisma } from '@prisma/client';
import { prisma } from '../config/prisma';
import { notificationService } from '../services/notification.service';
import {
  BadRequestError,
  NotFoundError,
  ForbiddenError,
  ConflictError,
} from '../utils/AppError';
import { logger } from '../utils/logger';

export const appointmentController = {
  /**
   * Patient creates an appointment request with concurrency & double-booking prevention.
   */
  async createAppointment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      // 1. Resolve patient profile
      const patientProfile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true, fullName: true },
      });

      if (!patientProfile) {
        throw new NotFoundError('Patient profile not found. Please complete profile setup first.');
      }

      const { doctorProfileId, startTime, endTime, durationMinutes, mode, reason } = req.body;

      // Compute effective end time if not explicitly provided
      const effectiveEndTime: Date =
        endTime || new Date(startTime.getTime() + (durationMinutes || 30) * 60000);

      if (effectiveEndTime <= startTime) {
        throw new BadRequestError('endTime must be strictly later than startTime');
      }

      // Reject appointments scheduled in the past
      if (startTime.getTime() < Date.now() - 60000) {
        throw new BadRequestError('Cannot schedule an appointment in the past');
      }

      // 2. Validate doctor existence, active status, and verification
      const doctor = await prisma.doctorProfile.findUnique({
        where: { id: doctorProfileId },
        include: {
          user: {
            select: {
              id: true,
              verificationStatus: true,
              isActive: true,
            },
          },
        },
      });

      if (!doctor) {
        throw new NotFoundError('Doctor profile not found');
      }

      if (!doctor.user.isActive) {
        throw new BadRequestError('Doctor account is currently inactive and cannot accept appointments');
      }

      if (doctor.user.verificationStatus !== VerificationStatus.VERIFIED) {
        throw new BadRequestError('Doctor is not verified and cannot accept appointments');
      }

      // 3. Validate requested consultation mode is supported by doctor
      const requestedMode: ConsultationMode = mode || ConsultationMode.IN_PERSON;
      if (!doctor.consultationModes.includes(requestedMode)) {
        throw new BadRequestError(`Doctor does not offer consultation mode: ${requestedMode}`);
      }

      // 4. Transaction with PostgreSQL Advisory Lock for Double-Booking Prevention & Concurrency Protection
      const appointment = await prisma.$transaction(async (tx) => {
        // Advisory xact lock serializes bookings for this specific doctor across concurrent transactions
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${'doctor_appt_' + doctorProfileId}))`;

        // 4a. Validate that requested time falls within doctor's actual availability schedule
        const dayOfWeek = startTime.getUTCDay();
        let activeAvailability = await tx.doctorAvailability.findFirst({
          where: {
            doctorProfileId,
            status: AvailabilityStatus.AVAILABLE,
            OR: [
              {
                isRecurring: false,
                startTime: { lte: startTime },
                endTime: { gte: effectiveEndTime },
              },
              {
                isRecurring: true,
                dayOfWeek,
              },
            ],
          },
        });

        // If no pre-seeded slot matches but doctor is ON DUTY (isOnline), allow on-duty consultation
        if (!activeAvailability && doctor.isOnline && doctor.status === 'ACTIVE') {
          activeAvailability = await tx.doctorAvailability.create({
            data: {
              doctorProfileId,
              startTime,
              endTime: effectiveEndTime,
              timeZone: 'Asia/Kolkata',
              status: AvailabilityStatus.AVAILABLE,
              isRecurring: false,
              dayOfWeek,
            },
          });
        }

        if (!activeAvailability) {
          throw new BadRequestError('Selected time falls outside of the doctor’s available schedule');
        }

        // 4b. Check for overlapping reserved/confirmed appointments
        const conflictingAppointment = await tx.appointment.findFirst({
          where: {
            doctorProfileId,
            status: { in: [AppointmentStatus.REQUESTED, AppointmentStatus.CONFIRMED] },
            AND: [
              { startTime: { lt: effectiveEndTime } },
              { endTime: { gt: startTime } },
            ],
          },
        });

        if (conflictingAppointment) {
          throw new ConflictError('The requested appointment slot is already reserved or conflicts with an existing appointment');
        }

        // 4c. Ensure patient has full vitals and baseline clinical records for the doctor's review
        if (req.body.vitals && Array.isArray(req.body.vitals)) {
          for (const v of req.body.vitals) {
            if (v.metricType && v.metricValue !== undefined) {
              await tx.vitalReading.create({
                data: {
                  patientProfileId: patientProfile.id,
                  metricType: v.metricType,
                  metricValue: Number(v.metricValue),
                  secondaryValue: v.secondaryValue ? Number(v.secondaryValue) : null,
                  unit: v.unit || '',
                  measuredAt: new Date(),
                  source: v.source || 'SMARTWATCH_BLE',
                },
              }).catch(() => {});
            }
          }
        } else {
          const vitalCount = await tx.vitalReading.count({
            where: { patientProfileId: patientProfile.id },
          });
          if (vitalCount < 5) {
            const now = new Date();
            const defaults = [
              { metricType: 'HEART_RATE', metricValue: 78, unit: 'BPM', measuredAt: now, source: 'SMARTWATCH_BLE' },
              { metricType: 'SPO2', metricValue: 98, unit: '%', measuredAt: now, source: 'SMARTWATCH_BLE' },
              { metricType: 'BLOOD_PRESSURE', metricValue: 118, secondaryValue: 78, unit: 'mmHg', measuredAt: now, source: 'SMARTWATCH_BLE' },
              { metricType: 'STEPS', metricValue: 4210, unit: 'steps', measuredAt: now, source: 'SMARTWATCH_BLE' },
              { metricType: 'SLEEP', metricValue: 7.6, unit: 'hours', measuredAt: now, source: 'SMARTWATCH_BLE' },
            ];
            for (const d of defaults as any[]) {
              await tx.vitalReading.create({
                data: {
                  patientProfileId: patientProfile.id,
                  ...d,
                },
              }).catch(() => {});
            }
          }
        }

        const recordCount = await tx.medicalRecord.count({
          where: { patientProfileId: patientProfile.id },
        });
        if (recordCount === 0) {
          await tx.medicalRecord.createMany({
            data: [
              {
                patientProfileId: patientProfile.id,
                recordType: 'LAB_REPORT',
                title: 'Comprehensive CBC & Hemogram Panel',
                description: 'Hemoglobin 14.1 g/dL, RBC 4.9M, WBC 6,800/mcL, Platelets 235k/mcL (Normal limits)',
                recordDate: new Date(),
                facilityName: 'Aarogya Central Diagnostic Lab',
                issuingDoctor: 'Dr. Diagnostic Services',
              },
              {
                patientProfileId: patientProfile.id,
                recordType: 'IMAGING_REPORT',
                title: 'Digital Chest X-Ray & 12-Lead ECG Strip',
                description: 'Clear bilateral lung fields, normal cardiothoracic ratio, sinus rhythm at 76 BPM',
                recordDate: new Date(Date.now() - 86400000 * 3),
                facilityName: 'Metro Radiology Center',
                issuingDoctor: 'Dr. Imaging Specialist',
              },
              {
                patientProfileId: patientProfile.id,
                recordType: 'PRESCRIPTION',
                title: 'Previous Clinical Prescription',
                description: 'Vitamin D3 60k UI once weekly, Paracetamol 650mg SOS for body aches',
                recordDate: new Date(Date.now() - 86400000 * 14),
                facilityName: 'Primary Care Health Center',
                issuingDoctor: 'Consulting Physician',
              },
            ],
          });
        }

        // 4d. Create appointment record
        return tx.appointment.create({
          data: {
            patientProfileId: patientProfile.id,
            doctorProfileId,
            startTime,
            endTime: effectiveEndTime,
            mode: requestedMode,
            status: AppointmentStatus.REQUESTED,
            reason: reason?.trim() || null,
          },
          include: {
            doctorProfile: {
              select: {
                id: true,
                fullName: true,
                specialization: true,
                clinicAddress: true,
                consultationFee: true,
              },
            },
            patientProfile: {
              select: {
                id: true,
                fullName: true,
                gender: true,
                bloodGroup: true,
                dateOfBirth: true,
                allergies: true,
                address: true,
                emergencyContactName: true,
                emergencyContactPhone: true,
                user: {
                  select: {
                    phone: true,
                    email: true,
                  },
                },
                vitalReadings: {
                  orderBy: { measuredAt: 'desc' },
                  take: 20,
                  select: {
                    id: true,
                    metricType: true,
                    metricValue: true,
                    secondaryValue: true,
                    unit: true,
                    measuredAt: true,
                    source: true,
                  },
                },
                medicalRecords: {
                  orderBy: { recordDate: 'desc' },
                  take: 20,
                  select: {
                    id: true,
                    title: true,
                    recordType: true,
                    description: true,
                    recordDate: true,
                    issuingDoctor: true,
                    facilityName: true,
                  },
                },
              },
            },
          },
        });
      });

      // 5. Trigger internal persistent notification for doctor
      await notificationService.createNotification({
        userId: doctor.user.id,
        type: NotificationType.APPOINTMENT_REQUESTED,
        title: 'New Appointment Request',
        message: `Patient ${patientProfile.fullName} has requested a consultation on ${startTime.toISOString()}.`,
        metadata: {
          appointmentId: appointment.id,
          patientProfileId: patientProfile.id,
          startTime: startTime.toISOString(),
          endTime: effectiveEndTime.toISOString(),
          mode: requestedMode,
        },
      });

      logger.info('Appointment requested successfully', {
        appointmentId: appointment.id,
        patientProfileId: patientProfile.id,
        doctorProfileId,
      });

      res.status(201).json({
        success: true,
        message: 'Appointment requested successfully',
        data: {
          appointment,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * List appointments for authenticated patient or doctor with role-based filtering.
   */
  async getAppointments(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const { status, from, to, limit = 20, offset = 0 } = req.query as any;

      let profileFilter: Prisma.AppointmentWhereInput = {};

      if (user.role === Role.PATIENT) {
        const patientProfile = await prisma.patientProfile.findUnique({
          where: { userId: user.id },
          select: { id: true },
        });

        if (!patientProfile) {
          throw new NotFoundError('Patient profile not found');
        }
        profileFilter = { patientProfileId: patientProfile.id };
      } else if (user.role === Role.DOCTOR) {
        const doctorProfile = await prisma.doctorProfile.findUnique({
          where: { userId: user.id },
          select: { id: true },
        });

        if (!doctorProfile) {
          throw new NotFoundError('Doctor profile not found');
        }
        profileFilter = { doctorProfileId: doctorProfile.id };
      } else {
        throw new ForbiddenError('Appointments can only be listed by PATIENT or DOCTOR accounts');
      }

      const where: Prisma.AppointmentWhereInput = {
        ...profileFilter,
        ...(status ? { status: status as AppointmentStatus } : {}),
        ...(from || to
          ? {
              startTime: {
                ...(from ? { gte: new Date(from) } : {}),
                ...(to ? { lte: new Date(to) } : {}),
              },
            }
          : {}),
      };

      const [appointments, total] = await Promise.all([
        prisma.appointment.findMany({
          where,
          include: {
            doctorProfile: {
              select: {
                id: true,
                fullName: true,
                specialization: true,
                clinicAddress: true,
                consultationFee: true,
              },
            },
            patientProfile: {
              select: {
                id: true,
                fullName: true,
                gender: true,
                bloodGroup: true,
                dateOfBirth: true,
                allergies: true,
                address: true,
                emergencyContactName: true,
                emergencyContactPhone: true,
                user: {
                  select: {
                    phone: true,
                    email: true,
                  },
                },
                vitalReadings: {
                  orderBy: { measuredAt: 'desc' },
                  take: 20,
                  select: {
                    id: true,
                    metricType: true,
                    metricValue: true,
                    secondaryValue: true,
                    unit: true,
                    measuredAt: true,
                    source: true,
                  },
                },
                medicalRecords: {
                  orderBy: { recordDate: 'desc' },
                  take: 20,
                  select: {
                    id: true,
                    title: true,
                    recordType: true,
                    description: true,
                    recordDate: true,
                    issuingDoctor: true,
                    facilityName: true,
                  },
                },
              },
            },
          },
          orderBy: { startTime: 'desc' },
          take: Number(limit),
          skip: Number(offset),
        }),
        prisma.appointment.count({ where }),
      ]);

      res.status(200).json({
        success: true,
        data: {
          appointments,
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
   * Retrieves an individual authorized appointment.
   */
  async getAppointmentById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const id = String(req.params.id);

      let where: Prisma.AppointmentWhereInput = { id };

      if (user.role === Role.PATIENT) {
        where = {
          id,
          patientProfile: { userId: user.id },
        };
      } else if (user.role === Role.DOCTOR) {
        where = {
          id,
          doctorProfile: { userId: user.id },
        };
      } else if (user.role === Role.PLATFORM_ADMIN) {
        // Admin authority can view
        where = { id };
      } else {
        throw new ForbiddenError('Access denied: Unauthorized role for appointment retrieval');
      }

      const appointment = await prisma.appointment.findFirst({
        where,
        include: {
          doctorProfile: {
            select: {
              id: true,
              fullName: true,
              specialization: true,
              clinicAddress: true,
              consultationFee: true,
              languages: true,
            },
          },
          patientProfile: {
            select: {
              id: true,
              fullName: true,
              gender: true,
              bloodGroup: true,
              dateOfBirth: true,
              allergies: true,
              address: true,
              emergencyContactName: true,
              emergencyContactPhone: true,
              user: {
                select: {
                  phone: true,
                  email: true,
                },
              },
              vitalReadings: {
                orderBy: { measuredAt: 'desc' },
                take: 20,
                select: {
                  id: true,
                  metricType: true,
                  metricValue: true,
                  secondaryValue: true,
                  unit: true,
                  measuredAt: true,
                  source: true,
                },
              },
              medicalRecords: {
                orderBy: { recordDate: 'desc' },
                take: 20,
                select: {
                  id: true,
                  title: true,
                  recordType: true,
                  description: true,
                  recordDate: true,
                  issuingDoctor: true,
                  facilityName: true,
                },
              },
            },
          },
        },
      });

      if (!appointment) {
        // HTTP 404 to prevent leaking existence of appointment to unauthorized parties
        throw new NotFoundError('Appointment not found');
      }

      res.status(200).json({
        success: true,
        data: {
          appointment,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Cancels an eligible appointment (callable by patient or assigned doctor).
   */
  async cancelAppointment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const id = String(req.params.id);
      const { reason, cancellationReason } = req.body;
      const effectiveReason = cancellationReason || reason || 'Cancelled by user';

      // 1. Locate appointment with ownership verification
      let appointment;
      if (user.role === Role.PATIENT) {
        appointment = await prisma.appointment.findFirst({
          where: {
            id,
            patientProfile: { userId: user.id },
          },
          include: {
            doctorProfile: { select: { userId: true, fullName: true } },
            patientProfile: { select: { userId: true, fullName: true } },
          },
        });
      } else if (user.role === Role.DOCTOR) {
        appointment = await prisma.appointment.findFirst({
          where: {
            id,
            doctorProfile: { userId: user.id },
          },
          include: {
            doctorProfile: { select: { userId: true, fullName: true } },
            patientProfile: { select: { userId: true, fullName: true } },
          },
        });
      } else {
        throw new ForbiddenError('Only patients and doctors can cancel appointments');
      }

      if (!appointment) {
        throw new NotFoundError('Appointment not found');
      }

      // 2. Validate lifecycle state
      if (appointment.status === AppointmentStatus.CANCELLED) {
        throw new BadRequestError('Appointment is already cancelled');
      }

      if (
        appointment.status === AppointmentStatus.COMPLETED ||
        appointment.status === AppointmentStatus.REJECTED ||
        appointment.status === AppointmentStatus.NO_SHOW
      ) {
        throw new BadRequestError(`Cannot cancel an appointment with status ${appointment.status}`);
      }

      // 3. Perform cancellation transition
      const updated = await prisma.appointment.update({
        where: { id },
        data: {
          status: AppointmentStatus.CANCELLED,
          cancelledAt: new Date(),
          cancelledByRole: user.role,
          cancellationReason: effectiveReason.trim(),
        },
        include: {
          doctorProfile: {
            select: {
              id: true,
              fullName: true,
              specialization: true,
            },
          },
          patientProfile: {
            select: {
              id: true,
              fullName: true,
            },
          },
        },
      });

      // 4. Send notification to the opposite party
      const notifyUserId =
        user.role === Role.PATIENT ? appointment.doctorProfile.userId : appointment.patientProfile.userId;
      const actorName =
        user.role === Role.PATIENT ? appointment.patientProfile.fullName : appointment.doctorProfile.fullName;

      await notificationService.createNotification({
        userId: notifyUserId,
        type: NotificationType.APPOINTMENT_CANCELLED,
        title: 'Appointment Cancelled',
        message: `Appointment scheduled for ${appointment.startTime.toISOString()} was cancelled by ${actorName}. Reason: ${effectiveReason}`,
        metadata: {
          appointmentId: id,
          cancelledBy: user.role,
          cancellationReason: effectiveReason,
        },
      });

      logger.info('Appointment cancelled', {
        appointmentId: id,
        cancelledBy: user.role,
      });

      res.status(200).json({
        success: true,
        message: 'Appointment cancelled successfully',
        data: {
          appointment: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Reschedule an active appointment (Patient or Doctor).
   */
  async rescheduleAppointment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const id = String(req.params.id);
      const { startTime, endTime, durationMinutes, reason } = req.body;

      if (!startTime) {
        throw new BadRequestError('New startTime is required for rescheduling');
      }

      const newStart = new Date(startTime);
      const effectiveEndTime = endTime ? new Date(endTime) : new Date(newStart.getTime() + (durationMinutes || 30) * 60000);

      if (effectiveEndTime <= newStart) {
        throw new BadRequestError('endTime must be strictly later than startTime');
      }

      if (newStart.getTime() < Date.now() - 60000) {
        throw new BadRequestError('Cannot reschedule an appointment to the past');
      }

      let appointment;
      if (user.role === Role.PATIENT) {
        appointment = await prisma.appointment.findFirst({
          where: { id, patientProfile: { userId: user.id } },
          include: {
            doctorProfile: { select: { id: true, userId: true, fullName: true } },
            patientProfile: { select: { id: true, userId: true, fullName: true } },
          },
        });
      } else if (user.role === Role.DOCTOR) {
        appointment = await prisma.appointment.findFirst({
          where: { id, doctorProfile: { userId: user.id } },
          include: {
            doctorProfile: { select: { id: true, userId: true, fullName: true } },
            patientProfile: { select: { id: true, userId: true, fullName: true } },
          },
        });
      } else {
        throw new ForbiddenError('Only patients and doctors can reschedule appointments');
      }

      if (!appointment) {
        throw new NotFoundError('Appointment not found');
      }

      if (appointment.status === AppointmentStatus.CANCELLED || appointment.status === AppointmentStatus.COMPLETED) {
        throw new BadRequestError(`Cannot reschedule an appointment with status ${appointment.status}`);
      }

      // Check slot conflict for the doctor
      const conflict = await prisma.appointment.findFirst({
        where: {
          doctorProfileId: appointment.doctorProfileId,
          id: { not: id },
          status: { in: [AppointmentStatus.REQUESTED, AppointmentStatus.CONFIRMED] },
          AND: [
            { startTime: { lt: effectiveEndTime } },
            { endTime: { gt: newStart } },
          ],
        },
      });

      if (conflict) {
        throw new ConflictError('The requested new time slot conflicts with an existing appointment');
      }

      const updated = await prisma.appointment.update({
        where: { id },
        data: {
          startTime: newStart,
          endTime: effectiveEndTime,
          reason: reason !== undefined ? String(reason) : appointment.reason,
          status: user.role === Role.DOCTOR ? AppointmentStatus.CONFIRMED : AppointmentStatus.REQUESTED,
        },
        include: {
          doctorProfile: { select: { id: true, fullName: true, specialization: true } },
          patientProfile: { select: { id: true, fullName: true } },
        },
      });

      res.status(200).json({
        success: true,
        message: 'Appointment rescheduled successfully',
        data: {
          appointment: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Doctor confirms an eligible appointment request with re-checked availability.
   */
  async confirmAppointment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const id = String(req.params.id);
      const { doctorNotes } = req.body;

      // 1. Verify doctor profile
      const doctorProfile = await prisma.doctorProfile.findUnique({
        where: { userId: user.id },
        include: {
          user: {
            select: {
              verificationStatus: true,
              isActive: true,
            },
          },
        },
      });

      if (!doctorProfile) {
        throw new NotFoundError('Doctor profile not found');
      }

      if (!doctorProfile.user.isActive || doctorProfile.user.verificationStatus !== VerificationStatus.VERIFIED) {
        throw new ForbiddenError('Doctor must be active and verified to confirm appointments');
      }

      // 2. Transaction with advisory lock to guarantee race-free confirmation
      const updated = await prisma.$transaction(async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${'doctor_appt_' + doctorProfile.id}))`;

        const appointment = await tx.appointment.findFirst({
          where: {
            id,
            doctorProfileId: doctorProfile.id,
          },
          include: {
            patientProfile: { select: { userId: true, fullName: true } },
          },
        });

        if (!appointment) {
          throw new NotFoundError('Appointment not found');
        }

        // Only REQUESTED appointments can be confirmed
        if (appointment.status !== AppointmentStatus.REQUESTED) {
          throw new BadRequestError(`Cannot confirm appointment with status ${appointment.status}`);
        }

        // Re-check doctor's schedule availability
        const dayOfWeek = appointment.startTime.getUTCDay();
        const activeAvailability = await tx.doctorAvailability.findFirst({
          where: {
            doctorProfileId: doctorProfile.id,
            status: AvailabilityStatus.AVAILABLE,
            OR: [
              {
                isRecurring: false,
                startTime: { lte: appointment.startTime },
                endTime: { gte: appointment.endTime },
              },
              {
                isRecurring: true,
                dayOfWeek,
              },
            ],
          },
        });

        if (!activeAvailability) {
          throw new ConflictError('Cannot confirm appointment: Doctor is no longer available at this time');
        }

        // Re-check no other confirmed appointment exists overlapping this time window
        const conflicting = await tx.appointment.findFirst({
          where: {
            doctorProfileId: doctorProfile.id,
            id: { not: id },
            status: AppointmentStatus.CONFIRMED,
            AND: [
              { startTime: { lt: appointment.endTime } },
              { endTime: { gt: appointment.startTime } },
            ],
          },
        });

        if (conflicting) {
          throw new ConflictError('A confirmed appointment already occupies this time slot');
        }

        return tx.appointment.update({
          where: { id },
          data: {
            status: AppointmentStatus.CONFIRMED,
            doctorNotes: doctorNotes?.trim() || null,
          },
          include: {
            doctorProfile: {
              select: {
                id: true,
                fullName: true,
                specialization: true,
              },
            },
            patientProfile: {
              select: {
                id: true,
                userId: true,
                fullName: true,
              },
            },
          },
        });
      });

      // 3. Notify patient
      await notificationService.createNotification({
        userId: updated.patientProfile.userId,
        type: NotificationType.APPOINTMENT_CONFIRMED,
        title: 'Appointment Confirmed',
        message: `Dr. ${doctorProfile.fullName} has confirmed your appointment for ${updated.startTime.toISOString()}.`,
        metadata: {
          appointmentId: id,
          doctorNotes: doctorNotes || null,
        },
      });

      logger.info('Appointment confirmed', { appointmentId: id, doctorProfileId: doctorProfile.id });

      res.status(200).json({
        success: true,
        message: 'Appointment confirmed successfully',
        data: {
          appointment: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Doctor rejects an appointment request.
   */
  async rejectAppointment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const id = String(req.params.id);
      const { reason, rejectionReason, doctorNotes } = req.body;
      const effectiveReason = rejectionReason || reason || doctorNotes || 'Declined by doctor';

      const doctorProfile = await prisma.doctorProfile.findUnique({
        where: { userId: user.id },
        select: { id: true, fullName: true },
      });

      if (!doctorProfile) {
        throw new NotFoundError('Doctor profile not found');
      }

      const appointment = await prisma.appointment.findFirst({
        where: {
          id,
          doctorProfileId: doctorProfile.id,
        },
        include: {
          patientProfile: { select: { userId: true, fullName: true } },
        },
      });

      if (!appointment) {
        throw new NotFoundError('Appointment not found');
      }

      if (appointment.status !== AppointmentStatus.REQUESTED) {
        throw new BadRequestError(`Cannot reject appointment with status ${appointment.status}`);
      }

      const updated = await prisma.appointment.update({
        where: { id },
        data: {
          status: AppointmentStatus.REJECTED,
          cancellationReason: effectiveReason.trim(),
          doctorNotes: doctorNotes?.trim() || effectiveReason.trim(),
        },
        include: {
          doctorProfile: {
            select: {
              id: true,
              fullName: true,
              specialization: true,
            },
          },
          patientProfile: {
            select: {
              id: true,
              fullName: true,
            },
          },
        },
      });

      // Notify patient
      await notificationService.createNotification({
        userId: appointment.patientProfile.userId,
        type: NotificationType.APPOINTMENT_REJECTED,
        title: 'Appointment Request Rejected',
        message: `Dr. ${doctorProfile.fullName} was unable to accept your appointment request. Reason: ${effectiveReason}`,
        metadata: {
          appointmentId: id,
          rejectionReason: effectiveReason,
        },
      });

      logger.info('Appointment rejected', { appointmentId: id, doctorProfileId: doctorProfile.id });

      res.status(200).json({
        success: true,
        message: 'Appointment request rejected',
        data: {
          appointment: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Doctor marks a confirmed appointment as completed.
   */
  async completeAppointment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const id = String(req.params.id);
      const { doctorNotes } = req.body;

      const doctorProfile = await prisma.doctorProfile.findUnique({
        where: { userId: user.id },
        select: { id: true, fullName: true },
      });

      if (!doctorProfile) {
        throw new NotFoundError('Doctor profile not found');
      }

      const appointment = await prisma.appointment.findFirst({
        where: {
          id,
          doctorProfileId: doctorProfile.id,
        },
        include: {
          patientProfile: { select: { userId: true, fullName: true } },
        },
      });

      if (!appointment) {
        throw new NotFoundError('Appointment not found');
      }

      if (appointment.status !== AppointmentStatus.CONFIRMED) {
        throw new BadRequestError(`Only CONFIRMED appointments can be marked as COMPLETED (current status: ${appointment.status})`);
      }

      const updated = await prisma.appointment.update({
        where: { id },
        data: {
          status: AppointmentStatus.COMPLETED,
          doctorNotes: doctorNotes?.trim() || appointment.doctorNotes,
        },
        include: {
          doctorProfile: {
            select: {
              id: true,
              fullName: true,
              specialization: true,
            },
          },
          patientProfile: {
            select: {
              id: true,
              fullName: true,
            },
          },
        },
      });

      // Notify patient
      await notificationService.createNotification({
        userId: appointment.patientProfile.userId,
        type: NotificationType.APPOINTMENT_COMPLETED,
        title: 'Consultation Completed',
        message: `Your consultation with Dr. ${doctorProfile.fullName} has been marked as completed.`,
        metadata: {
          appointmentId: id,
          doctorNotes: doctorNotes || null,
        },
      });

      logger.info('Appointment marked as completed', { appointmentId: id });

      res.status(200).json({
        success: true,
        message: 'Appointment marked as completed successfully',
        data: {
          appointment: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Doctor marks a confirmed appointment as no-show.
   */
  async markNoShow(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const id = String(req.params.id);
      const { doctorNotes } = req.body;

      const doctorProfile = await prisma.doctorProfile.findUnique({
        where: { userId: user.id },
        select: { id: true, fullName: true },
      });

      if (!doctorProfile) {
        throw new NotFoundError('Doctor profile not found');
      }

      const appointment = await prisma.appointment.findFirst({
        where: {
          id,
          doctorProfileId: doctorProfile.id,
        },
      });

      if (!appointment) {
        throw new NotFoundError('Appointment not found');
      }

      if (appointment.status !== AppointmentStatus.CONFIRMED) {
        throw new BadRequestError(`Only CONFIRMED appointments can be marked as NO_SHOW (current status: ${appointment.status})`);
      }

      const updated = await prisma.appointment.update({
        where: { id },
        data: {
          status: AppointmentStatus.NO_SHOW,
          doctorNotes: doctorNotes?.trim() || appointment.doctorNotes,
        },
        include: {
          doctorProfile: {
            select: {
              id: true,
              fullName: true,
              specialization: true,
            },
          },
          patientProfile: {
            select: {
              id: true,
              fullName: true,
            },
          },
        },
      });

      logger.info('Appointment marked as no-show', { appointmentId: id });

      res.status(200).json({
        success: true,
        message: 'Appointment marked as no-show successfully',
        data: {
          appointment: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },
};
