import { z } from 'zod';
import { passwordSchema, emailSchema } from './auth.validation';

export const queryUsersSchema = {
  query: z.object({
    limit: z
      .string()
      .optional()
      .transform((val) => (val ? parseInt(val, 10) : 20))
      .refine((val) => val > 0 && val <= 100, { message: 'limit must be between 1 and 100' }),
    offset: z
      .string()
      .optional()
      .transform((val) => (val ? parseInt(val, 10) : 0))
      .refine((val) => val >= 0, { message: 'offset must be 0 or greater' }),
    role: z
      .enum(['PATIENT', 'DOCTOR', 'HOSPITAL_ADMIN', 'DRIVER', 'AMBULANCE_DRIVER', 'SUPER_ADMIN', 'PLATFORM_ADMIN', 'PARAMEDIC'])
      .optional(),
    isActive: z
      .string()
      .optional()
      .transform((val) => (val === undefined ? undefined : val === 'true')),
    verificationStatus: z
      .enum(['PENDING', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED', 'SUSPENDED'])
      .optional(),
    search: z.string().trim().optional(),
  }),
};

export const adminCreateUserSchema = {
  body: z.object({
    email: emailSchema,
    password: passwordSchema,
    role: z.enum([
      'PATIENT',
      'HOSPITAL_ADMIN',
      'DRIVER',
      'AMBULANCE_DRIVER',
      'SUPER_ADMIN',
      'PLATFORM_ADMIN',
      'DOCTOR',
    ]),
    fullName: z.string().trim().min(2, 'Full name must be at least 2 characters'),
    phone: z.string().trim().optional(),
  }),
};

export const updateUserStatusSchema = {
  body: z.object({
    isActive: z.boolean({ required_error: 'isActive (boolean) is required' }),
    reason: z.string().trim().optional(),
  }),
};

export const assignUserRoleSchema = {
  body: z.object({
    role: z.enum([
      'PATIENT',
      'HOSPITAL_ADMIN',
      'DRIVER',
      'AMBULANCE_DRIVER',
      'SUPER_ADMIN',
      'PLATFORM_ADMIN',
      'DOCTOR',
    ], {
      required_error: 'role is required',
    }),
  }),
};

