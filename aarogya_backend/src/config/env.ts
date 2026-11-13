import dotenv from 'dotenv';
import { z } from 'zod';

// Load environment variables from .env file
dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().transform((val) => parseInt(val, 10)).pipe(z.number().positive()).default('5000'),
  DATABASE_URL: z.string().optional(),
  CORS_ORIGIN: z.string().default('*'),
  JWT_ACCESS_SECRET: z.string().min(16).default('aarogya-super-secure-dev-access-secret-32-chars!'),
  JWT_REFRESH_SECRET: z.string().optional(),
  JWT_ACCESS_EXPIRY: z.string().default('30d'),
  JWT_REFRESH_EXPIRY: z.string().default('60d'),
  GROQ_API_KEY: z.string().optional(),
  GROK_API_KEY: z.string().optional(),
  GEMINI_API_KEY: z.string().optional(),
  GOOGLE_PLACES_API_KEY: z.string().optional(),
  MEDICAL_AI_PROVIDER: z.enum(['gemini', 'groq', 'custom_ml']).default('gemini'),
  GROQ_VISION_MODEL: z.string().optional(),
  // External AI Inference Providers (MRI, Lung, Skin)
  HUGGINGFACE_API_KEY: z.string().optional(),
  MRI_AI_API_URL: z.string().url().default('https://api-inference.huggingface.co/models/Hemgg/brain-tumor-classification'),
  MRI_AI_API_KEY: z.string().optional(),
  MRI_AI_MODEL: z.string().default('Hemgg/brain-tumor-classification'),
  LUNG_AI_API_URL: z.string().url().default('https://api-inference.huggingface.co/models/dima806/chest_xray_pneumonia_detection'),
  LUNG_AI_API_KEY: z.string().optional(),
  LUNG_AI_MODEL: z.string().default('dima806/chest_xray_pneumonia_detection'),
  SKIN_AI_API_URL: z.string().url().default('https://api-inference.huggingface.co/models/Tanishq77/skin-condition-classifier'),
  SKIN_AI_API_KEY: z.string().optional(),
  SKIN_AI_MODEL: z.string().default('Tanishq77/skin-condition-classifier'),
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Invalid environment variables:', parsedEnv.error.format());
  process.exit(1);
}

export const env = parsedEnv.data;
