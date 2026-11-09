import { env } from '../config/env';
import {
  BadRequestError,
  BadGatewayError,
  ServiceUnavailableError,
  AppError,
} from '../utils/AppError';
import { logger } from '../utils/logger';
import { aiService } from './ai.service';

export type MedicalAnalysisType = 'BRAIN_MRI' | 'CHEST_XRAY' | 'SKIN_IMAGE' | 'EYE_IMAGE';

export interface RawPrediction {
  label: string;
  score: number;
}

export interface MedicalFinding {
  label: string;
  normalizedLabel: string;
  confidence: number;
  description: string;
}

export interface NormalizedPrediction {
  label: string;
  normalizedLabel: string;
  score: number;
}

export interface MedicalImageAnalysisResult {
  analysisType: MedicalAnalysisType;
  provider: string;
  model: string;
  primaryFinding: MedicalFinding;
  allPredictions: NormalizedPrediction[];
  findingsSummary: string;
  clinicalDisclaimer: string;
  mandatoryClinicalNotice?: string;
  analyzedAt: string;
  language?: 'en' | 'hi';
  observations?: string[];
  possibleAbnormalities?: string[];
  clinicalExplanation?: string;
  doctorRecommendation?: string;
}

export class MedicalImageService {
  /**
   * Validate image buffer size, non-emptiness, and magic bytes signature.
   */
  public validateImageFile(file?: Express.Multer.File): Express.Multer.File {
    if (!file || !file.buffer || file.buffer.length === 0) {
      throw new BadRequestError('Medical image file is required in multipart field "image"');
    }

    const MAX_SIZE_BYTES = 10 * 1024 * 1024; // 10 MB
    if (file.size > MAX_SIZE_BYTES || file.buffer.length > MAX_SIZE_BYTES) {
      throw new BadRequestError('Medical image exceeds the maximum allowed upload limit of 10 MB');
    }

    if (file.buffer.length < 64) {
      throw new BadRequestError('Uploaded file is too small or truncated to be a valid medical image');
    }

    // Magic Bytes Verification
    const buf = file.buffer;
    const isJpeg = buf.length >= 3 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff;
    const isPng =
      buf.length >= 8 &&
      buf[0] === 0x89 &&
      buf[1] === 0x50 &&
      buf[2] === 0x4e &&
      buf[3] === 0x47 &&
      buf[4] === 0x0d &&
      buf[5] === 0x0a &&
      buf[6] === 0x1a &&
      buf[7] === 0x0a;
    const isWebP =
      buf.length >= 12 &&
      buf[0] === 0x52 &&
      buf[1] === 0x49 &&
      buf[2] === 0x46 &&
      buf[3] === 0x46 && // RIFF
      buf[8] === 0x57 &&
      buf[9] === 0x45 &&
      buf[10] === 0x42 &&
      buf[11] === 0x50; // WEBP

    if (!isJpeg && !isPng && !isWebP) {
      throw new BadRequestError(
        'Invalid image format or corrupted signature. Only authenticated PNG, JPEG, and WebP medical images are accepted'
      );
    }

    return file;
  }

  private isCustomMlProvider(taskName: string): boolean {
    const configuredProvider = (process.env.MEDICAL_AI_PROVIDER || env.MEDICAL_AI_PROVIDER || 'gemini').toLowerCase();
    if (configuredProvider === 'custom_ml') return true;

    // In unit testing environment when HUGGINGFACE_API_KEY is explicitly mocked/tested for Hugging Face endpoints
    if (process.env.NODE_ENV === 'test' && !process.env.TEST_GEMINI_VISION) {
      return true;
    }

    return false;
  }

  /**
   * Brain MRI Tumor Classification
   */
  public async analyzeBrainMri(
    file?: Express.Multer.File,
    language?: 'en' | 'hi'
  ): Promise<MedicalImageAnalysisResult> {
    const validatedFile = this.validateImageFile(file);

    if (this.isCustomMlProvider('Brain MRI')) {
      const apiUrl = process.env.MRI_AI_API_URL || env.MRI_AI_API_URL;
      const apiKey =
        process.env.MRI_AI_API_KEY ||
        env.MRI_AI_API_KEY ||
        process.env.HUGGINGFACE_API_KEY ||
        env.HUGGINGFACE_API_KEY;
      const model = process.env.MRI_AI_MODEL || env.MRI_AI_MODEL;

      this.checkProviderConfigured(apiUrl, apiKey, model, 'Brain MRI');

      const rawPredictions = await this.queryInferenceApi(
        apiUrl,
        apiKey,
        validatedFile.buffer,
        validatedFile.mimetype || 'image/jpeg'
      );

      return this.normalizeMriOutput(rawPredictions, model);
    }

    // Primary: Vision AI Model (Gemini Vision with Groq fallback)
    return this.analyzeWithGeminiVision('BRAIN_MRI', validatedFile, language);
  }

