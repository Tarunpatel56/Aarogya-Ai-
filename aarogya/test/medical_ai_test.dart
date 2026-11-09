import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:aarogya/models/medical_analysis_model.dart';
import 'package:aarogya/services/medical_ai_service.dart';
import 'package:aarogya/services/sample_medical_images.dart';
import 'package:aarogya/screens/ai/brain_mri_screen.dart';
import 'package:aarogya/screens/ai/lung_xray_screen.dart';
import 'package:aarogya/screens/ai/skin_analysis_screen.dart';
import 'package:aarogya/core/api/api_client.dart';
import 'package:aarogya/core/storage/token_storage.dart';

class MockMultipartHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;

  MockMultipartHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('MedicalAnalysisModel Tests', () {
    final sampleJson = {
      'analysisType': 'BRAIN_MRI',
      'provider': 'Hugging Face Hosted Inference',
      'model': 'Hemgg/brain-tumor-classification',
      'primaryFinding': {
        'label': 'glioma',
        'normalizedLabel': 'Glioma',
        'score': 0.9421,
        'description': 'Features suggestive of glial cell lesion.',
      },
      'allPredictions': [
        {'label': 'glioma', 'normalizedLabel': 'Glioma', 'score': 0.9421},
        {'label': 'meningioma', 'normalizedLabel': 'Meningioma', 'score': 0.0412},
        {'label': 'pituitary', 'normalizedLabel': 'Pituitary Tumor', 'score': 0.0125},
        {'label': 'notumor', 'normalizedLabel': 'No Tumor Detected', 'score': 0.0042},
      ],
      'findingsSummary': 'Primary prediction: Glioma (94.2% confidence).',
      'clinicalDisclaimer':
          'Brain MRI AI screening is an assistive computational tool and does not constitute a definitive radiological diagnosis.',
      'mandatoryClinicalNotice': null,
      'analyzedAt': '2026-10-28T10:00:00.000Z',
    };

    test('deserializes MedicalAnalysisResult correctly from JSON', () {
      final result = MedicalAnalysisResult.fromJson(sampleJson);
      expect(result.analysisType, 'BRAIN_MRI');
      expect(result.provider, 'Hugging Face Hosted Inference');
      expect(result.model, 'Hemgg/brain-tumor-classification');
      expect(result.primaryFinding.normalizedLabel, 'Glioma');
      expect(result.primaryFinding.score, 0.9421);
      expect(result.primaryFinding.formattedConfidence, '94.2%');
      expect(result.primaryFinding.description, contains('glial cell lesion'));
      expect(result.allPredictions.length, 4);
      expect(result.isNormal, false);
      expect(result.clinicalDisclaimer, contains('Brain MRI AI screening'));
    });

    test('isNormal evaluates true for No Tumor Detected and Normal labels', () {
      final normalMriJson = Map<String, dynamic>.from(sampleJson);
      normalMriJson['primaryFinding'] = {
        'label': 'notumor',
        'normalizedLabel': 'No Tumor Detected',
        'score': 0.985,
      };
      final result = MedicalAnalysisResult.fromJson(normalMriJson);
      expect(result.isNormal, true);
    });

    test('deserializes Lung X-ray result with mandatoryClinicalNotice', () {
      final lungJson = {
        'analysisType': 'CHEST_XRAY',
        'provider': 'Hugging Face Hosted Inference',
        'model': 'dima806/chest_xray_pneumonia_detection',
        'primaryFinding': {
          'label': 'NORMAL',
          'normalizedLabel': 'Normal (No Pneumonia Features)',
          'score': 0.9765,
          'description': 'No acute consolidations detected.',
        },
        'allPredictions': [
          {'label': 'NORMAL', 'normalizedLabel': 'Normal (No Pneumonia Features)', 'score': 0.9765},
          {'label': 'PNEUMONIA', 'normalizedLabel': 'Pneumonia Detected', 'score': 0.0235},
        ],
        'findingsSummary': 'Primary finding: Normal (97.7% confidence).',
        'clinicalDisclaimer': 'Chest radiograph AI analysis is an assistive screening aid.',
        'mandatoryClinicalNotice':
            'CRITICAL CLINICAL NOTICE: A "NORMAL" classification DOES NOT rule out other pulmonary pathologies.',
        'analyzedAt': '2026-10-28T10:00:00.000Z',
      };

      final result = MedicalAnalysisResult.fromJson(lungJson);
      expect(result.analysisType, 'CHEST_XRAY');
      expect(result.isNormal, true);
      expect(result.mandatoryClinicalNotice, contains('DOES NOT rule out other pulmonary pathologies'));
    });
  });

  group('MedicalAiService Integration Tests', () {
    test('analyzeBrainMri posts multipart to /ai/mri-analysis and parses result', () async {
      final mockClient = MockMultipartHttpClient((request) async {
        expect(request.url.path, endsWith('/ai/mri-analysis'));
        expect(request.method, 'POST');

        final responseBody = jsonEncode({
          'success': true,
          'data': {
            'analysisType': 'BRAIN_MRI',
            'provider': 'Hugging Face',
            'model': 'Hemgg/brain-tumor-classification',
            'primaryFinding': {
              'label': 'glioma',
              'normalizedLabel': 'Glioma',
              'score': 0.95,
              'description': 'Glial proliferative pattern.',
            },
            'allPredictions': [
              {'label': 'glioma', 'normalizedLabel': 'Glioma', 'score': 0.95},
            ],
            'findingsSummary': 'Glioma detected',
            'clinicalDisclaimer': 'Assistive screening only.',
            'analyzedAt': DateTime.now().toIso8601String(),
          },
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage(),
      );
      final service = MedicalAiService(apiClient: apiClient);

      final result = await service.analyzeBrainMri(
        imageBytes: SampleMedicalImages.sampleGliomaMri,
        filename: 'scan.png',
      );

      expect(result.analysisType, 'BRAIN_MRI');
      expect(result.primaryFinding.normalizedLabel, 'Glioma');
      expect(result.primaryFinding.score, 0.95);
    });

    test('analyzeLungXray posts multipart to /ai/lung-analysis', () async {
      final mockClient = MockMultipartHttpClient((request) async {
        expect(request.url.path, endsWith('/ai/lung-analysis'));

        final responseBody = jsonEncode({
          'success': true,
          'data': {
            'analysisType': 'CHEST_XRAY',
            'provider': 'Hugging Face',
            'model': 'dima806/chest_xray_pneumonia_detection',
            'primaryFinding': {
              'label': 'NORMAL',
              'normalizedLabel': 'Normal (No Pneumonia Features)',
              'score': 0.98,
            },
            'allPredictions': [
              {'label': 'NORMAL', 'normalizedLabel': 'Normal', 'score': 0.98},
            ],
            'findingsSummary': 'Normal radiograph',
            'clinicalDisclaimer': 'Assistive screening only.',
            'mandatoryClinicalNotice': 'NORMAL does not exclude other pathologies.',
            'analyzedAt': DateTime.now().toIso8601String(),
          },
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage(),
      );
      final service = MedicalAiService(apiClient: apiClient);

      final result = await service.analyzeLungXray(
        imageBytes: SampleMedicalImages.samplePneumoniaXray,
      );

      expect(result.analysisType, 'CHEST_XRAY');
      expect(result.mandatoryClinicalNotice, contains('NORMAL does not exclude'));
    });

    test('analyzeSkinImage posts multipart to /ai/skin-analysis', () async {
      final mockClient = MockMultipartHttpClient((request) async {
        expect(request.url.path, endsWith('/ai/skin-analysis'));

        final responseBody = jsonEncode({
          'success': true,
          'data': {
            'analysisType': 'SKIN_IMAGE',
            'provider': 'Hugging Face',
            'model': 'Tanishq77/skin-condition-classifier',
            'primaryFinding': {
              'label': 'eczema',
              'normalizedLabel': 'Eczema',
              'score': 0.89,
            },
            'allPredictions': [
              {'label': 'eczema', 'normalizedLabel': 'Eczema', 'score': 0.89},
            ],
            'findingsSummary': 'Eczema finding',
            'clinicalDisclaimer': 'Sensitive to lighting and phototype.',
            'analyzedAt': DateTime.now().toIso8601String(),
          },
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        tokenStorage: InMemoryTokenStorage(),
      );
      final service = MedicalAiService(apiClient: apiClient);

      final result = await service.analyzeSkinImage(
        imageBytes: SampleMedicalImages.sampleEczemaSkin,
      );

      expect(result.analysisType, 'SKIN_IMAGE');
      expect(result.primaryFinding.normalizedLabel, 'Eczema');
    });
  });

  group('Medical AI Screens Widget Tests', () {
    testWidgets('BrainMriScreen renders initial state and runs analysis', (tester) async {
      final mockClient = MockMultipartHttpClient((request) async {
        final responseBody = jsonEncode({
          'success': true,
          'data': {
            'analysisType': 'BRAIN_MRI',
            'provider': 'Hugging Face',
            'model': 'Hemgg/brain-tumor-classification',
            'primaryFinding': {
              'label': 'glioma',
              'normalizedLabel': 'Glioma',
              'score': 0.942,
              'description': 'Features suggestive of glial cell proliferative lesion.',
            },
            'allPredictions': [
              {'label': 'glioma', 'normalizedLabel': 'Glioma', 'score': 0.942},
              {'label': 'notumor', 'normalizedLabel': 'No Tumor Detected', 'score': 0.058},
            ],
            'findingsSummary': 'Glioma (94.2% confidence)',
            'clinicalDisclaimer':
                'Brain MRI AI screening is an assistive computational tool and does not constitute a definitive radiological diagnosis.',
            'analyzedAt': DateTime.now().toIso8601String(),
          },
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MedicalAiService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: InMemoryTokenStorage()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BrainMriScreen(
            medicalAiService: service,
            initialImageBytes: SampleMedicalImages.sampleGliomaMri,
            initialImageName: 'sample_glioma.png',
          ),
        ),
      );

      expect(find.text('Brain MRI Tumor Analysis'), findsOneWidget);
      expect(find.text('Brain MRI Analysis'), findsOneWidget);
      expect(find.text('Run Brain MRI Analysis'), findsOneWidget);

      // Tap Run Brain MRI Analysis
      await tester.tap(find.text('Run Brain MRI Analysis'));
      await tester.pump(); // Start request

      await tester.pump(const Duration(milliseconds: 100)); // Finish async
      await tester.pumpAndSettle();

      // Check results
      expect(find.text('Glioma'), findsWidgets);
      expect(find.text('Confidence: 94.2%'), findsOneWidget);
      expect(find.text('Features suggestive of glial cell proliferative lesion.'), findsOneWidget);
      expect(find.textContaining('Brain MRI AI screening is an assistive computational tool'), findsOneWidget);
      expect(find.text('Consult Neurologist'), findsOneWidget);
    });

    testWidgets('LungXrayScreen renders and displays critical negative ruling notice', (tester) async {
      final mockClient = MockMultipartHttpClient((request) async {
        final responseBody = jsonEncode({
          'success': true,
          'data': {
            'analysisType': 'CHEST_XRAY',
            'provider': 'Hugging Face',
            'model': 'dima806/chest_xray_pneumonia_detection',
            'primaryFinding': {
              'label': 'NORMAL',
              'normalizedLabel': 'Normal (No Pneumonia Features)',
              'score': 0.985,
              'description': 'No acute radiographic consolidations detected.',
            },
            'allPredictions': [
              {'label': 'NORMAL', 'normalizedLabel': 'Normal (No Pneumonia Features)', 'score': 0.985},
            ],
            'findingsSummary': 'Normal (98.5% confidence)',
            'clinicalDisclaimer': 'Chest radiograph AI analysis is an assistive screening aid.',
            'mandatoryClinicalNotice':
                'CRITICAL CLINICAL NOTICE: A "NORMAL" classification DOES NOT rule out other pulmonary pathologies.',
            'analyzedAt': DateTime.now().toIso8601String(),
          },
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MedicalAiService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: InMemoryTokenStorage()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LungXrayScreen(
            medicalAiService: service,
            initialImageBytes: SampleMedicalImages.samplePneumoniaXray,
          ),
        ),
      );

      expect(find.text('Chest X-Ray Pulmonary Screening'), findsOneWidget);
      expect(find.text('Pulmonary Radiograph AI'), findsOneWidget);

      await tester.tap(find.text('Analyze Chest X-Ray'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Normal (No Pneumonia Features)'), findsWidgets);
      expect(find.textContaining('DOES NOT rule out other pulmonary pathologies'), findsOneWidget);
      expect(find.text('Consult Pulmonologist'), findsOneWidget);
    });

    testWidgets('SkinAnalysisScreen renders and shows dermatological disclaimer', (tester) async {
      final mockClient = MockMultipartHttpClient((request) async {
        final responseBody = jsonEncode({
          'success': true,
          'data': {
            'analysisType': 'SKIN_IMAGE',
            'provider': 'Hugging Face',
            'model': 'Tanishq77/skin-condition-classifier',
            'primaryFinding': {
              'label': 'eczema',
              'normalizedLabel': 'Eczema',
              'score': 0.885,
              'description': 'Dermatological pattern analysis suggests features consistent with Eczema.',
            },
            'allPredictions': [
              {'label': 'eczema', 'normalizedLabel': 'Eczema', 'score': 0.885},
            ],
            'findingsSummary': 'Eczema (88.5% confidence)',
            'clinicalDisclaimer':
                'Dermatological image classification is sensitive to lighting and does NOT replace biopsy.',
            'analyzedAt': DateTime.now().toIso8601String(),
          },
        });

        return http.StreamedResponse(
          Stream.value(utf8.encode(responseBody)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MedicalAiService(
        apiClient: ApiClient(httpClient: mockClient, tokenStorage: InMemoryTokenStorage()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SkinAnalysisScreen(
            medicalAiService: service,
            initialImageBytes: SampleMedicalImages.sampleEczemaSkin,
          ),
        ),
      );

      expect(find.text('Dermatological Analysis'), findsOneWidget);
      expect(find.text('Dermatological AI Screening'), findsOneWidget);

      await tester.tap(find.text('Analyze Skin Image'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Eczema'), findsWidgets);
      expect(find.textContaining('sensitive to lighting and does NOT replace biopsy'), findsOneWidget);
      expect(find.text('Consult Dermatologist'), findsOneWidget);
    });
  });
}
