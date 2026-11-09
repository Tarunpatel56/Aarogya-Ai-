import '../core/api/api_client.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  final ApiClient _apiClient;

  PrescriptionService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Create and digitally sign a prescription for a patient
  Future<PrescriptionModel> createPrescription({
    required String patientProfileId,
    String? appointmentId,
    required String diagnosis,
    String? doctorNotes,
    String? generalAdvice,
    DateTime? followUpDate,
    String? digitalSignature,
    required List<PrescriptionItemModel> items,
  }) async {
    final body = {
      'patientProfileId': patientProfileId,
      'appointmentId': appointmentId,
      'diagnosis': diagnosis,
      'doctorNotes': doctorNotes,
      'generalAdvice': generalAdvice,
      'followUpDate': followUpDate?.toIso8601String(),
      'digitalSignature': digitalSignature,
      'items': items.map((i) => i.toJson()).toList(),
    };

    final res = await _apiClient.post('/prescriptions', body: body);
    final data = res['data']?['prescription'] ?? res;
    return PrescriptionModel.fromJson(data as Map<String, dynamic>);
  }

  /// Retrieve prescriptions authored by the authenticated doctor
  Future<List<PrescriptionModel>> getDoctorPrescriptions() async {
    try {
      final res = await _apiClient.get('/prescriptions/doctor/me');
      final list = res['data']?['prescriptions'] as List<dynamic>? ?? [];
      return list.map((json) => PrescriptionModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Retrieve prescriptions for a specific patient
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientProfileId) async {
    try {
      final res = await _apiClient.get('/prescriptions/patient/$patientProfileId');
      final list = res['data']?['prescriptions'] as List<dynamic>? ?? [];
      return list.map((json) => PrescriptionModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}

