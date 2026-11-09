import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/hospital_model.dart';

class HospitalService {
  final ApiClient _apiClient;

  HospitalService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch nearby verified hospitals with live verified ICU beds
  Future<List<HospitalModel>> getNearbyHospitals({
    double? latitude,
    double? longitude,
    double? radiusKm,
    bool? emergencyBay,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (radiusKm != null) queryParams['radiusKm'] = radiusKm;
      if (emergencyBay != null) queryParams['emergencyBay'] = emergencyBay;

      final res = await _apiClient.get(
        '/hospitals/nearby',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data']
          : res;

      if (data is Map<String, dynamic> && data['hospitals'] is List) {
        return (data['hospitals'] as List)
            .map((item) => HospitalModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to load nearby hospitals: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Get single hospital detail
  Future<HospitalModel> getHospitalById(String id) async {
    try {
      final res = await _apiClient.get('/hospitals/$id');
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data']
          : res;

      if (data is Map<String, dynamic> && data['hospital'] != null) {
        return HospitalModel.fromJson(data['hospital'] as Map<String, dynamic>);
      }
      throw Exception('Invalid hospital data returned');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to load hospital details: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

