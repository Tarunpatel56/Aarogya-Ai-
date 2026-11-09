import { describe, it, expect, beforeAll, afterAll, vi } from 'vitest';
import request from 'supertest';
import { Role, VerificationStatus } from '@prisma/client';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { tokenService } from '../src/services/token.service';
import { passwordService } from '../src/services/password.service';
import { medicalImageService } from '../src/services/medical-image.service';

describe('Aarogya Medical AI Imaging API Integration Tests (MRI, Lung, Skin)', () => {
  const testRunId = Date.now().toString().slice(-6);
  const password = 'StrongPassword123!';
  const patientEmail = `patient_imaging_${testRunId}@aarogya.test`;

  let patientToken: string;
  let patientUserId: string;

  // Valid 1x1 PNG image buffer with valid PNG magic bytes: \x89PNG\r\n\x1a\n...
  const validPngBuffer = Buffer.from([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, // PNG Signature
    0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, // IHDR header
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 width/height
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // 8-bit truecolor
    0xde, 0x00, 0x00, 0x00, 0x0c, 0x49, 0x44, 0x41,
    0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
    0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xdd, 0x8d,
    0xb0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e,
    0x44, 0xae, 0x42, 0x60, 0x82, 0x00, 0x00, 0x00, // IEND + extra bytes for >64 bytes
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  ]);

  // Valid JPEG image buffer with valid JPEG magic bytes: 0xFF, 0xD8, 0xFF
  const validJpegBuffer = Buffer.concat([
    Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46]),
    Buffer.alloc(70, 0x00),
    Buffer.from([0xff, 0xd9]),
  ]);

  beforeAll(async () => {
    process.env.HUGGINGFACE_API_KEY = 'hf_mock_test_key_for_testing';
    const hashedPassword = await passwordService.hash(password);

    const patientUser = await prisma.user.create({
      data: {
        email: patientEmail,
        passwordHash: hashedPassword,
        phone: `9840${testRunId}1`,
        role: Role.PATIENT,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    patientUserId = patientUser.id;
    patientToken = tokenService.signAccessToken({
      id: patientUser.id,
      email: patientUser.email,
      role: patientUser.role,
      verificationStatus: patientUser.verificationStatus,
    });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { id: patientUserId },
    });
  });

  describe('Authentication & Access Control', () => {
    it('rejects unauthenticated request to /api/v1/ai/mri-analysis with HTTP 401', async () => {
      const res = await request(app)
        .post('/api/v1/ai/mri-analysis')
        .attach('image', validPngBuffer, 'brain.png');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('rejects unauthenticated request to /api/v1/ai/lung-analysis with HTTP 401', async () => {
      const res = await request(app)
        .post('/api/v1/ai/lung-analysis')
        .attach('image', validJpegBuffer, 'chest.jpg');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('rejects unauthenticated request to /api/v1/ai/skin-analysis with HTTP 401', async () => {
      const res = await request(app)
        .post('/api/v1/ai/skin-analysis')
        .attach('image', validJpegBuffer, 'skin.jpg');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });

  describe('Input Validation & Magic Bytes Integrity', () => {
    it('rejects request with missing image file with HTTP 400', async () => {
      const res = await request(app)
        .post('/api/v1/ai/mri-analysis')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('Medical image file is required');
    });

    it('rejects text file disguised as PNG with HTTP 400 (corrupt signature)', async () => {
      const fakeImage = Buffer.from('This is a plain text file pretending to be an image!'.repeat(3));
      const res = await request(app)
        .post('/api/v1/ai/mri-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', fakeImage, 'fake_mri.png');

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('Invalid image format or corrupted signature');
    });

    it('rejects empty or truncated image buffer under 64 bytes with HTTP 400', async () => {
      const tinyBuffer = Buffer.from([0x89, 0x50, 0x4e, 0x47]); // Only 4 bytes
      const res = await request(app)
        .post('/api/v1/ai/lung-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', tinyBuffer, 'tiny.png');

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('too small or truncated');
    });
  });

  describe('Brain MRI Analysis Endpoint', () => {
    it('returns HTTP 503 when Hugging Face API key is not configured', async () => {
      const originalApiKey = process.env.HUGGINGFACE_API_KEY;
      const originalMriKey = process.env.MRI_AI_API_KEY;
      delete process.env.HUGGINGFACE_API_KEY;
      delete process.env.MRI_AI_API_KEY;

      const res = await request(app)
        .post('/api/v1/ai/mri-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validPngBuffer, 'scan.png');

      expect(res.status).toBe(503);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('HUGGINGFACE_API_KEY');

      // Restore
      process.env.HUGGINGFACE_API_KEY = 'hf_mock_test_key_for_testing';
      if (originalMriKey) process.env.MRI_AI_API_KEY = originalMriKey;
    });

    it('successfully processes Brain MRI and returns normalized glioma prediction with disclaimer', async () => {
      const mockRawPredictions = [
        { label: 'glioma', score: 0.9421 },
        { label: 'meningioma', score: 0.0412 },
        { label: 'pituitary', score: 0.0125 },
        { label: 'notumor', score: 0.0042 },
      ];

      vi.spyOn(medicalImageService, 'queryInferenceApi').mockResolvedValueOnce(mockRawPredictions);

      const res = await request(app)
        .post('/api/v1/ai/mri-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validPngBuffer, 'brain_mri.png');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.analysisType).toBe('BRAIN_MRI');
      expect(res.body.data.primaryFinding.normalizedLabel).toBe('Glioma');
      expect(res.body.data.primaryFinding.confidence).toBe(0.9421);
      expect(res.body.data.primaryFinding.description).toContain('glial-origin');
      expect(res.body.data.clinicalDisclaimer).toContain('neuro-radiologist');
      expect(res.body.data.allPredictions.length).toBe(4);
      expect(res.body.data.analyzedAt).toBeDefined();
    });

    it('successfully normalizes no-tumor result', async () => {
      const mockRawPredictions = [
        { label: 'notumor', score: 0.985 },
        { label: 'meningioma', score: 0.01 },
      ];

      vi.spyOn(medicalImageService, 'queryInferenceApi').mockResolvedValueOnce(mockRawPredictions);

      const res = await request(app)
        .post('/api/v1/ai/mri-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validPngBuffer, 'brain_mri_clear.png');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.primaryFinding.normalizedLabel).toBe('No Tumor Detected');
    });
  });

  describe('Chest X-Ray Analysis Endpoint', () => {
    it('successfully processes Chest X-Ray and includes mandatory negative ruling clinical notice', async () => {
      const mockRawPredictions = [
        { label: 'NORMAL', score: 0.9765 },
        { label: 'PNEUMONIA', score: 0.0235 },
      ];

      vi.spyOn(medicalImageService, 'queryInferenceApi').mockResolvedValueOnce(mockRawPredictions);

      const res = await request(app)
        .post('/api/v1/ai/lung-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validJpegBuffer, 'chest_xray.jpg');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.analysisType).toBe('CHEST_XRAY');
      expect(res.body.data.primaryFinding.normalizedLabel).toContain('Normal');
      // Crucial requirement: must include mandatory clinical notice explaining NORMAL doesn't rule out other lung diseases
      expect(res.body.data.mandatoryClinicalNotice).toBeDefined();
      expect(res.body.data.mandatoryClinicalNotice).toContain('DOES NOT rule out other pulmonary pathologies');
    });

    it('successfully classifies pneumonia case', async () => {
      const mockRawPredictions = [
        { label: 'PNEUMONIA', score: 0.912 },
        { label: 'NORMAL', score: 0.088 },
      ];

      vi.spyOn(medicalImageService, 'queryInferenceApi').mockResolvedValueOnce(mockRawPredictions);

      const res = await request(app)
        .post('/api/v1/ai/lung-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validJpegBuffer, 'chest_pneumonia.jpg');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.primaryFinding.normalizedLabel).toBe('Pneumonia Detected');
      expect(res.body.data.primaryFinding.description).toContain('airspace opacities');
    });
  });

  describe('Skin Condition Analysis Endpoint', () => {
    it('successfully processes skin lesion image and returns dermatological notice', async () => {
      const mockRawPredictions = [
        { label: 'eczema', score: 0.884 },
        { label: 'psoriasis', score: 0.072 },
        { label: 'acne', score: 0.044 },
      ];

      vi.spyOn(medicalImageService, 'queryInferenceApi').mockResolvedValueOnce(mockRawPredictions);

      const res = await request(app)
        .post('/api/v1/ai/skin-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validJpegBuffer, 'skin_lesion.jpg');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.analysisType).toBe('SKIN_IMAGE');
      expect(res.body.data.primaryFinding.normalizedLabel).toBe('Eczema');
      expect(res.body.data.clinicalDisclaimer).toContain('phototypes');
      expect(res.body.data.clinicalDisclaimer).toContain('dermatologist');
    });
  });

  describe('Provider Resilience & Error Propagation', () => {
    it('handles upstream 503 model warm-up gracefully with estimated time', async () => {
      vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce({
        status: 503,
        ok: false,
        json: async () => ({
          error: 'Model is currently loading',
          estimated_time: 25.4,
        }),
      } as unknown as Response);

      const res = await request(app)
        .post('/api/v1/ai/mri-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validPngBuffer, 'scan.png');

      expect(res.status).toBe(503);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('warming up');
    });

    it('handles upstream 429 rate limit correctly', async () => {
      vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce({
        status: 429,
        ok: false,
        json: async () => ({ error: 'Rate limit reached' }),
      } as unknown as Response);

      const res = await request(app)
        .post('/api/v1/ai/lung-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validJpegBuffer, 'lung.jpg');

      expect(res.status).toBe(429);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('rate limit exceeded');
    });

    it('handles upstream 401 provider authentication failure as 503', async () => {
      vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce({
        status: 401,
        ok: false,
        text: async () => 'Invalid token',
      } as unknown as Response);

      const res = await request(app)
        .post('/api/v1/ai/skin-analysis')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validJpegBuffer, 'skin.jpg');

      expect(res.status).toBe(503);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('unauthorized or expired');
    });
  });
});