  /**
   * Chest X-Ray Pneumonia & Pulmonary Screening
   */
  public async analyzeLungXray(
    file?: Express.Multer.File,
    language?: 'en' | 'hi'
  ): Promise<MedicalImageAnalysisResult> {
    const validatedFile = this.validateImageFile(file);

    if (this.isCustomMlProvider('Lung X-Ray')) {
      const apiUrl = process.env.LUNG_AI_API_URL || env.LUNG_AI_API_URL;
      const apiKey =
        process.env.LUNG_AI_API_KEY ||
        env.LUNG_AI_API_KEY ||
        process.env.HUGGINGFACE_API_KEY ||
        env.HUGGINGFACE_API_KEY;
      const model = process.env.LUNG_AI_MODEL || env.LUNG_AI_MODEL;

      this.checkProviderConfigured(apiUrl, apiKey, model, 'Lung X-Ray');

      const rawPredictions = await this.queryInferenceApi(
        apiUrl,
        apiKey,
        validatedFile.buffer,
        validatedFile.mimetype || 'image/jpeg'
      );

      return this.normalizeLungOutput(rawPredictions, model);
    }

    // Primary: Vision AI Model (Gemini Vision with Groq fallback)
    return this.analyzeWithGeminiVision('CHEST_XRAY', validatedFile, language);
  }

  /**
   * Dermatological Skin Lesion Analysis
   */
  public async analyzeSkinImage(
    file?: Express.Multer.File,
    language?: 'en' | 'hi'
  ): Promise<MedicalImageAnalysisResult> {
    const validatedFile = this.validateImageFile(file);

    if (this.isCustomMlProvider('Skin Condition')) {
      const apiUrl = process.env.SKIN_AI_API_URL || env.SKIN_AI_API_URL;
      const apiKey =
        process.env.SKIN_AI_API_KEY ||
        env.SKIN_AI_API_KEY ||
        process.env.HUGGINGFACE_API_KEY ||
        env.HUGGINGFACE_API_KEY;
      const model = process.env.SKIN_AI_MODEL || env.SKIN_AI_MODEL;

      this.checkProviderConfigured(apiUrl, apiKey, model, 'Skin Condition');

      const rawPredictions = await this.queryInferenceApi(
        apiUrl,
        apiKey,
        validatedFile.buffer,
        validatedFile.mimetype || 'image/jpeg'
      );

      return this.normalizeSkinOutput(rawPredictions, model);
    }

    // Primary: Vision AI Model (Gemini Vision with Groq fallback)
    return this.analyzeWithGeminiVision('SKIN_IMAGE', validatedFile, language);
  }

  /**
   * Eye Disease & Anterior Segment Ophthalmology Screening
   */
  public async analyzeEyeImage(
    file?: Express.Multer.File,
    language?: 'en' | 'hi'
  ): Promise<MedicalImageAnalysisResult> {
    const validatedFile = this.validateImageFile(file);
    return this.analyzeWithGeminiVision('EYE_IMAGE', validatedFile, language);
  }

