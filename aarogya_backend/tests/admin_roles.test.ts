import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { Role, VerificationStatus } from '@prisma/client';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { passwordService } from '../src/services/password.service';
import { tokenService } from '../src/services/token.service';

describe('Four User Roles & Administrative Backend APIs (Part 1)', () => {
  const runId = Date.now().toString().slice(-6);
  const superAdminEmail = `superadmin_${runId}@aarogya.test`;
  const hospitalAdminEmail = `hospadmin_${runId}@aarogya.test`;
  const driverEmail = `driver_${runId}@aarogya.test`;
  const patientEmail = `patient_${runId}@aarogya.test`;
  const otherPatientEmail = `patient_other_${runId}@aarogya.test`;
  const password = 'StrongPassword123!';

  let superAdminToken: string;
  let hospitalAdminToken: string;
  let driverToken: string;
  let patientToken: string;
  let otherPatientToken: string;

  let superAdminUser: any;
  let hospitalAdminUser: any;
  let driverUser: any;
  let patientUser: any;
  let otherPatientUser: any;

  beforeAll(async () => {
    const passwordHash = await passwordService.hash(password);

    // 1. Create Super Admin
    superAdminUser = await prisma.user.create({
      data: {
        email: superAdminEmail,
        passwordHash,
        role: Role.PLATFORM_ADMIN,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
        isEmailVerified: true,
      },
    });
    superAdminToken = tokenService.signAccessToken({
      id: superAdminUser.id,
      email: superAdminUser.email,
      role: superAdminUser.role,
      verificationStatus: superAdminUser.verificationStatus,
    });

    // 2. Create Hospital Admin
    hospitalAdminUser = await prisma.user.create({
      data: {
        email: hospitalAdminEmail,
        passwordHash,
        role: Role.HOSPITAL_ADMIN,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
        isEmailVerified: true,
        hospitalAdminProfile: {
          create: {
            fullName: 'Admin Rajesh',
            hospitalName: 'Apollo City Hospital',
            hospitalLicenseNumber: `HOSP-LIC-${runId}`,
            designation: 'Chief Medical Director',
            verifiedAt: new Date(),
          },
        },
      },
    });
    hospitalAdminToken = tokenService.signAccessToken({
      id: hospitalAdminUser.id,
      email: hospitalAdminUser.email,
      role: hospitalAdminUser.role,
      verificationStatus: hospitalAdminUser.verificationStatus,
    });

    // 3. Create Driver
    driverUser = await prisma.user.create({
      data: {
        email: driverEmail,
        passwordHash,
        role: Role.AMBULANCE_DRIVER,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
        isEmailVerified: true,
        ambulanceStaffProfile: {
          create: {
            fullName: 'Driver Vikram',
            staffRole: Role.AMBULANCE_DRIVER,
            licenseNumber: `DL-AMB-${runId}`,
            assignedVehicleNumber: 'DL-01-AMB-9482',
            verifiedAt: new Date(),
          },
        },
      },
    });
    driverToken = tokenService.signAccessToken({
      id: driverUser.id,
      email: driverUser.email,
      role: driverUser.role,
      verificationStatus: driverUser.verificationStatus,
    });

    // 4. Create Patients
    patientUser = await prisma.user.create({
      data: {
        email: patientEmail,
        passwordHash,
        role: Role.PATIENT,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
        isEmailVerified: true,
        patientProfile: {
          create: {
            fullName: 'Patient Rahul',
            abhaId: `ABHA-${runId}-1`,
          },
        },
      },
      include: { patientProfile: true },
    });
    patientToken = tokenService.signAccessToken({
      id: patientUser.id,
      email: patientUser.email,
      role: patientUser.role,
      verificationStatus: patientUser.verificationStatus,
    });

    otherPatientUser = await prisma.user.create({
      data: {
        email: otherPatientEmail,
        passwordHash,
        role: Role.PATIENT,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
        isEmailVerified: true,
        patientProfile: {
          create: {
            fullName: 'Patient Sneha',
            abhaId: `ABHA-${runId}-2`,
          },
        },
      },
      include: { patientProfile: true },
    });
    otherPatientToken = tokenService.signAccessToken({
      id: otherPatientUser.id,
      email: otherPatientUser.email,
      role: otherPatientUser.role,
      verificationStatus: otherPatientUser.verificationStatus,
    });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: {
        email: {
          in: [
            superAdminEmail,
            hospitalAdminEmail,
            driverEmail,
            patientEmail,
            otherPatientEmail,
          ],
        },
      },
    });
  });

  describe('1. Current Authenticated User & Role Verification (/auth/me)', () => {
    it('returns SUPER_ADMIN canonical role for Super Admin', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.role).toBe('PLATFORM_ADMIN');
      expect(res.body.data.user.effectiveRole).toBe('SUPER_ADMIN');
    });

    it('returns HOSPITAL_ADMIN role and profile for Hospital Admin', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${hospitalAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.user.effectiveRole).toBe('HOSPITAL_ADMIN');
      expect(res.body.data.profile.hospitalName).toBe('Apollo City Hospital');
    });

    it('returns DRIVER canonical role and vehicle profile for Ambulance Driver', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${driverToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.user.effectiveRole).toBe('DRIVER');
      expect(res.body.data.profile.assignedVehicleNumber).toBe('DL-01-AMB-9482');
    });

    it('returns PATIENT role for Patient', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.user.effectiveRole).toBe('PATIENT');
      expect(res.body.data.profile.fullName).toBe('Patient Rahul');
    });
  });

  describe('2. Role-Based Authorization & Boundary Enforcement', () => {
    it('allows Super Admin to view platform stats (/admin/stats)', async () => {
      const res = await request(app)
        .get('/api/v1/admin/stats')
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.users.total).toBeGreaterThan(0);
      expect(res.body.data.operations.systemHealth).toBe('OPERATIONAL');
    });

    it('blocks Patient from accessing Super Admin stats with HTTP 403', async () => {
      const res = await request(app)
        .get('/api/v1/admin/stats')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('Access denied');
    });

    it('blocks Hospital Admin from accessing Super Admin stats with HTTP 403', async () => {
      const res = await request(app)
        .get('/api/v1/admin/stats')
        .set('Authorization', `Bearer ${hospitalAdminToken}`);

      expect(res.status).toBe(403);
    });

    it('blocks Driver from accessing Super Admin stats with HTTP 403', async () => {
      const res = await request(app)
        .get('/api/v1/admin/stats')
        .set('Authorization', `Bearer ${driverToken}`);

      expect(res.status).toBe(403);
    });
  });

  describe('3. Hospital Administration & Isolation (/hospitals/*)', () => {
    it('allows Hospital Admin to view own hospital profile and staff', async () => {
      const res = await request(app)
        .get('/api/v1/hospitals/me')
        .set('Authorization', `Bearer ${hospitalAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.profile.hospitalName).toBe('Apollo City Hospital');
    });

    it('allows Hospital Admin to update own hospital settings', async () => {
      const res = await request(app)
        .patch('/api/v1/hospitals/me')
        .set('Authorization', `Bearer ${hospitalAdminToken}`)
        .send({ designation: 'Senior Medical Superintendent' });

      expect(res.status).toBe(200);
      expect(res.body.data.profile.designation).toBe('Senior Medical Superintendent');
    });

    it('blocks Driver and Patient from hospital admin endpoints with HTTP 403', async () => {
      const resPatient = await request(app)
        .get('/api/v1/hospitals/me')
        .set('Authorization', `Bearer ${patientToken}`);
      expect(resPatient.status).toBe(403);

      const resDriver = await request(app)
        .get('/api/v1/hospitals/me')
        .set('Authorization', `Bearer ${driverToken}`);
      expect(resDriver.status).toBe(403);
    });
  });

  describe('4. Driver Management & Trip Reporting (/drivers/*)', () => {
    it('allows Driver to view own profile and assigned vehicle', async () => {
      const res = await request(app)
        .get('/api/v1/drivers/me')
        .set('Authorization', `Bearer ${driverToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.profile.licenseNumber).toBe(`DL-AMB-${runId}`);
    });

    it('allows Driver to fetch assigned emergency trips and update status', async () => {
      const res = await request(app)
        .get('/api/v1/drivers/me/trips')
        .set('Authorization', `Bearer ${driverToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data.trips)).toBe(true);

      if (res.body.data.trips.length > 0) {
        const tripId = res.body.data.trips[0].id;
        const updateRes = await request(app)
          .patch(`/api/v1/drivers/me/trips/${tripId}/status`)
          .set('Authorization', `Bearer ${driverToken}`)
          .send({ status: 'EN_ROUTE', vitalNotes: 'En route with active oxygen' });

        expect(updateRes.status).toBe(200);
        expect(updateRes.body.data.trip.status).toBe('EN_ROUTE');
      }
    });

    it('blocks Patient and Hospital Admin from driver routes with HTTP 403', async () => {
      const resPatient = await request(app)
        .get('/api/v1/drivers/me')
        .set('Authorization', `Bearer ${patientToken}`);
      expect(resPatient.status).toBe(403);

      const resHosp = await request(app)
        .get('/api/v1/drivers/me')
        .set('Authorization', `Bearer ${hospitalAdminToken}`);
      expect(resHosp.status).toBe(403);
    });
  });

  describe('5. Super Admin User Management & Protected Operations (/admin/users)', () => {
    let createdUserId: string;
    const testNewUserEmail = `created_user_${runId}@aarogya.test`;

    afterAll(async () => {
      if (createdUserId) {
        await prisma.user.deleteMany({ where: { id: createdUserId } });
      }
    });

    it('lists platform users with pagination and role filters', async () => {
      const res = await request(app)
        .get('/api/v1/admin/users?limit=10&offset=0&role=PATIENT')
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data.users)).toBe(true);
      expect(res.body.data.pagination.limit).toBe(10);
      expect(res.body.data.users.every((u: any) => u.effectiveRole === 'PATIENT')).toBe(true);
    });

    it('Super Admin creates an authorized HOSPITAL_ADMIN account', async () => {
      const res = await request(app)
        .post('/api/v1/admin/users')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({
          email: testNewUserEmail,
          password: 'CreatedUser123!',
          role: 'HOSPITAL_ADMIN',
          fullName: 'Dr. Ramesh Admin',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.user.effectiveRole).toBe('HOSPITAL_ADMIN');
      createdUserId = res.body.data.user.id;
    });

    it('Super Admin deactivates and reactivates a user account', async () => {
      // Deactivate
      const deactRes = await request(app)
        .patch(`/api/v1/admin/users/${createdUserId}/status`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({ isActive: false, reason: 'Temporary administrative audit' });

      expect(deactRes.status).toBe(200);
      expect(deactRes.body.data.user.isActive).toBe(false);

      // Reactivate
      const reactRes = await request(app)
        .patch(`/api/v1/admin/users/${createdUserId}/status`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({ isActive: true });

      expect(reactRes.status).toBe(200);
      expect(reactRes.body.data.user.isActive).toBe(true);
    });

    it('Super Admin updates user role to DRIVER', async () => {
      const res = await request(app)
        .patch(`/api/v1/admin/users/${createdUserId}/role`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({ role: 'DRIVER' });

      expect(res.status).toBe(200);
      expect(res.body.data.user.effectiveRole).toBe('DRIVER');
    });

    it('prevents Super Admin from deactivating their own active account', async () => {
      const res = await request(app)
        .patch(`/api/v1/admin/users/${superAdminUser.id}/status`)
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({ isActive: false });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('Super Admins cannot deactivate their own');
    });

    it('records privileged actions in audit logs', async () => {
      const res = await request(app)
        .get('/api/v1/admin/audit-logs')
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.data.auditLogs)).toBe(true);
      expect(res.body.data.auditLogs.some((l: any) => l.action === 'CREATE_USER')).toBe(true);
    });
  });

  describe('6. Patient Record Isolation', () => {
    let patientRecordId: string;

    beforeAll(async () => {
      const record = await prisma.medicalRecord.create({
        data: {
          patientProfileId: patientUser.patientProfile.id,
          recordType: 'PRESCRIPTION',
          title: 'Rahul Telmisartan Rx',
          description: 'Take 40mg daily',
        },
      });
      patientRecordId = record.id;
    });

    afterAll(async () => {
      if (patientRecordId) {
        await prisma.medicalRecord.deleteMany({ where: { id: patientRecordId } });
      }
    });

    it('allows patient to access their own medical record', async () => {
      const res = await request(app)
        .get(`/api/v1/patients/me/medical-records/${patientRecordId}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.record.title).toBe('Rahul Telmisartan Rx');
    });

    it('blocks another patient from accessing Rahul\'s record with HTTP 404', async () => {
      const res = await request(app)
        .get(`/api/v1/patients/me/medical-records/${patientRecordId}`)
        .set('Authorization', `Bearer ${otherPatientToken}`);

      // Returns 404 to avoid leaking existence of record
      expect(res.status).toBe(404);
    });
  });
});
