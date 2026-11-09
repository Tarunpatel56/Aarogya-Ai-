import { Request, Response, NextFunction } from 'express';
import { RecordType } from '@prisma/client';
import { prisma } from '../config/prisma';
import { NotFoundError, ConflictError } from '../utils/AppError';

export const patientController = {
  /**
   * Retrieves the authenticated patient's own profile and user metadata.
   */
  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      let profile = await prisma.patientProfile.findUnique({
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
          familyMembers: {
            orderBy: { createdAt: 'desc' },
          },
          _count: {
            select: {
              medicalRecords: true,
            },
          },
        },
      });

      if (!profile) {
        // Auto-heal: If authenticated user is a PATIENT, initialize patient profile
        if (req.user!.role === 'PATIENT') {
          const user = await prisma.user.findUnique({ where: { id: userId } });
          if (user) {
            const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
            profile = await prisma.patientProfile.create({
              data: {
                userId,
                fullName: fallbackName,
              },
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
                familyMembers: {
                  orderBy: { createdAt: 'desc' },
                },
                _count: {
                  select: {
                    medicalRecords: true,
                  },
                },
              },
            });
          }
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
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
   * Updates permitted fields on the authenticated patient's profile.
   * Privileged fields (role, verificationStatus, id, userId) cannot be modified.
   */
  async updateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const existingProfile = await prisma.patientProfile.findUnique({
        where: { userId },
      });

      if (!existingProfile) {
        throw new NotFoundError('Patient profile not found');
      }

      const {
        fullName,
        phone,
        dateOfBirth,
        gender,
        bloodGroup,
        abhaId,
        allergies,
        address,
        emergencyContactName,
        emergencyContactPhone,
      } = req.body;

      // Uniqueness validation for phone if changing
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

      // Uniqueness validation for ABHA ID if changing
      if (abhaId !== undefined && abhaId !== null && abhaId !== '') {
        const existingAbha = await prisma.patientProfile.findFirst({
          where: {
            abhaId,
            NOT: { userId },
          },
        });

        if (existingAbha) {
          throw new ConflictError('This ABHA ID is already linked to another profile');
        }
      }

      const updatedProfile = await prisma.$transaction(async (tx) => {
        if (phone !== undefined) {
          await tx.user.update({
            where: { id: userId },
            data: { phone },
          });
        }

        return tx.patientProfile.update({
          where: { userId },
          data: {
            ...(fullName !== undefined ? { fullName } : {}),
            ...(dateOfBirth !== undefined ? { dateOfBirth } : {}),
            ...(gender !== undefined ? { gender } : {}),
            ...(bloodGroup !== undefined ? { bloodGroup } : {}),
            ...(abhaId !== undefined ? { abhaId } : {}),
            ...(allergies !== undefined ? { allergies } : {}),
            ...(address !== undefined ? { address } : {}),
            ...(emergencyContactName !== undefined ? { emergencyContactName } : {}),
            ...(emergencyContactPhone !== undefined ? { emergencyContactPhone } : {}),
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

      res.status(200).json({
        success: true,
        message: 'Patient profile updated successfully',
        data: {
          profile: updatedProfile,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves medical records metadata authorized for the authenticated patient.
   */
  async getMedicalRecords(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      let profile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile && req.user!.role === 'PATIENT') {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (user) {
          const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
          profile = await prisma.patientProfile.create({
            data: {
              userId,
              fullName: fallbackName,
            },
            select: { id: true },
          });
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
      }

      const { recordType, limit = 20, offset = 0 } = req.query as {
        recordType?: RecordType;
        limit?: number;
        offset?: number;
      };

      const [records, total] = await Promise.all([
        prisma.medicalRecord.findMany({
          where: {
            patientProfileId: profile.id,
            ...(recordType ? { recordType } : {}),
          },
          orderBy: {
            recordDate: 'desc',
          },
          take: Number(limit),
          skip: Number(offset),
        }),
        prisma.medicalRecord.count({
          where: {
            patientProfileId: profile.id,
            ...(recordType ? { recordType } : {}),
          },
        }),
      ]);

      res.status(200).json({
        success: true,
        data: {
          records,
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
   * Creates a new metadata-only medical record for the authenticated patient.
   * Large binaries are not stored directly in PostgreSQL.
   */
  async createMedicalRecord(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      let profile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile && req.user!.role === 'PATIENT') {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (user) {
          const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
          profile = await prisma.patientProfile.create({
            data: {
              userId,
              fullName: fallbackName,
            },
            select: { id: true },
          });
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
      }

      const { recordType, title, description, recordDate, documentMetadata, issuingDoctor, facilityName } = req.body;

      const record = await prisma.medicalRecord.create({
        data: {
          patientProfileId: profile.id,
          recordType,
          title,
          description,
          recordDate: recordDate || new Date(),
          documentMetadata: documentMetadata || undefined,
          issuingDoctor,
          facilityName,
        },
      });

      res.status(201).json({
        success: true,
        message: 'Medical record entry created successfully',
        data: {
          record,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves a single medical record by ID, strictly isolating patient ownership.
   */
  async getMedicalRecordById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const id = String(req.params.id);

      const record = await prisma.medicalRecord.findFirst({
        where: {
          id,
          patientProfile: {
            userId,
          },
        },
      });

      if (!record) {
        // Return 404 to avoid leaking existence of records belonging to other patients
        throw new NotFoundError('Medical record not found');
      }

      res.status(200).json({
        success: true,
        data: {
          record,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves all family members registered under this patient profile.
   */
  async getFamilyMembers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      let profile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile && req.user!.role === 'PATIENT') {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (user) {
          const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
          profile = await prisma.patientProfile.create({
            data: {
              userId,
              fullName: fallbackName,
            },
            select: { id: true },
          });
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
      }

      const familyMembers = await prisma.familyMember.findMany({
        where: { patientProfileId: profile.id },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({
        success: true,
        data: {
          familyMembers,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Add a new family member to this patient profile.
   */
  async addFamilyMember(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      let profile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile && req.user!.role === 'PATIENT') {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (user) {
          const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
          profile = await prisma.patientProfile.create({
            data: {
              userId,
              fullName: fallbackName,
            },
            select: { id: true },
          });
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
      }

      const { fullName, relationship, dateOfBirth, gender, bloodGroup, allergies, medicalHistory } = req.body;

      if (!fullName || !relationship) {
        throw new ConflictError('Full name and relationship are required for family member');
      }

      const familyMember = await prisma.familyMember.create({
        data: {
          patientProfileId: profile.id,
          fullName: String(fullName).trim(),
          relationship: String(relationship).trim(),
          dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : undefined,
          gender: gender ? String(gender).trim() : undefined,
          bloodGroup: bloodGroup ? String(bloodGroup).trim() : undefined,
          allergies: allergies ? String(allergies).trim() : undefined,
          medicalHistory: medicalHistory ? String(medicalHistory).trim() : undefined,
        },
      });

      res.status(201).json({
        success: true,
        message: 'Family member registered successfully',
        data: {
          familyMember,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Update an existing family member record.
   */
  async updateFamilyMember(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const id = String(req.params.id);

      let profile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile && req.user!.role === 'PATIENT') {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (user) {
          const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
          profile = await prisma.patientProfile.create({
            data: {
              userId,
              fullName: fallbackName,
            },
            select: { id: true },
          });
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
      }

      const existing = await prisma.familyMember.findFirst({
        where: { id, patientProfileId: profile.id },
      });

      if (!existing) {
        throw new NotFoundError('Family member record not found');
      }

      const { fullName, relationship, dateOfBirth, gender, bloodGroup, allergies, medicalHistory } = req.body;

      const updated = await prisma.familyMember.update({
        where: { id },
        data: {
          fullName: fullName !== undefined ? String(fullName).trim() : undefined,
          relationship: relationship !== undefined ? String(relationship).trim() : undefined,
          dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : undefined,
          gender: gender !== undefined ? String(gender).trim() : undefined,
          bloodGroup: bloodGroup !== undefined ? String(bloodGroup).trim() : undefined,
          allergies: allergies !== undefined ? String(allergies).trim() : undefined,
          medicalHistory: medicalHistory !== undefined ? String(medicalHistory).trim() : undefined,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Family member updated successfully',
        data: {
          familyMember: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Remove a family member from this patient profile.
   */
  async deleteFamilyMember(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const id = String(req.params.id);

      let profile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile && req.user!.role === 'PATIENT') {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (user) {
          const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
          profile = await prisma.patientProfile.create({
            data: {
              userId,
              fullName: fallbackName,
            },
            select: { id: true },
          });
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
      }

      await prisma.familyMember.deleteMany({
        where: {
          id,
          patientProfileId: profile.id,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Family member removed successfully',
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves active medicine reminders and today's dose logs for this patient.
   */
  async getMedicineReminders(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      let profile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile && req.user!.role === 'PATIENT') {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (user) {
          const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
          profile = await prisma.patientProfile.create({
            data: {
              userId,
              fullName: fallbackName,
            },
            select: { id: true },
          });
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
      }

      const reminders = await prisma.medicineReminder.findMany({
        where: {
          patientProfileId: profile.id,
          isActive: true,
        },
        include: {
          doseLogs: {
            orderBy: { scheduledTime: 'desc' },
            take: 10,
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({
        success: true,
        data: {
          count: reminders.length,
          reminders,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Add a new medicine reminder schedule.
   */
  async addMedicineReminder(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      let profile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile && req.user!.role === 'PATIENT') {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (user) {
          const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
          profile = await prisma.patientProfile.create({
            data: {
              userId,
              fullName: fallbackName,
            },
            select: { id: true },
          });
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
      }

      const { medicineName, dosage, dosageForm, frequency, reminderTimes, instructions, startDate, endDate } = req.body;

      if (!medicineName || !dosage) {
        throw new NotFoundError('Medicine name and dosage are required');
      }

      const reminder = await prisma.medicineReminder.create({
        data: {
          patientProfileId: profile.id,
          medicineName: String(medicineName).trim(),
          dosage: String(dosage).trim(),
          dosageForm: dosageForm || 'Tablet',
          frequency: frequency || 'Once Daily',
          reminderTimes: Array.isArray(reminderTimes) && reminderTimes.length > 0 ? reminderTimes : ['08:00 AM'],
          instructions: instructions ? String(instructions).trim() : null,
          startDate: startDate ? new Date(startDate) : new Date(),
          endDate: endDate ? new Date(endDate) : null,
        },
      });

      res.status(201).json({
        success: true,
        message: 'Medicine reminder created successfully',
        data: { reminder },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Log an adherence status for a dose (TAKEN, MISSED, SKIPPED).
   */
  async logMedicineDose(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const { status, scheduledTime } = req.body;

      const validStatus = status === 'MISSED' ? 'MISSED' : status === 'SKIPPED' ? 'SKIPPED' : 'TAKEN';

      const doseLog = await prisma.medicineDoseLog.create({
        data: {
          medicineReminderId: id,
          status: validStatus,
          scheduledTime: scheduledTime ? new Date(scheduledTime) : new Date(),
          takenAt: validStatus === 'TAKEN' ? new Date() : null,
        },
      });

      res.status(201).json({
        success: true,
        message: `Dose logged as ${validStatus}`,
        data: { doseLog },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Delete or deactivate a medicine reminder.
   */
  async deleteMedicineReminder(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const id = String(req.params.id);

      let profile = await prisma.patientProfile.findUnique({
        where: { userId },
        select: { id: true },
      });

      if (!profile && req.user!.role === 'PATIENT') {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (user) {
          const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
          profile = await prisma.patientProfile.create({
            data: {
              userId,
              fullName: fallbackName,
            },
            select: { id: true },
          });
        }
      }

      if (!profile) {
        throw new NotFoundError('Patient profile not found');
      }

      await prisma.medicineReminder.deleteMany({
        where: {
          id,
          patientProfileId: profile.id,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Medicine reminder removed successfully',
      });
    } catch (error) {
      next(error);
    }
  },
};
