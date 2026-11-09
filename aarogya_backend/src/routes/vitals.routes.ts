import { Router } from 'express';
import { vitalsController } from '../controllers/vitals.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protect all vitals and device routes
router.use(authenticate);

// Vitals synchronization and querying
router.post('/sync', vitalsController.sync);
router.get('/latest', vitalsController.getLatest);
router.get('/history', vitalsController.getHistory);
router.get('/summary', vitalsController.getSummary);

export const vitalsRoutes = router;

// Devices sub-router
const deviceRouter = Router();
deviceRouter.use(authenticate);

deviceRouter.get('/', vitalsController.getDevices);
deviceRouter.post('/connect', vitalsController.connectDevice);
deviceRouter.post('/disconnect', vitalsController.disconnectDevice);
deviceRouter.get('/status', vitalsController.getDeviceStatus);

export const deviceRoutes = deviceRouter;