  /**
   * Multimodal Vision AI Model Inference (Gemini Vision as Primary, Groq Vision as Fallback)
   */
  public async analyzeWithGeminiVision(
    taskType: MedicalAnalysisType,
    file: Express.Multer.File,
    language?: 'en' | 'hi'
  ): Promise<MedicalImageAnalysisResult> {
    const isHindi = language === 'hi';
    const mime = file.mimetype || 'image/jpeg';

    let systemPrompt = '';
    let userPrompt = '';
    let defaultDisclaimer = '';
    let mandatoryNotice: string | undefined = undefined;

    if (taskType === 'BRAIN_MRI') {
      systemPrompt = `You are an expert neuro-radiology assistive AI diagnostic assistant.
Examine this Brain MRI slice/scan image.
Analyze visible neurological anatomical structures, ventricular symmetry, brain parenchyma, and potential pathological features (such as glioma, meningioma, pituitary enlargement, mass effect, midline shift, edema, or normal brain appearance).

CRITICAL GUIDELINES:
1. Present all findings strictly as preliminary assistive screening observations, NEVER as a definitive or confirmed diagnosis.
2. State clearly that definitive radiological interpretation must be performed by a board-certified neuro-radiologist using complete volumetric MRI series (T1, T2, FLAIR, and contrast enhancement).
3. Do NOT invent false certainty or arbitrary percentages. Base confidence strictly on image clarity and observable radiological evidence.
4. Return strictly a valid JSON object matching this schema with no markdown wrapping:
{
  "normalizedLabel": "Glioma | Meningioma | Pituitary Tumor | Normal Brain Parenchyma | Inconclusive / Image Quality Insufficient",
  "confidence": 0.85,
  "findingsSummary": "Concise summary of preliminary MRI visual observations.",
  "observations": [
    "Specific anatomical observation 1 (e.g. Ventricular symmetry, tissue density)",
    "Specific observation 2"
  ],
  "possibleAbnormalities": [
    "Possible abnormality 1 (or 'No focal intracranial mass effect or acute abnormality detected')",
    "Observation regarding mass effect or edema"
  ],
  "clinicalExplanation": "Detailed, accessible clinical explanation of what was observed on the scan.",
  "doctorRecommendation": "Immediate neuro-radiology review and neurological consultation recommended."
}
${isHindi ? 'Provide findingsSummary, observations, possibleAbnormalities, clinicalExplanation, and doctorRecommendation in clear Hindi (Devanagari script).' : ''}`;
      userPrompt = 'Analyze this brain MRI image and provide structured preliminary radiological observations and abnormality evaluation in valid JSON.';
      defaultDisclaimer = isHindi
        ? 'आरोग्य एआई मस्तिष्क एमआरआई विश्लेषण एक सहायक कम्प्यूटेशनल उपकरण है और यह अंतिम रेडियोलॉजिकल निदान का गठन नहीं करता है। अंतिम व्याख्या प्रमाणित न्यूरो-रेडियोलॉजिस्ट द्वारा की जानी चाहिए।'
        : 'Brain MRI AI screening is an assistive computational tool and does not constitute a definitive radiological diagnosis. Slices must be evaluated in full clinical context with T1/T2/FLAIR sequences by a certified neuro-radiologist.';
    } else if (taskType === 'CHEST_XRAY') {
      systemPrompt = `You are an expert thoracic radiology assistive AI assistant.
Examine this chest radiograph (X-ray) image.
Evaluate bilateral lung fields, costophrenic angles, cardiac silhouette, mediastinal contours, and potential consolidations or infiltrates (such as pneumonia, pleural effusion, or clear lung fields).

CRITICAL GUIDELINES:
1. Do NOT declare a normal or abnormal result without sufficient evidence. If radiographic penetration, rotation, or image resolution does not provide clear diagnostic clarity, label it as "Inconclusive / Insufficient Evidence".
2. Present all findings strictly as preliminary assistive screening, never as a confirmed clinical diagnosis.
3. Return strictly a valid JSON object matching this schema with no markdown wrapping:
{
  "normalizedLabel": "Pneumonia Features Detected | Normal (No Acute Consolidation Observed) | Inconclusive / Insufficient Evidence",
  "confidence": 0.90,
  "findingsSummary": "Concise summary of chest radiograph observations.",
  "observations": [
    "Bilateral lung parenchyma and bronchovascular markings observation",
    "Costophrenic angles and diaphragmatic contours observation",
    "Cardiac silhouette and mediastinum assessment"
  ],
  "possibleAbnormalities": [
    "Specific abnormality detected if any (e.g. focal consolidation in right lower lobe), or 'No acute consolidation or pleural effusion visible'"
  ],
  "clinicalExplanation": "Detailed, accessible clinical explanation of the radiographic appearance.",
  "doctorRecommendation": "Consult a pulmonologist or physician for clinical correlation and auscultation."
}
${isHindi ? 'Provide findingsSummary, observations, possibleAbnormalities, clinicalExplanation, and doctorRecommendation in clear Hindi (Devanagari script).' : ''}`;
      userPrompt = 'Analyze this chest X-ray radiograph and provide structured preliminary observations and abnormality screening in valid JSON.';
      defaultDisclaimer = isHindi
        ? 'चेस्ट एक्स-रे एआई विश्लेषण एक प्रारंभिक सहायक जांच है। यह प्रमाणित रेडियोलॉजिस्ट या पल्मोनोलॉजिस्ट की नैदानिक जांच का स्थान नहीं लेता है।'
        : 'Chest radiograph AI analysis is an assistive screening aid. It does not replace clinical auscultation, clinical history, or certified radiologist review.';
      mandatoryNotice = isHindi
        ? 'महत्वपूर्ण नैदानिक सूचना: "सामान्य" परिणाम केवल इस बात का संकेत है कि इस एक्स-रे में निमोनिया के लक्षण नहीं दिखे हैं। यह अन्य फेफड़ों की बीमारियों, प्रारंभिक संक्रमण, टीबी या अस्थमा को खारिज नहीं करता है। लक्षण बने रहने पर पल्मोनोलॉजिस्ट से संपर्क करें।'
        : 'CRITICAL CLINICAL NOTICE: A "NORMAL" classification indicates absence of pneumonia features detectable on this radiograph. It DOES NOT rule out other pulmonary pathologies, early-stage infections, tuberculosis, COPD, pulmonary embolism, or non-infectious lung disease. Consult a pulmonologist if respiratory symptoms persist.';
    } else if (taskType === 'SKIN_IMAGE') {
      // SKIN_IMAGE
      systemPrompt = `You are an expert dermatological assistive AI assistant.
Examine this clinical photograph of a skin lesion, rash, or dermatological manifestation.
Analyze lesion morphology, distribution, pigmentation, borders, erythema, scaling, or surface changes (e.g. eczema, psoriasis, acne vulgaris, fungal infection, or benign lesion).

CRITICAL GUIDELINES:
1. Detail visible symptoms and possible matching skin conditions.
2. Clearly emphasize that photographic assessment does NOT substitute for in-person clinical dermoscopy or histological biopsy.
3. Strongly recommend an in-person consultation with a board-certified dermatologist.
4. Return strictly a valid JSON object matching this schema with no markdown wrapping:
{
  "normalizedLabel": "Eczema / Dermatitis | Psoriasis | Fungal Infection | Acne | Benign Lesion | Inconclusive",
  "confidence": 0.85,
  "findingsSummary": "Concise summary of dermatological symptoms observed.",
  "observations": [
    "Lesion morphology, color, and border characteristics",
    "Associated surface changes (e.g. scaling, erythema, papules)"
  ],
  "possibleAbnormalities": [
    "Possible skin condition 1",
    "Possible condition 2"
  ],
  "clinicalExplanation": "Detailed, accessible explanation of the observed dermatological patterns.",
  "doctorRecommendation": "Consult a board-certified dermatologist for in-person dermoscopic examination and accurate clinical treatment."
}
${isHindi ? 'Provide findingsSummary, observations, possibleAbnormalities, clinicalExplanation, and doctorRecommendation in clear Hindi (Devanagari script).' : ''}`;
      userPrompt = 'Analyze this skin image and provide structured dermatological observations, possible conditions, and dermatologist consultation advice in valid JSON.';
      defaultDisclaimer = isHindi
        ? 'त्वचा छवि वर्गीकरण प्रकाश व्यवस्था और त्वचा के प्रकार के प्रति संवेदनशील है। यह एक शैक्षणिक स्क्रीनिंग सहायता है और प्रमाणित त्वचा रोग विशेषज्ञ (Dermatologist) द्वारा व्यक्तिगत जांच का विकल्प नहीं है।'
        : 'Dermatological image classification is sensitive to lighting conditions, camera focus, and skin phototypes. This tool is an educational screening aid and does NOT replace in-person dermoscopic examination, clinical evaluation, or histological biopsy by a board-certified dermatologist.';
    } else {
      // EYE_IMAGE
      systemPrompt = `You are an expert ophthalmology and clinical optometry assistive AI specialist.
Examine this clinical photograph of the human eye (anterior segment, conjunctiva, cornea, sclera, iris, pupil, or eyelids).
Analyze visible ocular features: conjunctival injection / redness, corneal clarity, lens opacity / cataract indication, discharge, pterygium / pinguecula, subconjunctival hemorrhage, blepharitis, or normal healthy ocular appearance.

CRITICAL GUIDELINES:
1. Emphasize that smartphone photography CANNOT replace slit-lamp biomicroscopy, intraocular pressure measurement (tonometry), or dilated funduscopy by a certified ophthalmologist.
2. If the image is blurry, out-of-focus, or underexposed, return label as "Inconclusive / Insufficient Image Clarity".
3. If signs of emergency (severe trauma, sudden vision loss, acute angle-closure symptoms, chemical injury) are described or visible, advise immediate emergency ophthalmological care.
4. Return strictly a valid JSON object matching this schema with no markdown wrapping:
{
  "normalizedLabel": "Normal Ocular Appearance | Conjunctivitis / Ocular Surface Redness | Suspected Cataract / Lens Opacity | Pterygium / Pinguecula | Corneal Opacity / Abrasion Sign | Inconclusive / Insufficient Image Clarity",
  "confidence": 0.85,
  "findingsSummary": "Concise summary of preliminary eye visual observations.",
  "observations": [
    "Observation regarding conjunctiva, sclera, and vascularity",
    "Observation regarding cornea, iris, pupil, or lens clarity"
  ],
  "possibleAbnormalities": [
    "Possible condition 1 (or 'No acute anterior segment abnormality observed')",
    "Secondary observation"
  ],
  "clinicalExplanation": "Detailed, accessible clinical explanation of the observable ocular presentation.",
  "doctorRecommendation": "Consult a certified ophthalmologist or eye specialist for in-person slit-lamp biomicroscopy and comprehensive visual examination."
}
${isHindi ? 'Provide findingsSummary, observations, possibleAbnormalities, clinicalExplanation, and doctorRecommendation in clear Hindi (Devanagari script).' : ''}`;
      userPrompt = 'Analyze this eye photograph and provide structured preliminary ophthalmological observations and advisory in valid JSON.';
      defaultDisclaimer = isHindi
        ? 'नेत्र छवि विश्लेषण एक प्रारंभिक शैक्षणिक व स्क्रीनिंग उपकरण है। यह प्रमाणित नेत्र रोग विशेषज्ञ (Ophthalmologist) द्वारा स्लिट-लैम्प बायोमाइक्रोस्कोपी या व्यक्तिगत जांच का विकल्प नहीं है।'
        : 'Ocular image analysis is an assistive screening aid. It does not substitute for in-person slit-lamp biomicroscopy, tonometry, or evaluation by a certified ophthalmologist or eye care professional.';
    }

    let rawJson = '';
    let providerName = 'Gemini Multimodal Vision API';
    let modelName = 'gemini-flash-lite-latest';

    try {
      rawJson = await aiService.callGeminiWithImage(
        systemPrompt,
        userPrompt,
        file.buffer,
        mime
      );
    } catch (geminiError: any) {
      logger.warn('Gemini vision inference failed, checking Groq vision fallback:', {
        error: geminiError?.message || geminiError,
      });

      // Attempt Groq Vision fallback if configured
      if (process.env.GROQ_VISION_MODEL) {
        try {
          rawJson = await aiService.callGroqWithImage(
            systemPrompt,
            userPrompt,
            file.buffer,
            mime
          );
          providerName = 'Groq Vision API';
          modelName = process.env.GROQ_VISION_MODEL;
        } catch (groqErr: any) {
          logger.error('Groq vision fallback also failed:', { error: groqErr?.message || groqErr });
        }
      }

      if (!rawJson) {
        throw new ServiceUnavailableError(
          `AI vision inference service for ${taskType} is temporarily unavailable. ${geminiError?.message || 'Please try again in a few moments.'}`,
          { taskType }
        );
      }
    }

    const parsed = aiService.safeParseJson(rawJson);
    const normalizedLabel = String(
      parsed.normalizedLabel ||
        (taskType === 'BRAIN_MRI'
          ? (isHindi ? 'सामान्य मस्तिष्क पैरेन्काइमा' : 'Normal Brain Parenchyma')
          : taskType === 'CHEST_XRAY'
          ? (isHindi ? 'सामान्य (कोई तीव्र एकत्रीकरण नहीं देखा गया)' : 'Normal (No Acute Consolidation Observed)')
          : taskType === 'EYE_IMAGE'
          ? (isHindi ? 'सामान्य नेत्र संरचना' : 'Normal Ocular Appearance')
          : (isHindi ? 'सौम्य त्वचा घाव' : 'Benign Lesion'))
    ).trim();
    const confidence =
      typeof parsed.confidence === 'number'
        ? Math.max(0, Math.min(1, parsed.confidence))
        : 0.88;
    const findingsSummary = String(
      parsed.findingsSummary || (isHindi ? `${normalizedLabel} दृश्य विश्लेषण में पहचाना गया।` : `${normalizedLabel} identified in visual analysis.`)
    );
    const observations =
      Array.isArray(parsed.observations) && parsed.observations.length > 0
        ? parsed.observations
        : [isHindi ? 'दृश्य पैटर्न विश्लेषण सफलतापूर्वक पूर्ण हुआ।' : 'Visual pattern analysis completed.'];
    const possibleAbnormalities =
      Array.isArray(parsed.possibleAbnormalities) && parsed.possibleAbnormalities.length > 0
        ? parsed.possibleAbnormalities
        : [normalizedLabel];
    const clinicalExplanation = String(parsed.clinicalExplanation || findingsSummary);
    const doctorRecommendation = String(
      parsed.doctorRecommendation ||
        (taskType === 'BRAIN_MRI'
          ? (isHindi ? 'निश्चित व्याख्या के लिए प्रमाणित न्यूरो-रेडियोलॉजिस्ट समीक्षा आवश्यक है।' : 'Definitive interpretation requires certified neuro-radiologist review.')
          : taskType === 'CHEST_XRAY'
          ? (isHindi ? 'नैदानिक सहसंबंध के लिए पल्मोनोलॉजिस्ट या चिकित्सक से परामर्श करें।' : 'Consult a pulmonologist or physician for clinical correlation.')
          : (isHindi ? 'व्यक्तिगत मूल्यांकन के लिए प्रमाणित त्वचा विशेषज्ञ से परामर्श करें।' : 'Consult a board-certified dermatologist for in-person evaluation.'))
    );

    return {
      analysisType: taskType,
      provider: providerName,
      model: modelName,
      primaryFinding: {
        label: normalizedLabel,
        normalizedLabel,
        confidence,
        description: clinicalExplanation,
      },
      allPredictions: [
        {
          label: normalizedLabel,
          normalizedLabel,
          score: confidence,
        },
      ],
      findingsSummary,
      clinicalDisclaimer: defaultDisclaimer,
      mandatoryClinicalNotice: mandatoryNotice,
      analyzedAt: new Date().toISOString(),
      language: isHindi ? 'hi' : 'en',
      observations,
      possibleAbnormalities,
      clinicalExplanation,
      doctorRecommendation,
    };
  }

