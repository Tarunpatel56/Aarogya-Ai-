import { Router } from 'express';
import { Role } from '@prisma/client';
import { prescriptionController } from '../controllers/prescription.controller';
import { authenticate, requireRoles } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

// Doctor authors a digital prescription
router.post(
  '/',
  requireRoles(Role.DOCTOR, Role.HOSPITAL_ADMIN, Role.PLATFORM_ADMIN),
  prescriptionController.createPrescription
);

// Doctor views prescriptions they have authored
router.get(
  '/doctor/me',
  requireRoles(Role.DOCTOR),
  prescriptionController.getDoctorPrescriptions
);

// View prescriptions for a specific patient
router.get(
  '/patient/:id',
  prescriptionController.getPatientPrescriptions
);

// View single prescription details
router.get(
  '/:id',
  prescriptionController.getPrescriptionById
);

// Doctor updates an authored prescription
router.patch(
  '/:id',
  requireRoles(Role.DOCTOR, Role.HOSPITAL_ADMIN, Role.PLATFORM_ADMIN),
  prescriptionController.updatePrescription
);

export const prescriptionRoutes = router;

