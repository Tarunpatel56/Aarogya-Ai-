import { Router } from 'express';
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

const router = Router();

// Root API information
router.get('/', (_req, res) => {
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

// Administrative authority & verification workflows
router.use('/admin', adminRoutes);

export const apiRoutes = router;