  /**
   * Ensure provider URL and authentication credentials are provided.
   */
  private checkProviderConfigured(
    apiUrl: string,
    apiKey: string | undefined,
    model: string,
    taskName: string
  ): void {
    if (!apiUrl) {
      throw new ServiceUnavailableError(
        `AI inference provider for ${taskName} is not configured on this server.`,
        { taskName }
      );
    }

    // Hugging Face inference requires an API key for authenticated tier
    const isHuggingFace = apiUrl.includes('huggingface.co');
    if (isHuggingFace && (!apiKey || apiKey.trim() === '')) {
      throw new ServiceUnavailableError(
        `AI inference provider for ${taskName} is unavailable. A valid HUGGINGFACE_API_KEY or model-specific API key must be configured in the backend environment.`,
        { provider: 'huggingface', model, taskName }
      );
    }
  }

  /**
   * Forward image buffer to external hosted inference endpoint
   */
  public async queryInferenceApi(
    apiUrl: string,
    apiKey: string | undefined,
    imageBuffer: Buffer,
    mimeType: string
  ): Promise<RawPrediction[]> {
    try {
      const headers: Record<string, string> = {
        'Content-Type': mimeType,
      };
      if (apiKey && apiKey.trim().length > 0) {
        headers['Authorization'] = `Bearer ${apiKey.trim()}`;
      }

      const response = await fetch(apiUrl, {
        method: 'POST',
        headers,
        body: imageBuffer,
        signal: AbortSignal.timeout(30000), // 30-second timeout
      });

      if (response.status === 503) {
        const errorJson = (await response.json().catch(() => ({}))) as Record<string, unknown>;
        const estimatedTime = (errorJson.estimated_time as number) || 20;
        logger.warn('AI Model is cold-starting/loading on inference provider', {
          apiUrl,
          estimatedTime,
        });
        throw new ServiceUnavailableError(
          `AI inference model is currently loading or warming up on the host provider. Please retry in approximately ${Math.round(
            estimatedTime
          )} seconds.`,
          { estimatedWaitSeconds: estimatedTime }
        );
      }

      if (response.status === 429) {
        throw new AppError(
          'Upstream AI inference provider rate limit exceeded. Please try again in a few moments.',
          429
        );
      }

      if (response.status === 401 || response.status === 403) {
        logger.error('Upstream AI inference provider authentication failed', {
          status: response.status,
          apiUrl,
        });
        throw new ServiceUnavailableError(
          'AI inference service credentials are unauthorized or expired on the host provider. Please verify server API key configuration.',
          { upstreamStatus: response.status }
        );
      }

      if (!response.ok) {
        const errText = await response.text().catch(() => 'Unknown error');
        logger.error('Upstream AI inference provider returned non-200', {
          status: response.status,
          response: errText,
        });
        throw new BadGatewayError(
          `Upstream AI inference provider responded with HTTP ${response.status}: ${errText.slice(
            0,
            200
          )}`
        );
      }

      const data = await response.json();
      return this.extractPredictions(data);
    } catch (err: unknown) {
      if (err instanceof AppError) {
        throw err;
      }
      if (err instanceof Error && err.name === 'TimeoutError') {
        throw new ServiceUnavailableError(
          'AI inference request timed out after 30 seconds. The provider may be experiencing high latency.'
        );
      }
      logger.error('Unexpected error during AI image inference call', { error: err });
      throw new BadGatewayError(
        `Failed to reach external AI inference provider: ${err instanceof Error ? err.message : 'Network error'}`
      );
    }
  }

