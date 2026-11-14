import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String? _customBaseUrl;

  /// Live Production Cloud Backend Endpoint on Render
  static const String productionCloudUrl = 'https://aarogya-ai-azgi.onrender.com';

  /// Default API base URL based on runtime platform
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return '$productionCloudUrl/api/v1';
  }

  /// Get current effective API base URL
  static String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  /// Root host for WebSockets (without /api/v1)
  static String get socketUrl {
    final effective = baseUrl;
    if (effective.endsWith('/api/v1')) {
      return effective.substring(0, effective.length - 7);
    }
    return effective;
  }

  /// Override base URL at runtime
  static void setBaseUrl(String? url) {
    _customBaseUrl = url;
  }

  /// Request timeout duration (60s to handle Render cold start)
  static const Duration timeout = Duration(seconds: 60);

  /// Auto-probe candidate URLs to find active backend host
  static Future<String> autoDetectBaseUrl() async {
    if (_customBaseUrl != null) return _customBaseUrl!;

    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      _customBaseUrl = fromEnv;
      return fromEnv;
    }

    if (kIsWeb) {
      _customBaseUrl = defaultBaseUrl;
      return _customBaseUrl!;
    }

    // Always use live Render production backend — no local fallbacks
    _customBaseUrl = defaultBaseUrl;
    return _customBaseUrl!;
  }
}

