import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { Role, VerificationStatus, AvailabilityStatus, ConsultationMode, AppointmentStatus } from '@prisma/client';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { tokenService } from '../src/services/token.service';
import { passwordService } from '../src/services/password.service';

describe('Secure Appointment Booking & Consultation Workflow Foundation Tests (Phase 5)', () => {
  const testRunId = Date.now().toString().slice(-6);
  const password = 'StrongPassword123!';

  // Emails
  const doctorEmailA = `doc_appt_a_${testRunId}@aarogya.test`;
  const doctorEmailB = `doc_appt_b_${testRunId}@aarogya.test`;
  const doctorUnverifiedEmail = `doc_appt_unver_${testRunId}@aarogya.test`;
  const patientEmail1 = `pat_appt_1_${testRunId}@aarogya.test`;
  const patientEmail2 = `pat_appt_2_${testRunId}@aarogya.test`;
  const adminEmail = `admin_appt_${testRunId}@aarogya.test`;

  // Tokens & IDs
  let doctorTokenA: string;
  let doctorProfileIdA: string;
  let doctorUserIdA: string;

  let doctorTokenB: string;
  let doctorProfileIdB: string;
  let doctorUserIdB: string;

  let unverifiedDoctorToken: string;
  let unverifiedDoctorProfileId: string;

  let patientToken1: string;
  let patientProfileId1: string;
  let patientUserId1: string;

  let patientToken2: string;
  let patientProfileId2: string;
  let patientUserId2: string;

  let adminToken: string;

  // Base future timestamps for availability and appointments
  const baseFutureTime = Date.now() + 72 * 60 * 60 * 1000; // 3 days ahead
  const availStart = new Date(baseFutureTime).toISOString();
  const availEnd = new Date(baseFutureTime + 6 * 60 * 60 * 1000).toISOString(); // +6 hours window

  // Slot 1: [0, +30m]
  const slot1Start = new Date(baseFutureTime + 10 * 60 * 1000).toISOString();
  const slot1End = new Date(baseFutureTime + 40 * 60 * 1000).toISOString();

  // Slot 2: [60m, +90m]
  const slot2Start = new Date(baseFutureTime + 60 * 60 * 1000).toISOString();
  const slot2End = new Date(baseFutureTime + 90 * 60 * 1000).toISOString();

  // Slot 3: [120m, +150m]
  const slot3Start = new Date(baseFutureTime + 120 * 60 * 1000).toISOString();
  const slot3End = new Date(baseFutureTime + 150 * 60 * 1000).toISOString();

  // Slot 4: [180m, +210m] (Used for concurrency test)
  const slot4Start = new Date(baseFutureTime + 180 * 60 * 1000).toISOString();
  const slot4End = new Date(baseFutureTime + 210 * 60 * 1000).toISOString();

  beforeAll(async () => {
    // 1. Create Platform Admin to verify doctors
    const hashedPassword = await passwordService.hash(password);
    const adminUser = await prisma.user.create({
      data: {
        email: adminEmail,
        passwordHash: hashedPassword,
        phone: `9820${testRunId}0`,
        role: Role.PLATFORM_ADMIN,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    adminToken = tokenService.signAccessToken({
      id: adminUser.id,
      email: adminUser.email,
      role: adminUser.role,
      verificationStatus: adminUser.verificationStatus,
    });

    // 2. Register Doctor A
    const regDocA = await request(app).post('/api/v1/auth/register/doctor').send({
      email: doctorEmailA,
      password,
      fullName: 'Dr. Vikram Seth',
      phone: `9820${testRunId}1`,
      nmcRegistrationNumber: `NMC-SET-${testRunId}`,
      specialization: 'General Medicine',
      qualifications: 'MBBS, MD',
      experienceYears: 8,
    });
    doctorTokenA = regDocA.body.data.tokens.accessToken;
    doctorUserIdA = regDocA.body.data.user.id;
    doctorProfileIdA = regDocA.body.data.profile.id;

    // Admin verifies Doctor A
    await request(app)
      .patch(`/api/v1/admin/doctors/${doctorProfileIdA}/verify`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: VerificationStatus.VERIFIED });

    // Refresh Doctor A token with VERIFIED status
    doctorTokenA = tokenService.signAccessToken({
      id: doctorUserIdA,
      email: doctorEmailA,
      role: Role.DOCTOR,
      verificationStatus: VerificationStatus.VERIFIED,
    });

    // Doctor A creates availability window
    await request(app)
      .post('/api/v1/doctors/me/availability')
      .set('Authorization', `Bearer ${doctorTokenA}`)
      .send({
        startTime: availStart,
        endTime: availEnd,
        status: AvailabilityStatus.AVAILABLE,
      });

    // 3. Register Doctor B
    const regDocB = await request(app).post('/api/v1/auth/register/doctor').send({
      email: doctorEmailB,
      password,
      fullName: 'Dr. Ananya Ray',
      phone: `9820${testRunId}2`,
      nmcRegistrationNumber: `NMC-RAY-${testRunId}`,
      specialization: 'Pediatrics',
      qualifications: 'MBBS, DCH',
      experienceYears: 5,
    });
    doctorTokenB = regDocB.body.data.tokens.accessToken;
    doctorUserIdB = regDocB.body.data.user.id;
    doctorProfileIdB = regDocB.body.data.profile.id;

    // Admin verifies Doctor B
    await request(app)
      .patch(`/api/v1/admin/doctors/${doctorProfileIdB}/verify`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: VerificationStatus.VERIFIED });

    doctorTokenB = tokenService.signAccessToken({
      id: doctorUserIdB,
      email: doctorEmailB,
      role: Role.DOCTOR,
      verificationStatus: VerificationStatus.VERIFIED,
    });

    // Doctor B creates availability window
    await request(app)
      .post('/api/v1/doctors/me/availability')
      .set('Authorization', `Bearer ${doctorTokenB}`)
      .send({
        startTime: availStart,
        endTime: availEnd,
        status: AvailabilityStatus.AVAILABLE,
      });

    // 4. Register Doctor Unverified (remains PENDING)
    const regDocUnver = await request(app).post('/api/v1/auth/register/doctor').send({
      email: doctorUnverifiedEmail,
      password,
      fullName: 'Dr. Pending Verification',
      phone: `9820${testRunId}3`,
      nmcRegistrationNumber: `NMC-UNV-${testRunId}`,
      specialization: 'Neurology',
      qualifications: 'MBBS, DM',
    });
    unverifiedDoctorToken = regDocUnver.body.data.tokens.accessToken;
    unverifiedDoctorProfileId = regDocUnver.body.data.profile.id;

    // 5. Register Patient 1
    const regPat1 = await request(app).post('/api/v1/auth/register/patient').send({
      email: patientEmail1,
      password,
      fullName: 'Ramesh Gupta',
      phone: `9820${testRunId}4`,
    });
    patientToken1 = regPat1.body.data.tokens.accessToken;
    patientUserId1 = regPat1.body.data.user.id;
    patientProfileId1 = regPat1.body.data.profile.id;

    // 6. Register Patient 2
    const regPat2 = await request(app).post('/api/v1/auth/register/patient').send({
      email: patientEmail2,
      password,
      fullName: 'Sita Sharma',
      phone: `9820${testRunId}5`,
    });
    patientToken2 = regPat2.body.data.tokens.accessToken;
    patientUserId2 = regPat2.body.data.user.id;
    patientProfileId2 = regPat2.body.data.profile.id;
  });

  afterAll(async () => {
    // Isolated cleanup: delete only records created by this test suite
    await prisma.user.deleteMany({
      where: {
        email: {
          in: [
            doctorEmailA,
            doctorEmailB,
            doctorUnverifiedEmail,
            patientEmail1,
            patientEmail2,
            adminEmail,
          ],
        },
      },
    });
  });

  // ============================================================================
  // SECTION 1: Patient Appointment Booking Workflow
  // ============================================================================
  describe('Patient Appointment Creation & Security', () => {
    let createdAppointmentId: string;

    it('rejects unauthenticated request to create an appointment with HTTP 401', async () => {
      const res = await request(app).post('/api/v1/appointments').send({
        doctorProfileId: doctorProfileIdA,
        startTime: slot1Start,
        endTime: slot1End,
      });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('rejects non-patient role (DOCTOR) attempting to book an appointment with HTTP 403', async () => {
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          doctorProfileId: doctorProfileIdB,
          startTime: slot1Start,
          endTime: slot1End,
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('rejects booking with an unverified doctor with HTTP 400', async () => {
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({
          doctorProfileId: unverifiedDoctorProfileId,
          startTime: slot1Start,
          endTime: slot1End,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('not verified');
    });

    it('rejects appointment scheduled in the past with HTTP 400', async () => {
      const pastStart = new Date(Date.now() - 3600000).toISOString();
      const pastEnd = new Date(Date.now() - 1800000).toISOString();

      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({
          doctorProfileId: doctorProfileIdA,
          startTime: pastStart,
          endTime: pastEnd,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('rejects appointment outside of doctor availability schedule with HTTP 400', async () => {
      // Time that is not in Doctor A's availability window (e.g. 10 days in the future)
      const outsideStart = new Date(baseFutureTime + 10 * 24 * 3600000).toISOString();
      const outsideEnd = new Date(baseFutureTime + 10 * 24 * 3600000 + 1800000).toISOString();

      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({
          doctorProfileId: doctorProfileIdA,
          startTime: outsideStart,
          endTime: outsideEnd,
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('outside');
    });

    it('allows authenticated patient to book a valid appointment request with HTTP 201', async () => {
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({
          doctorProfileId: doctorProfileIdA,
          startTime: slot1Start,
          endTime: slot1End,
          mode: ConsultationMode.IN_PERSON,
          reason: 'Severe persistent migraine headaches for 3 days',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.appointment).toBeDefined();
      expect(res.body.data.appointment.status).toBe(AppointmentStatus.REQUESTED);
      expect(res.body.data.appointment.mode).toBe(ConsultationMode.IN_PERSON);
      expect(res.body.data.appointment.patientProfileId).toBe(patientProfileId1);
      expect(res.body.data.appointment.doctorProfileId).toBe(doctorProfileIdA);
      expect(res.body.data.appointment.reason).toContain('migraine');

      createdAppointmentId = res.body.data.appointment.id;
    });

    it('generates an internal persistent notification for doctor on appointment request', async () => {
      const notifRes = await request(app)
        .get('/api/v1/notifications')
        .set('Authorization', `Bearer ${doctorTokenA}`);

      expect(notifRes.status).toBe(200);
      expect(notifRes.body.success).toBe(true);
      expect(notifRes.body.data.notifications.length).toBeGreaterThanOrEqual(1);
      const apptNotif = notifRes.body.data.notifications.find(
        (n: any) => n.type === 'APPOINTMENT_REQUESTED'
      );
      expect(apptNotif).toBeDefined();
      expect(apptNotif.title).toContain('New Appointment Request');
    });

    it('prevents another patient from booking the same overlapping slot (HTTP 409 Conflict)', async () => {
      // Patient 2 tries to book slot 1 with Doctor A
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken2}`)
        .send({
          doctorProfileId: doctorProfileIdA,
          startTime: slot1Start,
          endTime: slot1End,
        });

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('already reserved');
    });

    it('allows booking the exact same time window with a DIFFERENT doctor (Doctor B)', async () => {
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken2}`)
        .send({
          doctorProfileId: doctorProfileIdB,
          startTime: slot1Start,
          endTime: slot1End,
          mode: ConsultationMode.ONLINE,
          reason: 'Child routine wellness checkup',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.appointment.doctorProfileId).toBe(doctorProfileIdB);
      expect(res.body.data.appointment.status).toBe(AppointmentStatus.REQUESTED);
    });

    it('allows patient to list only their own appointments (GET /api/v1/appointments)', async () => {
      const res = await request(app)
        .get('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken1}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.appointments)).toBe(true);
      const ids = res.body.data.appointments.map((a: any) => a.id);
      expect(ids).toContain(createdAppointmentId);

      // Verify no patient profile leakage: all appointments belong to patient 1
      res.body.data.appointments.forEach((a: any) => {
        expect(a.patientProfileId).toBe(patientProfileId1);
      });
    });

    it('STRICT PRIVACY: prevents Patient 2 from retrieving Patient 1 appointment by ID (HTTP 404)', async () => {
      const res = await request(app)
        .get(`/api/v1/appointments/${createdAppointmentId}`)
        .set('Authorization', `Bearer ${patientToken2}`);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('prevents patient from performing doctor-only status transition (HTTP 403 Forbidden)', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${createdAppointmentId}/confirm`)
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({ doctorNotes: 'Malicious confirmation' });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });
  });

  // ============================================================================
  // SECTION 2: Doctor Appointment Management & Lifecycle
  // ============================================================================
  describe('Doctor Appointment Workflow & Status Transitions', () => {
    let apptForDoctorA: string;
    let apptToReject: string;

    beforeAll(async () => {
      // Patient 1 creates appointment in Slot 2 with Doctor A
      const res2 = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({
          doctorProfileId: doctorProfileIdA,
          startTime: slot2Start,
          endTime: slot2End,
          reason: 'Blood pressure review',
        });
      apptForDoctorA = res2.body.data.appointment.id;

      // Patient 1 creates appointment in Slot 3 with Doctor A (to test rejection)
      const res3 = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({
          doctorProfileId: doctorProfileIdA,
          startTime: slot3Start,
          endTime: slot3End,
          reason: 'Second opinion consultation',
        });
      apptToReject = res3.body.data.appointment.id;
    });

    it('allows doctor to list their own appointment requests', async () => {
      const res = await request(app)
        .get('/api/v1/appointments')
        .set('Authorization', `Bearer ${doctorTokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      const ids = res.body.data.appointments.map((a: any) => a.id);
      expect(ids).toContain(apptForDoctorA);
      expect(ids).toContain(apptToReject);

      // Verify doctor only sees their own appointments
      res.body.data.appointments.forEach((a: any) => {
        expect(a.doctorProfileId).toBe(doctorProfileIdA);
      });
    });

    it('STRICT ISOLATION: prevents Doctor B from viewing Doctor A appointments (HTTP 404)', async () => {
      const res = await request(app)
        .get(`/api/v1/appointments/${apptForDoctorA}`)
        .set('Authorization', `Bearer ${doctorTokenB}`);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('STRICT ISOLATION: prevents Doctor B from confirming Doctor A appointment (HTTP 404)', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${apptForDoctorA}/confirm`)
        .set('Authorization', `Bearer ${doctorTokenB}`)
        .send({ doctorNotes: 'Unauthorized confirmation attempt' });

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });

    it('allows Doctor A to confirm an eligible appointment request (REQUESTED -> CONFIRMED)', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${apptForDoctorA}/confirm`)
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({ doctorNotes: 'Please bring recent lipid profile reports.' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.appointment.status).toBe(AppointmentStatus.CONFIRMED);
      expect(res.body.data.appointment.doctorNotes).toContain('recent lipid profile');
    });

    it('rejects confirming an appointment that is already CONFIRMED (HTTP 400)', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${apptForDoctorA}/confirm`)
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({ doctorNotes: 'Attempt double confirmation' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('allows Doctor A to reject an eligible appointment request (REQUESTED -> REJECTED)', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${apptToReject}/reject`)
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({
          reason: 'Emergency surgery schedule conflict at hospital',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.appointment.status).toBe(AppointmentStatus.REJECTED);
      expect(res.body.data.appointment.cancellationReason).toContain('Emergency surgery');
    });

    it('rejects rejecting an appointment that is already REJECTED (HTTP 400)', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${apptToReject}/reject`)
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({ reason: 'Already rejected' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('allows rebooking the slot after an appointment was REJECTED', async () => {
      // Patient 2 can now book slot 3 since previous request was rejected!
      const res = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken2}`)
        .send({
          doctorProfileId: doctorProfileIdA,
          startTime: slot3Start,
          endTime: slot3End,
          reason: 'Rebooking after slot freed up',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.appointment.status).toBe(AppointmentStatus.REQUESTED);
    });

    it('allows Doctor A to complete a CONFIRMED appointment (CONFIRMED -> COMPLETED)', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${apptForDoctorA}/complete`)
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({ doctorNotes: 'Consultation concluded. Prescribed lifestyle modification.' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.appointment.status).toBe(AppointmentStatus.COMPLETED);
    });

    it('rejects completing an appointment that is already COMPLETED (HTTP 400)', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${apptForDoctorA}/complete`)
        .set('Authorization', `Bearer ${doctorTokenA}`)
        .send({ doctorNotes: 'Duplicate completion' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('rejects cancelling a COMPLETED appointment (HTTP 400)', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${apptForDoctorA}/cancel`)
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({ reason: 'Attempt cancel completed' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  // ============================================================================
  // SECTION 3: Cancellation & Rebooking Lifecycle
  // ============================================================================
  describe('Cancellation and Rebooking Lifecycle', () => {
    let cancelApptId: string;
    const cancelSlotStart = new Date(baseFutureTime + 240 * 60 * 1000).toISOString();
    const cancelSlotEnd = new Date(baseFutureTime + 270 * 60 * 1000).toISOString();

    it('patient books and then cancels an appointment', async () => {
      const bookRes = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({
          doctorProfileId: doctorProfileIdA,
          startTime: cancelSlotStart,
          endTime: cancelSlotEnd,
          reason: 'Initial booking for cancellation test',
        });

      expect(bookRes.status).toBe(201);
      cancelApptId = bookRes.body.data.appointment.id;

      const cancelRes = await request(app)
        .patch(`/api/v1/appointments/${cancelApptId}/cancel`)
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({
          reason: 'Patient schedule conflict, need to reschedule',
        });

      expect(cancelRes.status).toBe(200);
      expect(cancelRes.body.success).toBe(true);
      expect(cancelRes.body.data.appointment.status).toBe(AppointmentStatus.CANCELLED);
      expect(cancelRes.body.data.appointment.cancelledAt).toBeDefined();
    });

    it('rejects duplicate cancellation with HTTP 400', async () => {
      const res = await request(app)
        .patch(`/api/v1/appointments/${cancelApptId}/cancel`)
        .set('Authorization', `Bearer ${patientToken1}`)
        .send({ reason: 'Attempt double cancel' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('allows rebooking the exact slot after cancellation', async () => {
      const rebookRes = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken2}`)
        .send({
          doctorProfileId: doctorProfileIdA,
          startTime: cancelSlotStart,
          endTime: cancelSlotEnd,
          reason: 'Patient 2 booking freed slot',
        });

      expect(rebookRes.status).toBe(201);
      expect(rebookRes.body.success).toBe(true);
      expect(rebookRes.body.data.appointment.status).toBe(AppointmentStatus.REQUESTED);
    });
  });

  // ============================================================================
  // SECTION 4: Concurrency Protection & Double Booking Prevention
  // ============================================================================
  describe('Concurrency Protection & Double-Booking Prevention', () => {
    it('prevents two concurrent requests from both reserving the same exclusive slot', async () => {
      // Both Patient 1 and Patient 2 attempt to book Slot 4 concurrently at the exact same millisecond
      const [res1, res2] = await Promise.all([
        request(app)
          .post('/api/v1/appointments')
          .set('Authorization', `Bearer ${patientToken1}`)
          .send({
            doctorProfileId: doctorProfileIdA,
            startTime: slot4Start,
            endTime: slot4End,
            reason: 'Concurrent booking attempt 1',
          }),
        request(app)
          .post('/api/v1/appointments')
          .set('Authorization', `Bearer ${patientToken2}`)
          .send({
            doctorProfileId: doctorProfileIdA,
            startTime: slot4Start,
            endTime: slot4End,
            reason: 'Concurrent booking attempt 2',
          }),
      ]);

      const statuses = [res1.status, res2.status].sort();

      // Exactly ONE request must succeed (HTTP 201), and the other MUST fail with HTTP 409 Conflict
      expect(statuses).toEqual([201, 409]);

      const successfulRes = res1.status === 201 ? res1 : res2;
      const conflictedRes = res1.status === 409 ? res1 : res2;

      expect(successfulRes.body.success).toBe(true);
      expect(conflictedRes.body.success).toBe(false);
      expect(conflictedRes.body.error.message).toContain('already reserved');

      // Verify in DB that only 1 active appointment exists for this slot
      const appointmentsInDb = await prisma.appointment.findMany({
        where: {
          doctorProfileId: doctorProfileIdA,
          startTime: new Date(slot4Start),
          endTime: new Date(slot4End),
        },
      });
      expect(appointmentsInDb.length).toBe(1);
    });

    it('allows concurrent requests for DIFFERENT doctors to succeed simultaneously', async () => {
      const slotDiffStart = new Date(baseFutureTime + 300 * 60 * 1000).toISOString();
      const slotDiffEnd = new Date(baseFutureTime + 330 * 60 * 1000).toISOString();

      // Patient 1 books with Doctor A, Patient 2 books with Doctor B at the exact same time
      const [resA, resB] = await Promise.all([
        request(app)
          .post('/api/v1/appointments')
          .set('Authorization', `Bearer ${patientToken1}`)
          .send({
            doctorProfileId: doctorProfileIdA,
            startTime: slotDiffStart,
            endTime: slotDiffEnd,
            reason: 'Doctor A parallel booking',
          }),
        request(app)
          .post('/api/v1/appointments')
          .set('Authorization', `Bearer ${patientToken2}`)
          .send({
            doctorProfileId: doctorProfileIdB,
            startTime: slotDiffStart,
            endTime: slotDiffEnd,
            reason: 'Doctor B parallel booking',
          }),
      ]);

      // Both must succeed with HTTP 201
      expect(resA.status).toBe(201);
      expect(resB.status).toBe(201);
      expect(resA.body.success).toBe(true);
      expect(resB.body.success).toBe(true);
    });
  });
});
