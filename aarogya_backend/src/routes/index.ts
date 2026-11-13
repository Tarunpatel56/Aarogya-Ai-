import { Router, Request, Response } from 'express';
import { healthRoutes } from './health.routes';
import { authRoutes } from './auth.routes';
import { patientRoutes } from './patient.routes';
import { doctorRoutes } from './doctor.routes';
import { hospitalRoutes } from './hospital.routes';
import { driverRoutes } from './driver.routes';
import { adminRoutes } from './admin.routes';
import { appointmentRoutes } from './appointment.routes';
import { notificationRoutes } from './notification.routes';
import { aiRoutes } from './ai.routes';
import { wearableRoutes } from './wearable.routes';
import { emergencyRoutes } from './emergency.routes';
import { prescriptionRoutes } from './prescription.routes';
import { vitalsRoutes, deviceRoutes } from './vitals.routes';
import { physiotherapyRoutes } from './physiotherapy.routes';
import { communityRoutes } from './community.routes';
import { abdmRoutes } from './abdm.routes';
import { governmentRoutes } from './government.routes';
import { mchRoutes } from './mch.routes';
import { placesRoutes } from './places.routes';
import { referralRoutes } from './referral.routes';

const router = Router();

// Root API information
router.get('/', (_req: Request, res: Response) => {
  res.json({
    success: true,
    message: 'Aarogya Healthcare Backend API',
    version: '1.0.0',
    documentation: '/api/docs',
  });
});

// System health check
router.use('/health', healthRoutes);

// Authentication & Identity routes
router.use('/auth', authRoutes);

// Patient self-service & authorized health records
router.use('/patients', patientRoutes);

// Doctor profiles, public directory & availability
router.use('/doctors', doctorRoutes);

// Hospital administration & staff management
router.use('/hospitals', hospitalRoutes);

// Driver management & assigned ambulance dispatches
router.use('/drivers', driverRoutes);

// Appointment booking & consultation lifecycle
router.use('/appointments', appointmentRoutes);

// Digital prescriptions authoring & patient access
router.use('/prescriptions', prescriptionRoutes);

// User notifications foundation
router.use('/notifications', notificationRoutes);

// Clinical and conversational AI services (Gemini & Groq)
router.use('/ai', aiRoutes);

// Wearable sensor telemetry & laptop bridge
router.use('/wearables', wearableRoutes);

// Smartwatch & Clinical Vitals Synchronization & History
router.use('/vitals', vitalsRoutes);

// Paired Bluetooth & Wearable Devices Management
router.use('/devices', deviceRoutes);

// Emergency SOS dispatch & live ambulance tracking
router.use('/emergency', emergencyRoutes);

// Real-time on-device MediaPipe Physiotherapy AI & Clinical ROM Tracking
router.use('/physiotherapy', physiotherapyRoutes);

// Community, Government Schemes, Blood Donors, Vaccine Tracker, Health Camps & Medicine Safety
router.use('/community', communityRoutes);

// ABDM (Ayushman Bharat Digital Mission) M1, M2, M3 Endpoints
router.use('/abdm', abdmRoutes);

// Government Healthcare Services (e-RaktKosh, Jan Aushadhi, PM-JAY, HFR/HPR, UHI, OPD Scan & Share)
router.use('/government', governmentRoutes);

// Maternal & Child Healthcare (MCH, ANC/PNC, U-WIN, PMSMA)
router.use('/mch', mchRoutes);

// Google Places Nearby Healthcare Finder Proxy
router.use('/places', placesRoutes);

// Inter-Doctor Clinical Referrals (aarogya_healthpro)
router.use('/referrals', referralRoutes);

// Administrative authority & verification workflows
router.use('/admin', adminRoutes);

export const apiRoutes = router;
