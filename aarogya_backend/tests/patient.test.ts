import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { RecordType, Role } from '@prisma/client';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';

describe('Patient Profile & Medical Record Foundation Tests', () => {
  const testRunId = Date.now().toString().slice(-6);
  const patientEmailA = `patient_a_${testRunId}@aarogya.test`;
  const patientEmailB = `patient_b_${testRunId}@aarogya.test`;
  const doctorEmail = `doctor_patient_test_${testRunId}@aarogya.test`;
  const password = 'StrongPassword123!';

  let patientTokenA: string;
  let patientTokenB: string;
  let doctorToken: string;
  let patientRecordIdB: string;

  beforeAll(async () => {
    // 1. Register Patient A
    const regResA = await request(app).post('/api/v1/auth/register/patient').send({
      email: patientEmailA,
      password,
      fullName: 'Patient Alpha',
      phone: `9876${testRunId}1`,
      bloodGroup: 'B+',
      abhaId: `ABHA-A-${testRunId}`,
      allergies: 'Penicillin',
      address: '123 Health Ave, Bangalore',
    });
    patientTokenA = regResA.body.data.tokens.accessToken;

    // 2. Register Patient B
    const regResB = await request(app).post('/api/v1/auth/register/patient').send({
      email: patientEmailB,
      password,
      fullName: 'Patient Beta',
      phone: `9876${testRunId}2`,
      bloodGroup: 'O-',
      abhaId: `ABHA-B-${testRunId}`,
    });
    patientTokenB = regResB.body.data.tokens.accessToken;

    // 3. Register a Doctor to test role boundaries
    const regDoc = await request(app).post('/api/v1/auth/register/doctor').send({
      email: doctorEmail,
      password,
      fullName: 'Dr. Siddharth Verma',
      nmcRegistrationNumber: `NMC-PT-${testRunId}`,
      specialization: 'Internal Medicine',
      qualifications: 'MBBS, MD',
    });
    doctorToken = regDoc.body.data.tokens.accessToken;

    // 4. Create a medical record for Patient B to test privacy isolation
    const recordResB = await request(app)
      .post('/api/v1/patients/me/medical-records')
      .set('Authorization', `Bearer ${patientTokenB}`)
      .send({
        recordType: RecordType.LAB_REPORT,
        title: 'Complete Blood Count (CBC) - Patient B Confidential',
        description: 'Hemoglobin and platelet count results',
        issuingDoctor: 'Dr. Diagnostic',
        facilityName: 'Central Diagnostic Labs',
        documentMetadata: {
          fileRef: 'sec-doc-ref-patient-b-cbc.pdf',
          mimeType: 'application/pdf',
          fileSizeBytes: 245000,
          checksumSha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        },
      });
    patientRecordIdB = recordResB.body.data.record.id;
  });

  afterAll(async () => {
    // Clean up only this suite's test accounts
    await prisma.user.deleteMany({
      where: {
        email: {
          in: [patientEmailA, patientEmailB, doctorEmail],
        },
      },
    });
  });

  describe('GET /api/v1/patients/me', () => {
    it('returns the authenticated patient profile derived strictly from the session token', async () => {
      const res = await request(app)
        .get('/api/v1/patients/me')
        .set('Authorization', `Bearer ${patientTokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.profile.fullName).toBe('Patient Alpha');
      expect(res.body.data.profile.bloodGroup).toBe('B+');
      expect(res.body.data.profile.allergies).toBe('Penicillin');
      expect(res.body.data.profile.address).toBe('123 Health Ave, Bangalore');
      expect(res.body.data.profile.user.email).toBe(patientEmailA);
      expect(res.body.data.profile.user.role).toBe(Role.PATIENT);

      // Password hash must never be returned
      expect(res.body.data.profile.user).not.toHaveProperty('passwordHash');
    });

    it('rejects unauthenticated requests with HTTP 401 Unauthorized', async () => {
      const res = await request(app).get('/api/v1/patients/me');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('rejects non-patient role (DOCTOR) accessing patient self-service endpoint with HTTP 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/v1/patients/me')
        .set('Authorization', `Bearer ${doctorToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('Access denied');
    });
  });

  describe('PATCH /api/v1/patients/me', () => {
    it('allows patient to update permitted fields', async () => {
      const res = await request(app)
        .patch('/api/v1/patients/me')
        .set('Authorization', `Bearer ${patientTokenA}`)
        .send({
          fullName: 'Patient Alpha Updated',
          bloodGroup: 'AB+',
          allergies: 'Penicillin, Sulfa drugs',
          emergencyContactName: 'Emergency Contact Person',
          emergencyContactPhone: '9988776655',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.profile.fullName).toBe('Patient Alpha Updated');
      expect(res.body.data.profile.bloodGroup).toBe('AB+');
      expect(res.body.data.profile.allergies).toBe('Penicillin, Sulfa drugs');
      expect(res.body.data.profile.emergencyContactName).toBe('Emergency Contact Person');
    });

    it('prevents clients from changing role or verification status through profile update', async () => {
      const res = await request(app)
        .patch('/api/v1/patients/me')
        .set('Authorization', `Bearer ${patientTokenA}`)
        .send({
          fullName: 'Patient Alpha Secure',
          role: 'DOCTOR',
          verificationStatus: 'SUSPENDED',
          id: 'hacked-id',
          userId: 'hacked-user-id',
        });

      expect(res.status).toBe(200);
      expect(res.body.data.profile.user.role).toBe(Role.PATIENT); // Unchanged!
      expect(res.body.data.profile.user.verificationStatus).toBe('VERIFIED'); // Unchanged!
    });

    it('rejects duplicate ABHA ID when updating profile', async () => {
      const res = await request(app)
        .patch('/api/v1/patients/me')
        .set('Authorization', `Bearer ${patientTokenA}`)
        .send({
          abhaId: `ABHA-B-${testRunId}`, // Belongs to Patient B
        });

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('already linked');
    });

    it('rejects invalid inputs on profile update with HTTP 400 Validation Error', async () => {
      const res = await request(app)
        .patch('/api/v1/patients/me')
        .set('Authorization', `Bearer ${patientTokenA}`)
        .send({
          phone: '123', // Too short
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toBe('Validation error');
    });
  });

  describe('Medical Record Management & Authorization Isolation', () => {
    it('allows patient to create metadata-only medical records', async () => {
      const res = await request(app)
        .post('/api/v1/patients/me/medical-records')
        .set('Authorization', `Bearer ${patientTokenA}`)
        .send({
          recordType: RecordType.PRESCRIPTION,
          title: 'Cardiology Consultation Prescription',
          description: 'Prescription for blood pressure medication',
          issuingDoctor: 'Dr. Aarav Mehta',
          facilityName: 'Aarogya Memorial Hospital',
          documentMetadata: {
            fileRef: 'prescriptions/2026/rx-cardio-001.pdf',
            mimeType: 'application/pdf',
            fileSizeBytes: 104857,
          },
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.record.title).toBe('Cardiology Consultation Prescription');
      expect(res.body.data.record.recordType).toBe(RecordType.PRESCRIPTION);
      expect(res.body.data.record.documentMetadata.fileRef).toBe('prescriptions/2026/rx-cardio-001.pdf');
    });

    it('rejects invalid record types with HTTP 400', async () => {
      const res = await request(app)
        .post('/api/v1/patients/me/medical-records')
        .set('Authorization', `Bearer ${patientTokenA}`)
        .send({
          recordType: 'INVALID_RECORD_TYPE',
          title: 'Invalid record',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('returns only the authenticated patient records on GET /me/medical-records', async () => {
      const res = await request(app)
        .get('/api/v1/patients/me/medical-records')
        .set('Authorization', `Bearer ${patientTokenA}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.records).toBeInstanceOf(Array);
      expect(res.body.data.records.length).toBeGreaterThanOrEqual(1);

      // Verify none of Patient B's confidential records appear in Patient A's query!
      const containsPatientBRecord = res.body.data.records.some(
        (r: any) => r.id === patientRecordIdB || r.title.includes('Patient B Confidential')
      );
      expect(containsPatientBRecord).toBe(false);
    });

    it('filters records by recordType when query parameter is provided', async () => {
      const res = await request(app)
        .get(`/api/v1/patients/me/medical-records?recordType=${RecordType.PRESCRIPTION}`)
        .set('Authorization', `Bearer ${patientTokenA}`);

      expect(res.status).toBe(200);
      for (const record of res.body.data.records) {
        expect(record.recordType).toBe(RecordType.PRESCRIPTION);
      }
    });

    it('returns a single medical record by ID for the owning patient', async () => {
      const listRes = await request(app)
        .get('/api/v1/patients/me/medical-records')
        .set('Authorization', `Bearer ${patientTokenA}`);

      const recordIdA = listRes.body.data.records[0].id;

      const singleRes = await request(app)
        .get(`/api/v1/patients/me/medical-records/${recordIdA}`)
        .set('Authorization', `Bearer ${patientTokenA}`);

      expect(singleRes.status).toBe(200);
      expect(singleRes.body.success).toBe(true);
      expect(singleRes.body.data.record.id).toBe(recordIdA);
    });

    it('STRICT PRIVACY: prevents Patient A from accessing Patient B record by ID with HTTP 404', async () => {
      // Patient A attempts to fetch Patient B's confidential record
      const res = await request(app)
        .get(`/api/v1/patients/me/medical-records/${patientRecordIdB}`)
        .set('Authorization', `Bearer ${patientTokenA}`);

      // Must return 404 (does not leak that the record ID exists on the system)
      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('not found');
    });

    it('prevents non-patient (DOCTOR) from accessing patient medical records self-service endpoint', async () => {
      const res = await request(app)
        .get('/api/v1/patients/me/medical-records')
        .set('Authorization', `Bearer ${doctorToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });
  });
});
