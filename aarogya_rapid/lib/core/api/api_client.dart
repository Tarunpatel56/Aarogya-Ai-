import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _httpClient;
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;
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
      'ngrok-skip-browser-warning': 'true',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
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
    }, endpoint);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      return await _httpClient
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConfig.timeout);
    }, endpoint);
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      return await _httpClient
          .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConfig.timeout);
    }, endpoint);
  }

  Future<dynamic> _sendWithRetry(Future<http.Response> Function() requestFn, String endpoint) async {
    try {
      final response = await requestFn();
      if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final retryResponse = await requestFn();
          return _handleResponse(retryResponse);
        } else {
          await _tokenStorage.clearAll();
          onSessionExpired?.call();
          throw const ApiException(statusCode: 401, message: 'Session expired. Please log in again.');
        }
      }
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException(statusCode: 0, message: 'Network connection failed: ${e.message}', isNetworkError: true);
    } on TimeoutException {
      throw const ApiException(statusCode: 408, message: 'Request timed out.', isNetworkError: true);
    }
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/refresh');
      final res = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final payload = data['data'] ?? data;
        final tokens = payload['tokens'] as Map<String, dynamic>?;
        final newAccess = tokens?['accessToken'] ?? payload['accessToken'];
        final newRefresh = tokens?['refreshToken'] ?? payload['refreshToken'];
        if (newAccess != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccess.toString(),
            refreshToken: (newRefresh ?? refreshToken).toString(),
          );
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
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
        ? (body['message'] ?? body['error'] ?? 'Request failed (${response.statusCode})')
        : 'Request failed (${response.statusCode})';

    throw ApiException(
      statusCode: response.statusCode,
      message: message.toString(),
      details: body is Map ? body['details'] : null,
      isConflict: response.statusCode == 409,
    );
  }
}

