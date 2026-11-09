import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/doctor_ai_model.dart';

class DoctorAiService {
  final ApiClient _apiClient;

  DoctorAiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch Clinical Co-Pilot patient and telemetry summary (Groq & Gemini)
  Future<ClinicalCoPilotInsight> fetchCoPilotSummary({
    required String patientName,
    int? age,
    String? gender,
    Map<String, dynamic>? telemetry,
    String? currentDiagnosis,
    List<String>? medications,
    String? recentObservations,
  }) async {
    try {
      final body = <String, dynamic>{
        'patientName': patientName.trim(),
      };
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;
      if (telemetry != null) body['telemetry'] = telemetry;
      if (currentDiagnosis != null) body['currentDiagnosis'] = currentDiagnosis;
      if (medications != null) body['medications'] = medications;
      if (recentObservations != null) body['recentObservations'] = recentObservations;

      final res = await _apiClient.post('/ai/copilot-summary', body: body);
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data'] as Map<String, dynamic>
          : res as Map<String, dynamic>;

      return ClinicalCoPilotInsight.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Clinical Co-Pilot service is currently unreachable.',
        statusCode: 0,
      );
    }
  }

  /// Clinical triage evaluation for incoming triage queue
  Future<Map<String, dynamic>> assessClinicalTriage({
    required String symptoms,
    String? duration,
    String severity = 'MODERATE',
    Map<String, dynamic>? vitals,
  }) async {
    try {
      final body = <String, dynamic>{
        'symptoms': symptoms.trim(),
        'severity': severity,
      };
      if (duration != null) body['duration'] = duration;
      if (vitals != null) body['vitals'] = vitals;

      final res = await _apiClient.post('/ai/triage', body: body);
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data'] as Map<String, dynamic>
          : res as Map<String, dynamic>;

      return data;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Triage evaluation unavailable.',
        statusCode: 0,
      );
    }
  }
}
