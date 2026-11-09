import { z } from 'zod';
import { RecordType } from '@prisma/client';

export const updatePatientProfileSchema = {
  body: z.object({
    fullName: z.string().trim().min(2, 'Full name must be at least 2 characters').max(100).optional(),
    phone: z.string().trim().min(7, 'Invalid phone number').max(20).optional(),
    dateOfBirth: z
      .string()
      .optional()
      .transform((val) => (val ? new Date(val) : undefined)),
    gender: z.string().trim().max(30).optional(),
    bloodGroup: z.string().trim().max(10).optional(),
    abhaId: z.string().trim().max(50).optional(),
    allergies: z.string().trim().max(500).optional(),
    address: z.string().trim().max(500).optional(),
    emergencyContactName: z.string().trim().max(100).optional(),
    emergencyContactPhone: z.string().trim().max(20).optional(),
  }),
};

export const createMedicalRecordSchema = {
  body: z.object({
    recordType: z.nativeEnum(RecordType, {
      errorMap: () => ({ message: `Invalid record type. Must be one of: ${Object.values(RecordType).join(', ')}` }),
    }),
    title: z.string().trim().min(2, 'Title must be at least 2 characters').max(150),
    description: z.string().trim().max(2000).optional(),
    recordDate: z
      .string()
      .optional()
      .transform((val) => (val ? new Date(val) : new Date())),
    documentMetadata: z
      .object({
        fileRef: z.string().trim().max(500).optional(),
        mimeType: z.string().trim().max(100).optional(),
        fileSizeBytes: z.number().int().positive().optional(),
        checksumSha256: z.string().trim().max(64).optional(),
        notes: z.string().trim().max(500).optional(),
      })
      .optional(),
    issuingDoctor: z.string().trim().max(150).optional(),
    facilityName: z.string().trim().max(150).optional(),
  }),
};

export const queryMedicalRecordsSchema = {
  query: z.object({
    recordType: z.nativeEnum(RecordType).optional(),
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
