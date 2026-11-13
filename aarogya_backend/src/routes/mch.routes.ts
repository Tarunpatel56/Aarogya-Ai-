import { Router } from 'express';
import { mchController } from '../controllers/mch.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.get('/profiles/:patientProfileId', authenticate, mchController.getProfiles);
router.post('/profiles', authenticate, mchController.createProfile);
router.patch('/vaccine-status', authenticate, mchController.updateVaccineStatus);

export const mchRoutes = router;

