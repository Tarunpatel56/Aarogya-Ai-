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

    dynamic list;
    if (res is Map<String, dynamic>) {
      if (res['doctors'] is List) {
        list = res['doctors'];
      } else if (res['data'] is Map && res['data']['doctors'] is List) {
        list = res['data']['doctors'];
      } else if (res['data'] is List) {
        list = res['data'];
      }
    } else if (res is List) {
      list = res;
    }

    if (list is List) {
      return list
          .map((item) => DoctorModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Retrieve public profile of an individual verified doctor
  Future<DoctorModel> getDoctorById(String id) async {
    final res = await _apiClient.get('/doctors/$id', includeAuth: false);
    dynamic docData;
    if (res is Map<String, dynamic>) {
      if (res['doctor'] != null) {
        docData = res['doctor'];
      } else if (res['data'] is Map && res['data']['doctor'] != null) {
        docData = res['data']['doctor'];
      } else if (res['data'] is Map) {
        docData = res['data'];
      } else {
        docData = res;
      }
    } else {
      docData = res;
    }
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
