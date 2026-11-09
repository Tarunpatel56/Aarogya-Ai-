import '../core/api/api_client.dart';
import '../models/trip_model.dart';

class AmbulanceDispatchService {
  final ApiClient _apiClient;

  AmbulanceDispatchService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch pending emergency requests waiting for ambulance dispatch
  Future<List<EmergencyRequest>> getAvailableDispatches() async {
    try {
      final res = await _apiClient.get('/drivers/dispatches');
      final list = res['data']?['dispatches'] as List<dynamic>? ?? [];
      return list.map((json) => EmergencyRequest.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch trips assigned to this authenticated driver
  Future<List<EmergencyRequest>> getAssignedTrips() async {
    try {
      final res = await _apiClient.get('/drivers/me/trips');
      final list = res['data']?['trips'] as List<dynamic>? ?? [];
      return list.map((json) => EmergencyRequest.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Accept an emergency request and assign this ambulance
  Future<bool> acceptDispatch(String emergencyId) async {
    try {
      final res = await _apiClient.post('/drivers/trips/$emergencyId/accept');
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Update active trip milestone (EN_ROUTE, PATIENT_ON_BOARD, REACHED_HOSPITAL, COMPLETED)
  Future<bool> updateMilestone(
    String emergencyId, {
    required String status,
    double? latitude,
    double? longitude,
    String? vitalNotes,
    String? destinationHospitalId,
    String? destinationHospitalName,
  }) async {
    try {
      final res = await _apiClient.patch(
        '/drivers/me/trips/$emergencyId/status',
        body: {
          'status': status,
          'latitude': latitude,
          'longitude': longitude,
          'vitalNotes': vitalNotes,
          'destinationHospitalId': destinationHospitalId,
          'destinationHospitalName': destinationHospitalName,
        },
      );
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve nearby partner hospitals with live verified ICU beds
  Future<List<Map<String, dynamic>>> getNearbyHospitals({
    double lat = 28.5672,
    double lng = 77.2100,
  }) async {
    try {
      final res = await _apiClient.get('/hospitals/nearby?lat=$lat&lng=$lng');
      final list = res['data']?['hospitals'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

