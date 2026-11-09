import { z } from 'zod';

export const healthChatSchema = {
  body: z.object({
    message: z.string().trim().min(1, 'Message is required').max(2000),
    history: z
      .array(
        z.object({
          role: z.enum(['user', 'assistant', 'system']),
          content: z.string().max(2000),
        })
      )
      .max(20)
      .optional(),
    language: z.enum(['en', 'hi']).optional().default('en'),
    patientVitals: z
      .object({
        heartRate: z.number().int().min(20).max(300).optional(),
        systolicBp: z.number().int().min(40).max(300).optional(),
        diastolicBp: z.number().int().min(20).max(200).optional(),
        glucose: z.number().min(20).max(800).optional(),
        temperature: z.number().min(90).max(110).optional(),
      })
      .optional(),
  }),
};

export const medicineAnalysisSchema = {
  body: z.object({
    ocrText: z.string().trim().min(2, 'OCR text is required').max(5000),
    language: z.enum(['en', 'hi']).optional().default('en'),
  }),
};

export const triageSchema = {
  body: z.object({
    symptoms: z.string().trim().min(2, 'Symptoms description is required').max(2000),
    duration: z.string().trim().max(100).optional(),
    severity: z.enum(['MILD', 'MODERATE', 'SEVERE']).optional().default('MODERATE'),
    vitals: z
      .object({
        heartRate: z.number().int().min(20).max(300).optional(),
        systolicBp: z.number().int().min(40).max(300).optional(),
        diastolicBp: z.number().int().min(20).max(200).optional(),
        temperature: z.number().min(90).max(110).optional(),
        oxygenSaturation: z.number().min(50).max(100).optional(),
      })
      .optional(),
    language: z.enum(['en', 'hi']).optional().default('en'),
  }),
};

export const copilotSummarySchema = {
  body: z.object({
    patientName: z.string().trim().min(1, 'Patient name is required').max(100),
    age: z.number().int().min(0).max(130).optional(),
    gender: z.string().trim().max(20).optional(),
    telemetry: z
      .object({
        heartRate: z.number().optional(),
        bp: z.string().optional(),
        glucose: z.number().optional(),
        spo2: z.number().optional(),
      })
      .optional(),
    currentDiagnosis: z.string().trim().max(500).optional(),
    medications: z.array(z.string().trim().max(100)).max(50).optional(),
    recentObservations: z.string().trim().max(2000).optional(),
  }),
};
