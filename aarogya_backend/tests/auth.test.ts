import { describe, it, expect, afterAll } from 'vitest';
import request from 'supertest';
import express from 'express';
import jwt from 'jsonwebtoken';
import rateLimit from 'express-rate-limit';
import { Role, VerificationStatus } from '@prisma/client';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { env } from '../src/config/env';
import { passwordService } from '../src/services/password.service';
import { tokenService } from '../src/services/token.service';
import { authenticate, requireRoles, requireVerified } from '../src/middleware/auth.middleware';
import { errorHandler } from '../src/middleware/errorHandler';

describe('Authentication & RBAC Foundation Tests', () => {
  const testRunId = `${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  const testPatientEmail = `patient_${testRunId}@aarogya.test`;
  const testDoctorEmail = `doctor_${testRunId}@aarogya.test`;
  const testAdminEmail = `admin_${testRunId}@aarogya.test`;
  const testDriverEmail = `driver_${testRunId}@aarogya.test`;
  const testParamedicEmail = `paramedic_${testRunId}@aarogya.test`;
  const strongPassword = 'StrongPassword123!';

  // Dedicated test app for testing middleware pipeline with errorHandler
  const testApp = express();
  testApp.use(express.json());
  testApp.get('/test-doctor-only', authenticate, requireRoles(Role.DOCTOR), (_req, res) => {
    res.json({ success: true, message: 'Doctor access granted' });
  });
  testApp.get(
    '/test-clinical-verified',
    authenticate,
    requireRoles(Role.DOCTOR),
    requireVerified,
    (_req, res) => {
      res.json({ success: true, message: 'Verified clinical action granted' });
    }
  );
  testApp.use(errorHandler);

  afterAll(async () => {
    // Clean up only this suite's test accounts
    await prisma.user.deleteMany({
      where: {
        email: {
          in: [testPatientEmail, testDoctorEmail, testAdminEmail, testDriverEmail, testParamedicEmail],
        },
      },
    });
  });

  // 1. Password Hashing and Verification
  describe('Password Security (Argon2id)', () => {
    it('hashes passwords securely and generates unique salts for identical inputs', async () => {
      const hash1 = await passwordService.hash(strongPassword);
      const hash2 = await passwordService.hash(strongPassword);

      expect(hash1).not.toBe(strongPassword);
      expect(hash1).not.toBe(hash2); // Different salts
      expect(hash1).toContain('$argon2id$');

      const isValid = await passwordService.verify(hash1, strongPassword);
      expect(isValid).toBe(true);

      const isInvalid = await passwordService.verify(hash1, 'WrongPassword123!');
      expect(isInvalid).toBe(false);
    });
  });

  // 2. Registration Validation
  describe('Registration Input Validation', () => {
    it('rejects passwords that do not meet security requirements', async () => {
      const res = await request(app).post('/api/v1/auth/register/patient').send({
        email: `invalid_pwd_${testRunId}@aarogya.test`,
        password: 'weak',
        fullName: 'Test Weak',
      });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toBe('Validation error');
    });

    it('rejects invalid email formats', async () => {
      const res = await request(app).post('/api/v1/auth/register/patient').send({
        email: 'not-an-email',
        password: strongPassword,
        fullName: 'Test Format',
      });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  // 3 & 4. Patient Registration & Duplicate Handling
  describe('Patient Registration', () => {
    it('registers a patient and creates both user identity and patient profile', async () => {
      const res = await request(app).post('/api/v1/auth/register/patient').send({
        email: testPatientEmail,
        password: strongPassword,
        fullName: 'Aarav Sharma',
        bloodGroup: 'O+',
        abhaId: `ABHA-${testRunId}`,
      });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.role).toBe('PATIENT');
      expect(res.body.data.user.verificationStatus).toBe('VERIFIED');
      expect(res.body.data.profile.fullName).toBe('Aarav Sharma');
      expect(res.body.data.tokens).toHaveProperty('accessToken');
      expect(res.body.data.tokens).toHaveProperty('refreshToken');

      // Password hash must never be returned in API response
      expect(res.body.data.user).not.toHaveProperty('passwordHash');
    });

    it('rejects duplicate email registration with HTTP 409 Conflict', async () => {
      const res = await request(app).post('/api/v1/auth/register/patient').send({
        email: testPatientEmail,
        password: strongPassword,
        fullName: 'Duplicate Sharma',
      });

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('already exists');
    });
  });

  // 5. Professional Registration Defaulting to PENDING
  describe('Professional Registration & Verification Status', () => {
    it('registers a DOCTOR with status PENDING', async () => {
      const res = await request(app).post('/api/v1/auth/register/doctor').send({
        email: testDoctorEmail,
        password: strongPassword,
        fullName: 'Dr. Priya Desai',
        nmcRegistrationNumber: `NMC-${testRunId}`,
        specialization: 'Cardiology',
        qualifications: 'MBBS, MD',
        experienceYears: 8,
      });

      expect(res.status).toBe(201);
      expect(res.body.data.user.role).toBe('DOCTOR');
      expect(res.body.data.user.verificationStatus).toBe('PENDING');
      expect(res.body.data.profile.nmcRegistrationNumber).toBe(`NMC-${testRunId}`);
    });

    it('registers a HOSPITAL_ADMIN with status PENDING', async () => {
      const res = await request(app).post('/api/v1/auth/register/hospital-admin').send({
        email: testAdminEmail,
        password: strongPassword,
        fullName: 'Vikram Joshi',
        hospitalName: 'Apollo City Hospital',
        hospitalLicenseNumber: `HOSP-LIC-${testRunId}`,
        designation: 'Medical Superintendent',
      });

      expect(res.status).toBe(201);
      expect(res.body.data.user.role).toBe('HOSPITAL_ADMIN');
      expect(res.body.data.user.verificationStatus).toBe('PENDING');
    });

    it('registers an AMBULANCE_DRIVER with status PENDING', async () => {
      const res = await request(app).post('/api/v1/auth/register/ambulance-staff').send({
        email: testDriverEmail,
        password: strongPassword,
        fullName: 'Ramesh Kumar',
        staffRole: 'AMBULANCE_DRIVER',
        licenseNumber: `DL-KA-${testRunId}`,
        assignedVehicleNumber: 'KA-01-EQ-9988',
      });

      expect(res.status).toBe(201);
      expect(res.body.data.user.role).toBe('AMBULANCE_DRIVER');
      expect(res.body.data.user.verificationStatus).toBe('PENDING');
    });

    it('registers a PARAMEDIC with status PENDING', async () => {
      const res = await request(app).post('/api/v1/auth/register/ambulance-staff').send({
        email: testParamedicEmail,
        password: strongPassword,
        fullName: 'Ananya Roy',
        staffRole: 'PARAMEDIC',
        licenseNumber: `MEDIC-${testRunId}`,
        certificationLevel: 'ALS Certified',
      });

      expect(res.status).toBe(201);
      expect(res.body.data.user.role).toBe('PARAMEDIC');
      expect(res.body.data.user.verificationStatus).toBe('PENDING');
    });
  });

  // 6. Prevention of Public PLATFORM_ADMIN Registration
  describe('Security Constraints on Roles', () => {
    it('prevents public registration from specifying PLATFORM_ADMIN', async () => {
      const res = await request(app).post('/api/v1/auth/register/ambulance-staff').send({
        email: `fake_admin_${testRunId}@aarogya.test`,
        password: strongPassword,
        fullName: 'Attacker Admin',
        staffRole: 'PLATFORM_ADMIN',
        licenseNumber: 'FAKE-123',
      });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('does not expose any public platform-admin registration route', async () => {
      const res = await request(app).post('/api/v1/auth/register/platform-admin').send({
        email: `platform_admin_${testRunId}@aarogya.test`,
        password: strongPassword,
      });

      expect(res.status).toBe(404);
    });
  });

  // 7. Successful Login & Generic Failed-Login Responses
  describe('Login & Credential Verification', () => {
    it('authenticates valid credentials and returns access token and refresh token', async () => {
      const res = await request(app).post('/api/v1/auth/login').send({
        email: testPatientEmail,
        password: strongPassword,
      });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.tokens).toHaveProperty('accessToken');
      expect(res.body.data.tokens).toHaveProperty('refreshToken');
      expect(res.body.data.user).not.toHaveProperty('passwordHash');
    });

    it('returns generic error on wrong password to prevent credential enumeration', async () => {
      const res = await request(app).post('/api/v1/auth/login').send({
        email: testPatientEmail,
        password: 'IncorrectPassword123!',
      });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toBe('Invalid email or password');
    });

    it('returns the same generic error on non-existent email', async () => {
      const res = await request(app).post('/api/v1/auth/login').send({
        email: `non_existent_${testRunId}@aarogya.test`,
        password: strongPassword,
      });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toBe('Invalid email or password');
    });
  });

  // 8. Access Token Validation and Expiry
  describe('Access Token Lifecycle', () => {
    it('authenticates valid access token against /api/v1/auth/me', async () => {
      const loginRes = await request(app).post('/api/v1/auth/login').send({
        email: testPatientEmail,
        password: strongPassword,
      });

      const token = loginRes.body.data.tokens.accessToken;

      const meRes = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(meRes.status).toBe(200);
      expect(meRes.body.success).toBe(true);
      expect(meRes.body.data.user.email).toBe(testPatientEmail);
    });

    it('rejects requests with missing Authorization header with HTTP 401', async () => {
      const res = await request(app).get('/api/v1/auth/me');
      expect(res.status).toBe(401);
      expect(res.body.error.message).toContain('token required');
    });

    it('rejects requests with invalid token signature', async () => {
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', 'Bearer invalid.token.payload');

      expect(res.status).toBe(401);
    });

    it('rejects expired access tokens with token expired code', async () => {
      const expiredToken = jwt.sign(
        {
          sub: 'fake-id',
          email: 'test@expired.test',
          role: Role.PATIENT,
          verificationStatus: VerificationStatus.VERIFIED,
          jti: 'fake-jti',
        },
        env.JWT_ACCESS_SECRET,
        { expiresIn: -10 } // Expired 10 seconds ago
      );

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${expiredToken}`);

      expect(res.status).toBe(401);
      expect(res.body.error.details).toHaveProperty('code', 'TOKEN_EXPIRED');
    });
  });

  // 9. Refresh Token Rotation and Revoked-Token Reuse Detection
  describe('Refresh Token Rotation & Reuse Detection', () => {
    it('rotates refresh token on valid request and returns new pair', async () => {
      const loginRes = await request(app).post('/api/v1/auth/login').send({
        email: testPatientEmail,
        password: strongPassword,
      });

      const initialRefreshToken = loginRes.body.data.tokens.refreshToken;

      const refreshRes = await request(app).post('/api/v1/auth/refresh-token').send({
        refreshToken: initialRefreshToken,
      });

      expect(refreshRes.status).toBe(200);
      expect(refreshRes.body.success).toBe(true);
      expect(refreshRes.body.data.tokens).toHaveProperty('accessToken');
      expect(refreshRes.body.data.tokens).toHaveProperty('refreshToken');

      const newRefreshToken = refreshRes.body.data.tokens.refreshToken;
      expect(newRefreshToken).not.toBe(initialRefreshToken);

      // Replaying the old (now revoked) initial refresh token MUST trigger breach mitigation!
      const replayRes = await request(app).post('/api/v1/auth/refresh-token').send({
        refreshToken: initialRefreshToken,
      });

      expect(replayRes.status).toBe(401);
      expect(replayRes.body.error.message).toContain('Compromised refresh token reuse detected');

      // The new refresh token should also be revoked because the entire family was invalidated
      const subsequentRes = await request(app).post('/api/v1/auth/refresh-token').send({
        refreshToken: newRefreshToken,
      });
      expect(subsequentRes.status).toBe(401);
    });
  });

  // 10. Logout and Logout-All
  describe('Session Termination (Logout & Logout-All)', () => {
    it('revokes refresh token on /auth/logout', async () => {
      const loginRes = await request(app).post('/api/v1/auth/login').send({
        email: testPatientEmail,
        password: strongPassword,
      });

      const tokenToLogout = loginRes.body.data.tokens.refreshToken;

      const logoutRes = await request(app).post('/api/v1/auth/logout').send({
        refreshToken: tokenToLogout,
      });

      expect(logoutRes.status).toBe(200);

      // Subsequent refresh with logged out token must fail
      const refreshRes = await request(app).post('/api/v1/auth/refresh-token').send({
        refreshToken: tokenToLogout,
      });
      expect(refreshRes.status).toBe(401);
    });

    it('terminates all sessions on /auth/logout-all', async () => {
      const loginRes1 = await request(app).post('/api/v1/auth/login').send({
        email: testDoctorEmail,
        password: strongPassword,
      });

      const loginRes2 = await request(app).post('/api/v1/auth/login').send({
        email: testDoctorEmail,
        password: strongPassword,
      });

      const session1Refresh = loginRes1.body.data.tokens.refreshToken;
      const session2Access = loginRes2.body.data.tokens.accessToken;
      const session2Refresh = loginRes2.body.data.tokens.refreshToken;

      // Call logout-all using session 2 access token
      const logoutAllRes = await request(app)
        .post('/api/v1/auth/logout-all')
        .set('Authorization', `Bearer ${session2Access}`);

      expect(logoutAllRes.status).toBe(200);

      // Both refresh tokens must now be revoked
      const refresh1 = await request(app).post('/api/v1/auth/refresh-token').send({
        refreshToken: session1Refresh,
      });
      expect(refresh1.status).toBe(401);

      const refresh2 = await request(app).post('/api/v1/auth/refresh-token').send({
        refreshToken: session2Refresh,
      });
      expect(refresh2.status).toBe(401);
    });
  });

  // 11 & 12. Role-Based Access Rejection & Professional Verification Gate
  describe('RBAC & Professional Verification Gate Middleware', () => {
    it('rejects PATIENT attempting to access DOCTOR-only route with HTTP 403', async () => {
      const loginRes = await request(app).post('/api/v1/auth/login').send({
        email: testPatientEmail,
        password: strongPassword,
      });

      const patientToken = loginRes.body.data.tokens.accessToken;

      const res = await request(testApp)
        .get('/test-doctor-only')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('Access denied');
    });

    it('blocks unverified DOCTOR (PENDING status) from accessing clinical route with HTTP 403', async () => {
      const loginRes = await request(app).post('/api/v1/auth/login').send({
        email: testDoctorEmail,
        password: strongPassword,
      });

      const doctorToken = loginRes.body.data.tokens.accessToken;

      const res = await request(testApp)
        .get('/test-clinical-verified')
        .set('Authorization', `Bearer ${doctorToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('Professional credentials must be verified');
    });

    it('permits verified DOCTOR to access clinical route with HTTP 200', async () => {
      // Temporarily mark doctor as VERIFIED in DB for testing
      const doctor = await prisma.user.update({
        where: { email: testDoctorEmail },
        data: { verificationStatus: VerificationStatus.VERIFIED },
      });

      // Login to get token with VERIFIED status
      const loginRes = await request(app).post('/api/v1/auth/login').send({
        email: testDoctorEmail,
        password: strongPassword,
      });

      const verifiedDoctorToken = loginRes.body.data.tokens.accessToken;

      const res = await request(testApp)
        .get('/test-clinical-verified')
        .set('Authorization', `Bearer ${verifiedDoctorToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('Verified clinical action granted');

      // Restore doctor status to PENDING
      await prisma.user.update({
        where: { id: doctor.id },
        data: { verificationStatus: VerificationStatus.PENDING },
      });
    });
  });

  // 13. Rate Limiting Tests
  describe('Authentication Rate Limiting', () => {
    it('rate limiter triggers HTTP 429 when threshold exceeded', async () => {
      const limitedApp = express();
      limitedApp.use(express.json());
      const testLimiter = rateLimit({
        windowMs: 60 * 1000,
        max: 2,
        message: { success: false, error: { message: 'Too many requests', statusCode: 429 } },
      });
      limitedApp.post('/test-limit', testLimiter, (_req, res) => res.json({ success: true }));

      // Requests 1 & 2 pass
      const r1 = await request(limitedApp).post('/test-limit');
      expect(r1.status).toBe(200);

      const r2 = await request(limitedApp).post('/test-limit');
      expect(r2.status).toBe(200);

      // Request 3 is blocked with 429
      const r3 = await request(limitedApp).post('/test-limit');
      expect(r3.status).toBe(429);
      expect(r3.body.error.message).toContain('Too many requests');
    });
  });
});
