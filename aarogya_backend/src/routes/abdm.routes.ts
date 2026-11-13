import { Router } from 'express';
import { abdmController } from '../controllers/abdm.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.post('/generate-otp', authenticate, abdmController.generateOtp);
router.post('/create-or-link', authenticate, abdmController.createOrLinkAbha);
router.get('/profile/:patientProfileId', authenticate, abdmController.getAbhaProfile);
router.post('/consent/request', authenticate, abdmController.requestConsent);
router.patch('/consent/:id/action', authenticate, abdmController.updateConsent);

export const abdmRoutes = router;

