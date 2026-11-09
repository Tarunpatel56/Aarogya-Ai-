import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { wearableService } from '../src/services/wearable.service';

describe('Wearable Telemetry & Laptop Bridge Tests', () => {
  const testRunId = Date.now().toString().slice(-6);
  const patientEmail = `wearable_${testRunId}@aarogya.test`;
  const password = 'StrongPassword123!';
  let patientToken: string;
  let testUserId: string;

  beforeAll(async () => {
    const regRes = await request(app).post('/api/v1/auth/register/patient').send({
      email: patientEmail,
      password,
      fullName: 'Wearable Test User',
      phone: `9100${testRunId}`,
      bloodGroup: 'O+',
    });

    patientToken = regRes.body.data.tokens.accessToken;
    testUserId = regRes.body.data.user.id;
  });

  afterAll(async () => {
    if (testUserId) {
      await prisma.user.delete({ where: { id: testUserId } }).catch(() => {});
    }
  });

  it('rejects unauthenticated requests to /wearables/bridge/watch with HTTP 401', async () => {
    const res = await request(app).get('/api/v1/wearables/bridge/watch');
    expect(res.status).toBe(401);
  });

  it('rejects unauthenticated requests to /wearables/capabilities with HTTP 401', async () => {
    const res = await request(app).get('/api/v1/wearables/capabilities');
    expect(res.status).toBe(401);
  });

  it('returns documented watch capabilities for FireBoltt 182 when authenticated', async () => {
    const res = await request(app)
      .get('/api/v1/wearables/capabilities')
      .set('Authorization', `Bearer ${patientToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.modelName).toBe('FireBoltt 182');
    expect(res.body.data.macAddress).toBe('F4:4E:FC:B8:F3:42');
    expect(res.body.data.connectivity.bluetoothLowEnergy.supported).toBe(true);

    const services = res.body.data.connectivity.bluetoothLowEnergy.standardGattServices;
    const uuids = services.map((s: any) => s.uuid);
    expect(uuids).toContain('0x180D'); // Heart Rate
    expect(uuids).toContain('0x180F'); // Battery
    expect(uuids).toContain('0x180A'); // Device Info
  });

  it('returns valid watch telemetry via laptop bridge when authenticated', async () => {
    const res = await request(app)
      .get('/api/v1/wearables/bridge/watch')
      .set('Authorization', `Bearer ${patientToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.device).toBeDefined();
    expect(res.body.data.device.name).toContain('FireBoltt');
    expect(res.body.data.device.macAddress).toBe('F4:4E:FC:B8:F3:42');
    expect(res.body.data.telemetry).toBeDefined();
    expect(res.body.data.telemetry.heartRate).toBeDefined();
    expect(res.body.data.telemetry.heartRate.supported).toBe(true);
    expect(res.body.data.telemetry.steps.supported).toBe(true);
    expect(res.body.data.bridgeMode).toBe('Local Laptop BLE Bridge');
    expect(res.body.data.timestamp).toBeDefined();
  }, 30000);

  it('wearableService getWatchCapabilities returns valid specification matrix', () => {
    const caps = wearableService.getWatchCapabilities();
    expect(caps.modelName).toBe('FireBoltt 182');
    expect(caps.hardwareModel).toBe('FD28');
    expect(caps.connectivity.classicBluetooth.supported).toBe(true);
  });
});
