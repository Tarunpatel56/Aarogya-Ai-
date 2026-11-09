import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aarogya_healthpro/core/api/api_client.dart';
import 'package:aarogya_healthpro/core/storage/token_storage.dart';
import 'package:aarogya_healthpro/models/clinical_imaging_review_model.dart';
import 'package:aarogya_healthpro/models/doctor_profile_model.dart';
import 'package:aarogya_healthpro/services/clinical_imaging_service.dart';
import 'package:aarogya_healthpro/services/doctor_auth_service.dart';
import 'package:aarogya_healthpro/services/doctor_ai_service.dart';
import 'package:aarogya_healthpro/screens/doctor_imaging_review_screen.dart';
import 'package:aarogya_healthpro/screens/modals/physio_prescribe_dialog.dart';
import 'package:aarogya_healthpro/screens/modals/doctor_copilot_telemetry_dialog.dart';

void main() {
  group('ClinicalImagingReview Model & Service Tests', () {
    test('Model serializes and deserializes correctly', () {
      final sample = ClinicalImagingReview(
        id: 'rev-test-1',
        patientId: 'patient-test',
        patientName: 'Test Patient',
        patientAge: 50,
        patientGender: 'Male',
        modality: ImagingModality.chestXray,
        uploadedAt: DateTime.parse('2026-10-28T10:00:00Z'),
        aiPreClassification: 'Pneumonia Detected',
        aiConfidence: 0.935,
        aiProvider: 'dima806/chest_xray_pneumonia_detection',
        mandatoryClinicalNotice: 'Mandatory clinical disclaimer.',
      );

      final jsonMap = sample.toJson();
      final reconstructed = ClinicalImagingReview.fromJson(jsonMap);

      expect(reconstructed.id, 'rev-test-1');
      expect(reconstructed.patientName, 'Test Patient');
      expect(reconstructed.modality, ImagingModality.chestXray);
      expect(reconstructed.aiConfidence, closeTo(0.935, 0.001));
      expect(reconstructed.isPending, isTrue);
    });

    test('ClinicalImagingService filters by modality and status', () {
      final service = ClinicalImagingService();

      final mriOnly = service.getReviews(modality: ImagingModality.brainMri);
      expect(mriOnly.every((r) => r.modality == ImagingModality.brainMri), isTrue);

      final pendingOnly = service.getReviews(status: ClinicalReviewStatus.pendingReview);
      expect(pendingOnly.every((r) => r.isPending), isTrue);
    });

    test('ClinicalImagingService validates review with doctor agreement', () async {
      final service = ClinicalImagingService();

      final updated = await service.validateReview(
        id: 'rev-mri-001',
        doctorName: 'Dr. Aarav Mehta, MD',
        notes: 'Confirmed sella turcica mass compatible with pituitary adenoma.',
        agreesWithAi: true,
        prescribedPhysioPlan: 'Desk Worker Cervical Relief Routine',
        prescribedMedications: ['Cabergoline 0.5mg'],
      );

      expect(updated.isValidated, isTrue);
      expect(updated.isAgreedWithAi, isTrue);
      expect(updated.doctorSignOff, 'Dr. Aarav Mehta, MD');
      expect(updated.prescribedPhysioPlan, contains('Cervical Relief'));
      expect(updated.prescribedMedications, contains('Cabergoline 0.5mg'));
    });

    test('ClinicalImagingService records clinical override with custom rationale', () async {
      final service = ClinicalImagingService();

      final updated = await service.validateReview(
        id: 'rev-lung-002',
        doctorName: 'Dr. Aarav Mehta, MD',
        notes: 'Opacification appears atelectatic secondary to mucous plug rather than bacterial pneumonia.',
        agreesWithAi: false,
        overrideDiagnosis: 'Right Middle Lobe Atelectasis (Non-Infectious)',
      );

      expect(updated.isOverridden, isTrue);
      expect(updated.isAgreedWithAi, isFalse);
      expect(updated.overrideDiagnosis, contains('Atelectasis'));
    });
  });

  group('DoctorImagingReviewScreen Widget Tests', () {
    late ClinicalImagingService imagingService;
    late DoctorAuthService authService;
    late DoctorAiService aiService;

    setUp(() {
      imagingService = ClinicalImagingService();

      final tokenStorage = InMemoryTokenStorage();
      tokenStorage.saveTokens(accessToken: 'mock-doc-token', refreshToken: 'mock-refresh');

      final mockHttp = MockClient((req) async {
        if (req.url.path.endsWith('/ai/copilot-summary')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'clinicalSummary': 'Patient Rahul Sharma shows stable cardiac and neurological metrics.',
                'riskAssessment': 'STABLE',
                'suggestedInterventions': ['Endocrine consult', 'Monitor visual fields'],
                'vitalAnomalies': [],
                'provider': 'groq',
                'model': 'qwen/qwen3.8-27b',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp, tokenStorage: tokenStorage);
      authService = DoctorAuthService(apiClient: apiClient);
      authService.setProfileForTesting(
        const DoctorProfileModel(
          id: 'doc-1',
          userId: 'user-doc-1',
          fullName: 'Dr. Aarav Mehta, MD',
          specialization: 'Cardiology',
          medicalLicenseNumber: 'MCI-9482-DEL',
          qualifications: 'MBBS, MD',
          experienceYears: 14,
          consultationFee: 800,
        ),
      );

      aiService = DoctorAiService(apiClient: apiClient);
    });

    testWidgets('DoctorImagingReviewScreen renders review cards and AI pre-classifications', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DoctorImagingReviewScreen(
            imagingService: imagingService,
            authService: authService,
            aiService: aiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Clinical Imaging Review Queue'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Validated'), findsOneWidget);
      expect(find.text('Rahul Sharma (Male, 48y)'), findsOneWidget);
      expect(find.text('Pituitary Tumor Detected'), findsOneWidget);
      expect(find.textContaining('94.2% AI Confidence'), findsOneWidget);
      expect(find.textContaining('Certified neuro-radiologist correlation'), findsOneWidget);
    });

    testWidgets('Doctor signs off report with agreement and clinical notes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DoctorImagingReviewScreen(
            imagingService: imagingService,
            authService: authService,
            aiService: aiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter doctor notes in the text field
      final notesField = find.widgetWithText(TextField, 'Doctor Clinical Diagnostic Notes *').first;
      await tester.enterText(notesField, 'Review completed. Confirmed pituitary microadenoma.');
      await tester.pump();

      // Tap Sign & Validate Clinical Report
      final signBtn = find.widgetWithText(ElevatedButton, 'Sign & Validate Clinical Report').first;
      await tester.ensureVisible(signBtn);
      await tester.tap(signBtn);
      await tester.pumpAndSettle();

      // Status badge and certificate should update
      expect(find.text('Signed & Verified by Dr. Aarav Mehta, MD'), findsOneWidget);
      expect(find.textContaining('Review completed. Confirmed pituitary microadenoma.'), findsOneWidget);
    });

    testWidgets('Doctor prescribes physiotherapy protocol from modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysioPrescribeDialog(
              patientName: 'Rahul Sharma',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Prescribe Physiotherapy Plan'), findsOneWidget);
      expect(find.text('Desk Worker Cervical Relief Routine'), findsOneWidget);
      expect(find.text('Lumbar Spine Core & Mobility Protocol'), findsOneWidget);

      // Tap prescribe button
      final prescribeBtn = find.widgetWithText(ElevatedButton, 'Prescribe Protocol to Patient');
      await tester.tap(prescribeBtn);
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.byType(PhysioPrescribeDialog), findsNothing);
    });

    testWidgets('Doctor opens Co-Pilot Telemetry dialog and displays AI synthesis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoctorCoPilotTelemetryDialog(
              patientName: 'Rahul Sharma',
              age: 48,
              gender: 'Male',
              aiService: aiService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Physician Co-Pilot Telemetry Summary'), findsOneWidget);
      expect(find.text('STABLE'), findsOneWidget);
      expect(find.textContaining('Rahul Sharma shows stable cardiac'), findsOneWidget);
      expect(find.text('Endocrine consult'), findsOneWidget);
    });
  });
}
