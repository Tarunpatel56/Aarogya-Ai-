import { Router } from 'express';
import { Role } from '@prisma/client';
import { driverController } from '../controllers/driver.controller';
import { authenticate, requireRoles } from '../middleware/auth.middleware';

const router = Router();

// Gated strictly for DRIVER / AMBULANCE_DRIVER / PARAMEDIC authority
router.use(authenticate, requireRoles(Role.AMBULANCE_DRIVER, Role.PARAMEDIC, 'DRIVER'));

// Self-service driver profile & vehicle assignment
router.get('/me', driverController.getProfile);
router.patch('/me', driverController.updateProfile);

// Assigned ambulance trips & emergency status reporting
router.get('/dispatches', driverController.getAvailableDispatches);
router.post('/trips/:id/accept', driverController.acceptEmergencyDispatch);
router.get('/me/trips', driverController.getAssignedTrips);
router.patch('/me/trips/:id/status', driverController.updateTripStatus);

export const driverRoutes = router;

