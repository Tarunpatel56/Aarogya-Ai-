import { describe, it, expect, beforeAll, vi } from 'vitest';
import { medicalImageService } from '../src/services/medical-image.service';
import { aiService } from '../src/services/ai.service';

describe('Aarogya Vision AI & Multimodal Medicine API Tests', () => {
  // Valid PNG buffer > 64 bytes with valid PNG header
  const validPngBuffer = Buffer.from([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
    0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xde, 0x00, 0x00, 0x00, 0x0c, 0x49, 0x44, 0x41,
    0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
    0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xdd, 0x8d,
    0xb0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e,
    0x44, 0xae, 0x42, 0x60, 0x82, 0x00, 0x00, 0x00,
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
  ]);

  // Valid minimal 1x1 JPEG image buffer that decodes cleanly in Gemini Vision
  const validJpegBuffer = Buffer.from(
    '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=',
    'base64'
  );

  function mockMulter(buf: Buffer, filename: string, mimetype: string): Express.Multer.File {
    return {
      fieldname: 'image',
      originalname: filename,
      encoding: '7bit',
      mimetype,
      size: buf.length,
      buffer: buf,
      destination: '',
      filename,
      path: '',
      stream: null as any,
    };
  }

  it('Brain MRI vision analysis produces structured observations and radiologist guidance', async () => {
    vi.spyOn(aiService, 'callGeminiWithImage').mockResolvedValueOnce(
      JSON.stringify({
        normalizedLabel: 'Glioma',
        confidence: 0.942,
        findingsSummary: 'Preliminary MRI pattern indicates glial-origin proliferative lesion.',
        observations: ['Ventricular asymmetry observed', 'Signal hyperintensity in right parietal parenchyma'],
        possibleAbnormalities: ['Glioma lesion'],
        clinicalExplanation: 'Imaging patterns consistent with proliferative glial lesion. Consult neuro-radiologist.',
        doctorRecommendation: 'Urgent neuro-radiology review and neurosurgical consultation indicated.',
      })
    );

    const file = mockMulter(validPngBuffer, 'brain_mri.png', 'image/png');
    const result = await medicalImageService.analyzeWithGeminiVision('BRAIN_MRI', file, 'en');

    expect(result.analysisType).toBe('BRAIN_MRI');
    expect(result.provider).toContain('Vision');
    expect(result.primaryFinding.normalizedLabel).toBe('Glioma');
    expect(result.primaryFinding.confidence).toBe(0.942);
    expect(result.clinicalDisclaimer).toContain('neuro-radiologist');
    expect(result.observations?.length).toBeGreaterThan(0);
    expect(result.possibleAbnormalities?.length).toBeGreaterThan(0);
    expect(result.doctorRecommendation).toContain('neuro-radiology');
  });

  it('Chest X-Ray vision analysis includes mandatory clinical notice', async () => {
    vi.spyOn(aiService, 'callGeminiWithImage').mockResolvedValueOnce(
      JSON.stringify({
        normalizedLabel: 'Normal (No Acute Consolidation Observed)',
        confidence: 0.954,
        findingsSummary: 'Bilateral lung fields clear of acute consolidations.',
        observations: ['Bilateral lung fields well-aerated', 'Costophrenic angles sharp', 'Normal cardiothoracic ratio'],
        possibleAbnormalities: ['No acute consolidation detected'],
        clinicalExplanation: 'Chest radiograph does not show acute pneumonic infiltrates.',
        doctorRecommendation: 'Consult a pulmonologist if respiratory symptoms persist.',
      })
    );

    const file = mockMulter(validJpegBuffer, 'chest_xray.jpg', 'image/jpeg');
    const result = await medicalImageService.analyzeWithGeminiVision('CHEST_XRAY', file, 'en');

    expect(result.analysisType).toBe('CHEST_XRAY');
    expect(result.primaryFinding.normalizedLabel).toContain('Normal');
    expect(result.mandatoryClinicalNotice).toContain('CRITICAL CLINICAL NOTICE');
    expect(result.mandatoryClinicalNotice).toContain('DOES NOT rule out other pulmonary pathologies');
    expect(result.observations?.length).toBeGreaterThan(0);
    expect(result.possibleAbnormalities?.length).toBeGreaterThan(0);
  });

  it('Skin Disease vision analysis returns visible symptoms and dermatologist advice', async () => {
    vi.spyOn(aiService, 'callGeminiWithImage').mockResolvedValueOnce(
      JSON.stringify({
        normalizedLabel: 'Eczema / Dermatitis',
        confidence: 0.885,
        findingsSummary: 'Erythematous pruritic plaque with surface scaling.',
        observations: ['Erythematous border', 'Mild xerosis and epidermal flaking'],
        possibleAbnormalities: ['Atopic Dermatitis', 'Contact Dermatitis'],
        clinicalExplanation: 'Features suggestive of eczematous skin manifestation.',
        doctorRecommendation: 'Consult a board-certified dermatologist for in-person dermoscopy.',
      })
    );

    const file = mockMulter(validJpegBuffer, 'skin_lesion.jpg', 'image/jpeg');
    const result = await medicalImageService.analyzeWithGeminiVision('SKIN_IMAGE', file, 'en');

    expect(result.analysisType).toBe('SKIN_IMAGE');
    expect(result.primaryFinding.normalizedLabel).toContain('Eczema');
    expect(result.clinicalDisclaimer).toContain('dermatologist');
    expect(result.observations?.length).toBeGreaterThan(0);
    expect(result.doctorRecommendation).toContain('dermatologist');
  });

  it('Medicine Analyzer extracts packaging details, strictly prohibits dosage, and respects printed MRP', async () => {
    vi.spyOn(aiService, 'callGeminiWithImage').mockResolvedValueOnce(
      JSON.stringify({
        medicineName: 'Telma 40',
        brandName: 'Telma',
        genericName: 'Telmisartan',
        composition: 'Telmisartan 40mg',
        strength: '40mg',
        manufacturer: 'Glenmark Pharmaceuticals Ltd',
        mrp: '₹52.50 per 10 tablets',
        dosage: 'As prescribed by physician',
        dosageGuideline: 'Dosage must be determined solely by a licensed physician based on your clinical assessment.',
        dosageForm: 'Tablet',
        frequency: 'Once daily',
        purpose: 'Hypertension',
        uses: ['High Blood Pressure (Hypertension)', 'Cardiovascular risk reduction'],
        disadvantages: ['Dizziness upon standing up', 'Elevated potassium levels'],
        whatHappensWhenTaken: 'Relaxes blood vessels by blocking Angiotensin II to lower BP smoothly within 2-4 hours.',
        precautions: ['Strictly contraindicated during pregnancy', 'Monitor serum potassium'],
        estimatedPrice: '₹35 - ₹65 per strip (10 tablets)',
        instructions: 'Take once daily with water after food.',
        warnings: ['Avoid alcohol while taking medication.'],
      })
    );

    const file = mockMulter(validJpegBuffer, 'medicine_strip.jpg', 'image/jpeg');
    const result = await aiService.analyzeMedicineImage(file, 'en');

    expect(result.medicineName).toBe('Telma 40');
    expect(result.brandName).toBe('Telma');
    expect(result.composition).toBe('Telmisartan 40mg');
    expect(result.strength).toBe('40mg');
    expect(result.manufacturer).toBe('Glenmark Pharmaceuticals Ltd');
    expect(result.mrp).toBe('₹52.50 per 10 tablets');
    expect(result.uses.length).toBeGreaterThan(0);
    expect(result.disadvantages.length).toBeGreaterThan(0);
    expect(result.precautions?.length).toBeGreaterThan(0);
    expect(result.whatHappensWhenTaken).toContain('blood vessels');
    expect(result.dosageGuideline).toContain('Dosage must be determined solely by a licensed physician');
    expect(result.dosage).toContain('As prescribed');
  });

  it('Hindi localization produces responses in Hindi for medical imaging and OCR', async () => {
    vi.spyOn(aiService, 'callGeminiWithImage').mockResolvedValueOnce(
      JSON.stringify({
        normalizedLabel: 'Glioma',
        confidence: 0.942,
        findingsSummary: 'ग्लिओमा के प्रारंभिक लक्षण देखे गए हैं।',
        observations: ['वेंट्रिकुलर समरूपता में हल्का अंतर'],
        possibleAbnormalities: ['ग्लिओमा असामान्यता'],
        clinicalExplanation: 'मस्तिष्क स्कैन में संदिग्ध टिशू दिखाई दिया है। न्यूरोलॉजिस्ट से मिलें।',
        doctorRecommendation: 'प्रमाणित न्यूरो-रेडियोलॉजिस्ट से तत्काल समीक्षा कराएं।',
      })
    );

    const file = mockMulter(validPngBuffer, 'brain_mri_hi.png', 'image/png');
    const result = await medicalImageService.analyzeWithGeminiVision('BRAIN_MRI', file, 'hi');

    expect(result.language).toBe('hi');
    expect(result.clinicalDisclaimer).toContain('आरोग्य एआई');

    vi.spyOn(aiService as any, 'callGemini').mockResolvedValueOnce(
      JSON.stringify({
        medicineName: 'Telma 40',
        brandName: 'Telma 40',
        genericName: 'Telmisartan',
        composition: 'Telmisartan IP 40mg',
        strength: '40mg',
        manufacturer: 'Glenmark Pharmaceuticals',
        mrp: '₹120',
        uses: ['उच्च रक्तचाप (Hypertension) का उपचार'],
        disadvantages: ['चक्कर आना', 'सिरदर्द'],
        whatHappensWhenTaken: 'यह दवा रक्त वाहिकाओं को आराम देती है।',
        precautions: ['गर्भावस्था में उपयोग न करें'],
        dosageGuideline: 'खुराक केवल चिकित्सक द्वारा निर्धारित की जानी चाहिए।',
      })
    );

    const ocrResult = await aiService.analyzeMedicineOcr({
      ocrText: 'TELMISARTAN TABLETS IP 40mg',
      language: 'hi',
    });
    expect(ocrResult.language).toBe('hi');
    expect(ocrResult.dosageGuideline).toContain('खुराक');
  }, 15000);
});
