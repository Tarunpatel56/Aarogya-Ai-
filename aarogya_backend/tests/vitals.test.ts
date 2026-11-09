import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { Role, VerificationStatus, VitalMetricType } from '@prisma/client';
import { tokenService } from '../src/services/token.service';
import { passwordService } from '../src/services/password.service';

describe('Wearable & Smartwatch Vitals API Tests', () => {
  const runId = Date.now().toString().slice(-6);
  let patientToken: string;
  let patientUserId: string;
  let patientProfileId: string;

  beforeAll(async () => {
    const passwordHash = await passwordService.hash('Password123!');
    const user = await prisma.user.create({
      data: {
        email: `vitals_test_${runId}@aarogya.test`,
        phone: `9200${runId}`,
        passwordHash,
        role: Role.PATIENT,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    patientUserId = user.id;

    const profile = await prisma.patientProfile.create({
      data: {
        userId: user.id,
        fullName: 'Test Vitals Patient',
        gender: 'Male',
      },
    });
    patientProfileId = profile.id;

    patientToken = tokenService.signAccessToken({
      id: user.id,
      email: user.email,
      role: Role.PATIENT,
      verificationStatus: VerificationStatus.VERIFIED,
    });
  });

  describe('1. Device Registration & Pairing (/api/v1/devices)', () => {
    it('registers or pairs a smartwatch (FireBoltt 182)', async () => {
      const res = await request(app)
        .post('/api/v1/devices/connect')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          name: 'FireBoltt 182',
          macAddress: 'F4:4E:FC:B8:F3:42',
          deviceType: 'SMARTWATCH',
          batteryLevel: 90,
          firmwareVersion: '1.0.4',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.device.name).toBe('FireBoltt 182');
      expect(res.body.data.device.macAddress).toBe('F4:4E:FC:B8:F3:42');
      expect(res.body.data.device.connectionStatus).toBe('CONNECTED');
    });

    it('retrieves paired devices list', async () => {
      const res = await request(app)
        .get('/api/v1/devices')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.devices.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data.devices[0].macAddress).toBe('F4:4E:FC:B8:F3:42');
    });

    it('retrieves specific device status', async () => {
      const res = await request(app)
        .get('/api/v1/devices/status?macAddress=F4:4E:FC:B8:F3:42')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.connected).toBe(true);
      expect(res.body.data.device.name).toBe('FireBoltt 182');
    });
  });

  describe('2. Vitals Synchronization & Retrieval (/api/v1/vitals)', () => {
    it('synchronizes real health readings from watch into database', async () => {
      const res = await request(app)
        .post('/api/v1/vitals/sync')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          readings: [
            {
              metricType: VitalMetricType.HEART_RATE,
              metricValue: 78,
              unit: 'bpm',
              source: 'SMARTWATCH_BLE',
              measuredAt: new Date().toISOString(),
            },
            {
              metricType: VitalMetricType.SPO2,
              metricValue: 98,
              unit: '%',
              source: 'SMARTWATCH_BLE',
              measuredAt: new Date().toISOString(),
            },
            {
              metricType: VitalMetricType.STEPS,
              metricValue: 4520,
              unit: 'steps',
              source: 'SMARTWATCH_BLE',
              measuredAt: new Date().toISOString(),
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.syncedCount).toBe(3);
    });

    it('fetches latest vitals for patient', async () => {
      const res = await request(app)
        .get('/api/v1/vitals/latest')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.vitals[VitalMetricType.HEART_RATE]).toBeDefined();
      expect(res.body.data.vitals[VitalMetricType.HEART_RATE].metricValue).toBe(78);
      expect(res.body.data.vitals[VitalMetricType.SPO2].metricValue).toBe(98);
      expect(res.body.data.vitals[VitalMetricType.STEPS].metricValue).toBe(4520);
    });

    it('fetches vitals history with metric filtering', async () => {
      const res = await request(app)
        .get(`/api/v1/vitals/history?metricType=${VitalMetricType.HEART_RATE}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.count).toBeGreaterThanOrEqual(1);
      expect(res.body.data.readings[0].metricType).toBe(VitalMetricType.HEART_RATE);
    });

    it('calculates vitals summary (min, max, avg)', async () => {
      const res = await request(app)
        .get('/api/v1/vitals/summary')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.heartRate.samples).toBeGreaterThanOrEqual(1);
      expect(res.body.data.heartRate.min).toBe(78);
      expect(res.body.data.heartRate.max).toBe(78);
      expect(res.body.data.heartRate.avg).toBe(78);
      expect(res.body.data.steps.total).toBe(4520);
    });

    it('disconnects smartwatch', async () => {
      const res = await request(app)
        .post('/api/v1/devices/disconnect')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          macAddress: 'F4:4E:FC:B8:F3:42',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.success).toBe(true);
    });
  });
});
