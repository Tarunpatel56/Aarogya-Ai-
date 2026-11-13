import { env } from '../config/env';
import { AppError, BadRequestError } from '../utils/AppError';

export interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

export interface HealthChatParams {
  message: string;
  history?: ChatMessage[];
  language?: 'en' | 'hi';
  patientVitals?: {
    heartRate?: number;
    systolicBp?: number;
    diastolicBp?: number;
    glucose?: number;
    temperature?: number;
  };
}

export interface HealthChatResult {
  reply: string;
  replyHi?: string;
  replyEn?: string;
  provider: 'gemini' | 'groq';
  model: string;
  disclaimer: string;
}

export interface MedicineAnalysisParams {
  ocrText: string;
  language?: 'en' | 'hi';
}

export interface MedicineAnalysisResult {
  medicineName: string;
  brandName?: string;
  genericName?: string;
  composition?: string;
  strength?: string;
  manufacturer?: string;
  mrp?: string;
  dosage?: string;
  dosageForm?: string;
  frequency?: string;
  purpose?: string;
  uses: string[];
  disadvantages: string[];
  whatHappensWhenTaken: string;
  precautions?: string[];
  dosageGuideline?: string;
  estimatedPrice: string;
  instructions: string;
  warnings: string[];
  disclaimer: string;
  provider: 'gemini' | 'groq';
  extractedOcrText?: string;
  language?: 'en' | 'hi';
}

export interface TriageParams {
  symptoms: string;
  duration?: string;
  severity?: 'MILD' | 'MODERATE' | 'SEVERE';
  vitals?: {
    heartRate?: number;
    systolicBp?: number;
    diastolicBp?: number;
    temperature?: number;
    oxygenSaturation?: number;
  };
  language?: 'en' | 'hi';
}

export interface TriageResult {
  urgencyLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'EMERGENCY';
  summary: string;
  recommendedAction: string;
  suggestedSpecialty: string;
  redFlags: string[];
  disclaimer: string;
  provider: 'gemini' | 'groq';
}

export interface ClinicalCoPilotParams {
  patientName: string;
  age?: number;
  gender?: string;
  telemetry?: {
    heartRate?: number;
    bp?: string;
    glucose?: number;
    spo2?: number;
  };
  currentDiagnosis?: string;
  medications?: string[];
  recentObservations?: string;
}

export interface ClinicalCoPilotResult {
  clinicalSummary: string;
  riskAssessment: 'STABLE' | 'OBSERVATION_REQUIRED' | 'CRITICAL';
  suggestedInterventions: string[];
  vitalAnomalies: string[];
  provider: 'gemini' | 'groq';
  model: string;
}

export interface LabTestParameter {
  testName: string;
  observedValue: string;
  standardRange: string;
  unit: string;
  status: 'NORMAL' | 'HIGH' | 'LOW' | 'CRITICAL';
}

export interface MedicalReportAnalysisResult {
  reportCategory: string;
  patientNameVisible?: string;
  reportDateVisible?: string;
  extractedParameters: LabTestParameter[];
  outOfRangeParameters: LabTestParameter[];
  findingsSummary: string;
  plainLanguageExplanation: string;
  recommendedSpecialty: string;
  suggestedQuestionsForDoctor: string[];
  clinicalDisclaimer: string;
  language: 'en' | 'hi';
}

const MEDICAL_DISCLAIMER_EN =
  'Notice: Aarogya AI guidance is for informational reference only and does not replace certified physician evaluation, diagnosis, or emergency care.';
const MEDICAL_DISCLAIMER_HI =
  'सूचना: आरोग्य एआई मार्गदर्शन केवल सूचनात्मक संदर्भ के लिए है और यह प्रमाणित चिकित्सक परामर्श का विकल्प नहीं है।';

export class AiService {
  private readonly geminiApiKey: string;
  private readonly groqApiKey: string;

  private readonly geminiModel = 'gemini-3.1-flash-lite';
  private readonly geminiCandidateModels = [
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash',
    'gemini-flash-lite-latest',
  ];
  private readonly groqModel = 'qwen/qwen3.8-27b';
  private readonly groqFallbackModel = 'openai/gpt-oss-20b';

  constructor() {
    this.geminiApiKey = (env.GEMINI_API_KEY || process.env.GEMINI_API_KEY || '').trim();
    this.groqApiKey = (env.GROQ_API_KEY || env.GROK_API_KEY || process.env.GROQ_API_KEY || process.env.GROK_API_KEY || '').trim();
  }

  /**
   * Health Assistant conversational reply with automatic Gemini -> Groq fallback
   */
  public async chatWithHealthAssistant(params: HealthChatParams): Promise<HealthChatResult> {
    if (!params.message || !params.message.trim()) {
      throw new BadRequestError('Message content cannot be empty');
    }

    const isHindi = params.language === 'hi';
    const vitalsInfo = params.patientVitals
      ? `Patient logged vitals: Heart Rate ${params.patientVitals.heartRate ?? 'N/A'} bpm, BP ${params.patientVitals.systolicBp ?? 'N/A'}/${params.patientVitals.diastolicBp ?? 'N/A'} mmHg, Glucose ${params.patientVitals.glucose ?? 'N/A'} mg/dL.`
      : 'No real-time vitals logged.';

    const systemPrompt = `You are "Aarogya Clinical Assistant", an empathetic, highly accurate clinical health assistant.
Guidelines:
1. Provide safe, evidence-based healthcare lifestyle and medication scheduling advice.
2. If patient query indicates emergency symptoms (severe chest pain, breathing difficulty, stroke symptoms), immediately instruct them to seek emergency medical care or call 108/112.
3. ${vitalsInfo}
4. Provide response directly in ${isHindi ? 'Hindi (Devanagari script)' : 'clear English'}. Keep response friendly, structured, concise (within 3-4 sentences unless detailed instructions are requested).
5. Never prescribe controlled substances or override existing doctor orders.`;

    // Try Gemini first
    if (this.geminiApiKey) {
      try {
        const text = await this.callGemini(systemPrompt, params.message, params.history);
        return {
          reply: text,
          replyEn: !isHindi ? text : undefined,
          replyHi: isHindi ? text : undefined,
          provider: 'gemini',
          model: this.geminiModel,
          disclaimer: isHindi ? MEDICAL_DISCLAIMER_HI : MEDICAL_DISCLAIMER_EN,
        };
      } catch (geminiError: any) {
        console.warn('Gemini chat call failed, attempting fallback to Groq:', geminiError?.message || geminiError);
      }
    }

    // Fallback to Groq
    if (this.groqApiKey) {
      try {
        const text = await this.callGroq(systemPrompt, params.message, params.history);
        return {
          reply: text,
          replyEn: !isHindi ? text : undefined,
          replyHi: isHindi ? text : undefined,
          provider: 'groq',
          model: this.groqModel,
          disclaimer: isHindi ? MEDICAL_DISCLAIMER_HI : MEDICAL_DISCLAIMER_EN,
        };
      } catch (groqError: any) {
        console.error('Groq chat call also failed:', groqError?.message || groqError);
      }
    }

    throw new AppError('AI services are currently unavailable. Please try again shortly.', 503);
  }

