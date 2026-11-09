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

  /// Retrieve driver operational profile and vehicle info
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await _apiClient.get('/drivers/me');
      return res['data']?['profile'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Super Admin: Retrieve all registered ambulance staff with verification details
  Future<List<Map<String, dynamic>>> getAdminDrivers({String? status, String? search}) async {
    try {
      final params = <String>[];
      if (status != null && status.isNotEmpty) params.add('status=$status');
      if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/admin/drivers$query');
      final list = res['data']?['staff'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Super Admin: Verify, reject, or update ambulance driver verification status
  Future<bool> verifyDriver(
    String driverId, {
    required String status,
    String? rejectionReason,
    String? notes,
  }) async {
    try {
      final res = await _apiClient.patch(
        '/admin/drivers/$driverId/verify',
        body: {
          'status': status,
          'rejectionReason': rejectionReason,
          'notes': notes,
        },
      );
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

