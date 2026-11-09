import '../core/api/api_client.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final ApiClient _apiClient;

  DoctorService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Retrieve list of verified public doctors with optional filters
  Future<List<DoctorModel>> getDoctors({
    String? specialization,
    String? consultationMode,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (specialization != null && specialization.trim().isNotEmpty) {
      query['specialization'] = specialization.trim();
    }
    if (consultationMode != null && consultationMode.trim().isNotEmpty) {
      query['consultationMode'] = consultationMode.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final res = await _apiClient.get('/doctors', queryParams: query, includeAuth: false);

    if (res is Map<String, dynamic> && res['doctors'] is List) {
      return (res['doctors'] as List)
          .map((item) => DoctorModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (res is List) {
      return res
          .map((item) => DoctorModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Retrieve public profile of an individual verified doctor
  Future<DoctorModel> getDoctorById(String id) async {
    final res = await _apiClient.get('/doctors/$id', includeAuth: false);
    final docData = res is Map<String, dynamic> && res.containsKey('doctor')
        ? res['doctor']
        : res;
    return DoctorModel.fromJson(docData as Map<String, dynamic>);
  }

  /// Retrieve active availability slots for a verified doctor
  Future<List<DoctorAvailabilityModel>> getDoctorAvailability(String doctorProfileId) async {
    final res = await _apiClient.get(
      '/doctors/$doctorProfileId/availability',
      includeAuth: false,
    );

    dynamic list;
    if (res is Map<String, dynamic>) {
      if (res['availabilities'] is List) {
        list = res['availabilities'];
      } else if (res['data'] is Map && res['data']['availabilities'] is List) {
        list = res['data']['availabilities'];
      } else if (res['data'] is List) {
        list = res['data'];
      }
    } else if (res is List) {
      list = res;
    }

    if (list is List) {
      return list
          .map((item) => DoctorAvailabilityModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
