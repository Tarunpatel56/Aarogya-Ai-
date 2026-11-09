import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

typedef SessionExpiredCallback = void Function();

class ApiClient {
  final http.Client _httpClient;
  final ITokenStorage _tokenStorage;
  final SessionExpiredCallback? onSessionExpired;
  final String? _customBaseUrl;

  Completer<bool>? _refreshCompleter;

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    ITokenStorage? tokenStorage,
    this.onSessionExpired,
  })  : _customBaseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage();

  ITokenStorage get tokenStorage => _tokenStorage;

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final rawBase = _customBaseUrl ?? ApiConfig.baseUrl;
    final base = rawBase.endsWith('/')
        ? rawBase.substring(0, rawBase.length - 1)
        : rawBase;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$normalizedPath';

    if (queryParams == null || queryParams.isEmpty) {
      return Uri.parse(fullUrl);
    }

    final sanitizedParams = <String, String>{};
    queryParams.forEach((key, value) {
      if (value != null) {
        sanitizedParams[key] = value.toString();
      }
    });

    return Uri.parse(fullUrl).replace(queryParameters: sanitizedParams);
  }

  Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    if (includeAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path, queryParams);
      final headers = await _buildHeaders(includeAuth: includeAuth);
      return _httpClient.get(uri, headers: headers).timeout(ApiConfig.timeout);
    }, includeAuth: includeAuth);
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path, queryParams);
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;
      return _httpClient
          .post(uri, headers: headers, body: encodedBody)
          .timeout(ApiConfig.timeout);
    }, includeAuth: includeAuth);
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path, queryParams);
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;
      return _httpClient
          .patch(uri, headers: headers, body: encodedBody)
          .timeout(ApiConfig.timeout);
    }, includeAuth: includeAuth);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path, queryParams);
      final headers = await _buildHeaders(includeAuth: includeAuth);
      return _httpClient
          .delete(uri, headers: headers)
          .timeout(ApiConfig.timeout);
    }, includeAuth: includeAuth);
  }

  Future<dynamic> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    String fieldName = 'image',
    Map<String, String>? fields,
    bool includeAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);

      if (includeAuth) {
        final token = await _tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.headers['Accept'] = 'application/json';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: filename,
        ),
      );

      final streamedResponse =
          await _httpClient.send(request).timeout(ApiConfig.timeout);
      return http.Response.fromStream(streamedResponse);
    }, includeAuth: includeAuth);
  }

  Future<dynamic> _sendWithRetry(
    Future<http.Response> Function() requestFn, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await requestFn();

      if (response.statusCode == 401 && includeAuth) {
        // Attempt token refresh with concurrency lock
        final refreshed = await _handleTokenRefresh();
        if (refreshed) {
          // Retry original request with newly refreshed token
          final retryResponse = await requestFn();
          return _handleResponse(retryResponse);
        } else {
          await _tokenStorage.clear();
          onSessionExpired?.call();
          throw const ApiException(
            statusCode: 401,
            message: 'Session expired. Please log in again.',
            code: 'SESSION_EXPIRED',
          );
        }
      }

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message: 'Unable to connect to Aarogya server. Please check your network.',
        code: 'NETWORK_ERROR',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic jsonBody;
    try {
      if (response.body.isNotEmpty) {
        jsonBody = jsonDecode(response.body);
      }
    } catch (_) {
      // Non-JSON response
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('data')) {
        return jsonBody['data'];
      }
      return jsonBody;
    }

    String errorMessage = 'Request failed with status ${response.statusCode}';
    dynamic errorDetails;
    String? errorCode;

    if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('error')) {
      final err = jsonBody['error'];
      if (err is Map<String, dynamic>) {
        errorMessage = err['message']?.toString() ?? errorMessage;
        errorDetails = err['details'];
        if (err['details'] is List && (err['details'] as List).isNotEmpty) {
          final first = (err['details'] as List).first;
          if (first is Map && first['message'] != null) {
            errorMessage = first['field'] != null
                ? '${first['field']}: ${first['message']}'
                : first['message'].toString();
          }
        } else if (err['details'] is Map<String, dynamic>) {
          errorCode = err['details']['code']?.toString();
        }
      } else if (err is String) {
        errorMessage = err;
      }
    } else if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('message')) {
      errorMessage = jsonBody['message'].toString();
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      details: errorDetails,
      code: errorCode,
    );
  }

  Future<bool> _handleTokenRefresh() async {
    // If a refresh is already in progress, wait for it to complete
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final uri = _buildUri('/auth/refresh');
      final response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? json;
        final newAccess = data['accessToken']?.toString();
        final newRefresh = data['refreshToken']?.toString();

        if (newAccess != null && newRefresh != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}