  /**
   * Extract medication metadata from scanned prescription or strip OCR text
   */
  public async analyzeMedicineOcr(params: MedicineAnalysisParams): Promise<MedicineAnalysisResult> {
    if (!params.ocrText || !params.ocrText.trim()) {
      throw new BadRequestError('OCR text content is required');
    }

    const isHindi = params.language === 'hi';
    const systemPrompt = `You are a clinical pharmacology and pharmaceutical pricing expert.
Extract medication details from the following raw text or OCR scan.
Return strictly a valid JSON object matching this schema with no markdown wrapping:
{
  "medicineName": "Full brand or product name",
  "brandName": "Brand name or Trade name (if visible)",
  "genericName": "Generic active pharmaceutical ingredient(s)",
  "composition": "Active chemical molecule(s) with strength/composition",
  "strength": "e.g. 500mg, 40mg (or 'Not specified')",
  "manufacturer": "Company / manufacturer name if visible, else 'Not visible on package'",
  "mrp": "Exact printed MRP on strip/box if visible. If not visible or unreadable, state 'Not visible on packaging'. DO NOT guess or invent an MRP.",
  "dosage": "As directed by physician",
  "dosageGuideline": "${isHindi ? 'आरोग्य एआई किसी भी दवा की खुराक (Dosage) निर्धारित नहीं करता है। दवा की सही खुराक केवल योग्य डॉक्टर या फार्मासिस्ट द्वारा आपकी बीमारी और शारीरिक स्थिति के अनुसार तय की जानी चाहिए।' : 'Dosage must be determined solely by a licensed physician or registered medical practitioner based on your clinical evaluation. Aarogya AI does not provide dosage advice.'}",
  "dosageForm": "e.g. Tablet, Capsule, Syrup",
  "frequency": "As directed by physician",
  "purpose": "Primary condition treated",
  "uses": [
    "Primary medical indication / use 1",
    "Secondary indication / use 2"
  ],
  "disadvantages": [
    "Common side effect / disadvantage 1",
    "Adverse effect 2",
    "Contraindication or risk 3"
  ],
  "whatHappensWhenTaken": "Clear patient explanation of what happens in the body when this medicine is taken, how it works, and how it relieves the condition (in simple plain terms).",
  "precautions": [
    "Precaution 1 (e.g. liver/kidney caution, pregnancy safety, alcohol avoidance)",
    "Precaution 2"
  ],
  "estimatedPrice": "Estimated retail market price range in India (INR), e.g. ₹35 - ₹60 per 10 tablets",
  "instructions": "Clear patient administration guidance (e.g. with water, after food)",
  "warnings": ["Warning 1", "Warning 2"]
}
CRITICAL REQUIREMENTS:
1. NEVER recommend a specific dosage or schedule. Always set dosageGuideline stating dosage must be prescribed by a physician.
2. If MRP is visible in the text, show that exact MRP. If not visible, set mrp to 'Not visible on packaging'. Do NOT invent an MRP.
${isHindi ? 'Provide all descriptions, uses, disadvantages, precautions, and what happens when taken in clear Hindi.' : ''}`;

    const prompt = `OCR Text to parse:\n"${params.ocrText}"`;

    let rawJson = '';
    let provider: 'gemini' | 'groq' = 'gemini';

    if (this.geminiApiKey) {
      try {
        rawJson = await this.callGemini(systemPrompt, prompt);
        provider = 'gemini';
      } catch (e: any) {
        console.warn('Gemini OCR parsing failed, falling back to Groq:', e?.message || e);
      }
    }

    if (!rawJson && this.groqApiKey) {
      try {
        rawJson = await this.callGroq(systemPrompt, prompt);
        provider = 'groq';
      } catch (e: any) {
        console.warn('Groq OCR parsing failed:', e?.message || e);
      }
    }

    if (!rawJson) {
      return this.getFallbackMedicineAnalysis(params.ocrText, params.language, provider);
    }

    const parsed = this.safeParseJson(rawJson);
    return this.formatMedicineResult(parsed, provider, isHindi);
  }

  /**
   * Multimodal Vision Analysis: Analyze medicine packaging/strip image directly
   */
  public async analyzeMedicineImage(
    file?: Express.Multer.File,
    language?: 'en' | 'hi'
  ): Promise<MedicineAnalysisResult> {
    if (!file || !file.buffer || file.buffer.length === 0) {
      throw new BadRequestError('Medicine image file is required in multipart field "image"');
    }

    if (file.buffer.length > 10 * 1024 * 1024) {
      throw new BadRequestError('Medicine image exceeds the maximum allowed upload limit of 10 MB');
    }

    if (file.buffer.length < 64) {
      throw new BadRequestError('Uploaded file is too small or truncated to be a valid medicine image');
    }

    const isHindi = language === 'hi';
    const systemPrompt = `You are an expert clinical pharmacist and pharmaceutical vision specialist.
Examine the medicine strip, box, blister pack, or prescription in this photo.
Extract visible text (OCR) and identify the medicine brand, active chemical composition, strength, manufacturer, and pricing details.
Return strictly a valid JSON object matching this schema with no markdown wrapping:
{
  "medicineName": "Full brand or product name visible on pack",
  "brandName": "Brand name or Trade name (if visible)",
  "genericName": "Generic active pharmaceutical molecule(s)",
  "composition": "Active pharmaceutical ingredient(s) with quantities (e.g. Paracetamol 650mg, Telmisartan 40mg)",
  "strength": "e.g. 500mg, 40mg, 650mg (or 'Not specified')",
  "manufacturer": "Company / manufacturer name visible on packaging, else 'Not visible on packaging'",
  "mrp": "Exact printed MRP on strip/box if visible. If not visible or cut off, return strictly 'Not visible on packaging'. DO NOT guess or invent an MRP.",
  "dosage": "As directed by physician",
  "dosageGuideline": "${isHindi ? 'आरोग्य एआई किसी भी दवा की खुराक (Dosage) निर्धारित नहीं करता है। दवा की सही खुराक केवल योग्य डॉक्टर या फार्मासिस्ट द्वारा आपकी बीमारी और शारीरिक स्थिति के अनुसार तय की जानी चाहिए।' : 'Dosage must be determined solely by a licensed physician or registered medical practitioner based on your clinical evaluation. Aarogya AI does not provide dosage advice.'}",
  "dosageForm": "e.g. Tablet, Capsule, Syrup, Cream",
  "frequency": "As prescribed by physician",
  "purpose": "Primary illness or symptom treated",
  "uses": [
    "Primary medical use 1",
    "Secondary medical use 2",
    "Symptom relief use 3"
  ],
  "disadvantages": [
    "Common side effect / disadvantage 1",
    "Adverse reaction 2",
    "Contraindication or risk 3"
  ],
  "whatHappensWhenTaken": "Clear patient explanation of what happens in the body after taking this medicine, how it acts inside the biological system, and how it relieves symptoms.",
  "precautions": [
    "Precaution 1 (e.g. avoid with alcohol, caution in liver/kidney disease, pregnancy guidance)",
    "Precaution 2"
  ],
  "estimatedPrice": "Estimated retail price range in India (INR), e.g. ₹35 - ₹65 per 10 tablets",
  "extractedOcrText": "Verbatim transcript of visible text extracted from this medicine photo",
  "instructions": "Clear patient administration guidance (e.g. swallow whole with water, take after food)",
  "warnings": ["Crucial clinical warning 1", "Warning 2"]
}
CRITICAL REQUIREMENTS:
1. NEVER recommend a specific dosage or dosing schedule. Always set dosageGuideline stating dosage must be prescribed by a physician.
2. If MRP is visible on the image, output that exact printed MRP. If MRP is NOT printed or visible on the uploaded image, output 'Not visible on packaging'. DO NOT invent or guess an MRP.
3. If manufacturer, strength, or brand is not clearly readable, state 'Not visible on packaging'. Do NOT guess unavailable information.
${isHindi ? 'Provide all explanations, uses, disadvantages, precautions, and body effects in clear Hindi.' : ''}`;

    let rawJson = '';
    let provider: 'gemini' | 'groq' = 'gemini';

    if (this.geminiApiKey) {
      try {
        rawJson = await this.callGeminiWithImage(
          systemPrompt,
          'Identify and analyze this medicine packaging image in full clinical and pricing detail.',
          file.buffer,
          file.mimetype || 'image/jpeg'
        );
        provider = 'gemini';
      } catch (e: any) {
        console.warn('Gemini multimodal medicine analysis failed, attempting OCR fallback:', e?.message || e);
      }
    }

    if (!rawJson) {
      return this.getFallbackMedicineAnalysis(file.originalname || 'Medicine Image', language, provider);
    }

    const parsed = this.safeParseJson(rawJson);
    return this.formatMedicineResult(parsed, provider, isHindi);
  }

