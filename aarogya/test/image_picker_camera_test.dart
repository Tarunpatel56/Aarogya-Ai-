import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aarogya/services/image_picker_service.dart';
import 'package:aarogya/services/medical_ai_service.dart';
import 'package:aarogya/services/ai_service.dart';
import 'package:aarogya/models/ai_response_model.dart';
import 'package:aarogya/models/medical_analysis_model.dart';
import 'package:aarogya/models/user_model.dart';
import 'package:aarogya/screens/ai/brain_mri_screen.dart';
import 'package:aarogya/screens/ai/lung_xray_screen.dart';
import 'package:aarogya/screens/ai/skin_analysis_screen.dart';
import 'package:aarogya/screens/ocr_scanner_modal.dart';
import 'package:aarogya/screens/ai_assistant_screen.dart';

// In-Memory Mock XFile that requires zero disk file system access
class MockPickedFile extends Fake implements XFile {
  @override
  final String name;
  final Uint8List bytes;
  @override
  final String? mimeType;

  MockPickedFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  @override
  String get path => name;

  @override
  Future<Uint8List> readAsBytes() async => bytes;
}

// Mock ImagePicker
class FakeImagePicker extends Fake implements ImagePicker {
  XFile? simulatedFile;
  bool shouldThrow = false;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (shouldThrow) {
      throw Exception('Camera device failed or permission denied');
    }
    return simulatedFile;
  }
}

// Mock MedicalAiService
class MockMedicalAiService extends Fake implements MedicalAiService {
  Uint8List? lastUploadedBytes;
  String? lastUploadedFilename;

  @override
  Future<MedicalAnalysisResult> analyzeBrainMri({
    required List<int> imageBytes,
    String filename = 'brain_mri.png',
    String language = 'en',
  }) async {
    lastUploadedBytes = Uint8List.fromList(imageBytes);
    lastUploadedFilename = filename;
    return MedicalAnalysisResult(
      analysisType: 'BRAIN_MRI',
      provider: 'huggingface',
      model: 'Hemgg/brain-tumor-classification',
      primaryFinding: const MedicalPrediction(label: 'glioma', normalizedLabel: 'Glioma', score: 0.942),
      allPredictions: const [
        MedicalPrediction(label: 'glioma', normalizedLabel: 'Glioma', score: 0.942),
        MedicalPrediction(label: 'notumor', normalizedLabel: 'No Tumor Detected', score: 0.058),
      ],
      findingsSummary: 'Primary prediction: Glioma (94.2% confidence).',
      clinicalDisclaimer: 'Assistive AI classification. Not final diagnosis.',
      analyzedAt: DateTime.now(),
    );
  }

  @override
  Future<MedicalAnalysisResult> analyzeLungXray({
    required List<int> imageBytes,
    String filename = 'chest_xray.jpg',
    String language = 'en',
  }) async {
    lastUploadedBytes = Uint8List.fromList(imageBytes);
    lastUploadedFilename = filename;
    return MedicalAnalysisResult(
      analysisType: 'CHEST_XRAY',
      provider: 'huggingface',
      model: 'dima806/chest_xray_pneumonia_detection',
      primaryFinding: const MedicalPrediction(label: 'pneumonia', normalizedLabel: 'Pneumonia', score: 0.915),
      allPredictions: const [
        MedicalPrediction(label: 'pneumonia', normalizedLabel: 'Pneumonia', score: 0.915),
        MedicalPrediction(label: 'normal', normalizedLabel: 'Normal', score: 0.085),
      ],
      findingsSummary: 'Primary prediction: Pneumonia (91.5% confidence).',
      clinicalDisclaimer: 'Assistive pneumonia radiograph detection.',
      mandatoryClinicalNotice: 'CRITICAL CLINICAL NOTICE: Normal does not rule out other pulmonary pathologies.',
      analyzedAt: DateTime.now(),
    );
  }

