import { Router, Request, Response, NextFunction } from 'express';
import { Role } from '@prisma/client';
import rateLimit from 'express-rate-limit';
import multer from 'multer';
import { env } from '../config/env';
import { authenticate, requireRoles } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validateRequest';
import { aiController } from '../controllers/ai.controller';
import { BadRequestError } from '../utils/AppError';
import {
  healthChatSchema,
  medicineAnalysisSchema,
  triageSchema,
  copilotSummarySchema,
} from '../validation/ai.validation';

const router = Router();

// Rate limiter for AI inference requests (60 requests per 10 minutes in non-test env)
const aiRateLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: env.NODE_ENV === 'test' ? 1000 : 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      message: 'Too many AI requests. Please slow down.',
      statusCode: 429,
    },
  },
  skip: () => env.NODE_ENV === 'test' && process.env.TEST_RATE_LIMIT !== 'true',
});

// All AI endpoints require valid Bearer token authentication
router.use(authenticate);
router.use(aiRateLimiter);

// 1. Health Assistant Chatbot (Patients & Clinicians)
router.post('/chat', validateRequest(healthChatSchema), (req, res, next) => {
  aiController.chat(req, res, next);
});

// 2. Medicine Strip / Prescription OCR Parsing
router.post('/analyze-medicine', validateRequest(medicineAnalysisSchema), (req, res, next) => {
  aiController.analyzeMedicine(req, res, next);
});

// 3. Rapid Symptom Triage Assessment
router.post('/triage', validateRequest(triageSchema), (req, res, next) => {
  aiController.triage(req, res, next);
});

// 4. Physician Clinical Co-Pilot Telemetry Summary (Doctors & Admins only)
router.post(
  '/copilot-summary',
  requireRoles(Role.DOCTOR, Role.HOSPITAL_ADMIN, Role.PLATFORM_ADMIN),
  validateRequest(copilotSummarySchema),
  (req, res, next) => {
    aiController.copilotSummary(req, res, next);
  }
);

// 5. Connectivity and Provider Status
router.get('/status', (req, res, next) => {
  aiController.status(req, res, next);
});

// Configure Multer in-memory storage for medical image uploads (max 10MB)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10 MB maximum
  },
});

const imageUploadMiddleware = (req: Request, res: Response, next: NextFunction) => {
  upload.single('image')(req, res, (err: unknown) => {
    if (err) {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return next(
            new BadRequestError('Medical image exceeds the maximum allowed upload limit of 10 MB')
          );
        }
        return next(new BadRequestError(`Image upload error: ${err.message}`));
      }
      return next(err);
    }
    next();
  });
};

// 6. Brain MRI Analysis
router.post('/mri-analysis', imageUploadMiddleware, (req, res, next) => {
  aiController.analyzeMri(req, res, next);
});

// 7. Chest X-Ray Analysis
router.post('/lung-analysis', imageUploadMiddleware, (req, res, next) => {
  aiController.analyzeLung(req, res, next);
});

// 8. Skin Condition Analysis
router.post('/skin-analysis', imageUploadMiddleware, (req, res, next) => {
  aiController.analyzeSkin(req, res, next);
});

// 9. Medicine Packaging / Strip Image Direct Vision Analysis
router.post('/analyze-medicine-image', imageUploadMiddleware, (req: Request, res: Response, next: NextFunction) => {
  aiController.analyzeMedicineImage(req, res, next);
});

// 10. Ophthalmology Eye Disease Vision Analysis
router.post('/eye-analysis', imageUploadMiddleware, (req: Request, res: Response, next: NextFunction) => {
  aiController.analyzeEye(req, res, next);
});

// 11. Diagnostic Lab Report / Pathology Document Analysis (Image or Form Body)
router.post('/analyze-report', imageUploadMiddleware, (req: Request, res: Response, next: NextFunction) => {
  aiController.analyzeReport(req, res, next);
});

export const aiRoutes = router;