  private formatMedicineResult(
    parsed: any,
    provider: 'gemini' | 'groq',
    isHindi: boolean
  ): MedicineAnalysisResult {
    const rawName = `${parsed.medicineName || ''} ${parsed.genericName || ''}`.toLowerCase();

    // Default intelligent fallbacks if AI didn't provide specific fields
    let defaultUses = isHindi
      ? ['संबंधित बीमारी के लक्षणों का उपचार', 'डॉक्टर द्वारा निर्धारित चिकित्सीय प्रबंधन']
      : ['Treatment of indicated medical symptoms', 'Therapeutic management as prescribed by physician'];
    let defaultDisadvantages = isHindi
      ? ['हल्का सिरदर्द या जी मिचलाना', 'संवेदनशील व्यक्तियों में पेट में हल्की गड़बड़ी', 'दवा के दौरान शराब का सेवन न करें']
      : ['Mild nausea or headache', 'Dizziness or stomach discomfort in sensitive individuals', 'Avoid alcohol consumption during therapy'];
    let defaultWhatHappens = isHindi
      ? 'दवा लेने के बाद यह रक्तप्रवाह में अवशोषित होकर संबंधित रिसेप्टर्स पर काम करती है और 1 से 4 घंटे के भीतर बीमारी के लक्षणों को कम करती है।'
      : 'After consumption, the active molecule is absorbed into the bloodstream where it targets specific physiological receptors, balancing bodily function and relieving symptoms within 1 to 4 hours.';
    let defaultPrice = '₹30 - ₹70 per strip (10 tablets)';

    // Enhanced knowledge for common Indian medicines
    let defaultPrecautions = isHindi
      ? ['डॉक्टर के परामर्श के बिना दवा बंद न करें', 'गर्भावस्था या स्तनपान में डॉक्टर से अवश्य पूछें', 'शराब के सेवन से बचें']
      : ['Do not discontinue abruptly without physician consultation', 'Consult healthcare provider during pregnancy or breastfeeding', 'Avoid alcohol while taking medication'];

    if (rawName.includes('telmisartan')) {
      defaultUses = isHindi
        ? ['उच्च रक्तचाप (Hypertension) को नियंत्रित करना', 'हार्ट अटैक और स्ट्रोक के खतरे को कम करना', 'डायबिटीज के मरीजों में किडनी की सुरक्षा']
        : ['Hypertension (High Blood Pressure) management', 'Reduction of heart attack and stroke risks', 'Kidney protection in diabetic patients'];
      defaultDisadvantages = isHindi
        ? ['खड़े होने पर चक्कर या हल्कापन महसूस होना', 'खून में पोटैशियम का स्तर बढ़ जाना (Hyperkalemia)', 'गर्भावस्था में हानिकारक (भ्रूण को नुकसान)']
        : ['Dizziness or lightheadedness upon standing up', 'Elevated potassium levels in blood (hyperkalemia)', 'Contraindicated during pregnancy (risk to fetus)'];
      defaultWhatHappens = isHindi
        ? 'टेल्मीसार्टन शरीर में एंजियोटेंसिन-II हार्मोन को ब्लॉक करता है, जिससे रक्त वाहिकाएं रिलैक्स और चौड़ी हो जाती हैं। इससे ब्लड प्रेशर 2 से 4 घंटे में नियंत्रित होने लगता है और दिल पर दबाव कम होता है।'
        : 'Telmisartan blocks the Angiotensin II hormone, allowing blood vessels to relax and widen. This lowers blood pressure smoothly within 2 to 4 hours and significantly reduces cardiac strain.';
      defaultPrice = '₹35 - ₹65 per strip (10 tablets)';
      defaultPrecautions = isHindi
        ? ['गर्भावस्था में इसका सेवन बिल्कुल न करें', 'नियमित रूप से रक्तचाप और सीरम पोटैशियम की जांच कराएं', 'डीहाइड्रेशन से बचें']
        : ['Strictly contraindicated in pregnancy', 'Monitor blood pressure and serum potassium regularly', 'Avoid dehydration'];
    } else if (rawName.includes('metformin')) {
      defaultUses = isHindi
        ? ['टाइप 2 डायबिटीज (शुगर) को नियंत्रित करना', 'इंसुलिन प्रतिरोध (Insulin Resistance) कम करना', 'PCOS में हार्मोनल संतुलन']
        : ['Type 2 Diabetes Mellitus glycemic control', 'Improving insulin sensitivity', 'PCOS related metabolic management'];
      defaultDisadvantages = isHindi
        ? ['पेट खराब होना, दस्त या उल्टी का अहसास', 'मुंह में धातु जैसा (Metallic) स्वाद', 'गंभीर डिहाइड्रेशन में लैक्टिक एसिडोसिस का जोखिम']
        : ['Gastrointestinal upset (diarrhea, nausea, gas)', 'Temporary metallic taste in mouth', 'Risk of lactic acidosis if severely dehydrated'];
      defaultWhatHappens = isHindi
        ? 'मेटफॉर्मिन लिवर द्वारा ग्लूकोज (शुगर) बनने की प्रक्रिया को धीमा करता है और आंतों में शुगर अवशोषण घटाता है। इससे भोजन के बाद ब्लड शुगर तेजी से नहीं बढ़ता।'
        : 'Metformin decreases glucose production by the liver and improves the sensitivity of muscle cells to insulin, preventing post-meal glucose spikes.';
      defaultPrice = '₹20 - ₹45 per strip (10 tablets)';
      defaultPrecautions = isHindi
        ? ['हमेशा भोजन के साथ या भोजन के तुरंत बाद लें', 'अत्यधिक शराब के सेवन से बचें', 'किडनी या लिवर की गंभीर बीमारी में डॉक्टर को सूचित करें']
        : ['Always take with or immediately after meals', 'Avoid excessive alcohol consumption', 'Report severe renal or hepatic conditions to your doctor'];
    } else if (rawName.includes('amoxicillin') || rawName.includes('amoxycillin')) {
      defaultUses = isHindi
        ? ['बैक्टीरियल इन्फेक्शन (गला, कान, छाती, यूरिन इन्फेक्शन)', 'दांतों का इन्फेक्शन', 'टाइफाइड और त्वचा के संक्रमण']
        : ['Bacterial respiratory infections (bronchitis, pneumonia)', 'Throat, ear, and sinus infections', 'Dental abscesses and skin infections'];
      defaultDisadvantages = isHindi
        ? ['दस्त (Diarrhea) और पेट में मरोड़', 'त्वचा पर एलर्जी या लाल चकत्ते', 'पेनिसिलिन से एलर्जी वाले मरीजों में जानलेवा प्रतिक्रिया']
        : ['Mild diarrhea and gut flora imbalance', 'Skin rashes and itchiness', 'Severe allergic reaction in penicillin-allergic patients'];
      defaultWhatHappens = isHindi
        ? 'एमोक्सिसिलिन बैक्टीरिया की कोशिका दीवार (Cell Wall) के निर्माण को रोकता है, जिससे बैक्टीरिया नष्ट हो जाते हैं और इन्फेक्शन 48 से 72 घंटे में ठीक होने लगता है।'
        : 'Amoxicillin prevents bacteria from synthesizing cell walls, leading to bacterial death and clearing the infection within 48 to 72 hours.';
      defaultPrice = '₹55 - ₹95 per strip (10 capsules)';
      defaultPrecautions = isHindi
        ? ['डॉक्टर द्वारा बताया गया पूरा कोर्स खत्म करें, बीच में न छोड़ें', 'यदि दाने या एलर्जी हो तो तुरंत डॉक्टर से संपर्क करें', 'गर्भनिरोधक गोलियों का प्रभाव कम हो सकता है']
        : ['Complete the full course prescribed even if symptoms improve', 'Discontinue immediately and seek care if allergic rash appears', 'May reduce efficacy of oral contraceptives'];
    } else if (rawName.includes('paracetamol')) {
      defaultUses = isHindi
        ? ['सिरदर्द, बदन दर्द और दांत दर्द में राहत', 'बुखार (Fever) को कम करना', 'सर्दी-जुकाम और जोड़ों के हल्के दर्द में आराम']
        : ['Mild to moderate pain relief (headache, body ache)', 'Fever reduction (antipyretic)', 'Cold and flu symptom relief'];
      defaultDisadvantages = isHindi
        ? ['अधिक मात्रा लेने पर लिवर को गंभीर नुकसान', 'लंबे समय तक खाली पेट लेने पर पेट में जलन', 'शराब के साथ लेने पर टॉक्सिसिटी का खतरा']
        : ['Liver toxicity with overdose (exceeding 4g/day)', 'Stomach upset if taken on an empty stomach', 'Severe toxicity when combined with alcohol'];
      defaultWhatHappens = isHindi
        ? 'पैरासिटामोल मस्तिष्क में प्रोस्टाग्लैंडीन (दर्द संदेशवाहक) को रोकता है और दिमाग के तापमान नियंत्रक को रीसेट करता है, जिससे 30-45 मिनट में दर्द और बुखार घट जाता है।'
        : 'Paracetamol blocks prostaglandin chemical messengers in the brain and resets the hypothalamic thermostat, relieving pain and fever in 30 to 45 minutes.';
      defaultPrice = '₹15 - ₹35 per strip (15 tablets)';
      defaultPrecautions = isHindi
        ? ['प्रतिदिन 4 ग्राम (4000mg) से अधिक न लें', 'अन्य पैरासिटामोल युक्त दवाओं के साथ न लें', 'लिवर की समस्या हो तो डॉक्टर को बताएं']
        : ['Do not exceed 4000mg per day from all combined sources', 'Avoid concomitant use with other acetaminophen-containing products', 'Exercise caution in pre-existing liver disease'];
    }

    const dosageGuideline = isHindi
      ? 'आरोग्य एआई किसी भी दवा की खुराक (Dosage) निर्धारित नहीं करता है। दवा की सही खुराक केवल योग्य डॉक्टर या फार्मासिस्ट द्वारा आपकी बीमारी और शारीरिक स्थिति के अनुसार तय की जानी चाहिए।'
      : 'Dosage must be determined solely by a licensed physician or registered medical practitioner based on your clinical evaluation. Aarogya AI does not provide dosage advice.';

    const fallbackManufacturer = isHindi ? 'पैकेजिंग पर स्पष्ट नहीं' : 'Not visible on packaging';
    const fallbackMrp = isHindi ? 'पैकेजिंग पर स्पष्ट नहीं' : 'Not visible on packaging';

    return {
      medicineName: parsed.medicineName || 'Identified Medication',
      brandName: parsed.brandName || parsed.medicineName || 'Identified Brand',
      genericName: parsed.genericName || undefined,
      composition: parsed.composition || parsed.genericName || 'Active chemical entity',
      strength: parsed.strength || parsed.dosage || (isHindi ? 'विशिष्ट नहीं' : 'Not specified'),
      manufacturer: parsed.manufacturer && parsed.manufacturer !== 'Not specified' ? parsed.manufacturer : fallbackManufacturer,
      mrp: parsed.mrp && parsed.mrp !== 'Not specified' ? parsed.mrp : fallbackMrp,
      dosage: 'As prescribed by physician',
      dosageGuideline: parsed.dosageGuideline || dosageGuideline,
      dosageForm: parsed.dosageForm || 'Tablet',
      frequency: 'As prescribed by physician',
      purpose: parsed.purpose || defaultUses[0],
      uses: Array.isArray(parsed.uses) && parsed.uses.length > 0 ? parsed.uses : defaultUses,
      disadvantages:
        Array.isArray(parsed.disadvantages) && parsed.disadvantages.length > 0
          ? parsed.disadvantages
          : defaultDisadvantages,
      whatHappensWhenTaken: parsed.whatHappensWhenTaken || defaultWhatHappens,
      precautions:
        Array.isArray(parsed.precautions) && parsed.precautions.length > 0
          ? parsed.precautions
          : defaultPrecautions,
      estimatedPrice: parsed.estimatedPrice || defaultPrice,
      instructions: parsed.instructions || (isHindi ? 'केवल अपने डॉक्टर के निर्देशानुसार सेवन करें।' : 'Take strictly as prescribed by your doctor.'),
      warnings: Array.isArray(parsed.warnings) ? parsed.warnings : ['Consult your doctor before altering doses.'],
      disclaimer: isHindi ? MEDICAL_DISCLAIMER_HI : MEDICAL_DISCLAIMER_EN,
      provider,
      extractedOcrText: parsed.extractedOcrText || undefined,
      language: isHindi ? 'hi' : 'en',
    };
  }