  @override
  Future<MedicalAnalysisResult> analyzeSkinImage({
    required List<int> imageBytes,
    String filename = 'skin_lesion.jpg',
    String language = 'en',
  }) async {
    lastUploadedBytes = Uint8List.fromList(imageBytes);
    lastUploadedFilename = filename;
    return MedicalAnalysisResult(
      analysisType: 'SKIN_LESION',
      provider: 'huggingface',
      model: 'Tanishq77/skin-condition-classifier',
      primaryFinding: const MedicalPrediction(label: 'eczema', normalizedLabel: 'Eczema', score: 0.884),
      allPredictions: const [
        MedicalPrediction(label: 'eczema', normalizedLabel: 'Eczema', score: 0.884),
        MedicalPrediction(label: 'acne', normalizedLabel: 'Acne', score: 0.116),
      ],
      findingsSummary: 'Primary prediction: Eczema (88.4% confidence).',
      clinicalDisclaimer: 'Assistive dermatological classification.',
      analyzedAt: DateTime.now(),
    );
  }
}

// Mock AiService for Medicine OCR & Chat
class MockAiService extends Fake implements AiService {
  @override
  Future<AiChatResponse> sendChatMessage({
    required String message,
    List<Map<String, String>>? history,
    String language = 'en',
    Map<String, dynamic>? patientVitals,
  }) async {
    return const AiChatResponse(
      reply: 'Telmisartan is an angiotensin II receptor blocker used for hypertension.',
      replyEn: 'Telmisartan is an angiotensin II receptor blocker used for hypertension.',
      replyHi: 'टेल्मीसार्टन उच्च रक्तचाप के इलाज के लिए इस्तेमाल की जाने वाली दवा है।',
      provider: 'gemini',
      model: 'gemini-1.5-pro',
      disclaimer: 'Clinical AI assistance.',
    );
  }

  @override
  Future<AiMedicineAnalysis> analyzeMedicine({
    required String ocrText,
    String language = 'en',
  }) async {
    return const AiMedicineAnalysis(
      medicineName: 'Telmisartan',
      brandName: 'Telma 40',
      genericName: 'Telmisartan IP',
      composition: 'Telmisartan 40mg',
      strength: '40 mg',
      manufacturer: 'Glenmark Pharmaceuticals Ltd',
      mrp: '₹52.50 per 10 tablets',
      dosage: '40mg',
      dosageGuideline: 'Dosage must be determined solely by a physician based on your clinical evaluation. Aarogya AI does not provide dosage advice.',
      dosageForm: 'Tablet',
      frequency: 'Once daily',
      purpose: 'Blood pressure regulation',
      uses: ['High Blood Pressure (Hypertension)', 'Heart attack risk reduction'],
      disadvantages: ['Dizziness upon standing up', 'Elevated potassium levels'],
      precautions: ['Do not use in pregnancy', 'Avoid with alcohol'],
      whatHappensWhenTaken: 'Relaxes blood vessels by blocking Angiotensin II to lower BP within 2-4 hours.',
      estimatedPrice: '₹35 - ₹65 per strip (10 tablets)',
      instructions: 'Take once daily in evening',
      warnings: ['May cause dizziness'],
      disclaimer: 'Clinical AI assistance.',
      provider: 'gemini',
    );
  }

  @override
  Future<AiMedicineAnalysis> analyzeMedicineImage({
    required List<int> imageBytes,
    String filename = 'medicine_strip.jpg',
    String language = 'en',
  }) async {
    return analyzeMedicine(ocrText: 'TELMISARTAN TABLETS IP 40mg', language: language);
  }
}

