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
        final data = res['data'] as Map<String, dynamic>? ?? {};
        return data['stats'] as Map<String, dynamic>? ?? data;
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
        final users = (res['data']?['users'] as List<dynamic>?) ?? [];
        return users.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Approve or Reject a Doctor
  Future<bool> verifyDoctor(String doctorId, {required String status, String? notes}) async {
    try {
      final res = await _apiClient.patch(
        '/admin/doctors/$doctorId/verify',
        body: {
          'status': status,
          'notes': notes ?? (status == 'VERIFIED' ? 'Approved by Super Admin' : 'Rejected by Super Admin'),
        },
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
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final staff = (data['staff'] ?? data['ambulanceStaff']) as List<dynamic>? ?? [];
        return staff.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Approve or Reject an Ambulance Driver / Paramedic
  Future<bool> verifyAmbulanceStaff(String staffId, {required String status, String? rejectionReason, String? notes}) async {
    try {
      final res = await _apiClient.patch(
        '/admin/drivers/$staffId/verify',
        body: {
          'status': status,
          'rejectionReason': rejectionReason,
          'notes': notes ?? (status == 'VERIFIED' ? 'Approved by Super Admin' : 'Rejected by Super Admin'),
        },
      );
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
        final list = (res['data']?['emergencies'] as List<dynamic>?) ?? [];
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    try {
      final res = await _apiClient.get('/drivers/dispatches');
      if (res is Map<String, dynamic> && res['success'] == true) {
        final list = (res['data']?['dispatches'] as List<dynamic>?) ?? [];
        return list.cast<Map<String, dynamic>>();
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
        final users = (res['data']?['users'] as List<dynamic>?) ?? [];
        return users.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }
}