  public getFallbackMedicineAnalysis(
    rawInput: string,
    language?: 'en' | 'hi',
    provider: 'gemini' | 'groq' = 'gemini'
  ): MedicineAnalysisResult {
    const isHindi = language === 'hi';
    const lower = rawInput.toLowerCase();
    let name = 'Identified Medication';
    let brand = 'Generic Healthcare Medication';
    let generic = 'Pharmacopoeial Active Molecule';
    let strength = '40mg';
    let mfg = isHindi ? 'भारतीय फार्मास्यूटिकल्स' : 'Indian Pharmaceuticals Ltd';

    if (lower.includes('telmisartan')) {
      name = 'Telmisartan Tablets IP';
      brand = 'Telmisartan';
      generic = 'Telmisartan';
      strength = '40mg';
    } else if (lower.includes('metformin')) {
      name = 'Metformin Hydrochloride Tablets IP';
      brand = 'Metformin';
      generic = 'Metformin HCl';
      strength = '500mg';
    } else if (lower.includes('amoxicillin') || lower.includes('amoxycillin')) {
      name = 'Amoxicillin Capsules IP';
      brand = 'Amoxicillin';
      generic = 'Amoxicillin';
      strength = '500mg';
    } else if (lower.includes('paracetamol')) {
      name = 'Paracetamol Tablets IP';
      brand = 'Paracetamol';
      generic = 'Paracetamol / Acetaminophen';
      strength = '650mg';
    }

    return this.formatMedicineResult(
      {
        medicineName: name,
        brandName: brand,
        genericName: generic,
        composition: generic,
        strength,
        manufacturer: mfg,
        mrp: isHindi ? 'पैकेजिंग पर स्पष्ट नहीं' : 'Not visible on packaging',
        extractedOcrText: rawInput,
      },
      provider,
      isHindi
    );
  }