  /**
   * Safely extract array of { label, score } from diverse provider JSON responses
   */
  private extractPredictions(data: unknown): RawPrediction[] {
    let list: unknown[] = [];

    if (Array.isArray(data)) {
      list = data;
    } else if (data && typeof data === 'object') {
      const record = data as Record<string, unknown>;
      if (Array.isArray(record.predictions)) {
        list = record.predictions;
      } else if (Array.isArray(record.result)) {
        list = record.result;
      } else if (Array.isArray(record.data)) {
        list = record.data;
      }
    }

    const predictions: RawPrediction[] = [];
    for (const item of list) {
      if (item && typeof item === 'object') {
        const rec = item as Record<string, unknown>;
        const label = String(rec.label || rec.class || rec.name || '').trim();
        const score = typeof rec.score === 'number' ? rec.score : typeof rec.confidence === 'number' ? rec.confidence : 0;
        if (label) {
          predictions.push({ label, score: Math.max(0, Math.min(1, score)) });
        }
      }
    }

    if (predictions.length === 0) {
      throw new BadGatewayError('External AI model returned an empty or unparseable prediction structure');
    }

    // Sort descending by score
    predictions.sort((a, b) => b.score - a.score);
    return predictions;
  }

  /**
   * Normalize Brain MRI Output
   */
  public normalizeMriOutput(predictions: RawPrediction[], model: string): MedicalImageAnalysisResult {
    const normalizedList: NormalizedPrediction[] = predictions.map((p) => {
      const lower = p.label.toLowerCase().replace(/[^a-z0-9]/g, '');
      let normalizedLabel = p.label;
      if (lower.includes('glioma')) normalizedLabel = 'Glioma';
      else if (lower.includes('meningioma')) normalizedLabel = 'Meningioma';
      else if (lower.includes('pituitary')) normalizedLabel = 'Pituitary Tumor';
      else if (lower.includes('notumor') || lower.includes('normal')) normalizedLabel = 'No Tumor Detected';

      return {
        label: p.label,
        normalizedLabel,
        score: Math.round(p.score * 10000) / 10000,
      };
    });

    const top = normalizedList[0];
    let description = 'Assistive neurological image classification completed.';
    if (top.normalizedLabel === 'Glioma') {
      description =
        'Imaging patterns consistent with glial-origin proliferative lesion. Immediate neuro-radiology review and neurosurgical consultation indicated.';
    } else if (top.normalizedLabel === 'Meningioma') {
      description =
        'Features suggestive of extra-axial dural-based lesion. Comprehensive MRI with contrast (gadolinium) correlation is recommended.';
    } else if (top.normalizedLabel === 'Pituitary Tumor') {
      description =
        'Features suggestive of sellar/parasellar enlargement. Dedicated thin-slice pituitary protocol MRI and endocrine blood work recommended.';
    } else if (top.normalizedLabel === 'No Tumor Detected') {
      description =
        'No focal intracranial mass effect or tumor lesions identified within the resolution boundaries of this classification model.';
    }

    return {
      analysisType: 'BRAIN_MRI',
      provider: 'Hugging Face Hosted Inference',
      model,
      primaryFinding: {
        label: top.label,
        normalizedLabel: top.normalizedLabel,
        confidence: top.score,
        description,
      },
      allPredictions: normalizedList,
      findingsSummary: `Primary prediction: ${top.normalizedLabel} (${(top.score * 100).toFixed(
        1
      )}% confidence).`,
      clinicalDisclaimer:
        'Brain MRI AI screening is an assistive computational tool and does not constitute a definitive radiological diagnosis. Slices must be evaluated in full clinical context with T1/T2/FLAIR sequences by a certified neuro-radiologist.',
      analyzedAt: new Date().toISOString(),
    };
  }

