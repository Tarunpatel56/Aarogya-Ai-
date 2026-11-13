import { Router } from 'express';
import { referralController } from '../controllers/referral.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.post('/', authenticate, referralController.createReferral);
router.get('/doctor/:doctorId', authenticate, referralController.getDoctorReferrals);
router.patch('/:id/respond', authenticate, referralController.respondToReferral);

export const referralRoutes = router;

