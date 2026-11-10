import { Router } from 'express';
import { Role } from '@prisma/client';
import { hospitalController } from '../controllers/hospital.controller';
import { authenticate, requireRoles } from '../middleware/auth.middleware';

const router = Router();

// 1. Specific static sub-paths first
// Public / Authenticated nearby hospital directory with live verified ICU beds
router.get('/nearby', hospitalController.getNearbyHospitals);

// Gated strictly for HOSPITAL_ADMIN authority
router.get('/me', authenticate, requireRoles(Role.HOSPITAL_ADMIN), hospitalController.getProfile);
router.patch('/me', authenticate, requireRoles(Role.HOSPITAL_ADMIN), hospitalController.updateProfile);

// Hospital-isolated staff directory & appointments
router.get('/me/staff', authenticate, requireRoles(Role.HOSPITAL_ADMIN), hospitalController.getHospitalStaff);
router.post('/me/staff', authenticate, requireRoles(Role.HOSPITAL_ADMIN), hospitalController.addHospitalStaff);
router.get('/me/appointments', authenticate, requireRoles(Role.HOSPITAL_ADMIN), hospitalController.getHospitalAppointments);

// 2. Hospital granular beds & ward inventory
router.get('/:id/beds', authenticate, hospitalController.getHospitalBeds);
router.patch(
  '/:id/beds/:bedId',
  authenticate,
  requireRoles(Role.HOSPITAL_ADMIN, Role.PLATFORM_ADMIN, Role.DOCTOR),
  hospitalController.updateBedStatus
);

// 3. Generic parameterized route at the bottom
router.get('/:id', authenticate, hospitalController.getHospitalById);

export const hospitalRoutes = router;