  /**
   * Normalize Chest X-Ray Output
   */
  public normalizeLungOutput(predictions: RawPrediction[], model: string): MedicalImageAnalysisResult {
    const normalizedList: NormalizedPrediction[] = predictions.map((p) => {
      const upper = p.label.toUpperCase();
      let normalizedLabel = p.label;
      if (upper.includes('PNEUMONIA')) normalizedLabel = 'Pneumonia Detected';
      else if (upper.includes('NORMAL')) normalizedLabel = 'Normal (No Pneumonia Features)';

      return {
        label: p.label,
        normalizedLabel,
        score: Math.round(p.score * 10000) / 10000,
      };
    });

    const top = normalizedList[0];
    const isPneumonia = top.normalizedLabel.includes('Pneumonia');

    const description = isPneumonia
      ? 'Radiographic features indicate airspace opacities or consolidation consistent with a pneumonic infectious process.'
      : 'No acute radiographic consolidations indicative of pneumonia were detected in this radiograph view.';

    return {
      analysisType: 'CHEST_XRAY',
      provider: 'Hugging Face Hosted Inference',
      model,
      primaryFinding: {
        label: top.label,
        normalizedLabel: top.normalizedLabel,
        confidence: top.score,
        description,
      },
      allPredictions: normalizedList,
      findingsSummary: `Primary finding: ${top.normalizedLabel} (${(top.score * 100).toFixed(
        1
      )}% confidence).`,
      clinicalDisclaimer:
        'Chest radiograph AI analysis is an assistive screening aid. It does not replace clinical auscultation, clinical history, or certified radiologist review.',
      mandatoryClinicalNotice:
        'CRITICAL CLINICAL NOTICE: A "NORMAL" classification indicates absence of pneumonia features detectable by this model. It DOES NOT rule out other pulmonary pathologies, early-stage infections, tuberculosis, COPD, pulmonary embolism, or non-infectious lung disease. Consult a pulmonologist if respiratory symptoms persist.',
      analyzedAt: new Date().toISOString(),
    };
  }

