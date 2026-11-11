import 'dart:convert';
import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';

class SuperAdminService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  SuperAdminService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  ApiClient get apiClient => _apiClient;
  TokenStorage get tokenStorage => _tokenStorage;

  /// Super Admin Login
  Future<bool> login({required String email, required String password}) async {
    final res = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
      requiresAuth: false,
    );

    if (res is Map<String, dynamic> && res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final tokens = data['tokens'] as Map<String, dynamic>? ?? {};
      final accessToken = tokens['accessToken']?.toString() ?? '';
      final refreshToken = tokens['refreshToken']?.toString() ?? '';
      final user = data['user'] as Map<String, dynamic>? ?? {};

      if (accessToken.isNotEmpty) {
        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await _tokenStorage.saveAdminInfo(jsonEncode(user));
        return true;
      }
    }
    return false;
  }

  /// Check if active Super Admin session exists
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasValidToken();
  }

  /// Logout
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  /// Retrieve system-wide statistics (Platform Health, Active SOS, Registered Users)
  Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      final res = await _apiClient.get('/admin/stats');
      if (res is Map<String, dynamic> && res['success'] == true) {
        final data = res['data'];
        if (data is Map<String, dynamic>) {
          return data['stats'] as Map<String, dynamic>? ?? data;
        }
      }
    } catch (_) {}
    return {};
  }

  /// Retrieve all doctors (with verificationStatus filter: PENDING, VERIFIED, REJECTED)
  Future<List<Map<String, dynamic>>> getDoctors({String? verificationStatus, String? search}) async {
    try {
      final queryParams = <String>[];
      queryParams.add('role=DOCTOR');
      if (verificationStatus != null && verificationStatus != 'ALL') {
        queryParams.add('verificationStatus=$verificationStatus');
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search.trim())}');
      }
      queryParams.add('limit=50');

      final url = '/admin/users?${queryParams.join('&')}';
      final res = await _apiClient.get(url);
      if (res is Map<String, dynamic> && res['success'] == true) {
        final raw = res['data']?['users'] ?? res['data']?['doctors'] ?? res['data'];
        if (raw is List) {
          return raw.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Approve or Reject a Doctor
  Future<bool> verifyDoctor(String doctorId, {required String status, String? notes}) async {
    try {
      final body = <String, dynamic>{
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      final res = await _apiClient.patch(
        '/admin/doctors/$doctorId/verify',
        body: body,
      );
      return res is Map<String, dynamic> && res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve all ambulance staff (drivers & paramedics with documents and verification status)
  Future<List<Map<String, dynamic>>> getAmbulanceStaff({String? status, String? search}) async {
    try {
      final queryParams = <String>[];
      if (status != null && status != 'ALL') {
        queryParams.add('status=$status');
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search.trim())}');
      }

      final url = '/admin/drivers${queryParams.isNotEmpty ? "?${queryParams.join('&')}" : ""}';
      final res = await _apiClient.get(url);
      if (res is Map<String, dynamic> && res['success'] == true) {
        // Robust fallback checking both 'ambulanceStaff', 'staff', or root list
        final raw = res['data']?['ambulanceStaff'] ?? res['data']?['staff'] ?? res['data'];
        if (raw is List) {
          return raw.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Approve or Reject an Ambulance Driver / Paramedic
  Future<bool> verifyAmbulanceStaff(String staffId, {required String status, String? rejectionReason, String? notes}) async {
    try {
      final body = <String, dynamic>{
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (rejectionReason != null && rejectionReason.isNotEmpty) 'rejectionReason': rejectionReason,
      };
      final res = await _apiClient.patch(
        '/admin/drivers/$staffId/verify',
        body: body,
      );
      return res is Map<String, dynamic> && res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Permanently delete an ID/Account (Doctor, Driver, Patient)
  Future<bool> deleteUser(String userId) async {
    try {
      final res = await _apiClient.delete('/admin/users/$userId');
      return res is Map<String, dynamic> && res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve active SOS emergencies and live dispatches
  Future<List<Map<String, dynamic>>> getActiveEmergencies() async {
    try {
      final res = await _apiClient.get('/admin/emergencies');
      if (res is Map<String, dynamic> && res['success'] == true) {
        final raw = res['data']?['emergencies'] ?? res['data']?['dispatches'] ?? res['data'];
        if (raw is List) {
          return raw.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Retrieve registered patients list
  Future<List<Map<String, dynamic>>> getPatients({String? search}) async {
    try {
      final queryParams = <String>[];
      queryParams.add('role=PATIENT');
      if (search != null && search.trim().isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search.trim())}');
      }
      queryParams.add('limit=50');

      final url = '/admin/users?${queryParams.join('&')}';
      final res = await _apiClient.get(url);
      if (res is Map<String, dynamic> && res['success'] == true) {
        final raw = res['data']?['users'] ?? res['data']?['patients'] ?? res['data'];
        if (raw is List) {
          return raw.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return [];
  }
}