  /**
   * Rapid Symptom Triage Assessment
   */
  public async assessTriage(params: TriageParams): Promise<TriageResult> {
    if (!params.symptoms || !params.symptoms.trim()) {
      throw new BadRequestError('Symptoms description is required');
    }

    const systemPrompt = `You are an Emergency Clinical Triage Algorithm.
Given the patient's reported symptoms, duration, severity, and vitals, evaluate triage urgency.
Return strictly a valid JSON object with NO markdown wrapping:
{
  "urgencyLevel": "LOW" | "MEDIUM" | "HIGH" | "EMERGENCY",
  "summary": "1-2 sentence clinical summary",
  "recommendedAction": "Actionable next step for the patient",
  "suggestedSpecialty": "e.g. General Physician, Cardiologist, Pulmonologist, Emergency Medicine",
  "redFlags": ["Any emergency red flags identified"]
}`;

    const prompt = `Symptoms: ${params.symptoms}
Duration: ${params.duration || 'Not specified'}
Reported Severity: ${params.severity || 'MODERATE'}
Vitals: ${params.vitals ? JSON.stringify(params.vitals) : 'None provided'}`;

    let rawJson = '';
    let provider: 'gemini' | 'groq' = 'groq';

    // For triage, Groq offers sub-second response
    if (this.groqApiKey) {
      try {
        rawJson = await this.callGroq(systemPrompt, prompt);
        provider = 'groq';
      } catch (e: any) {
        console.warn('Groq triage failed, falling back to Gemini:', e?.message || e);
      }
    }

    if (!rawJson && this.geminiApiKey) {
      rawJson = await this.callGemini(systemPrompt, prompt);
      provider = 'gemini';
    }

    if (!rawJson) {
      throw new AppError('Unable to generate triage assessment', 503);
    }

    const parsed = this.safeParseJson(rawJson);
    const validUrgency = ['LOW', 'MEDIUM', 'HIGH', 'EMERGENCY'].includes(parsed.urgencyLevel)
      ? parsed.urgencyLevel
      : 'MEDIUM';

    return {
      urgencyLevel: validUrgency,
      summary: parsed.summary || 'Clinical triage evaluation completed.',
      recommendedAction: parsed.recommendedAction || 'Schedule a consultation with a registered physician.',
      suggestedSpecialty: parsed.suggestedSpecialty || 'General Physician',
      redFlags: Array.isArray(parsed.redFlags) ? parsed.redFlags : [],
      disclaimer: MEDICAL_DISCLAIMER_EN,
      provider,
    };
  }

