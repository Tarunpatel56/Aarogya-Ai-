import { Router } from 'express';
import { Role } from '@prisma/client';
import { physiotherapyController } from '../controllers/physiotherapy.controller';
import { authenticate, requireRoles } from '../middleware/auth.middleware';

const router = Router();

// 1. Patient routes (record session & view personal physiotherapy log)
router.post(
  '/sessions',
  authenticate,
  requireRoles(Role.PATIENT),
  physiotherapyController.saveSession
);

router.get(
  '/sessions',
  authenticate,
  requireRoles(Role.PATIENT),
  physiotherapyController.getPatientSessions
);

// 2. Shared route: view individual session report
router.get(
  '/sessions/:id',
  authenticate,
  physiotherapyController.getSessionById
);

// 3. Clinical Doctor access: view patient's physiotherapy telemetry & recovery curve
router.get(
  '/doctor/patient/:patientProfileId',
  authenticate,
  requireRoles(Role.DOCTOR, Role.PLATFORM_ADMIN),
  physiotherapyController.getDoctorPatientSessions
);

export const physiotherapyRoutes = router;

