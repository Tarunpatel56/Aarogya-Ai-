import { Router } from 'express';
import { Role } from '@prisma/client';
import { appointmentController } from '../controllers/appointment.controller';
import { authenticate, requireRoles, requireVerified } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validateRequest';
import {
  createAppointmentSchema,
  queryAppointmentsSchema,
  cancelAppointmentSchema,
  doctorConfirmAppointmentSchema,
  doctorRejectAppointmentSchema,
  doctorCompleteAppointmentSchema,
  doctorNoShowAppointmentSchema,
} from '../validation/appointment.validation';

const router = Router();

// All appointment endpoints require valid authentication
router.use(authenticate);

// 1. Patient requests a new appointment
router.post(
  '/',
  requireRoles(Role.PATIENT),
  validateRequest(createAppointmentSchema),
  appointmentController.createAppointment
);

// 2. List appointments for authenticated patient or doctor
router.get(
  '/',
  requireRoles(Role.PATIENT, Role.DOCTOR),
  validateRequest(queryAppointmentsSchema),
  appointmentController.getAppointments
);

// 3. Retrieve single appointment by ID
router.get(
  '/:id',
  requireRoles(Role.PATIENT, Role.DOCTOR, Role.PLATFORM_ADMIN),
  appointmentController.getAppointmentById
);

// 4. Cancel appointment (Patient or Doctor)
router.patch(
  '/:id/cancel',
  requireRoles(Role.PATIENT, Role.DOCTOR),
  validateRequest(cancelAppointmentSchema),
  appointmentController.cancelAppointment
);

// 4b. Reschedule appointment (Patient or Doctor)
router.patch(
  '/:id/reschedule',
  requireRoles(Role.PATIENT, Role.DOCTOR),
  appointmentController.rescheduleAppointment
);

// 5. Doctor accepts/confirms an appointment request
router.patch(
  '/:id/confirm',
  requireRoles(Role.DOCTOR),
  requireVerified,
  validateRequest(doctorConfirmAppointmentSchema),
  appointmentController.confirmAppointment
);

// 6. Doctor rejects an appointment request
router.patch(
  '/:id/reject',
  requireRoles(Role.DOCTOR),
  requireVerified,
  validateRequest(doctorRejectAppointmentSchema),
  appointmentController.rejectAppointment
);

// 7. Doctor completes a confirmed consultation
router.patch(
  '/:id/complete',
  requireRoles(Role.DOCTOR),
  requireVerified,
  validateRequest(doctorCompleteAppointmentSchema),
  appointmentController.completeAppointment
);

// 8. Doctor marks a confirmed appointment as no-show
router.patch(
  '/:id/no-show',
  requireRoles(Role.DOCTOR),
  requireVerified,
  validateRequest(doctorNoShowAppointmentSchema),
  appointmentController.markNoShow
);

export const appointmentRoutes = router;
