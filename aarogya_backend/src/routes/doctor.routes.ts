import { Router } from 'express';
import { Role } from '@prisma/client';
import { doctorController } from '../controllers/doctor.controller';
import { authenticate, requireRoles } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validateRequest';
import {
  updateDoctorProfileSchema,
  createAvailabilitySchema,
  updateAvailabilitySchema,
  queryDoctorListSchema,
  queryDoctorAvailabilitySchema,
} from '../validation/doctor.validation';

const router = Router();

// ==============================================================================
// 1. Private Doctor Self-Service Endpoints (DOCTOR role required)
// NOTE: Mounted before /:id parameterized routes to avoid shadowing
// ==============================================================================
router.get(
  '/me',
  authenticate,
  requireRoles(Role.DOCTOR),
  doctorController.getProfile
);

router.patch(
  '/me',
  authenticate,
  requireRoles(Role.DOCTOR),
  validateRequest(updateDoctorProfileSchema),
  doctorController.updateProfile
);

router.patch(
  '/me/duty-status',
  authenticate,
  requireRoles(Role.DOCTOR),
  doctorController.updateDutyStatus
);

// Doctor availability management
router.get(
  '/me/availability',
  authenticate,
  requireRoles(Role.DOCTOR),
  validateRequest(queryDoctorAvailabilitySchema),
  doctorController.getMyAvailability
);

router.post(
  '/me/availability',
  authenticate,
  requireRoles(Role.DOCTOR),
  validateRequest(createAvailabilitySchema),
  doctorController.createMyAvailability
);

router.patch(
  '/me/availability/:id',
  authenticate,
  requireRoles(Role.DOCTOR),
  validateRequest(updateAvailabilitySchema),
  doctorController.updateMyAvailability
);

router.delete(
  '/me/availability/:id',
  authenticate,
  requireRoles(Role.DOCTOR),
  doctorController.deleteMyAvailability
);

// ==============================================================================
// 2. Public Doctor Directory Endpoints (Verified doctors only)
// ==============================================================================
router.get(
  '/',
  validateRequest(queryDoctorListSchema),
  doctorController.listPublicDoctors
);

router.get(
  '/:id',
  doctorController.getPublicDoctorById
);

router.get(
  '/:id/availability',
  doctorController.getPublicDoctorAvailability
);

export const doctorRoutes = router;
