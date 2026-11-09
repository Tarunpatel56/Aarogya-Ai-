import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aarogya_healthpro/core/api/api_client.dart';
import 'package:aarogya_healthpro/core/api/api_exception.dart';
import 'package:aarogya_healthpro/core/storage/token_storage.dart';
import 'package:aarogya_healthpro/services/doctor_ai_service.dart';

void main() {
  group('Doctor App DoctorAiService Tests (Groq & Gemini)', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      tokenStorage.saveTokens(
        accessToken: 'mock-doctor-token',
        refreshToken: 'mock-doctor-refresh',
      );
    });

    test('fetchCoPilotSummary calls /ai/copilot-summary and parses insight', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/ai/copilot-summary')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['patientName'], 'Rahul Sharma');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'clinicalSummary': 'Patient shows stable telemetry with controlled BP on Telmisartan.',
                'riskAssessment': 'STABLE',
                'suggestedInterventions': ['Maintain current dosing', 'Log BP weekly'],
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

      final apiClient = ApiClient(httpClient: mockClient, tokenStorage: tokenStorage);
      final aiService = DoctorAiService(apiClient: apiClient);

      final insight = await aiService.fetchCoPilotSummary(
        patientName: 'Rahul Sharma',
        age: 45,
        gender: 'Male',
        currentDiagnosis: 'Hypertension',
      );

      expect(insight.clinicalSummary, contains('stable telemetry'));
      expect(insight.riskAssessment, 'STABLE');
      expect(insight.provider, 'groq');
      expect(insight.suggestedInterventions, contains('Maintain current dosing'));
    });

    test('assessClinicalTriage sends clinical telemetry and parses urgency', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/ai/triage')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'urgencyLevel': 'EMERGENCY',
                'summary': 'Critical vital signs indicate immediate resuscitation pathway.',
                'recommendedAction': 'Route to Red Bay Triage immediately.',
                'suggestedSpecialty': 'Emergency Medicine',
                'redFlags': ['SpO2 < 88% on room air'],
                'provider': 'groq',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, tokenStorage: tokenStorage);
      final aiService = DoctorAiService(apiClient: apiClient);

      final result = await aiService.assessClinicalTriage(
        symptoms: 'Severe respiratory distress',
        severity: 'SEVERE',
        vitals: {'heartRate': 130, 'spo2': 86},
      );

      expect(result['urgencyLevel'], 'EMERGENCY');
      expect(result['suggestedSpecialty'], 'Emergency Medicine');
    });

    test('throws ApiException on unauthorized or forbidden access', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'message': 'Access denied: Requires DOCTOR role'},
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, tokenStorage: tokenStorage);
      final aiService = DoctorAiService(apiClient: apiClient);

      expect(
        () => aiService.fetchCoPilotSummary(patientName: 'Jane Doe'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
