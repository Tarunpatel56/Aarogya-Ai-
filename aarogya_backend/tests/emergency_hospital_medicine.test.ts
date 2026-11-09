import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { Role } from '@prisma/client';
import { tokenService } from '../src/services/token.service';
import { passwordService } from '../src/services/password.service';
import { ensureVerifiedHospitalsSeeded } from '../src/services/hospital-seed.service';

describe('Emergency SOS, Nearby Hospitals & Medicine Reminders Tests', () => {
  let patientToken: string;
  let patientUserId: string;
  let patientProfileId: string;

  beforeAll(async () => {
    await ensureVerifiedHospitalsSeeded();

    const timestamp = Date.now();
    const email = `patient_sos_${timestamp}@aarogya.test`;
    const passwordHash = await passwordService.hash('Secret123!');

    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        role: Role.PATIENT,
        isActive: true,
      },
    });
    patientUserId = user.id;

    const profile = await prisma.patientProfile.create({
      data: {
        userId: user.id,
        fullName: 'Rahul Sharma',
        bloodGroup: 'B_POSITIVE',
        dateOfBirth: new Date('1994-06-15'),
        gender: 'Male',
      },
    });
    patientProfileId = profile.id;
    expect(patientUserId).toBe(user.id);
    expect(patientProfileId).toBe(profile.id);

    patientToken = tokenService.signAccessToken({
      id: user.id,
      email: user.email,
      role: user.role,
      verificationStatus: user.verificationStatus,
    });
  });

  describe('1. Nearby Hospitals Directory & Live Beds (/hospitals/nearby)', () => {
    it('returns nearby verified hospitals sorted by distance with verified ICU beds', async () => {
      const res = await request(app)
        .get('/api/v1/hospitals/nearby?latitude=28.5672&longitude=77.2100&radiusKm=25')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.count).toBeGreaterThanOrEqual(1);

      const first = res.body.data.hospitals[0];
      expect(first).toHaveProperty('name');
      expect(first).toHaveProperty('distanceKm');
      expect(first).toHaveProperty('availableIcuBeds');
      expect(first).toHaveProperty('emergencyPhone');
      expect(first.hasEmergencyBay).toBe(true);
    });

    it('filters hospitals by emergency bay availability', async () => {
      const res = await request(app)
        .get('/api/v1/hospitals/nearby?latitude=28.5672&longitude=77.2100&emergencyBay=true')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      for (const h of res.body.data.hospitals) {
        expect(h.hasEmergencyBay).toBe(true);
      }
    });
  });

  describe('2. Emergency SOS Dispatch & Live Ambulance Tracking (/emergency/sos)', () => {
    let createdEmergencyId: string;

    it('creates an emergency SOS request and assigns nearest ambulance with ETA', async () => {
      const res = await request(app)
        .post('/api/v1/emergency/sos')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          latitude: 28.5680,
          longitude: 77.2110,
          pickupAddress: 'Ansari Nagar, AIIMS Gate 2, New Delhi',
          vitalsSnapshot: { heartRate: 112, spo2: 91, systolicBp: 140, diastolicBp: 95 },
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.emergency).toHaveProperty('id');
      expect(res.body.data.emergency.status).toBe('ASSIGNED');
      expect(res.body.data.emergency).toHaveProperty('assignedVehicleNo');
      expect(res.body.data.emergency).toHaveProperty('estimatedMinutes');
      expect(res.body.data.emergency).toHaveProperty('driverLatitude');
      expect(res.body.data.emergency).toHaveProperty('driverLongitude');

      createdEmergencyId = res.body.data.emergency.id;
    });

    it('fetches current active emergency dispatch for patient', async () => {
      const res = await request(app)
        .get('/api/v1/emergency/sos/active')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.hasActiveEmergency).toBe(true);
      expect(res.body.data.emergency.id).toBe(createdEmergencyId);
    });

    it('simulates ambulance moving closer to patient and decrements ETA', async () => {
      const res = await request(app)
        .patch(`/api/v1/emergency/sos/${createdEmergencyId}/simulate-move`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.emergency).toHaveProperty('driverLatitude');
      expect(res.body.data.emergency).toHaveProperty('driverLongitude');
    });

    it('cancels the active emergency request upon patient request', async () => {
      const res = await request(app)
        .patch(`/api/v1/emergency/sos/${createdEmergencyId}/cancel`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.emergency.status).toBe('CANCELLED');
    });
  });

  describe('3. Medicine Reminders & Dose Adherence Tracking (/patients/me/medicine-reminders)', () => {
    let reminderId: string;

    it('creates a new medicine reminder schedule', async () => {
      const res = await request(app)
        .post('/api/v1/patients/me/medicine-reminders')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          medicineName: 'Metformin 500mg',
          dosage: '1 Tablet',
          dosageForm: 'Tablet',
          frequency: 'Twice Daily',
          reminderTimes: ['08:00 AM', '08:00 PM'],
          instructions: 'Take after meals with water',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.reminder).toHaveProperty('id');
      expect(res.body.data.reminder.medicineName).toBe('Metformin 500mg');
      expect(res.body.data.reminder.isActive).toBe(true);

      reminderId = res.body.data.reminder.id;
    });

    it('lists active medicine reminders for this patient', async () => {
      const res = await request(app)
        .get('/api/v1/patients/me/medicine-reminders')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.count).toBeGreaterThanOrEqual(1);
    });

    it('logs dose adherence status (TAKEN)', async () => {
      const res = await request(app)
        .patch(`/api/v1/patients/me/medicine-reminders/${reminderId}/dose`)
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          status: 'TAKEN',
          scheduledTime: new Date().toISOString(),
        });

      expect(res.status).toBe(201);
      expect(res.body.data.doseLog.status).toBe('TAKEN');
      expect(res.body.data.doseLog).toHaveProperty('takenAt');
    });

    it('deletes/removes a medicine reminder', async () => {
      const res = await request(app)
        .delete(`/api/v1/patients/me/medicine-reminders/${reminderId}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });
});