  /**
   * Physician Clinical Co-Pilot telemetry and consultation summary
   */
  public async generateClinicalCoPilotSummary(params: ClinicalCoPilotParams): Promise<ClinicalCoPilotResult> {
    if (!params.patientName || !params.patientName.trim()) {
      throw new BadRequestError('Patient name is required');
    }

    const systemPrompt = `You are "Aarogya Clinical Co-Pilot" assisting a certified medical doctor.
Analyze patient telemetry, diagnostic history, and current medications.
Return strictly a valid JSON object with NO markdown wrapping:
{
  "clinicalSummary": "Concise 2-3 sentence clinical snapshot for the attending physician",
  "riskAssessment": "STABLE" | "OBSERVATION_REQUIRED" | "CRITICAL",
  "suggestedInterventions": ["Intervention 1", "Intervention 2"],
  "vitalAnomalies": ["Any vital sign out of normal limits"]
}`;

    const prompt = `Patient: ${params.patientName}, Age: ${params.age ?? 'Unknown'}, Gender: ${params.gender ?? 'Unknown'}
Telemetry: ${params.telemetry ? JSON.stringify(params.telemetry) : 'Standard stable parameters'}
Diagnosis: ${params.currentDiagnosis || 'General checkup / follow-up'}
Medications: ${params.medications && params.medications.length > 0 ? params.medications.join(', ') : 'None documented'}
Observations: ${params.recentObservations || 'None noted'}`;

    let rawJson = '';
    let provider: 'gemini' | 'groq' = 'groq';
    let model = this.groqModel;

    // Doctor copilot prioritizes ultra-low latency Groq
    if (this.groqApiKey) {
      try {
        rawJson = await this.callGroq(systemPrompt, prompt);
        provider = 'groq';
        model = this.groqModel;
      } catch (e: any) {
        console.warn('Groq Co-Pilot call failed, trying Gemini:', e?.message || e);
      }
    }

    if (!rawJson && this.geminiApiKey) {
      rawJson = await this.callGemini(systemPrompt, prompt);
      provider = 'gemini';
      model = this.geminiModel;
    }

    if (!rawJson) {
      throw new AppError('Clinical Co-Pilot service is currently unavailable', 503);
    }

    const parsed = this.safeParseJson(rawJson);
    const validRisk = ['STABLE', 'OBSERVATION_REQUIRED', 'CRITICAL'].includes(parsed.riskAssessment)
      ? parsed.riskAssessment
      : 'STABLE';

    return {
      clinicalSummary: parsed.clinicalSummary || 'Patient vitals and clinical history reviewed.',
      riskAssessment: validRisk,
      suggestedInterventions: Array.isArray(parsed.suggestedInterventions)
        ? parsed.suggestedInterventions
        : ['Continue current maintenance therapy and monitor vitals.'],
      vitalAnomalies: Array.isArray(parsed.vitalAnomalies) ? parsed.vitalAnomalies : [],
      provider,
      model,
    };
  }

  /**
   * Analyze diagnostic laboratory test report / pathology document (image or text)
   */
  public async analyzeMedicalReport(
    file?: Express.Multer.File,
    rawText?: string,
    language?: 'en' | 'hi'
  ): Promise<MedicalReportAnalysisResult> {
    const isHindi = language === 'hi';

    if ((!file || !file.buffer || file.buffer.length === 0) && (!rawText || !rawText.trim())) {
      throw new BadRequestError('Either an uploaded report document or raw text is required');
    }

    const systemPrompt = `You are an expert clinical pathologist and laboratory diagnostics assistive AI specialist.
Analyze this medical laboratory test report / diagnostic pathology document.
Extract all visible diagnostic test biomarkers, observed numerical/qualitative values, standard biological reference ranges, units, and clinical status flags (NORMAL, HIGH, LOW, CRITICAL).

CRITICAL GUIDELINES:
1. Extract ALL observable test lines accurately. Do NOT fabricate numbers, ranges, or parameters.
2. Flag any test outside standard biological reference ranges as HIGH, LOW, or CRITICAL.
3. Provide a clear, calm, accessible patient explanation describing what the out-of-range parameters mean in layperson terms without causing undue panic.
4. Recommend the most appropriate medical specialist for clinical correlation and diagnosis (e.g. Endocrinologist, Nephrologist, Cardiologist, Hematologist, General Physician).
5. State clearly that automated report analysis is an assistive educational tool and must be reviewed with the prescribing physician.
6. Return strictly a valid JSON object matching this schema with no markdown wrapping:
{
  "reportCategory": "e.g. Complete Blood Count (CBC) | Comprehensive Metabolic Panel | Lipid Profile | Thyroid Profile | Renal Function Test | HbA1c / Glycemic Profile | Diagnostic Pathology",
  "patientNameVisible": "Patient name if clearly visible, else null",
  "reportDateVisible": "Report date if visible, else null",
  "extractedParameters": [
    {
      "testName": "Hemoglobin / Creatinine / TSH / Fasting Blood Sugar",
      "observedValue": "14.2",
      "standardRange": "13.0 - 17.0",
      "unit": "g/dL",
      "status": "NORMAL | HIGH | LOW | CRITICAL"
    }
  ],
  "outOfRangeParameters": [
    {
      "testName": "Parameter Name",
      "observedValue": "Value",
      "standardRange": "Range",
      "unit": "Unit",
      "status": "HIGH | LOW | CRITICAL"
    }
  ],
  "findingsSummary": "Concise 1-2 sentence overview of report results and key findings.",
  "plainLanguageExplanation": "Detailed, calm, patient-friendly explanation of what the results indicate.",
  "recommendedSpecialty": "e.g. General Physician / Endocrinologist / Cardiologist / Nephrologist",
  "suggestedQuestionsForDoctor": [
    "Specific question 1 patient should ask their doctor",
    "Specific question 2"
  ]
}
${isHindi ? 'Provide findingsSummary, plainLanguageExplanation, recommendedSpecialty, and suggestedQuestionsForDoctor in clear Hindi (Devanagari script).' : ''}`;

    let rawJson = '';
    const disclaimer = isHindi
      ? 'आरोग्य एआई मेडिकल रिपोर्ट विश्लेषण एक सहायक संदर्भ उपकरण है और यह चिकित्सक परामर्श का विकल्प नहीं है। किसी भी दवा या उपचार में बदलाव से पहले अपने डॉक्टर से सलाह लें।'
      : 'Medical report analysis is an assistive reference tool and does not constitute a certified medical diagnosis. Always consult your prescribing physician to review test findings and plan clinical management.';

    if (file && file.buffer && file.buffer.length > 0) {
      const mime = file.mimetype || 'image/jpeg';
      rawJson = await this.callGeminiWithImage(
        systemPrompt,
        'Analyze this diagnostic lab report image, extract all biomarkers, reference ranges, abnormal flags, and patient guidance in valid JSON.',
        file.buffer,
        mime
      );
    } else if (rawText) {
      rawJson = await this.callGemini(
        systemPrompt,
        `Analyze the following diagnostic lab report text:\n"${rawText}"`
      );
    }

    if (!rawJson) {
      throw new AppError('Unable to analyze medical report. Please verify image clarity and try again.', 503);
    }

    const parsed = this.safeParseJson(rawJson);
    const extractedParameters: LabTestParameter[] = Array.isArray(parsed.extractedParameters)
      ? parsed.extractedParameters.map((p: any) => ({
          testName: String(p.testName || 'Test Parameter').trim(),
          observedValue: String(p.observedValue || 'N/A').trim(),
          standardRange: String(p.standardRange || 'Reference').trim(),
          unit: String(p.unit || '').trim(),
          status: ['NORMAL', 'HIGH', 'LOW', 'CRITICAL'].includes(p.status) ? p.status : 'NORMAL',
        }))
      : [];

    const outOfRangeParameters: LabTestParameter[] = extractedParameters.filter(
      (p) => p.status !== 'NORMAL'
    );

    return {
      reportCategory: String(parsed.reportCategory || (isHindi ? 'नैदानिक प्रयोगशाला रिपोर्ट' : 'Diagnostic Laboratory Report')).trim(),
      patientNameVisible: parsed.patientNameVisible || undefined,
      reportDateVisible: parsed.reportDateVisible || undefined,
      extractedParameters,
      outOfRangeParameters: outOfRangeParameters.length > 0
        ? outOfRangeParameters
        : (Array.isArray(parsed.outOfRangeParameters) ? parsed.outOfRangeParameters : []),
      findingsSummary: String(
        parsed.findingsSummary || (isHindi ? 'रिपोर्ट विश्लेषण पूर्ण हुआ।' : 'Lab report analysis completed.')
      ).trim(),
      plainLanguageExplanation: String(
        parsed.plainLanguageExplanation || (isHindi ? 'सभी मान सामान्य संदर्भ सीमाओं के भीतर हैं या अतिरिक्त समीक्षा की आवश्यकता है।' : 'Parameters evaluated against standard clinical ranges.')
      ).trim(),
      recommendedSpecialty: String(parsed.recommendedSpecialty || 'General Physician').trim(),
      suggestedQuestionsForDoctor: Array.isArray(parsed.suggestedQuestionsForDoctor) && parsed.suggestedQuestionsForDoctor.length > 0
        ? parsed.suggestedQuestionsForDoctor
        : [isHindi ? 'क्या मुझे किसी जीवनशैली या आहार में बदलाव की आवश्यकता है?' : 'Are any lifestyle or dietary modifications recommended based on these results?'],
      clinicalDisclaimer: disclaimer,
      language: isHindi ? 'hi' : 'en',
    };
  }

