import '../core/api/api_client.dart';

class AdminService {
  final ApiClient _apiClient;

  AdminService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Retrieve platform-wide operational statistics
  Future<Map<String, dynamic>> getStats() async {
    final res = await _apiClient.get('/admin/stats');
    if (res is Map<String, dynamic>) {
      return res;
    }
    return {};
  }

  /// Query users with filtering and search
  Future<Map<String, dynamic>> getUsers({
    String? role,
    String? verificationStatus,
    bool? isActive,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (role != null && role != 'ALL') query['role'] = role;
    if (verificationStatus != null && verificationStatus != 'ALL') {
      query['verificationStatus'] = verificationStatus;
    }
    if (isActive != null) query['isActive'] = isActive;
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final res = await _apiClient.get('/admin/users', queryParams: query);
    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'users': [], 'pagination': {'total': 0}};
  }

  /// Verify or reject doctor account
  Future<void> verifyDoctor(String doctorProfileOrUserId, {required String status}) async {
    await _apiClient.patch(
      '/admin/doctors/$doctorProfileOrUserId/verify',
      body: {'status': status},
    );
  }

  /// Activate or deactivate user account
  Future<void> updateUserStatus(String userId, {required bool isActive, String? reason}) async {
    final body = <String, dynamic>{'isActive': isActive};
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }
    await _apiClient.patch(
      '/admin/users/$userId/status',
      body: body,
    );
  }

  /// Assign or change user role
  Future<void> assignUserRole(String userId, {required String role}) async {
    await _apiClient.patch(
      '/admin/users/$userId/role',
      body: {'role': role},
    );
  }

  /// Permanently delete a user account from the ecosystem
  Future<void> deleteUser(String userId) async {
    await _apiClient.delete('/admin/users/$userId');
  }

  /// Retrieve administrative audit trail
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final res = await _apiClient.get('/admin/audit-logs');
    if (res is Map<String, dynamic> && res['auditLogs'] is List) {
      return List<Map<String, dynamic>>.from(res['auditLogs']);
    }
    return [];
  }
}