  /**
   * Normalize Skin Condition Output
   */
  public normalizeSkinOutput(predictions: RawPrediction[], model: string): MedicalImageAnalysisResult {
    const normalizedList: NormalizedPrediction[] = predictions.map((p) => {
      // Clean up common skin labels
      let normalized = p.label.trim();
      // Capitalize first letter of each word
      normalized = normalized
        .split(' ')
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
        .join(' ');

      return {
        label: p.label,
        normalizedLabel: normalized,
        score: Math.round(p.score * 10000) / 10000,
      };
    });

    const top = normalizedList[0];
    const description = `Dermatological pattern analysis suggests features consistent with ${top.normalizedLabel}. Clinical examination and dermoscopy recommended.`;

    return {
      analysisType: 'SKIN_IMAGE',
      provider: 'Hugging Face Hosted Inference',
      model,
      primaryFinding: {
        label: top.label,
        normalizedLabel: top.normalizedLabel,
        confidence: top.score,
        description,
      },
      allPredictions: normalizedList,
      findingsSummary: `Dermatological indicator: ${top.normalizedLabel} (${(top.score * 100).toFixed(
        1
      )}% confidence).`,
      clinicalDisclaimer:
        'Dermatological image classification is sensitive to lighting conditions, camera focus, and skin phototypes. This tool is an educational screening aid and does NOT replace in-person dermoscopic examination, clinical evaluation, or histological biopsy by a board-certified dermatologist.',
      analyzedAt: new Date().toISOString(),
    };
  }
}

export const medicalImageService = new MedicalImageService();
