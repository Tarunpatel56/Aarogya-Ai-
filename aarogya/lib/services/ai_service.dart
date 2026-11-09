import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/ai_response_model.dart';
import '../models/medical_report_model.dart';

class AiService {
  final ApiClient _apiClient;

  AiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Send message to the clinical AI assistant (Gemini & Groq fallback)
  Future<AiChatResponse> sendChatMessage({
    required String message,
    List<Map<String, String>>? history,
    String language = 'en',
    Map<String, dynamic>? patientVitals,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': message.trim(),
        'language': language,
      };

      if (history != null && history.isNotEmpty) {
        body['history'] = history;
      }
      if (patientVitals != null && patientVitals.isNotEmpty) {
        body['patientVitals'] = patientVitals;
      }

      final res = await _apiClient.post('/ai/chat', body: body);
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data'] as Map<String, dynamic>
          : res as Map<String, dynamic>;

      return AiChatResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unable to connect to Aarogya AI service. Please check your internet connection.',
        statusCode: 0,
      );
    }
  }

  /// Analyze medicine packaging or prescription OCR text
  Future<AiMedicineAnalysis> analyzeMedicine({
    required String ocrText,
    String language = 'en',
  }) async {
    try {
      final body = <String, dynamic>{
        'ocrText': ocrText.trim(),
        'language': language,
      };

      final res = await _apiClient.post('/ai/analyze-medicine', body: body);
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data'] as Map<String, dynamic>
          : res as Map<String, dynamic>;

      return AiMedicineAnalysis.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to analyze medication. Please try again.',
        statusCode: 0,
      );
    }
  }

  /// Analyze medicine packaging or strip directly from image bytes
  Future<AiMedicineAnalysis> analyzeMedicineImage({
    required List<int> imageBytes,
    String filename = 'medicine_strip.jpg',
    String language = 'en',
  }) async {
    try {
      final res = await _apiClient.postMultipart(
        '/ai/analyze-medicine-image',
        fileBytes: imageBytes,
        filename: filename,
        fieldName: 'image',
        fields: {'language': language},
      );
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data'] as Map<String, dynamic>
          : res as Map<String, dynamic>;

      return AiMedicineAnalysis.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to analyze medicine photo. Please try again.',
        statusCode: 0,
      );
    }
  }

  /// Perform symptom triage assessment
  Future<AiTriageResult> assessTriage({
    required String symptoms,
    String? duration,
    String severity = 'MODERATE',
    Map<String, dynamic>? vitals,
    String language = 'en',
  }) async {
    try {
      final body = <String, dynamic>{
        'symptoms': symptoms.trim(),
        'severity': severity,
        'language': language,
      };
      if (duration != null && duration.isNotEmpty) {
        body['duration'] = duration;
      }
      if (vitals != null && vitals.isNotEmpty) {
        body['vitals'] = vitals;
      }

      final res = await _apiClient.post('/ai/triage', body: body);
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data'] as Map<String, dynamic>
          : res as Map<String, dynamic>;

      return AiTriageResult.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Triage assessment unavailable. In an emergency, please visit the nearest hospital or call 108.',
        statusCode: 0,
      );
    }
  }

  /// Analyze diagnostic lab report from document image bytes
  Future<MedicalReportAnalysisResult> analyzeMedicalReportImage({
    required List<int> imageBytes,
    String filename = 'lab_report.jpg',
    String language = 'en',
  }) async {
    try {
      final res = await _apiClient.postMultipart(
        '/ai/analyze-report?language=$language',
        fileBytes: imageBytes,
        filename: filename,
        fieldName: 'image',
      );
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data'] as Map<String, dynamic>
          : res as Map<String, dynamic>;

      return MedicalReportAnalysisResult.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to analyze lab report image. Please try again.',
        statusCode: 0,
      );
    }
  }

  /// Analyze diagnostic lab report from raw text / OCR string
  Future<MedicalReportAnalysisResult> analyzeMedicalReportText({
    required String reportText,
    String language = 'en',
  }) async {
    try {
      final body = <String, dynamic>{
        'rawText': reportText.trim(),
        'language': language,
      };

      final res = await _apiClient.post('/ai/analyze-report', body: body);
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data'] as Map<String, dynamic>
          : res as Map<String, dynamic>;

      return MedicalReportAnalysisResult.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to analyze lab report text. Please try again.',
        statusCode: 0,
      );
    }
  }

  /// Check connectivity status of AI providers
  Future<Map<String, dynamic>> checkAiStatus() async {
    try {
      final res = await _apiClient.get('/ai/status');
      return res is Map<String, dynamic> && res.containsKey('data')
          ? res['data'] as Map<String, dynamic>
          : res as Map<String, dynamic>;
    } catch (_) {
      return {'gemini': {'configured': false}, 'groq': {'configured': false}};
    }
  }
}
