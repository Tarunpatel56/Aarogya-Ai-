import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { app } from '../src/app';

describe('Health and System Endpoints', () => {
  it('GET /health returns health status report with api and database components', async () => {
    const res = await request(app).get('/health');

    // Health endpoint will return 200 (healthy) or 503 (degraded if DB not configured yet)
    expect([200, 503]).toContain(res.status);
    expect(res.body).toHaveProperty('success', true);
    expect(res.body).toHaveProperty('status');
    expect(res.body).toHaveProperty('services');
    expect(res.body.services).toHaveProperty('api');
    expect(res.body.services.api.status).toBe('up');
    expect(res.body.services).toHaveProperty('database');
    expect(res.body.services.database).toHaveProperty('status');
    expect(res.body).toHaveProperty('timestamp');
    expect(res.body).toHaveProperty('uptimeSeconds');
  });

  it('GET /api/v1 returns root API metadata', async () => {
    const res = await request(app).get('/api/v1');

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('success', true);
    expect(res.body).toHaveProperty('message');
    expect(res.body.message).toContain('Aarogya Healthcare Backend API');
  });

  it('GET /api/v1/health returns the same health structure', async () => {
    const res = await request(app).get('/api/v1/health');

    expect([200, 503]).toContain(res.status);
    expect(res.body).toHaveProperty('services');
    expect(res.body.services.api.status).toBe('up');
  });

  it('GET /undefined-route returns standard 404 JSON error response', async () => {
    const res = await request(app).get('/undefined-endpoint-for-testing');

    expect(res.status).toBe(404);
    expect(res.body).toHaveProperty('success', false);
    expect(res.body).toHaveProperty('error');
    expect(res.body.error).toHaveProperty('message');
    expect(res.body.error.message).toContain('not found');
  });
});