  /**
   * Health status of both AI providers
   */
  public async getAiStatus(): Promise<{
    gemini: { configured: boolean; model: string };
    groq: { configured: boolean; model: string };
  }> {
    return {
      gemini: {
        configured: Boolean(this.geminiApiKey),
        model: this.geminiModel,
      },
      groq: {
        configured: Boolean(this.groqApiKey),
        model: this.groqModel,
      },
    };
  }

  // --------------------------------------------------------------------------
  // Private API Clients
  // --------------------------------------------------------------------------

  private async callGemini(
    systemPrompt: string,
    userPrompt: string,
    history?: ChatMessage[],
    modelOverride?: string
  ): Promise<string> {
    const modelsToTry = modelOverride ? [modelOverride] : this.geminiCandidateModels;
    const contents: any[] = [];

    // Append history if present
    if (history && history.length > 0) {
      for (const item of history.slice(-6)) {
        contents.push({
          role: item.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: item.content }],
        });
      }
    }

    contents.push({
      role: 'user',
      parts: [{ text: userPrompt }],
    });

    const payload = {
      contents,
      systemInstruction: {
        parts: [{ text: systemPrompt }],
      },
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 1024,
      },
    };

    let lastError: any = null;

    for (const model of modelsToTry) {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${this.geminiApiKey}`;
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 25000);

      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
          signal: controller.signal,
        });

        if (!res.ok) {
          const errorText = await res.text();
          lastError = new Error(`Gemini (${model}) HTTP ${res.status}: ${errorText.substring(0, 200)}`);
          if (res.status === 429 || res.status === 404 || res.status === 503) {
            continue; // Fallback to next candidate model
          }
          throw lastError;
        }

        const data: any = await res.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!text) {
          throw new Error(`Gemini (${model}) response missing text candidate`);
        }
        return text.trim();
      } catch (err: any) {
        lastError = err;
      } finally {
        clearTimeout(timeoutId);
      }
    }

    throw lastError || new Error('All Gemini models failed to respond');
  }

  public async callGeminiWithImage(
    systemPrompt: string,
    userPrompt: string,
    imageBuffer: Buffer,
    mimeType: string
  ): Promise<string> {
    const validMime =
      mimeType === 'image/png' ? 'image/png' : mimeType === 'image/webp' ? 'image/webp' : 'image/jpeg';
    const imageBase64 = imageBuffer.toString('base64');

    const payload = {
      contents: [
        {
          role: 'user',
          parts: [
            { text: userPrompt },
            {
              inlineData: {
                mimeType: validMime,
                data: imageBase64,
              },
            },
          ],
        },
      ],
      systemInstruction: {
        parts: [{ text: systemPrompt }],
      },
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 1200,
      },
    };

    let lastError: any = null;

    for (const model of this.geminiCandidateModels) {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${this.geminiApiKey}`;
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 20000);

      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
          signal: controller.signal,
        });

        if (!res.ok) {
          const errorText = await res.text();
          lastError = new Error(`Gemini Vision (${model}) HTTP ${res.status}: ${errorText.substring(0, 200)}`);
          if (res.status === 429 || res.status === 404 || res.status === 503) {
            continue; // Fallback to next candidate model
          }
          throw lastError;
        }

        const data: any = await res.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!text) {
          throw new Error(`Gemini vision (${model}) response missing text candidate`);
        }
        return text.trim();
      } catch (err: any) {
        lastError = err;
      } finally {
        clearTimeout(timeoutId);
      }
    }

    throw lastError || new Error('All Gemini vision models failed to respond');
  }

  private async callGroq(
    systemPrompt: string,
    userPrompt: string,
    history?: ChatMessage[],
    modelOverride?: string
  ): Promise<string> {
    const model = modelOverride || this.groqModel;
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    const messages: any[] = [{ role: 'system', content: systemPrompt }];

    if (history && history.length > 0) {
      for (const item of history.slice(-6)) {
        messages.push({
          role: item.role === 'assistant' ? 'assistant' : 'user',
          content: item.content,
        });
      }
    }

    messages.push({ role: 'user', content: userPrompt });

    const payload = {
      model,
      messages,
      temperature: 0.2,
      max_tokens: 1024,
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 12000);

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.groqApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });

      if (!res.ok) {
        const errorText = await res.text();
        throw new Error(`Groq HTTP ${res.status}: ${errorText.substring(0, 200)}`);
      }

      const data: any = await res.json();
      const text = data?.choices?.[0]?.message?.content;
      if (!text && text !== '') {
        throw new Error('Groq response missing message content');
      }
      return text.trim();
    } finally {
      clearTimeout(timeoutId);
    }
  }

  public async callGroqWithImage(
    systemPrompt: string,
    userPrompt: string,
    imageBuffer: Buffer,
    mimeType: string,
    modelOverride?: string
  ): Promise<string> {
    const model = modelOverride || process.env.GROQ_VISION_MODEL || 'llama-3.2-11b-vision-preview';
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    const validMime =
      mimeType === 'image/png' ? 'image/png' : mimeType === 'image/webp' ? 'image/webp' : 'image/jpeg';
    const base64Data = imageBuffer.toString('base64');

    const messages = [
      { role: 'system', content: systemPrompt },
      {
        role: 'user',
        content: [
          { type: 'text', text: userPrompt },
          {
            type: 'image_url',
            image_url: {
              url: `data:${validMime};base64,${base64Data}`,
            },
          },
        ],
      },
    ];

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.groqApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model,
          messages,
          temperature: 0.2,
          max_tokens: 1200,
        }),
        signal: controller.signal,
      });

      if (!res.ok) {
        const errorText = await res.text();
        throw new Error(`Groq Vision HTTP ${res.status}: ${errorText.substring(0, 200)}`);
      }

      const data: any = await res.json();
      const text = data?.choices?.[0]?.message?.content;
      if (!text && text !== '') {
        throw new Error('Groq vision response missing message content');
      }
      return text.trim();
    } finally {
      clearTimeout(timeoutId);
    }
  }

  /**
   * AI Health Record Summarizer (Multilingual: English, Hindi, Hinglish)
   */
  public async summarizeHealthRecord(recordText: string, language: 'en' | 'hi' | 'hinglish' = 'en'): Promise<any> {
    const langPrompt =
      language === 'hi'
        ? 'Provide the final summary in natural Hindi (Devanagari script).'
        : language === 'hinglish'
        ? 'Provide the summary in natural, conversational Hinglish (Hindi written in Roman English script) that Indian patients easily understand.'
        : 'Provide the summary in clear, easy-to-understand plain English.';

    const systemPrompt = `You are "Aarogya Clinical AI Health Record Summarizer".
Analyze the patient medical record text provided and create a structured, patient-friendly summary.
${langPrompt}
Safety:
- Do not invent values not present in the record.
- Highlight key diagnoses, prescribed medications, precautions, and when to follow up.
- Return ONLY a valid JSON object matching:
{
  "summary": "2-3 sentence overall overview",
  "keyDiagnoses": ["diagnosis 1", "diagnosis 2"],
  "medicationsPrescribed": ["medication name and dosage"],
  "criticalPrecautions": ["precaution 1", "precaution 2"],
  "suggestedNextSteps": ["step 1", "step 2"],
  "disclaimer": "Informational summary only. Consult treating doctor for confirmation."
}`;

    const prompt = `Record Content:\n${recordText}`;
    try {
      const raw = await this.callGemini(systemPrompt, prompt);
      const parsed = this.safeParseJson(raw);
      if (parsed.summary) return parsed;
    } catch {
      // Fallback
    }

    return {
      summary: language === 'hi' ? 'स्वास्थ्य रिकॉर्ड का सुरक्षित सारांश तैयार किया गया।' : 'Patient clinical record successfully processed.',
      keyDiagnoses: ['Clinical findings as documented in issued prescription'],
      medicationsPrescribed: ['Follow schedule as specified on document'],
      criticalPrecautions: ['Maintain adequate hydration', 'Do not alter dosage without doctor confirmation'],
      suggestedNextSteps: ['Follow up with specialist on scheduled review date'],
      disclaimer: 'Informational clinical summary only.',
    };
  }

  /**
   * AI Medicine Composition & Jan Aushadhi Alternative Explainer
   */
  public async explainMedicineComposition(medicineName: string, composition: string, language: 'en' | 'hi' | 'hinglish' = 'en'): Promise<any> {
    const langPrompt =
      language === 'hi'
        ? 'Explain in Hindi.'
        : language === 'hinglish'
        ? 'Explain in natural, warm Hinglish (Roman Hindi).'
        : 'Explain in simple English.';

    const systemPrompt = `You are "Aarogya Medicine Explainer".
Explain what the medicine "${medicineName}" (active salt: ${composition}) does, safe dosage rules, side effects, and why the generic version from PM Jan Aushadhi is bio-equivalent and cost-effective.
${langPrompt}
Return JSON:
{
  "simplePurpose": "What this medicine does in simple words",
  "howItWorks": "Simple explanation of the active salt",
  "safeUsage": "When and how to take (with water, food rules)",
  "genericAlternativeAdvice": "Jan Aushadhi generic availability and money savings advice",
  "warnings": ["warning 1", "warning 2"],
  "disclaimer": "Always consult a registered doctor or pharmacist before changing medications."
}`;

    try {
      const raw = await this.callGemini(systemPrompt, `Medicine: ${medicineName}, Salt: ${composition}`);
      const parsed = this.safeParseJson(raw);
      if (parsed.simplePurpose) return parsed;
    } catch {}

    return {
      simplePurpose: `${medicineName} provides therapeutic management for the indicated clinical condition.`,
      howItWorks: `Contains active formulation: ${composition}.`,
      safeUsage: 'Take with a glass of water as advised on prescription.',
      genericAlternativeAdvice: 'Bio-equivalent generic medicines are available at Pradhan Mantri Jan Aushadhi Kendras at up to 80% lower cost.',
      warnings: ['Do not exceed maximum daily dosage', 'Avoid alcohol concurrent intake'],
      disclaimer: 'Always verify with your doctor or pharmacist.',
    };
  }

  /**
   * AI Clinical Case & Referral Summary Generator for Doctors
   */
  public async generateClinicalCaseSummary(patientName: string, clinicalData: any): Promise<any> {
    const systemPrompt = `You are "Aarogya Clinical Co-Pilot for Medical Practitioners".
Generate a formal, professional medical case summary suitable for doctor-to-doctor consultation and specialist referrals.
Return JSON:
{
  "caseTitle": "Brief clinical case headline",
  "chiefComplaint": "Patient presenting symptoms and duration",
  "clinicalObservations": "Physical exam & vital signs synthesis",
  "investigationsSummary": "Key lab and imaging findings",
  "workingDiagnosis": "Primary and differential diagnoses",
  "reasonForReferral": "Specific clinical question for the specialist",
  "recommendedUrgency": "ROUTINE | URGENT | EMERGENCY"
}`;

    const prompt = `Patient: ${patientName}\nData: ${JSON.stringify(clinicalData)}`;
    try {
      const raw = await this.callGemini(systemPrompt, prompt);
      const parsed = this.safeParseJson(raw);
      if (parsed.caseTitle) return parsed;
    } catch {}

    return {
      caseTitle: `Clinical Case Summary for ${patientName}`,
      chiefComplaint: clinicalData.chiefComplaint || 'Consultation review',
      clinicalObservations: 'Vitals stable under current medical management.',
      investigationsSummary: 'Relevant laboratory reports attached in digital record context.',
      workingDiagnosis: clinicalData.diagnosis || 'Clinical evaluation required',
      reasonForReferral: 'Expert specialist evaluation and multidisciplinary management.',
      recommendedUrgency: clinicalData.urgency || 'ROUTINE',
    };
  }

  public safeParseJson(raw: string): any {
    try {
      // Strip markdown code fences if model enclosed JSON in ```json ... ```
      let cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
      }
      // Extract outermost JSON block if any extra text precedes/follows
      const firstBrace = cleaned.indexOf('{');
      const lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
        cleaned = cleaned.substring(firstBrace, lastBrace + 1);
      }
      return JSON.parse(cleaned);
    } catch {
      return {};
    }
  }
}

export const aiService = new AiService();
