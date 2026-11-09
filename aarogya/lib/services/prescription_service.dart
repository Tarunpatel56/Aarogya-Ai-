import '../core/api/api_client.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  final ApiClient _apiClient;

  PrescriptionService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Retrieve all verified digital prescriptions for a patient
  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientProfileId) async {
    try {
      final res = await _apiClient.get('/prescriptions/patient/$patientProfileId');
      final list = res['data']?['prescriptions'] as List<dynamic>? ?? [];
      return list.map((json) => PrescriptionModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Retrieve a specific prescription by ID
  Future<PrescriptionModel?> getPrescriptionById(String id) async {
    try {
      final res = await _apiClient.get('/prescriptions/$id');
      final item = res['data']?['prescription'];
      if (item != null) {
        return PrescriptionModel.fromJson(item as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

