import { z } from 'zod';
import { ConsultationMode, AppointmentStatus } from '@prisma/client';

export const createAppointmentSchema = {
  body: z
    .object({
      doctorProfileId: z.string().uuid({ message: 'doctorProfileId must be a valid UUID' }),
      startTime: z
        .string()
        .datetime({ message: 'startTime must be a valid ISO 8601 datetime' })
        .transform((val) => new Date(val)),
      endTime: z
        .string()
        .datetime({ message: 'endTime must be a valid ISO 8601 datetime' })
        .transform((val) => new Date(val))
        .optional(),
      durationMinutes: z
        .number()
        .int('durationMinutes must be an integer')
        .min(5, 'Minimum consultation duration is 5 minutes')
        .max(240, 'Maximum consultation duration is 240 minutes')
        .optional(),
      mode: z.nativeEnum(ConsultationMode).default(ConsultationMode.IN_PERSON),
      reason: z.string().trim().max(1000, 'Reason must not exceed 1000 characters').optional(),
    })
    .refine(
      (data) => {
        // If endTime is missing, durationMinutes must be present
        return data.endTime !== undefined || data.durationMinutes !== undefined;
      },
      {
        message: 'Either endTime or durationMinutes must be provided',
        path: ['endTime'],
      }
    )
    .refine(
      (data) => {
        const computedEnd =
          data.endTime || (data.durationMinutes ? new Date(data.startTime.getTime() + data.durationMinutes * 60000) : null);
        return computedEnd && computedEnd > data.startTime;
      },
      {
        message: 'endTime must be strictly later than startTime',
        path: ['endTime'],
      }
    )
    .refine((data) => data.startTime.getTime() >= Date.now() - 60000, {
      message: 'Cannot schedule an appointment in the past',
      path: ['startTime'],
    }),
};

export const queryAppointmentsSchema = {
  query: z.object({
    status: z.nativeEnum(AppointmentStatus).optional(),
    from: z
      .string()
      .datetime({ message: 'from must be a valid ISO 8601 datetime' })
      .transform((val) => new Date(val))
      .optional(),
    to: z
      .string()
      .datetime({ message: 'to must be a valid ISO 8601 datetime' })
      .transform((val) => new Date(val))
      .optional(),
    limit: z
      .string()
      .optional()
      .transform((val) => (val ? Math.min(Math.max(parseInt(val, 10) || 20, 1), 100) : 20)),
    offset: z
      .string()
      .optional()
      .transform((val) => (val ? Math.max(parseInt(val, 10) || 0, 0) : 0)),
  }),
};

export const cancelAppointmentSchema = {
  body: z.object({
    reason: z.string().trim().max(500, 'Cancellation reason must not exceed 500 characters').optional(),
    cancellationReason: z.string().trim().max(500, 'Cancellation reason must not exceed 500 characters').optional(),
  }),
};

export const doctorConfirmAppointmentSchema = {
  body: z.object({
    doctorNotes: z.string().trim().max(1000, 'Doctor notes must not exceed 1000 characters').optional(),
  }),
};

export const doctorRejectAppointmentSchema = {
  body: z.object({
    reason: z.string().trim().max(500, 'Rejection reason must not exceed 500 characters').optional(),
    rejectionReason: z.string().trim().max(500, 'Rejection reason must not exceed 500 characters').optional(),
    doctorNotes: z.string().trim().max(1000, 'Doctor notes must not exceed 1000 characters').optional(),
  }),
};

export const doctorCompleteAppointmentSchema = {
  body: z.object({
    doctorNotes: z.string().trim().max(2000, 'Doctor notes must not exceed 2000 characters').optional(),
  }),
};

export const doctorNoShowAppointmentSchema = {
  body: z.object({
    doctorNotes: z.string().trim().max(1000, 'Doctor notes must not exceed 1000 characters').optional(),
  }),
};
