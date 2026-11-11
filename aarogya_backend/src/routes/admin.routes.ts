import { Router } from 'express';
import { Role } from '@prisma/client';
import { doctorController } from '../controllers/doctor.controller';
import { adminController } from '../controllers/admin.controller';
import { authenticate, requireRoles } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validateRequest';
import { adminVerifyDoctorSchema } from '../validation/doctor.validation';
import {
  queryUsersSchema,
  adminCreateUserSchema,
  updateUserStatusSchema,
  assignUserRoleSchema,
  adminVerifyDriverSchema,
} from '../validation/admin.validation';

const router = Router();

// Gated strictly for SUPER_ADMIN / PLATFORM_ADMIN authority
router.use(authenticate, requireRoles(Role.PLATFORM_ADMIN, 'SUPER_ADMIN'));

// Platform Operational Statistics & Audit Trail
router.get('/stats', adminController.getStats);
router.get('/audit-logs', adminController.getAuditLogs);

// User Management Foundation
router.get('/users', validateRequest(queryUsersSchema), adminController.getUsers);
router.get('/users/:id', adminController.getUserById);
router.post('/users', validateRequest(adminCreateUserSchema), adminController.createUser);
router.patch('/users/:id/status', validateRequest(updateUserStatusSchema), adminController.updateUserStatus);
router.patch('/users/:id/role', validateRequest(assignUserRoleSchema), adminController.assignUserRole);
router.delete('/users/:id', adminController.deleteUser);

// Transition doctor verification status (VERIFIED, REJECTED, SUSPENDED, UNDER_REVIEW)
router.patch('/doctors/:id/verify', validateRequest(adminVerifyDoctorSchema), doctorController.adminVerifyDoctor);

// Super Admin Ambulance Driver & Paramedic Fleet Verification
router.get('/drivers', adminController.getAmbulanceStaffList);
router.patch('/drivers/:id/verify', validateRequest(adminVerifyDriverSchema), adminController.verifyAmbulanceStaff);

// Super Admin Live SOS Emergency Radar & Dispatches
router.get('/emergencies', adminController.getEmergencies);

// Super Admin Platform Appointments Oversight
router.get('/appointments', adminController.getAppointments);

// Super Admin System Telemetry & Service Health
router.get('/system/health', adminController.getSystemHealth);
router.get('/system/settings', adminController.getSystemSettings);
router.patch('/system/settings', adminController.updateSystemSettings);

// Super Admin Community Desk & Content Management
router.get('/feedback', adminController.getFeedback);
router.post('/announcements', adminController.createAnnouncement);
router.post('/health-camps', adminController.createHealthCamp);
router.post('/health-tips', adminController.createHealthTip);

export const adminRoutes = router;
