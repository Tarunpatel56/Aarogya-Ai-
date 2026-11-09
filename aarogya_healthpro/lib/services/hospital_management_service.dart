import '../core/api/api_client.dart';
import '../models/hospital_bed_model.dart';

class HospitalManagementService {
  final ApiClient _apiClient;

  HospitalManagementService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Retrieve granular ward & bed inventory for a hospital
  Future<List<HospitalBedModel>> getHospitalBeds(String hospitalId) async {
    try {
      final res = await _apiClient.get('/hospitals/$hospitalId/beds');
      final list = res['data']?['beds'] as List<dynamic>? ?? [];
      return list.map((json) => HospitalBedModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Update bed status (AVAILABLE, OCCUPIED, MAINTENANCE, RESERVED)
  Future<HospitalBedModel?> updateBedStatus({
    required String hospitalId,
    required String bedId,
    required String status,
    String? occupiedByPatient,
    String? notes,
  }) async {
    try {
      final res = await _apiClient.patch(
        '/hospitals/$hospitalId/beds/$bedId',
        body: {
          'status': status,
          'occupiedByPatient': occupiedByPatient,
          'notes': notes,
        },
      );
      final bedData = res['data']?['bed'];
      if (bedData != null) {
        return HospitalBedModel.fromJson(bedData as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Retrieve hospital profile and summary metrics
  Future<Map<String, dynamic>?> getHospitalDetails(String hospitalId) async {
    try {
      final res = await _apiClient.get('/hospitals/$hospitalId');
      return res['data']?['hospital'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}

