import '../core/api/api_client.dart';

class GovernmentHealthService {
  final ApiClient _apiClient;

  GovernmentHealthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // ==========================================
  // 1. ABDM & ABHA INTEGRATION (M1, M2, M3)
  // ==========================================

  /// Generate Aadhaar OTP for ABDM sandbox / verification
  Future<Map<String, dynamic>> generateAbhaOtp({required String aadhaarNumber}) async {
    try {
      final res = await _apiClient.post('/abdm/generate-otp', body: {
        'aadhaarNumber': aadhaarNumber,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  /// Create or Link ABHA ID with verified profile
  Future<Map<String, dynamic>> createOrLinkAbha({
    required String aadhaarNumber,
    required String otp,
    required String patientProfileId,
    String? preferredAbhaAddress,
  }) async {
    try {
      final res = await _apiClient.post('/abdm/create-or-link', body: {
        'aadhaarNumber': aadhaarNumber,
        'otp': otp,
        'patientProfileId': patientProfileId,
        if (preferredAbhaAddress != null && preferredAbhaAddress.isNotEmpty)
          'preferredAbhaAddress': preferredAbhaAddress,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch full ABHA profile, active consents, and linked FHIR records
  Future<Map<String, dynamic>?> getAbhaProfile(String patientProfileId) async {
    try {
      final res = await _apiClient.get('/abdm/profile/$patientProfileId');
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : null;
    } catch (_) {
      return null;
    }
  }

  /// Request ABDM consent artefact
  Future<Map<String, dynamic>> requestConsent({
    required String patientProfileId,
    required String requesterName,
    required String requesterType,
    required String purpose,
    required List<String> hiTypes,
    required String validTo,
  }) async {
    try {
      final res = await _apiClient.post('/abdm/consent/request', body: {
        'patientProfileId': patientProfileId,
        'requesterName': requesterName,
        'requesterType': requesterType,
        'purpose': purpose,
        'hiTypes': hiTypes,
        'validTo': validTo,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  /// Update Consent status (GRANTED, DENIED, REVOKED)
  Future<Map<String, dynamic>> updateConsentAction(String consentId, String action) async {
    try {
      final res = await _apiClient.patch('/abdm/consent/$consentId/action', body: {
        'action': action,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // 2. e-RaktKosh – VERIFIED BLOOD BANKS
  // ==========================================

  Future<List<Map<String, dynamic>>> getBloodBanks({
    String? state,
    String? bloodGroup,
    String? component,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (state != null && state.isNotEmpty && state != 'ALL') queryParams['state'] = state;
      if (bloodGroup != null && bloodGroup.isNotEmpty && bloodGroup != 'ALL') queryParams['bloodGroup'] = bloodGroup;
      if (component != null && component.isNotEmpty && component != 'ALL') queryParams['component'] = component;

      final res = await _apiClient.get('/government/blood-banks', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'];
        if (data is Map<String, dynamic> && data.containsKey('bloodBanks')) {
          return List<Map<String, dynamic>>.from(data['bloodBanks']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // 3. JAN AUSHADHI (PMBJP) GENERIC MEDICINES & KENDRAS
  // ==========================================

  Future<List<Map<String, dynamic>>> getJanAushadhiMedicines({
    String? query,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (query != null && query.isNotEmpty) queryParams['query'] = query;
      if (category != null && category.isNotEmpty && category != 'ALL') queryParams['category'] = category;

      final res = await _apiClient.get('/government/jan-aushadhi/medicines', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'];
        if (data is Map<String, dynamic> && data.containsKey('medicines')) {
          return List<Map<String, dynamic>>.from(data['medicines']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getJanAushadhiKendras({
    String? state,
    String? pincode,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (state != null && state.isNotEmpty && state != 'ALL') queryParams['state'] = state;
      if (pincode != null && pincode.isNotEmpty) queryParams['pincode'] = pincode;

      final res = await _apiClient.get('/government/jan-aushadhi/kendras', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'];
        if (data is Map<String, dynamic> && data.containsKey('kendras')) {
          return List<Map<String, dynamic>>.from(data['kendras']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // 4. PM-JAY AYUSHMAN BHARAT (ELIGIBILITY & PACKAGES)
  // ==========================================

  Future<Map<String, dynamic>> checkAyushmanEligibility({
    required String idType,
    required String idNumber,
  }) async {
    try {
      final res = await _apiClient.get('/government/pmjay/check-eligibility', queryParams: {
        'idType': idType,
        'idNumber': idNumber,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPmjayPackages({
    String? specialty,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (specialty != null && specialty.isNotEmpty && specialty != 'ALL') queryParams['specialty'] = specialty;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final res = await _apiClient.get('/government/pmjay/packages', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'];
        if (data is Map<String, dynamic> && data.containsKey('packages')) {
          return List<Map<String, dynamic>>.from(data['packages']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // 5. HFR & HPR DIRECTORIES
  // ==========================================

  Future<List<Map<String, dynamic>>> getHfrFacilities({
    String? state,
    String? facilityType,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (state != null && state.isNotEmpty && state != 'ALL') queryParams['state'] = state;
      if (facilityType != null && facilityType.isNotEmpty && facilityType != 'ALL') queryParams['facilityType'] = facilityType;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final res = await _apiClient.get('/government/hfr/facilities', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'];
        if (data is Map<String, dynamic> && data.containsKey('facilities')) {
          return List<Map<String, dynamic>>.from(data['facilities']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHprPractitioners({
    String? state,
    String? specialization,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (state != null && state.isNotEmpty && state != 'ALL') queryParams['state'] = state;
      if (specialization != null && specialization.isNotEmpty && specialization != 'ALL') queryParams['specialization'] = specialization;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final res = await _apiClient.get('/government/hpr/doctors', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'];
        if (data is Map<String, dynamic> && data.containsKey('practitioners')) {
          return List<Map<String, dynamic>>.from(data['practitioners']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // 6. UHI & OPD SCAN & SHARE
  // ==========================================

  Future<List<Map<String, dynamic>>> searchUhiSlots({
    String? hfrFacilityId,
    String? specialty,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (hfrFacilityId != null) queryParams['hfrFacilityId'] = hfrFacilityId;
      if (specialty != null) queryParams['specialty'] = specialty;

      final res = await _apiClient.get('/government/uhi/slots', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'];
        if (data is Map<String, dynamic> && data.containsKey('slots')) {
          return List<Map<String, dynamic>>.from(data['slots']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> scanAndShareOpd({
    required String hipId,
    required String patientProfileId,
    String? department,
    String? counterId,
  }) async {
    try {
      final res = await _apiClient.post('/government/opd/scan-and-share', body: {
        'hipId': hipId,
        'qrPayload': hipId,
        'patientProfileId': patientProfileId,
        if (department != null) 'department': department,
        if (counterId != null) 'counterId': counterId,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // 7. MOTHER & CHILD HEALTHCARE (MCH)
  // ==========================================

  Future<List<Map<String, dynamic>>> getMchProfiles(String patientProfileId) async {
    try {
      final res = await _apiClient.get('/mch/profiles/$patientProfileId');
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'];
        if (data is Map<String, dynamic> && data.containsKey('profiles')) {
          return List<Map<String, dynamic>>.from(data['profiles']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createMchProfile(Map<String, dynamic> profileData) async {
    try {
      final res = await _apiClient.post('/mch/profiles', body: profileData);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateVaccineStatus({
    required String recordId,
    required String vaccineName,
    required String status,
    String? doseNumber,
  }) async {
    try {
      final res = await _apiClient.patch('/mch/vaccine-status', body: {
        'recordId': recordId,
        'vaccineName': vaccineName,
        'status': status,
        if (doseNumber != null) 'doseNumber': doseNumber,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // 8. GOOGLE PLACES API NEARBY HEALTHCARE FINDER
  // ==========================================

  Future<Map<String, dynamic>> searchNearbyHealthcare({
    required double latitude,
    required double longitude,
    String? category,
    int? radiusMeters,
    String? keyword,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (radiusMeters != null) 'radiusMeters': radiusMeters.toString(),
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      };

      final res = await _apiClient.get('/places/nearby', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (_) {
      return {'places': [], 'total': 0};
    }
  }

  // ==========================================
  // 9. MULTILINGUAL GEMINI AI SERVICES
  // ==========================================

  Future<Map<String, dynamic>> summarizeHealthRecord({
    required String recordText,
    String language = 'en',
  }) async {
    try {
      final res = await _apiClient.post('/ai/summarize-record', body: {
        'recordText': recordText,
        'language': language,
      });
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return Map<String, dynamic>.from(res['data']);
      }
      return res is Map<String, dynamic> ? res : {};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> explainMedicineGeneric({
    required String medicineName,
    required String composition,
    String language = 'en',
  }) async {
    try {
      final res = await _apiClient.post('/ai/explain-medicine', body: {
        'medicineName': medicineName,
        'composition': composition,
        'language': language,
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

