import '../core/api/api_client.dart';
import '../models/doctor_profile_model.dart';

class DoctorProfileService {
  final ApiClient _apiClient;

  DoctorProfileService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Retrieve the authenticated doctor's profile
  Future<DoctorProfileModel> getProfile() async {
    final res = await _apiClient.get('/doctors/me');
    final docData = res is Map<String, dynamic> && res.containsKey('profile')
        ? res['profile']
        : (res is Map<String, dynamic> && res.containsKey('doctor')
            ? res['doctor']
            : res);
    return DoctorProfileModel.fromJson(docData as Map<String, dynamic>);
  }

  /// Update permitted profile fields for the authenticated doctor
  Future<DoctorProfileModel> updateProfile({
    String? fullName,
    String? specialization,
    String? qualifications,
    int? experienceYears,
    double? consultationFee,
    String? bio,
    String? clinicAddress,
    String? hospitalAffiliation,
    List<String>? consultationModes,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (specialization != null) body['specialization'] = specialization;
    if (qualifications != null) body['qualifications'] = qualifications;
    if (experienceYears != null) body['experienceYears'] = experienceYears;
    if (consultationFee != null) body['consultationFee'] = consultationFee;
    if (bio != null) body['bio'] = bio;
    if (clinicAddress != null) body['clinicAddress'] = clinicAddress;
    if (hospitalAffiliation != null) body['hospitalAffiliation'] = hospitalAffiliation;
    if (consultationModes != null) body['consultationModes'] = consultationModes;

    final res = await _apiClient.patch('/doctors/me', body: body);
    final docData = res is Map<String, dynamic> && res.containsKey('profile')
        ? res['profile']
        : (res is Map<String, dynamic> && res.containsKey('doctor')
            ? res['doctor']
            : res);
    return DoctorProfileModel.fromJson(docData as Map<String, dynamic>);
  }

  /// Retrieve authenticated doctor's published availability slots
  Future<List<DoctorAvailabilityModel>> getAvailability() async {
    final res = await _apiClient.get('/doctors/me/availability');
    if (res is Map<String, dynamic> && res['availabilities'] is List) {
      return (res['availabilities'] as List)
          .map((item) => DoctorAvailabilityModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (res is List) {
      return res
          .map((item) => DoctorAvailabilityModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Create a new availability slot
  Future<DoctorAvailabilityModel> createAvailability({
    required int dayOfWeek,
    required DateTime startTime,
    required DateTime endTime,
    String status = 'AVAILABLE',
  }) async {
    final body = {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
    };

    final res = await _apiClient.post('/doctors/me/availability', body: body);
    final slotData = res is Map<String, dynamic> && res.containsKey('availability')
        ? res['availability']
        : res;
    return DoctorAvailabilityModel.fromJson(slotData as Map<String, dynamic>);
  }

  /// Delete an availability slot
  Future<void> deleteAvailability(String availabilityId) async {
    await _apiClient.delete('/doctors/me/availability/$availabilityId');
  }

  /// Toggle or update doctor's real-time duty status (On Duty vs Off Duty).
  /// Automatically ensures active consultation slots for today and tomorrow.
  Future<Map<String, dynamic>> setDutyStatus(bool isOnline) async {
    final res = await _apiClient.patch('/doctors/me/duty-status', body: {'isOnline': isOnline});
    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'isOnline': isOnline};
  }
}
