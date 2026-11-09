import { describe, it, expect, beforeAll, afterAll, vi } from 'vitest';
import request from 'supertest';
import { Role, VerificationStatus } from '@prisma/client';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { tokenService } from '../src/services/token.service';
import { passwordService } from '../src/services/password.service';
import { aiService } from '../src/services/ai.service';

describe('Aarogya Multi-Provider AI Integration Tests (Gemini & Groq)', () => {
  const testRunId = Date.now().toString().slice(-6);
  const password = 'StrongPassword123!';
  const patientEmail = `patient_ai_${testRunId}@aarogya.test`;
  const doctorEmail = `doctor_ai_${testRunId}@aarogya.test`;

  let patientToken: string;
  let doctorToken: string;
  let patientUserId: string;
  let doctorUserId: string;

  beforeAll(async () => {
    const hashedPassword = await passwordService.hash(password);

    // Create test patient user in DB
    const patientUser = await prisma.user.create({
      data: {
        email: patientEmail,
        passwordHash: hashedPassword,
        phone: `9830${testRunId}1`,
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

    // Create test doctor user in DB
    const doctorUser = await prisma.user.create({
      data: {
        email: doctorEmail,
        passwordHash: hashedPassword,
        phone: `9830${testRunId}2`,
        role: Role.DOCTOR,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    doctorUserId = doctorUser.id;
    doctorToken = tokenService.signAccessToken({
      id: doctorUser.id,
      email: doctorUser.email,
      role: doctorUser.role,
      verificationStatus: doctorUser.verificationStatus,
    });
  });

  afterAll(async () => {
    // Cleanup created test users
    await prisma.user.deleteMany({
      where: {
        id: { in: [patientUserId, doctorUserId] },
      },
    });
  });

  describe('Authentication & Access Control', () => {
    it('rejects unauthenticated requests with HTTP 401', async () => {
      const res = await request(app).post('/api/v1/ai/chat').send({ message: 'Hello' });
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('allows authenticated patient to access chat and receive AI guidance', async () => {
      const chatSpy = vi.spyOn(aiService, 'chatWithHealthAssistant').mockResolvedValueOnce({
        reply: 'Drink plenty of water and maintain regular rest.',
        provider: 'gemini',
        model: 'gemini-2.5-flash-lite',
        disclaimer: 'Notice: Aarogya AI guidance is for informational reference only.',
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          message: 'I have a mild headache, what should I do?',
          language: 'en',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.reply).toContain('Drink plenty of water');
      expect(res.body.data.provider).toBe('gemini');
      expect(res.body.data.disclaimer).toBeDefined();

      chatSpy.mockRestore();
    });

    it('blocks PATIENT from accessing DOCTOR-only copilot-summary with HTTP 403', async () => {
      const res = await request(app)
        .post('/api/v1/ai/copilot-summary')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          patientName: 'John Doe',
          telemetry: { heartRate: 110, bp: '145/95' },
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('Access denied');
    });

    it('allows DOCTOR to access copilot-summary with HTTP 200', async () => {
      const copilotSpy = vi.spyOn(aiService, 'generateClinicalCoPilotSummary').mockResolvedValueOnce({
        clinicalSummary: 'Patient exhibiting mild sinus tachycardia with Stage 1 systolic hypertension.',
        riskAssessment: 'OBSERVATION_REQUIRED',
        suggestedInterventions: ['Perform 12-lead ECG', 'Titrate antihypertensive therapy'],
        vitalAnomalies: ['Heart rate > 100 bpm', 'BP > 140/90 mmHg'],
        provider: 'groq',
        model: 'qwen/qwen3.8-27b',
      });

      const res = await request(app)
        .post('/api/v1/ai/copilot-summary')
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({
          patientName: 'Jane Smith',
          age: 58,
          gender: 'Female',
          telemetry: { heartRate: 112, bp: '146/92', spo2: 98 },
          currentDiagnosis: 'Essential Hypertension',
          medications: ['Amlodipine 5mg'],
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.riskAssessment).toBe('OBSERVATION_REQUIRED');
      expect(res.body.data.suggestedInterventions.length).toBeGreaterThan(0);

      copilotSpy.mockRestore();
    });
  });

  describe('Input Validation & Error Handling', () => {
    it('rejects empty message in chat with HTTP 400', async () => {
      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({ message: '' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('rejects missing OCR text in analyze-medicine with HTTP 400', async () => {
      const res = await request(app)
        .post('/api/v1/ai/analyze-medicine')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({});

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('validates and parses medicine OCR correctly with full uses, disadvantages, what happens, and price', async () => {
      const ocrSpy = vi.spyOn(aiService, 'analyzeMedicineOcr').mockResolvedValueOnce({
        medicineName: 'Telmisartan Tablets IP',
        genericName: 'Telmisartan',
        dosage: '40mg',
        dosageForm: 'Tablet',
        frequency: 'Once daily',
        purpose: 'Hypertension management',
        uses: ['Hypertension management', 'Cardiovascular risk reduction'],
        disadvantages: ['Dizziness', 'Hyperkalemia'],
        whatHappensWhenTaken: 'Relaxes blood vessels by blocking Angiotensin II.',
        estimatedPrice: '₹35 - ₹65 per strip (10 tablets)',
        instructions: 'Take once daily in the morning with water.',
        warnings: ['Do not use if pregnant', 'Avoid salt substitutes with potassium'],
        disclaimer: 'Notice: Aarogya AI guidance is for informational reference only.',
        provider: 'gemini',
      });

      const res = await request(app)
        .post('/api/v1/ai/analyze-medicine')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          ocrText: 'TELMISARTAN TABLETS IP 40mg Rx Only Mfg Lic No 1234',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.medicineName).toContain('Telmisartan');
      expect(res.body.data.dosage).toBe('40mg');
      expect(res.body.data.uses).toBeInstanceOf(Array);
      expect(res.body.data.disadvantages).toBeInstanceOf(Array);
      expect(res.body.data.whatHappensWhenTaken).toContain('blood vessels');
      expect(res.body.data.estimatedPrice).toContain('₹');
      expect(res.body.data.warnings).toBeInstanceOf(Array);

      ocrSpy.mockRestore();
    });

    it('analyzes uploaded medicine packaging image via analyze-medicine-image', async () => {
      // 1x1 valid PNG buffer
      const validPng = Buffer.from([
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
        0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
        0x89, 0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
        0x42, 0x60, 0x82,
      ]);

      const imageSpy = vi.spyOn(aiService, 'analyzeMedicineImage').mockResolvedValueOnce({
        medicineName: 'Paracetamol 650mg',
        genericName: 'Paracetamol / Acetaminophen',
        dosage: '650mg',
        dosageForm: 'Tablet',
        frequency: 'Every 6-8 hours as needed',
        purpose: 'Fever and pain relief',
        uses: ['Headache and body ache', 'Fever reduction'],
        disadvantages: ['Liver toxicity with overdose', 'Mild stomach upset'],
        whatHappensWhenTaken: 'Inhibits brain pain signals and resets body temperature in 30 minutes.',
        estimatedPrice: '₹15 - ₹35 per strip (15 tablets)',
        instructions: 'Take with water after meals.',
        warnings: ['Do not exceed 4000mg per day'],
        disclaimer: 'Notice: Aarogya AI guidance is for informational reference only.',
        provider: 'gemini',
      });

      const res = await request(app)
        .post('/api/v1/ai/analyze-medicine-image')
        .set('Authorization', `Bearer ${patientToken}`)
        .attach('image', validPng, 'paracetamol_strip.png');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.medicineName).toContain('Paracetamol');
      expect(res.body.data.uses).toBeInstanceOf(Array);
      expect(res.body.data.disadvantages).toBeInstanceOf(Array);
      expect(res.body.data.whatHappensWhenTaken).toBeDefined();
      expect(res.body.data.estimatedPrice).toBeDefined();

      imageSpy.mockRestore();
    });

    it('performs rapid symptom triage assessment', async () => {
      const triageSpy = vi.spyOn(aiService, 'assessTriage').mockResolvedValueOnce({
        urgencyLevel: 'HIGH',
        summary: 'Acute chest tightness with elevated blood pressure warrants urgent clinical review.',
        recommendedAction: 'Visit urgent care facility or consult your cardiologist immediately.',
        suggestedSpecialty: 'Cardiologist',
        redFlags: ['Sudden onset chest tightness'],
        disclaimer: 'Notice: Aarogya AI guidance is for informational reference only.',
        provider: 'groq',
      });

      const res = await request(app)
        .post('/api/v1/ai/triage')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          symptoms: 'Sudden chest discomfort and shortness of breath for past 45 minutes',
          duration: '45 mins',
          severity: 'SEVERE',
          vitals: { heartRate: 105, systolicBp: 155, diastolicBp: 98, oxygenSaturation: 94 },
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.urgencyLevel).toBe('HIGH');
      expect(res.body.data.suggestedSpecialty).toBe('Cardiologist');

      triageSpy.mockRestore();
    });
  });

  describe('Provider Connectivity & Status', () => {
    it('GET /api/v1/ai/status reports configured providers', async () => {
      const res = await request(app)
        .get('/api/v1/ai/status')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('gemini');
      expect(res.body.data).toHaveProperty('groq');
      expect(res.body.data.gemini.configured).toBe(true);
      expect(res.body.data.groq.configured).toBe(true);
    });
  });
});
