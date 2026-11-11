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

  /// Retrieve all platform appointments (Feature 87)
  Future<List<Map<String, dynamic>>> getAppointments({String? status}) async {
    try {
      final query = (status != null && status != 'ALL') ? '?status=$status' : '';
      final res = await _apiClient.get('/admin/appointments$query');
      if (res is Map<String, dynamic> && res['success'] == true) {
        final raw = res['data']?['appointments'];
        if (raw is List) return raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Retrieve real-time system health telemetry (Feature 94)
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final res = await _apiClient.get('/admin/system/health');
      if (res is Map<String, dynamic> && res['success'] == true) {
        return res['data'] as Map<String, dynamic>? ?? {};
      }
    } catch (_) {}
    return {};
  }

  /// Retrieve privileged audit logs (Feature 95)
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    try {
      final res = await _apiClient.get('/admin/audit-logs');
      if (res is Map<String, dynamic> && res['success'] == true) {
        final raw = res['data']?['auditLogs'] ?? res['data'];
        if (raw is List) return raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Retrieve user feedback & issue reports (Feature 91)
  Future<List<Map<String, dynamic>>> getFeedback() async {
    try {
      final res = await _apiClient.get('/admin/feedback');
      if (res is Map<String, dynamic> && res['success'] == true) {
        final raw = res['data']?['feedback'];
        if (raw is List) return raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Post platform announcement (Feature 90)
  Future<bool> postAnnouncement({required String title, required String message, String priority = 'INFO'}) async {
    try {
      final res = await _apiClient.post('/admin/announcements', body: {
        'title': title,
        'message': message,
        'priority': priority,
      });
      return res is Map<String, dynamic> && res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve global platform configuration & backup status (Features 97, 100)
  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final res = await _apiClient.get('/admin/system/settings');
      if (res is Map<String, dynamic> && res['success'] == true) {
        return res['data']?['settings'] as Map<String, dynamic>? ?? {};
      }
    } catch (_) {}
    return {};
  }

  /// Update platform settings
  Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      final res = await _apiClient.patch('/admin/system/settings', body: settings);
      return res is Map<String, dynamic> && res['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

