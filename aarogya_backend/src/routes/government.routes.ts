import { Router } from 'express';
import { governmentController } from '../controllers/government.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// e-RaktKosh
router.get('/blood-banks', governmentController.getBloodBanks);

// Jan Aushadhi (PMBJP)
router.get('/jan-aushadhi/medicines', governmentController.getJanAushadhiMedicines);
router.get('/jan-aushadhi/kendras', governmentController.getJanAushadhiKendras);

// PM-JAY Ayushman Bharat
router.get('/pmjay/check-eligibility', governmentController.checkAyushmanEligibility);
router.get('/pmjay/packages', governmentController.getPmjayPackages);

// HFR & HPR
router.get('/hfr/facilities', governmentController.getHfrFacilities);
router.get('/hpr/doctors', governmentController.getHprPractitioners);

// UHI
router.get('/uhi/slots', governmentController.searchUhiSlots);

// OPD Scan & Share
router.post('/opd/scan-and-share', authenticate, governmentController.scanAndShareOpd);

export const governmentRoutes = router;

