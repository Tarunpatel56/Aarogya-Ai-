import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aarogya/core/api/api_client.dart';
import 'package:aarogya/core/api/api_exception.dart';
import 'package:aarogya/core/storage/token_storage.dart';
import 'package:aarogya/services/ai_service.dart';

void main() {
  group('Patient App AiService Tests (Gemini & Groq)', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      tokenStorage.saveTokens(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
      );
    });

    test('sendChatMessage sends request and parses Gemini response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/ai/chat')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['message'], 'What is normal BP?');
          expect(body['language'], 'en');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'reply': 'Normal blood pressure for adults is typically around 120/80 mmHg.',
                'replyEn': 'Normal blood pressure for adults is typically around 120/80 mmHg.',
                'provider': 'gemini',
                'model': 'gemini-2.5-flash-lite',
                'disclaimer': 'Notice: Aarogya AI guidance is for informational reference only.',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, tokenStorage: tokenStorage);
      final aiService = AiService(apiClient: apiClient);

      final res = await aiService.sendChatMessage(
        message: 'What is normal BP?',
        language: 'en',
      );

      expect(res.reply, contains('120/80'));
      expect(res.provider, 'gemini');
      expect(res.model, 'gemini-2.5-flash-lite');
      expect(res.disclaimer, isNotEmpty);
    });

    test('analyzeMedicine parses extracted medicine metadata correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/ai/analyze-medicine')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'medicineName': 'Telmisartan Tablets IP',
                'genericName': 'Telmisartan',
                'dosage': '40mg',
                'dosageForm': 'Tablet',
                'frequency': 'Once daily',
                'purpose': 'Hypertension management',
                'instructions': 'Take in the evening with water.',
                'warnings': ['Avoid high-potassium supplements without consultation.'],
                'disclaimer': 'Notice: Aarogya AI guidance is for informational reference only.',
                'provider': 'gemini',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, tokenStorage: tokenStorage);
      final aiService = AiService(apiClient: apiClient);

      final res = await aiService.analyzeMedicine(
        ocrText: 'TELMISARTAN TABLETS IP 40mg',
      );

      expect(res.medicineName, 'Telmisartan Tablets IP');
      expect(res.dosage, '40mg');
      expect(res.warnings, contains('Avoid high-potassium supplements without consultation.'));
      expect(res.provider, 'gemini');
    });

    test('assessTriage returns urgency level and recommended action', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/ai/triage')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'urgencyLevel': 'HIGH',
                'summary': 'Acute chest tightness warrants immediate evaluation.',
                'recommendedAction': 'Consult your cardiologist or visit emergency triage.',
                'suggestedSpecialty': 'Cardiologist',
                'redFlags': ['Severe chest discomfort'],
                'disclaimer': 'Notice: Aarogya AI guidance is for informational reference only.',
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
      final aiService = AiService(apiClient: apiClient);

      final res = await aiService.assessTriage(
        symptoms: 'Sudden chest pain',
        severity: 'SEVERE',
      );

      expect(res.urgencyLevel, 'HIGH');
      expect(res.suggestedSpecialty, 'Cardiologist');
      expect(res.provider, 'groq');
    });

    test('handles network failure with clear ApiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'message': 'AI services temporarily degraded'},
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, tokenStorage: tokenStorage);
      final aiService = AiService(apiClient: apiClient);

      expect(
        () => aiService.sendChatMessage(message: 'Help'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
