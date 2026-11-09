import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { Role, VerificationStatus, AvailabilityStatus, ConsultationMode } from '@prisma/client';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { tokenService } from '../src/services/token.service';
import { passwordService } from '../src/services/password.service';

describe('Doctor Profile, Verification & Availability Foundation Tests', () => {
  const testRunId = Date.now().toString().slice(-6);
  const doctorEmailA = `doctor_a_${testRunId}@aarogya.test`;
  const doctorEmailB = `doctor_b_${testRunId}@aarogya.test`;
  const patientEmail = `patient_doc_test_${testRunId}@aarogya.test`;
  const adminEmail = `admin_doc_test_${testRunId}@aarogya.test`;
  const password = 'StrongPassword123!';

  let doctorTokenA: string;
  let doctorProfileIdA: string;
  let doctorUserIdA: string;

  let doctorTokenB: string;
  let doctorProfileIdB: string;
  let doctorUserIdB: string;

  let patientToken: string;
  let adminToken: string;
  let adminUserId: string;

  let availabilityIdA: string;

  beforeAll(async () => {
    // 1. Register Doctor A (Starts with PENDING verification status)
    const regDocA = await request(app).post('/api/v1/auth/register/doctor').send({
      email: doctorEmailA,
      password,
      fullName: 'Dr. Aarav Sharma',
      phone: `9811${testRunId}1`,
      nmcRegistrationNumber: `NMC-A-${testRunId}`,
      specialization: 'Cardiology',
      qualifications: 'MBBS, MD (Cardiology)',
      experienceYears: 10,
      hospitalAffiliation: 'Apollo Hospitals',
    });
    doctorTokenA = regDocA.body.data.tokens.accessToken;
    doctorUserIdA = regDocA.body.data.user.id;
    doctorProfileIdA = regDocA.body.data.profile.id;

    // 2. Register Doctor B (Second doctor for cross-tenant isolation testing)
    const regDocB = await request(app).post('/api/v1/auth/register/doctor').send({
      email: doctorEmailB,
      password,
      fullName: 'Dr. Meera Patel',
      phone: `9811${testRunId}2`,
      nmcRegistrationNumber: `NMC-B-${testRunId}`,
      specialization: 'Dermatology',
      qualifications: 'MBBS, DVD',
      experienceYears: 6,
    });
    doctorTokenB = regDocB.body.data.tokens.accessToken;
    doctorUserIdB = regDocB.body.data.user.id;
    doctorProfileIdB = regDocB.body.data.profile.id;

    // 3. Register a Patient to test role boundaries
    const regPatient = await request(app).post('/api/v1/auth/register/patient').send({
      email: patientEmail,
      password,
      fullName: 'Test Patient',
      phone: `9811${testRunId}3`,
    });
    patientToken = regPatient.body.data.tokens.accessToken;

    // 4. Create an authorized PLATFORM_ADMIN account for trusted verification tests
    const hashedPassword = await passwordService.hash(password);
    const adminUser = await prisma.user.create({
      data: {
        email: adminEmail,
        passwordHash: hashedPassword,
        phone: `9811${testRunId}4`,
        role: Role.PLATFORM_ADMIN,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    adminUserId = adminUser.id;
    adminToken = tokenService.signAccessToken({
      id: adminUser.id,
      email: adminUser.email,
      role: adminUser.role,
      verificationStatus: adminUser.verificationStatus,
    });
  });

  afterAll(async () => {
    // Clean up only test records created by this suite
    await prisma.user.deleteMany({
      where: {
        email: {
          in: [doctorEmailA, doctorEmailB, patientEmail, adminEmail],
        },
      },
    });
  });

  // ============================================================================
  // SECTION 1: Doctor Profile Management & Access Control
  // ============================================================================
  describe('Doctor Profile Access & Protection', () => {
    it('allows authenticated doctor to retrieve their own profile with HTTP 200', async () => {
      const res = await request(app)
        .get('/api/v1/doctors/me')
        .set('Authorization', `Bearer ${doctorTokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.profile.fullName).toBe('Dr. Aarav Sharma');
      expect(res.body.data.profile.specialization).toBe('Cardiology');
      expect(res.body.data.profile.nmcRegistrationNumber).toBe(`NMC-A-${testRunId}`);
      expect(res.body.data.profile.user).toBeDefined();
      expect(res.body.data.profile.user.verificationStatus).toBe(VerificationStatus.PENDING);
      // Security: verify passwordHash is never returned
      expect(res.body.data.profile.user.passwordHash).toBeUndefined();
    });

    it('rejects unauthenticated requests to /api/v1/doctors/me with HTTP 401 Unauthorized', async () => {
      const res = await request(app).get('/api/v1/doctors/me');

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.details.code).toBe('TOKEN_MISSING');
    });

    it('rejects patient access to doctor self-service endpoint with HTTP 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/v1/doctors/me')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('Access denied');
    });

    it('allows doctor to update permitted profile fields (bio, fee, languages, modes)', async () => {
      const res = await request(app)
        .patch('/api/v1/doctors/me')
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          consultationFee: 750,
          bio: 'Senior Interventional Cardiologist with extensive clinical experience.',
          languages: ['English', 'Hindi', 'Kannada'],
          consultationModes: [ConsultationMode.IN_PERSON, ConsultationMode.ONLINE],
          clinicAddress: 'Heart Care Clinic, Indiranagar, Bangalore',
          experienceYears: 12,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.profile.consultationFee).toBe(750);
      expect(res.body.data.profile.bio).toContain('Senior Interventional Cardiologist');
      expect(res.body.data.profile.languages).toEqual(['English', 'Hindi', 'Kannada']);
      expect(res.body.data.profile.experienceYears).toBe(12);
      expect(res.body.data.profile.clinicAddress).toContain('Indiranagar');
    });

    it('rejects updates with negative consultationFee with HTTP 400 Validation Error', async () => {
      const res = await request(app)
        .patch('/api/v1/doctors/me')
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          consultationFee: -100,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toBe('Validation error');
      expect(res.body.error.details).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ field: 'consultationFee' }),
        ])
      );
    });

    it('rejects updates with negative experienceYears with HTTP 400 Validation Error', async () => {
      const res = await request(app)
        .patch('/api/v1/doctors/me')
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          experienceYears: -5,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.details).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ field: 'experienceYears' }),
        ])
      );
    });

    it('prevents doctor from changing their own role or verificationStatus', async () => {
      // Doctor attempts to elevate their own role to PLATFORM_ADMIN and status to VERIFIED
      const res = await request(app)
        .patch('/api/v1/doctors/me')
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          role: 'PLATFORM_ADMIN',
          verificationStatus: 'VERIFIED',
          nmcRegistrationNumber: 'ALTERED-NMC-12345',
        });

      expect(res.status).toBe(200);

      // Verify in DB that role, verificationStatus, and nmcRegistrationNumber were NOT changed
      const freshUser = await prisma.user.findUnique({
        where: { id: doctorUserIdA },
        include: { doctorProfile: true },
      });
      expect(freshUser!.role).toBe(Role.DOCTOR);
      expect(freshUser!.verificationStatus).toBe(VerificationStatus.PENDING);
      expect(freshUser!.doctorProfile!.nmcRegistrationNumber).toBe(`NMC-A-${testRunId}`);
    });
  });

  // ============================================================================
  // SECTION 2: Doctor Verification Workflow
  // ============================================================================
  describe('Doctor Verification Workflow & Directory Eligibility', () => {
    it('prevents doctor from self-verifying via administrative verification endpoint with HTTP 403', async () => {
      const res = await request(app)
        .patch(`/api/v1/admin/doctors/${doctorProfileIdA}/verify`)
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          status: VerificationStatus.VERIFIED,
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('excludes unverified/pending doctors from the public doctor directory (GET /api/v1/doctors)', async () => {
      const res = await request(app).get('/api/v1/doctors');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      const doctorIds = res.body.data.doctors.map((d: any) => d.id);
      expect(doctorIds).not.toContain(doctorProfileIdA);
      expect(doctorIds).not.toContain(doctorProfileIdB);
    });

    it('returns HTTP 404 when requesting public profile of an unverified doctor to prevent status leak', async () => {
      const res = await request(app).get(`/api/v1/doctors/${doctorProfileIdA}`);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('allows PLATFORM_ADMIN to approve and verify doctor credentials with HTTP 200', async () => {
      const res = await request(app)
        .patch(`/api/v1/admin/doctors/${doctorProfileIdA}/verify`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          status: VerificationStatus.VERIFIED,
          notes: 'NMC registration verified with Karnataka Medical Council register.',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.doctor.user.verificationStatus).toBe(VerificationStatus.VERIFIED);
      expect(res.body.data.doctor.verifiedBy).toBe(adminUserId);
      expect(res.body.data.doctor.verifiedAt).toBeDefined();
    });

    it('includes verified doctor in the public directory with safe metadata', async () => {
      const res = await request(app).get('/api/v1/doctors');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      const found = res.body.data.doctors.find((d: any) => d.id === doctorProfileIdA);
      expect(found).toBeDefined();
      expect(found.fullName).toBe('Dr. Aarav Sharma');
      expect(found.specialization).toBe('Cardiology');
      expect(found.consultationFee).toBe(750);

      // Verify privacy: Doctor B (unverified) is still excluded
      const doctorIds = res.body.data.doctors.map((d: any) => d.id);
      expect(doctorIds).not.toContain(doctorProfileIdB);

      // Verify sensitive auth fields are omitted
      expect(found.passwordHash).toBeUndefined();
      expect(found.phone).toBeUndefined();
      expect(found.email).toBeUndefined();
    });

    it('allows public retrieval of verified doctor profile by ID (GET /api/v1/doctors/:id)', async () => {
      const res = await request(app).get(`/api/v1/doctors/${doctorProfileIdA}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.doctor.id).toBe(doctorProfileIdA);
      expect(res.body.data.doctor.fullName).toBe('Dr. Aarav Sharma');
      expect(res.body.data.doctor.specialization).toBe('Cardiology');
      expect(res.body.data.doctor.clinicAddress).toContain('Indiranagar');
      expect(res.body.data.doctor.passwordHash).toBeUndefined();
      expect(res.body.data.doctor.email).toBeUndefined();
    });

    it('supports query filtering by specialization on public doctor listing', async () => {
      const matchRes = await request(app)
        .get('/api/v1/doctors')
        .query({ specialization: 'Cardio' });

      expect(matchRes.status).toBe(200);
      const matched = matchRes.body.data.doctors.map((d: any) => d.id);
      expect(matched).toContain(doctorProfileIdA);

      const noMatchRes = await request(app)
        .get('/api/v1/doctors')
        .query({ specialization: 'Neurology' });

      expect(noMatchRes.status).toBe(200);
      const nonMatched = noMatchRes.body.data.doctors.map((d: any) => d.id);
      expect(nonMatched).not.toContain(doctorProfileIdA);
    });
  });

  // ============================================================================
  // SECTION 3: Doctor Availability Foundation
  // ============================================================================
  describe('Doctor Availability Schedule & Conflict Prevention', () => {
    const baseFutureTime = Date.now() + 24 * 60 * 60 * 1000; // Tomorrow
    const slot1Start = new Date(baseFutureTime).toISOString();
    const slot1End = new Date(baseFutureTime + 60 * 60 * 1000).toISOString(); // +1 hour

    it('allows doctor to create a valid future availability slot with HTTP 201 Created', async () => {
      const res = await request(app)
        .post('/api/v1/doctors/me/availability')
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          startTime: slot1Start,
          endTime: slot1End,
          timeZone: 'Asia/Kolkata',
          status: AvailabilityStatus.AVAILABLE,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.availability).toBeDefined();
      expect(res.body.data.availability.status).toBe(AvailabilityStatus.AVAILABLE);
      expect(res.body.data.availability.timeZone).toBe('Asia/Kolkata');
      availabilityIdA = res.body.data.availability.id;
    });

    it('rejects creating availability where endTime is earlier than or equal to startTime with HTTP 400', async () => {
      const res = await request(app)
        .post('/api/v1/doctors/me/availability')
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          startTime: slot1End,
          endTime: slot1Start, // Inverted!
          status: AvailabilityStatus.AVAILABLE,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toBe('Validation error');
      expect(res.body.error.details).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ field: 'endTime' }),
        ])
      );
    });

    it('rejects creating availability in the past with HTTP 400', async () => {
      const pastStart = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();
      const pastEnd = new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString();

      const res = await request(app)
        .post('/api/v1/doctors/me/availability')
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          startTime: pastStart,
          endTime: pastEnd,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.details).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ field: 'startTime' }),
        ])
      );
    });

    it('prevents overlapping availability windows for the same doctor with HTTP 409 Conflict', async () => {
      // Attempt to create a slot overlapping slot 1 (offset by +30 min)
      const overlapStart = new Date(baseFutureTime + 30 * 60 * 1000).toISOString();
      const overlapEnd = new Date(baseFutureTime + 90 * 60 * 1000).toISOString();

      const res = await request(app)
        .post('/api/v1/doctors/me/availability')
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          startTime: overlapStart,
          endTime: overlapEnd,
        });

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('overlaps');
    });

    it('allows a different doctor (Doctor B) to book the exact same time window without conflict', async () => {
      const res = await request(app)
        .post('/api/v1/doctors/me/availability')
        .set('Authorization', `Bearer ${doctorTokenB}`)
        .send({
          startTime: slot1Start,
          endTime: slot1End,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    });

    it('allows doctor to retrieve their own availability schedule (GET /api/v1/doctors/me/availability)', async () => {
      const res = await request(app)
        .get('/api/v1/doctors/me/availability')
        .set('Authorization', `Bearer ${doctorTokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.availabilities)).toBe(true);
      expect(res.body.data.availabilities.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data.availabilities[0].id).toBe(availabilityIdA);
    });

    it('allows doctor to update their own availability slot (e.g. status to BUSY)', async () => {
      const res = await request(app)
        .patch(`/api/v1/doctors/me/availability/${availabilityIdA}`)
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          status: AvailabilityStatus.BUSY,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.availability.status).toBe(AvailabilityStatus.BUSY);
    });

    it('STRICT ISOLATION: prevents Doctor B from updating Doctor A availability with HTTP 404', async () => {
      const res = await request(app)
        .patch(`/api/v1/doctors/me/availability/${availabilityIdA}`)
        .set('Authorization', `Bearer ${doctorTokenB}`)
        .send({
          status: AvailabilityStatus.AVAILABLE,
        });

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('STRICT ISOLATION: prevents Doctor B from deleting Doctor A availability with HTTP 404', async () => {
      const res = await request(app)
        .delete(`/api/v1/doctors/me/availability/${availabilityIdA}`)
        .set('Authorization', `Bearer ${doctorTokenB}`);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('allows public retrieval of upcoming available slots for verified doctor', async () => {
      // First update Doctor A slot back to AVAILABLE
      await request(app)
        .patch(`/api/v1/doctors/me/availability/${availabilityIdA}`)
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          status: AvailabilityStatus.AVAILABLE,
        });

      const res = await request(app).get(`/api/v1/doctors/${doctorProfileIdA}/availability`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.availabilities)).toBe(true);
      expect(res.body.data.availabilities.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data.availabilities[0].status).toBe(AvailabilityStatus.AVAILABLE);
    });

    it('returns HTTP 404 when querying public availability of an unverified doctor', async () => {
      const res = await request(app).get(`/api/v1/doctors/${doctorProfileIdB}/availability`);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('allows doctor to delete their own availability slot with HTTP 200', async () => {
      const res = await request(app)
        .delete(`/api/v1/doctors/me/availability/${availabilityIdA}`)
        .set('Authorization', `Bearer ${doctorTokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      // Verify deletion
      const checkRes = await request(app)
        .get('/api/v1/doctors/me/availability')
        .set('Authorization', `Bearer ${doctorTokenA}`);
      const ids = checkRes.body.data.availabilities.map((a: any) => a.id);
      expect(ids).not.toContain(availabilityIdA);
    });
  });
});
