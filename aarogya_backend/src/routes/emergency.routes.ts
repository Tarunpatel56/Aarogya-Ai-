import { Router } from 'express';
import { Role } from '@prisma/client';
import { emergencyController } from '../controllers/emergency.controller';
import { authenticate, requireRoles } from '../middleware/auth.middleware';

const router = Router();

// Gated for authenticated users
router.use(authenticate);

// Patient initiates SOS dispatch
router.post('/sos', requireRoles(Role.PATIENT), emergencyController.createEmergencySos);

// Check if patient currently has an active dispatch
router.get('/sos/active', requireRoles(Role.PATIENT), emergencyController.getActiveEmergency);

// Live emergency details & coordinates
router.get('/sos/:id', emergencyController.getEmergencyById);

// Patient cancels active request
router.patch('/sos/:id/cancel', requireRoles(Role.PATIENT), emergencyController.cancelEmergency);

// Simulation / Driver tracking update
router.patch('/sos/:id/simulate-move', emergencyController.simulateProgress);

export const emergencyRoutes = router;

