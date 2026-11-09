import { Request, Response, NextFunction } from 'express';
import { Role } from '@prisma/client';
import { prisma } from '../config/prisma';
import { BadRequestError, NotFoundError, ForbiddenError } from '../utils/AppError';
import { socketService } from '../services/socket.service';

export const prescriptionController = {
  /**
   * Doctor creates a new digital prescription for a patient
   */
  async createPrescription(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const doctorUserId = req.user!.id;
      const {
        patientProfileId,
        appointmentId,
        diagnosis,
        doctorNotes,
        generalAdvice,
        followUpDate,
        digitalSignature,
        items,
      } = req.body;

      if (!patientProfileId || !diagnosis) {
        throw new BadRequestError('PatientProfileId and diagnosis are required');
      }

      if (!items || !Array.isArray(items) || items.length === 0) {
        throw new BadRequestError('Prescription must contain at least one medication item');
      }

      // Verify doctor profile
      const doctorProfile = await prisma.doctorProfile.findUnique({
        where: { userId: doctorUserId },
      });

      if (!doctorProfile) {
        throw new NotFoundError('Doctor profile not found');
      }

      // Verify patient profile
      const patientProfile = await prisma.patientProfile.findUnique({
        where: { id: patientProfileId },
        include: {
          user: true,
        },
      });

      if (!patientProfile) {
        throw new NotFoundError('Patient profile not found');
      }

      // Create prescription with medication items in a single transaction
      const prescription = await prisma.prescription.create({
        data: {
          patientProfileId,
          doctorProfileId: doctorProfile.id,
          appointmentId: appointmentId || undefined,
          diagnosis: String(diagnosis).trim(),
          doctorNotes: doctorNotes ? String(doctorNotes).trim() : undefined,
          generalAdvice: generalAdvice ? String(generalAdvice).trim() : undefined,
          followUpDate: followUpDate ? new Date(followUpDate) : undefined,
          digitalSignature: digitalSignature || `Dr. ${doctorProfile.fullName} • Reg: ${doctorProfile.nmcRegistrationNumber}`,
          items: {
            create: items.map((item: any) => ({
              medicineName: String(item.medicineName || '').trim(),
              dosage: String(item.dosage || '1 unit').trim(),
              frequency: String(item.frequency || 'Daily').trim(),
              durationDays: Number(item.durationDays) || 5,
              timing: item.timing ? String(item.timing).trim() : undefined,
              instructions: item.instructions ? String(item.instructions).trim() : undefined,
            })),
          },
        },
        include: {
          items: true,
          doctorProfile: true,
          patientProfile: true,
        },
      });

      // Notify the patient in real time via Socket.IO
      socketService.emitPrescriptionCreated(patientProfile.userId, {
        id: prescription.id,
        diagnosis: prescription.diagnosis,
        doctorName: doctorProfile.fullName,
        itemsCount: prescription.items.length,
        createdAt: prescription.createdAt,
      });

      // Also create an in-app persistent notification
      await prisma.notification.create({
        data: {
          userId: patientProfile.userId,
          type: 'APPOINTMENT_COMPLETED',
          title: 'New Digital Prescription',
          message: `Dr. ${doctorProfile.fullName} has issued a digital prescription for ${prescription.diagnosis}.`,
          metadata: {
            prescriptionId: prescription.id,
            doctorProfileId: doctorProfile.id,
          },
        },
      });

      res.status(201).json({
        success: true,
        message: 'Digital prescription created successfully',
        data: {
          prescription,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves prescriptions for a specific patient
   */
  async getPatientPrescriptions(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const patientProfileId = String(req.params.id);
      const user = req.user!;

      // Enforce consent/ownership: If user is PATIENT, they can only view their own
      if (user.role === Role.PATIENT) {
        const patientProfile = await prisma.patientProfile.findUnique({
          where: { userId: user.id },
        });
        if (!patientProfile || patientProfile.id !== patientProfileId) {
          throw new ForbiddenError('Access denied: You can only view your own prescriptions');
        }
      }

      const prescriptions = await prisma.prescription.findMany({
        where: { patientProfileId },
        include: {
          items: true,
          doctorProfile: {
            select: {
              fullName: true,
              specialization: true,
              nmcRegistrationNumber: true,
              hospitalAffiliation: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });

      res.status(200).json({
        success: true,
        data: {
          prescriptions,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves single prescription by ID
   */
  async getPrescriptionById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);

      const prescription = await prisma.prescription.findUnique({
        where: { id },
        include: {
          items: true,
          doctorProfile: true,
          patientProfile: true,
        },
      });

      if (!prescription) {
        throw new NotFoundError('Prescription not found');
      }

      res.status(200).json({
        success: true,
        data: {
          prescription,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves all prescriptions authored by the authenticated doctor
   */
  async getDoctorPrescriptions(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const doctorUserId = req.user!.id;

      const doctorProfile = await prisma.doctorProfile.findUnique({
        where: { userId: doctorUserId },
      });

      if (!doctorProfile) {
        throw new NotFoundError('Doctor profile not found');
      }

      const prescriptions = await prisma.prescription.findMany({
        where: { doctorProfileId: doctorProfile.id },
        include: {
          items: true,
          patientProfile: true,
        },
        orderBy: {
          createdAt: 'desc',
        },
      });

      res.status(200).json({
        success: true,
        data: {
          prescriptions,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Updates an authored prescription (notes, advice, follow-up, items)
   */
  async updatePrescription(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const doctorUserId = req.user!.id;
      const id = String(req.params.id);

      const doctorProfile = await prisma.doctorProfile.findUnique({
        where: { userId: doctorUserId },
      });

      if (!doctorProfile) {
        throw new NotFoundError('Doctor profile not found');
      }

      const existing = await prisma.prescription.findFirst({
        where: { id, doctorProfileId: doctorProfile.id },
      });

      if (!existing) {
        throw new NotFoundError('Prescription not found or unauthorized');
      }

      const { diagnosis, doctorNotes, generalAdvice, followUpDate, items } = req.body;

      const updated = await prisma.$transaction(async (tx) => {
        if (items && Array.isArray(items)) {
          await tx.prescriptionItem.deleteMany({
            where: { prescriptionId: id },
          });

          await tx.prescriptionItem.createMany({
            data: items.map((it: any) => ({
              prescriptionId: id,
              medicineName: String(it.medicineName || 'Medication').trim(),
              dosage: String(it.dosage || '1 unit').trim(),
              frequency: String(it.frequency || 'Daily').trim(),
              durationDays: Number(it.durationDays) || 5,
              timing: it.timing ? String(it.timing).trim() : null,
              instructions: it.instructions ? String(it.instructions).trim() : null,
            })),
          });
        }

        return tx.prescription.update({
          where: { id },
          data: {
            diagnosis: diagnosis !== undefined ? String(diagnosis).trim() : undefined,
            doctorNotes: doctorNotes !== undefined ? String(doctorNotes).trim() : undefined,
            generalAdvice: generalAdvice !== undefined ? String(generalAdvice).trim() : undefined,
            followUpDate: followUpDate ? new Date(followUpDate) : undefined,
          },
          include: {
            items: true,
            doctorProfile: true,
            patientProfile: true,
          },
        });
      });

      res.status(200).json({
        success: true,
        message: 'Prescription updated successfully',
        data: {
          prescription: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },
};

