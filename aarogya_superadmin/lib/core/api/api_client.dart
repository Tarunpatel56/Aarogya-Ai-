import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _httpClient;
  final TokenStorage _tokenStorage;
  void Function()? onSessionExpired;

  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    this.onSessionExpired,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      return await _httpClient.get(uri, headers: headers).timeout(ApiConfig.timeout);
    }, requiresAuth: requiresAuth);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      return await _httpClient
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConfig.timeout);
    }, requiresAuth: requiresAuth);
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      return await _httpClient
          .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConfig.timeout);
    }, requiresAuth: requiresAuth);
  }

  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      return await _httpClient.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    }, requiresAuth: requiresAuth);
  }

  Future<dynamic> _sendWithRetry(
    Future<http.Response> Function() requestFn, {
    bool requiresAuth = true,
  }) async {
    try {
      var response = await requestFn();

      // Only attempt refresh or handle session expiry for authenticated requests
      if (requiresAuth && response.statusCode == 401) {
        // Attempt silent token refresh before declaring session expired
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          response = await requestFn();
        }

        if (response.statusCode == 401) {
          // Check if we still have a token
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            // Do not aggressively wipe out session on temporary network or refresh glitch
            // Return error response directly so user can retry
            return _handleResponse(response);
          }
          await _tokenStorage.clearAll();
          onSessionExpired?.call();
          throw const ApiException(statusCode: 401, message: 'Super Admin session expired.');
        }
      }

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: e.toString());
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/refresh');
      final res = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(ApiConfig.timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data['success'] == true) {
          final payload = data['data'] as Map<String, dynamic>? ?? {};
          final tokens = payload['tokens'] as Map<String, dynamic>? ?? {};
          final newAccess = (tokens['accessToken'] ?? payload['accessToken'])?.toString() ?? '';
          final newRefresh = (tokens['refreshToken'] ?? payload['refreshToken'])?.toString() ?? '';

          if (newAccess.isNotEmpty) {
            await _tokenStorage.saveTokens(
              accessToken: newAccess,
              refreshToken: newRefresh.isNotEmpty ? newRefresh : refreshToken,
            );
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body is Map)
        ? (body['message'] ?? body['error']?['message'] ?? 'Request failed (${response.statusCode})')
        : 'HTTP Error ${response.statusCode}';

    throw ApiException(
      statusCode: response.statusCode,
      message: message.toString(),
      details: body,
    );
  }
}

