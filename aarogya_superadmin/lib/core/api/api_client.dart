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
    });
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      return await _httpClient
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConfig.timeout);
    });
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      return await _httpClient
          .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(ApiConfig.timeout);
    });
  }

  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      return await _httpClient.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    });
  }

  Future<dynamic> _sendWithRetry(Future<http.Response> Function() requestFn) async {
    try {
      final response = await requestFn();
      if (response.statusCode == 401) {
        await _tokenStorage.clearAll();
        onSessionExpired?.call();
        throw const ApiException(statusCode: 401, message: 'Super Admin session expired.');
      }
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: e.toString());
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
        ? (body['message'] ?? body['error']?['message'] ?? 'Request failed (${response.statusCode})')
        : 'HTTP Error ${response.statusCode}';

    throw ApiException(
      statusCode: response.statusCode,
      message: message.toString(),
      details: body,
    );
  }
}

