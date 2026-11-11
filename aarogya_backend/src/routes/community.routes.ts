import { Router } from 'express';
import { communityController } from '../controllers/community.controller';

const router = Router();

// Public / User Accessible Endpoints
router.get('/government-schemes', communityController.getSchemes);
router.get('/government-schemes/:id', communityController.getSchemeById);

router.get('/blood-donors', communityController.getBloodDonors);
router.post('/blood-donors', communityController.registerBloodDonor);

router.get('/health-camps', communityController.getHealthCamps);
router.get('/vaccinations', communityController.getVaccines);
router.get('/medicine-safety/:drugName', communityController.getMedicineSafety);

router.get('/announcements', communityController.getAnnouncements);
router.post('/feedback', communityController.submitFeedback);
router.get('/health-tips', communityController.getHealthTips);

export const communityRoutes = router;

