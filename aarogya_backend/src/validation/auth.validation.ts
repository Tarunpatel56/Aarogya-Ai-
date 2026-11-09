import { z } from 'zod';

const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,128}$/;

export const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters long')
  .max(128, 'Password must not exceed 128 characters')
  .regex(
    passwordRegex,
    'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
  );

export const emailSchema = z
  .string()
  .email('Invalid email address')
  .transform((val) => val.trim().toLowerCase());

export const phoneSchema = z
  .string()
  .trim()
  .min(7, 'Phone number must be at least 7 digits')
  .max(15, 'Phone number must not exceed 15 digits');

export const registerPatientSchema = {
  body: z.object({
    email: emailSchema,
    password: passwordSchema,
    fullName: z.string().trim().min(2, 'Full name must be at least 2 characters'),
    phone: z.string().trim().optional(),
    dateOfBirth: z.string().optional().transform((val) => (val ? new Date(val) : undefined)),
    gender: z.string().trim().optional(),
    bloodGroup: z.string().trim().optional(),
    abhaId: z.string().trim().optional(),
    emergencyContactName: z.string().trim().optional(),
    emergencyContactPhone: z.string().trim().optional(),
    allergies: z.string().trim().optional(),
    address: z.string().trim().optional(),
  }),
};

export const registerDoctorSchema = {
  body: z
    .object({
      email: emailSchema,
      password: passwordSchema,
      fullName: z.string().trim().min(2, 'Full name must be at least 2 characters'),
      phone: z.string().trim().optional(),
      phoneNumber: z.string().trim().optional(),
      nmcRegistrationNumber: z.string().trim().min(3, 'NMC Registration Number is required').optional(),
      medicalLicenseNumber: z.string().trim().min(3, 'Medical License Number is required').optional(),
      specialization: z.string().trim().min(2, 'Specialization is required'),
      qualifications: z.string().trim().min(2, 'Qualifications are required'),
      experienceYears: z.number().int().min(0).default(0),
      hospitalAffiliation: z.string().trim().optional(),
      consultationFee: z.number().optional(),
      consultationModes: z.array(z.string()).optional(),
      clinicAddress: z.string().trim().optional(),
      bio: z.string().trim().optional(),
    })
    .refine((data) => !!(data.nmcRegistrationNumber || data.medicalLicenseNumber), {
      message: 'NMC / Medical License registration number is required',
      path: ['nmcRegistrationNumber'],
    }),
};

export const registerHospitalAdminSchema = {
  body: z.object({
    email: emailSchema,
    password: passwordSchema,
    fullName: z.string().trim().min(2, 'Full name must be at least 2 characters'),
    phone: z.string().trim().optional(),
    hospitalName: z.string().trim().min(2, 'Hospital Name is required'),
    hospitalLicenseNumber: z.string().trim().min(2, 'Hospital License Number is required'),
    designation: z.string().trim().min(2, 'Designation is required'),
  }),
};

export const registerAmbulanceStaffSchema = {
  body: z.object({
    email: emailSchema,
    password: passwordSchema,
    fullName: z.string().trim().min(2, 'Full name must be at least 2 characters'),
    phone: z.string().trim().optional(),
    staffRole: z.enum(['AMBULANCE_DRIVER', 'PARAMEDIC'], {
      errorMap: () => ({ message: 'staffRole must be either AMBULANCE_DRIVER or PARAMEDIC' }),
    }),
    licenseNumber: z.string().trim().min(2, 'License or Certification number is required'),
    certificationLevel: z.string().trim().optional(),
    assignedVehicleNumber: z.string().trim().optional(),
  }),
};

export const loginSchema = {
  body: z
    .object({
      email: emailSchema.optional(),
      phone: phoneSchema.optional(),
      password: z.string().min(1, 'Password is required'),
    })
    .refine((data) => Boolean(data.email || data.phone), {
      message: 'Either email or phone number is required',
    }),
};

export const sendOtpSchema = {
  body: z.object({
    phone: phoneSchema,
  }),
};

export const verifyOtpSchema = {
  body: z.object({
    phone: phoneSchema,
    otp: z.string().min(4, 'OTP code must be at least 4 digits').max(8),
  }),
};

export const forgotPasswordSchema = {
  body: z
    .object({
      email: emailSchema.optional(),
      phone: phoneSchema.optional(),
    })
    .refine((data) => Boolean(data.email || data.phone), {
      message: 'Either email or phone is required',
    }),
};

export const resetPasswordSchema = {
  body: z
    .object({
      email: emailSchema.optional(),
      phone: phoneSchema.optional(),
      otp: z.string().optional(),
      newPassword: passwordSchema,
    })
    .refine((data) => Boolean(data.email || data.phone), {
      message: 'Either email or phone is required',
    }),
};

export const refreshTokenSchema = {
  body: z.object({
    refreshToken: z.string().min(1, 'Refresh token is required'),
  }),
};

export const logoutSchema = {
  body: z.object({
    refreshToken: z.string().optional(),
  }),
};
