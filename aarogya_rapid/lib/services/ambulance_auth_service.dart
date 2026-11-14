import 'dart:convert';
import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';

class AmbulanceAuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AmbulanceAuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': 'AMBULANCE_DRIVER',
      },
      requiresAuth: false,
    );

    final data = res['data'] ?? res;
    final tokens = data['tokens'] as Map<String, dynamic>?;
    final accessToken = tokens?['accessToken'] ?? data['accessToken'];
    final refreshToken = tokens?['refreshToken'] ?? data['refreshToken'];
    final user = data['user'] ?? {};

    if (accessToken != null && refreshToken != null) {
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _tokenStorage.saveDriverInfo(jsonEncode(user));
    }

    return user;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String staffRole = 'AMBULANCE_DRIVER',
    required String licenseNumber,
    String? assignedVehicleNumber,
    String? certificationLevel,
    Map<String, dynamic>? documents,
  }) async {
    final res = await _apiClient.post(
      '/auth/register/ambulance-staff',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'fullName': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'staffRole': staffRole,
        'licenseNumber': licenseNumber.trim(),
        'assignedVehicleNumber': (assignedVehicleNumber != null && assignedVehicleNumber.trim().isNotEmpty)
            ? assignedVehicleNumber.trim()
            : 'DL-01-AMB-108',
        'certificationLevel': (certificationLevel != null && certificationLevel.trim().isNotEmpty)
            ? certificationLevel.trim()
            : 'EMT-Advanced',
        if (documents != null) ...{
          'documents': documents,
        },
      },
      requiresAuth: false,
    );

    final data = res['data'] ?? res;
    final tokens = data['tokens'] as Map<String, dynamic>?;
    final accessToken = tokens?['accessToken'] ?? data['accessToken'];
    final refreshToken = tokens?['refreshToken'] ?? data['refreshToken'];
    final user = data['user'] ?? {};

    if (accessToken != null && refreshToken != null) {
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _tokenStorage.saveDriverInfo(jsonEncode(user));
    }

    return user;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      await _apiClient.post(
        '/auth/logout',
        body: refreshToken != null ? {'refreshToken': refreshToken} : null,
      );
    } catch (_) {}
    await _tokenStorage.clearAll();
  }
}

