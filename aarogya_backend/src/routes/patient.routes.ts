import { Router } from 'express';
import { Role } from '@prisma/client';
import { patientController } from '../controllers/patient.controller';
import { authenticate, requireRoles } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validateRequest';
import {
  updatePatientProfileSchema,
  createMedicalRecordSchema,
  queryMedicalRecordsSchema,
} from '../validation/patient.validation';

const router = Router();

// Enforce authentication and PATIENT role across all patient self-service routes
router.use(authenticate, requireRoles(Role.PATIENT));

// Self-service patient profile management
router.get('/me', patientController.getProfile);
router.patch('/me', validateRequest(updatePatientProfileSchema), patientController.updateProfile);

// Family health profiles
router.get('/me/family-members', patientController.getFamilyMembers);
router.post('/me/family-members', patientController.addFamilyMember);
router.patch('/me/family-members/:id', patientController.updateFamilyMember);
router.delete('/me/family-members/:id', patientController.deleteFamilyMember);

// Self-service authorized medical records
router.get('/me/medical-records', validateRequest(queryMedicalRecordsSchema), patientController.getMedicalRecords);
router.post('/me/medical-records', validateRequest(createMedicalRecordSchema), patientController.createMedicalRecord);
router.get('/me/medical-records/:id', patientController.getMedicalRecordById);

// Medicine Reminders & Dose Adherence Tracking
router.get('/me/medicine-reminders', patientController.getMedicineReminders);
router.post('/me/medicine-reminders', patientController.addMedicineReminder);
router.patch('/me/medicine-reminders/:id/dose', patientController.logMedicineDose);
router.delete('/me/medicine-reminders/:id', patientController.deleteMedicineReminder);

export const patientRoutes = router;
