import { Request, Response, NextFunction } from 'express';
import { aiService } from '../services/ai.service';
import { medicalImageService } from '../services/medical-image.service';

export class AiController {
  /**
   * Conversational health assistant response
   * POST /api/v1/ai/chat
   */
  public async chat(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await aiService.chatWithHealthAssistant(req.body);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Analyze medicine prescription or strip OCR text
   * POST /api/v1/ai/analyze-medicine
   */
  public async analyzeMedicine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await aiService.analyzeMedicineOcr(req.body);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Analyze medicine prescription or packaging image directly via vision
   * POST /api/v1/ai/analyze-medicine-image
   */
  public async analyzeMedicineImage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const language = ((req.query.language || req.body?.language) === 'hi' ? 'hi' : 'en') as 'en' | 'hi';
      const result = await aiService.analyzeMedicineImage(req.file, language);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Rapid Symptom Triage Assessment
   * POST /api/v1/ai/triage
   */
  public async triage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await aiService.assessTriage(req.body);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Physician Clinical Co-Pilot Telemetry & Patient Summary
   * POST /api/v1/ai/copilot-summary
   */
  public async copilotSummary(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await aiService.generateClinicalCoPilotSummary(req.body);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Connectivity and model status for AI providers
   * GET /api/v1/ai/status
   */
  public async status(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const status = await aiService.getAiStatus();
      res.status(200).json({
        success: true,
        data: status,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Brain MRI Tumor Image Inference Analysis
   * POST /api/v1/ai/mri-analysis
   */
  public async analyzeMri(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const language = ((req.query.language || req.body?.language) === 'hi' ? 'hi' : 'en') as 'en' | 'hi';
      const result = await medicalImageService.analyzeBrainMri(req.file, language);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Chest X-Ray Pneumonia & Pulmonary Image Inference Analysis
   * POST /api/v1/ai/lung-analysis
   */
  public async analyzeLung(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const language = ((req.query.language || req.body?.language) === 'hi' ? 'hi' : 'en') as 'en' | 'hi';
      const result = await medicalImageService.analyzeLungXray(req.file, language);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Dermatological Skin Disease Image Inference Analysis
   * POST /api/v1/ai/skin-analysis
   */
  public async analyzeSkin(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const language = ((req.query.language || req.body?.language) === 'hi' ? 'hi' : 'en') as 'en' | 'hi';
      const result = await medicalImageService.analyzeSkinImage(req.file, language);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Ophthalmology Eye Disease Image Analysis
   * POST /api/v1/ai/eye-analysis
   */
  public async analyzeEye(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const language = ((req.query.language || req.body?.language) === 'hi' ? 'hi' : 'en') as 'en' | 'hi';
      const result = await medicalImageService.analyzeEyeImage(req.file, language);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Diagnostic Lab Report / Pathology Document Analysis
   * POST /api/v1/ai/analyze-report
   */
  public async analyzeReport(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const language = ((req.query.language || req.body?.language) === 'hi' ? 'hi' : 'en') as 'en' | 'hi';
      const rawText = req.body?.rawText || req.body?.reportText;
      const result = await aiService.analyzeMedicalReport(req.file, rawText, language);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Summarize FHIR / ABDM Health Record
   * POST /api/v1/ai/summarize-record
   */
  public async summarizeRecord(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { recordText, language } = req.body;
      const result = await aiService.summarizeHealthRecord(recordText || '', language || 'en');
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Explain Medicine Composition & Generic Alternative
   * POST /api/v1/ai/explain-medicine
   */
  public async explainMedicine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { medicineName, composition, language } = req.body;
      const result = await aiService.explainMedicineComposition(medicineName || '', composition || '', language || 'en');
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Generate Doctor-to-Doctor Clinical Referral Case Summary
   * POST /api/v1/ai/clinical-case-summary
   */
  public async clinicalCaseSummary(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { patientName, clinicalData } = req.body;
      const result = await aiService.generateClinicalCaseSummary(patientName || 'Patient', clinicalData || {});
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const aiController = new AiController();
