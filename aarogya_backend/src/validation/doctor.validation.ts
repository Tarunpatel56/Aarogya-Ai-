import { z } from 'zod';
import { ConsultationMode, AvailabilityStatus, VerificationStatus } from '@prisma/client';

export const updateDoctorProfileSchema = {
  body: z.object({
    fullName: z.string().trim().min(2, 'Full name must be at least 2 characters').max(100).optional(),
    phone: z.string().trim().min(7, 'Invalid phone number').max(20).optional(),
    specialization: z.string().trim().min(2, 'Specialization must be at least 2 characters').max(100).optional(),
    qualifications: z.string().trim().min(2, 'Qualifications must be at least 2 characters').max(200).optional(),
    experienceYears: z.number().int('Experience years must be an integer').min(0, 'Experience years cannot be negative').optional(),
    consultationFee: z.number().min(0, 'Consultation fee cannot be negative').optional(),
    bio: z.string().trim().max(2000, 'Bio must not exceed 2000 characters').optional(),
    languages: z.array(z.string().trim().min(1)).min(1, 'At least one language must be specified').optional(),
    consultationModes: z.array(z.nativeEnum(ConsultationMode)).min(1, 'At least one consultation mode must be specified').optional(),
    clinicAddress: z.string().trim().max(500, 'Clinic address must not exceed 500 characters').optional(),
    hospitalAffiliation: z.string().trim().max(200).optional(),
    isOnline: z.boolean().optional(),
    status: z.string().optional(),
  }),
};

export const createAvailabilitySchema = {
  body: z
    .object({
      startTime: z.string().datetime({ message: 'startTime must be a valid ISO 8601 datetime' }).transform((val) => new Date(val)),
      endTime: z.string().datetime({ message: 'endTime must be a valid ISO 8601 datetime' }).transform((val) => new Date(val)),
      timeZone: z.string().trim().max(50).default('Asia/Kolkata'),
      status: z.nativeEnum(AvailabilityStatus).default(AvailabilityStatus.AVAILABLE),
      isRecurring: z.boolean().default(false),
      dayOfWeek: z.number().int().min(0).max(6).optional(),
    })
    .refine((data) => data.endTime > data.startTime, {
      message: 'endTime must be strictly later than startTime',
      path: ['endTime'],
    })
    .refine((data) => data.startTime.getTime() >= Date.now() - 60000, {
      message: 'Cannot create availability in the past',
      path: ['startTime'],
    }),
};

export const updateAvailabilitySchema = {
  body: z
    .object({
      startTime: z.string().datetime({ message: 'startTime must be a valid ISO 8601 datetime' }).transform((val) => new Date(val)).optional(),
      endTime: z.string().datetime({ message: 'endTime must be a valid ISO 8601 datetime' }).transform((val) => new Date(val)).optional(),
      timeZone: z.string().trim().max(50).optional(),
      status: z.nativeEnum(AvailabilityStatus).optional(),
      isRecurring: z.boolean().optional(),
      dayOfWeek: z.number().int().min(0).max(6).optional(),
    })
    .refine(
      (data) => {
        if (data.startTime && data.endTime) {
          return data.endTime > data.startTime;
        }
        return true;
      },
      {
        message: 'endTime must be strictly later than startTime',
        path: ['endTime'],
      }
    ),
};

export const queryDoctorListSchema = {
  query: z.object({
    specialization: z.string().trim().optional(),
    consultationMode: z.nativeEnum(ConsultationMode).optional(),
    search: z.string().trim().optional(),
    limit: z
      .string()
      .optional()
      .transform((val) => (val ? parseInt(val, 10) : 20))
      .pipe(z.number().int().min(1).max(100)),
    offset: z
      .string()
      .optional()
      .transform((val) => (val ? parseInt(val, 10) : 0))
      .pipe(z.number().int().min(0)),
  }),
};

export const queryDoctorAvailabilitySchema = {
  query: z.object({
    from: z.string().datetime().optional().transform((val) => (val ? new Date(val) : undefined)),
    to: z.string().datetime().optional().transform((val) => (val ? new Date(val) : undefined)),
    status: z.nativeEnum(AvailabilityStatus).optional(),
  }),
};

export const adminVerifyDoctorSchema = {
  body: z.object({
    status: z.nativeEnum(VerificationStatus, {
      errorMap: () => ({ message: 'status must be a valid VerificationStatus (VERIFIED, REJECTED, UNDER_REVIEW, SUSPENDED)' }),
    }),
    notes: z.string().trim().max(500).nullish(),
  }),
};
