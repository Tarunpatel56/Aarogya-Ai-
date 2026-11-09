import { Router } from 'express';
import { wearableController } from '../controllers/wearable.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protect all wearable routes with authentication token
router.use(authenticate);

// Query telemetry from the laptop-connected smartwatch bridge
router.get('/bridge/watch', wearableController.getWatchTelemetry);

// Query documented GATT capabilities of the watch model
router.get('/capabilities', wearableController.getCapabilities);

export const wearableRoutes = router;
