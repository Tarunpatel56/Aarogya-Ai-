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
        'email': email.trim(),
        'password': password,
      },
      requiresAuth: false,
    );

    final data = res['data'] ?? res;
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
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
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    await _tokenStorage.clearAll();
  }
}