// 1x1 valid PNG bytes
final Uint8List tinyPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  group('Part 1 — User Role Mapping & Routing Verification', () {
    test('UserModel maps canonical roles and effectiveRole correctly', () {
      final patientUser = UserModel.fromJson({
        'id': 'usr-1',
        'email': 'patient@test.com',
        'role': 'PATIENT',
        'effectiveRole': 'PATIENT',
        'verificationStatus': 'VERIFIED',
      });
      expect(patientUser.canonicalRole, 'PATIENT');

      final hospitalAdminUser = UserModel.fromJson({
        'id': 'usr-2',
        'email': 'admin@hospital.com',
        'role': 'HOSPITAL_ADMIN',
        'effectiveRole': 'HOSPITAL_ADMIN',
        'verificationStatus': 'VERIFIED',
      });
      expect(hospitalAdminUser.canonicalRole, 'HOSPITAL_ADMIN');

      final driverUser = UserModel.fromJson({
        'id': 'usr-3',
        'email': 'driver@rapid.com',
        'role': 'AMBULANCE_DRIVER',
        'effectiveRole': 'DRIVER',
        'verificationStatus': 'VERIFIED',
      });
      expect(driverUser.canonicalRole, 'DRIVER');

      final superAdminUser = UserModel.fromJson({
        'id': 'usr-4',
        'email': 'superadmin@aarogya.com',
        'role': 'PLATFORM_ADMIN',
        'effectiveRole': 'SUPER_ADMIN',
        'verificationStatus': 'VERIFIED',
      });
      expect(superAdminUser.canonicalRole, 'SUPER_ADMIN');
    });
  });

  group('Part 2 — ImagePickerService Unit Tests', () {
    late FakeImagePicker fakePicker;
    late ImagePickerService service;

    setUp(() {
      fakePicker = FakeImagePicker();
      service = ImagePickerService(picker: fakePicker);
    });

    test('pickFromCamera successfully processes valid image', () async {
      fakePicker.simulatedFile = MockPickedFile(
        name: 'camera_mri.png',
        bytes: tinyPngBytes,
        mimeType: 'image/png',
      );

      final result = await service.pickFromCamera();
      expect(result, isNotNull);
      expect(result!.name, 'camera_mri.png');
      expect(result.sizeInBytes, tinyPngBytes.length);
      expect(result.formattedSize, '${tinyPngBytes.length} B');
    });

    test('pickFromGallery gracefully handles user cancellation', () async {
      fakePicker.simulatedFile = null;

      final result = await service.pickFromGallery();
      expect(result, isNull);
    });

    test('enforces strict 10 MB size limit and throws ImagePickerException', () async {
      final oversizedBytes = Uint8List(11 * 1024 * 1024);
      fakePicker.simulatedFile = MockPickedFile(
        name: 'giant_scan.jpg',
        bytes: oversizedBytes,
        mimeType: 'image/jpeg',
      );

      expect(
        () => service.pickFromGallery(),
        throwsA(isA<ImagePickerException>().having(
          (e) => e.message,
          'message',
          contains('Selected image exceeds the 10 MB limit'),
        )),
      );
    });

    test('rejects unsupported file formats', () async {
      fakePicker.simulatedFile = MockPickedFile(
        name: 'document.pdf',
        bytes: tinyPngBytes,
        mimeType: 'application/pdf',
      );

      expect(
        () => service.pickFromGallery(),
        throwsA(isA<ImagePickerException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported image format'),
        )),
      );
    });

    test('rejects empty or truncated image buffer', () async {
      fakePicker.simulatedFile = MockPickedFile(
        name: 'empty.png',
        bytes: Uint8List(0),
        mimeType: 'image/png',
      );

      expect(
        () => service.pickFromCamera(),
        throwsA(isA<ImagePickerException>().having(
          (e) => e.message,
          'message',
          contains('empty or corrupted'),
        )),
      );
    });
  });

  group('Part 2 — Camera & Gallery UI & Analysis Flow Tests', () {
    late FakeImagePicker fakePicker;
    late MockMedicalAiService mockAi;
    late ImagePickerService pickerService;

    setUp(() {
      fakePicker = FakeImagePicker();
      pickerService = ImagePickerService(picker: fakePicker);
      mockAi = MockMedicalAiService();
    });

    testWidgets('BrainMriScreen displays Camera & Gallery options and previews selected image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BrainMriScreen(
            medicalAiService: mockAi,
            imagePickerService: pickerService,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload Gallery'), findsOneWidget);
      expect(find.text('Upload or Capture MRI Scan'), findsOneWidget);

      fakePicker.simulatedFile = MockPickedFile(
        name: 'patient_axial_t2.png',
        bytes: tinyPngBytes,
        mimeType: 'image/png',
      );

      await tester.tap(find.text('Upload Gallery'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('patient_axial_t2.png'), findsOneWidget);
      expect(find.text('Change Image'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      await tester.ensureVisible(find.text('Run Brain MRI Analysis'));
      await tester.tap(find.text('Run Brain MRI Analysis'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Glioma'), findsAtLeastNWidgets(1));
      expect(find.text('Confidence: 94.2%'), findsOneWidget);
      expect(mockAi.lastUploadedFilename, 'patient_axial_t2.png');
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.textContaining('Assistive AI classification'), findsOneWidget);
      expect(find.text('Consult Neurologist'), findsOneWidget);
    });

    testWidgets('LungXrayScreen displays Camera & Gallery options and executes analysis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LungXrayScreen(
            medicalAiService: mockAi,
            imagePickerService: pickerService,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload Gallery'), findsOneWidget);
      expect(find.text('Upload or Capture Chest X-Ray'), findsOneWidget);

      fakePicker.simulatedFile = MockPickedFile(
        name: 'chest_pa_view.png',
        bytes: tinyPngBytes,
        mimeType: 'image/png',
      );

      await tester.tap(find.text('Take Photo'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('chest_pa_view.png'), findsOneWidget);

      await tester.ensureVisible(find.text('Analyze Chest X-Ray'));
      await tester.tap(find.text('Analyze Chest X-Ray'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pneumonia'), findsAtLeastNWidgets(1));
      expect(find.text('Confidence: 91.5%'), findsOneWidget);
      expect(find.textContaining('CRITICAL CLINICAL NOTICE'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('Consult Pulmonologist'), findsOneWidget);
    });

    testWidgets('SkinAnalysisScreen displays Camera & Gallery options and executes analysis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SkinAnalysisScreen(
            medicalAiService: mockAi,
            imagePickerService: pickerService,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload Gallery'), findsOneWidget);
      expect(find.text('Upload or Capture Skin Photo'), findsOneWidget);

      fakePicker.simulatedFile = MockPickedFile(
        name: 'rash_forearm.png',
        bytes: tinyPngBytes,
        mimeType: 'image/png',
      );

      await tester.tap(find.text('Upload Gallery'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('rash_forearm.png'), findsOneWidget);

      await tester.ensureVisible(find.text('Analyze Skin Image'));
      await tester.tap(find.text('Analyze Skin Image'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Eczema'), findsAtLeastNWidgets(1));
      expect(find.text('Confidence: 88.4%'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('Consult Dermatologist'), findsOneWidget);
    });

    testWidgets('OcrScannerModal allows Take Photo and Gallery upload with image preview', (tester) async {
      fakePicker.simulatedFile = MockPickedFile(
        name: 'telmisartan_strip.jpg',
        bytes: tinyPngBytes,
        mimeType: 'image/jpeg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrScannerModal(
              imagePickerService: pickerService,
              aiService: MockAiService(),
            ),
          ),
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload Gallery'), findsOneWidget);
      expect(find.text('Capture Medicine Strip or Rx'), findsOneWidget);

      await tester.tap(find.text('Take Photo'));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('telmisartan_strip.jpg'), findsOneWidget);
      expect(find.text('1. Raw Extracted Text (From Camera / OCR):'), findsOneWidget);
      expect(find.text('Edit OCR Text'), findsOneWidget);

      // Verify full clinical detail cards: price, uses, what happens when taken, disadvantages
      expect(find.textContaining('Estimated Retail Price'), findsOneWidget);
      expect(find.textContaining('Primary Medical Uses'), findsOneWidget);
      expect(find.textContaining('What Happens When You Take It'), findsOneWidget);
      expect(find.textContaining('Disadvantages & Potential Side Effects'), findsOneWidget);

      // Verify extracted OCR packaging details: Brand, Composition, Strength, Manufacturer, Printed MRP
      expect(find.textContaining('Brand Name:'), findsOneWidget);
      expect(find.textContaining('Active Molecule:'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Strength:'), findsOneWidget);
      expect(find.textContaining('Manufacturer:'), findsOneWidget);
      expect(find.textContaining('Printed MRP:'), findsOneWidget);

      // Verify strict dosage prohibition warning
      expect(find.textContaining('Dosage Notice:'), findsOneWidget);

      // Verify precautions and localization toggle
      expect(find.textContaining('Key Precautions & Warnings:'), findsOneWidget);
      expect(find.text('हिंदी में देखें'), findsOneWidget);
    });

    testWidgets('AIAssistantScreen camera button opens Take Photo / Upload Gallery options without medicine strip', (tester) async {
      final fakePicker = FakeImagePicker()
        ..simulatedFile = MockPickedFile(
          name: 'prescription.png',
          bytes: tinyPngBytes,
          mimeType: 'image/png',
        );
      final imagePickerService = ImagePickerService(picker: fakePicker);
      final mockAiService = MockAiService();

      await tester.pumpWidget(
        MaterialApp(
          home: AIAssistantScreen(
            aiService: mockAiService,
            imagePickerService: imagePickerService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap camera icon
      final cameraBtn = find.byIcon(Icons.camera_alt_outlined);
      expect(cameraBtn, findsOneWidget);
      await tester.tap(cameraBtn);
      await tester.pumpAndSettle();

      // Bottom sheet shows Take Photo and Upload Gallery
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload Gallery'), findsOneWidget);
      // Ensures medicine strip modal is NOT opened
      expect(find.text('Capture Medicine Strip or Rx'), findsNothing);
      expect(find.text('Analyze Medicine Strip'), findsNothing);

      // Tap Take Photo
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      // Attached image preview card is displayed with file name and size
      expect(find.text('prescription.png'), findsOneWidget);
      expect(find.textContaining('Photo attached'), findsOneWidget);

      // Now send the message with attached image
      final sendBtn = find.byIcon(Icons.send_rounded);
      expect(sendBtn, findsOneWidget);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Verify bot response DOES NOT show 'Verified GEMINI' or provider tags
      expect(find.textContaining('Verified GEMINI'), findsNothing);
      expect(find.textContaining('Aarogya Clinical AI (GEMINI)'), findsNothing);
      expect(find.text('Aarogya Health Assistant'), findsAtLeastNWidgets(1));
    });

    testWidgets('AIAssistantScreen mic button opens Voice Input Assistant modal with prompts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AIAssistantScreen(
            aiService: MockAiService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final micBtn = find.byIcon(Icons.mic_none_outlined);
      expect(micBtn, findsOneWidget);
      await tester.tap(micBtn);
      await tester.pumpAndSettle();

      // Verify Voice Input Modal
      expect(find.text('Voice Input Assistant'), findsOneWidget);
      expect(find.textContaining('Listening'), findsOneWidget);
      expect(find.text('Is Paracetamol safe with food?'), findsOneWidget);
      expect(find.text('Ask Assistant'), findsOneWidget);
      expect(find.text('Use in Chat'), findsOneWidget);

      // Tap a suggestion
      await tester.tap(find.text('Is Paracetamol safe with food?'));
      await tester.pumpAndSettle();

      // Tap Use in Chat
      await tester.tap(find.text('Use in Chat'));
      await tester.pumpAndSettle();

      // Verified text is inserted into chat textfield
      expect(find.text('Is Paracetamol safe with food?'), findsOneWidget);
    });
  });

  group('Part 3 — Overflow Prevention & Compact Device Tests', () {
    testWidgets('AIAssistantScreen adapts to mobile layout without vertical overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AIAssistantScreen(),
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Aarogya AI provides clinical educational assistance'), findsOneWidget);
    });

    testWidgets('BrainMriScreen renders on 360x640 screen with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: BrainMriScreen(
            medicalAiService: MockMedicalAiService(),
          ),
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tester.takeException(), isNull);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload Gallery'), findsOneWidget);
    });
  });
}
