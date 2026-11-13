import '../core/api/api_client.dart';

class ReferralService {
  final ApiClient _apiClient;

  ReferralService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Retrieve all incoming and outgoing referrals for a doctor
  Future<Map<String, dynamic>> getDoctorReferrals(String doctorId) async {
    try {
      final res = await _apiClient.get('/referrals/doctor/$doctorId');
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {'incoming': [], 'outgoing': []};
    } catch (_) {
      return {'incoming': [], 'outgoing': []};
    }
  }

  /// Create a new Inter-Doctor Clinical Referral
  Future<Map<String, dynamic>> createReferral({
    required String referringDoctorId,
    required String targetDoctorId,
    required String patientProfileId,
    required String specialtyRequired,
    required String clinicalReason,
    String priority = 'ROUTINE',
    String? clinicalSummary,
  }) async {
    try {
      final res = await _apiClient.post('/referrals', body: {
        'referringDoctorId': referringDoctorId,
        'targetDoctorId': targetDoctorId,
        'patientProfileId': patientProfileId,
        'specialtyRequired': specialtyRequired,
        'clinicalReason': clinicalReason,
        'priority': priority,
        if (clinicalSummary != null) 'clinicalSummary': clinicalSummary,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  /// Respond to incoming referral (ACCEPTED or REJECTED)
  Future<Map<String, dynamic>> respondToReferral({
    required String referralId,
    required String action,
    String? responseNotes,
  }) async {
    try {
      final res = await _apiClient.patch('/referrals/$referralId/respond', body: {
        'action': action,
        if (responseNotes != null) 'responseNotes': responseNotes,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  /// Generate AI Clinical Case Summary for referral
  Future<Map<String, dynamic>> generateAiCaseSummary({
    required String patientName,
    required Map<String, dynamic> clinicalData,
  }) async {
    try {
      final res = await _apiClient.post('/ai/clinical-case-summary', body: {
        'patientName': patientName,
        'clinicalData': clinicalData,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }
}

