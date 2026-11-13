import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiConfig {
  static String? _customBaseUrl;

  /// High-reliability Cloudflare Tunnel endpoint (unblocked worldwide across all mobile ISPs)
  static const String publicCloudflareUrl = 'https://mac-saw-polo-alex.trycloudflare.com';

  /// Active production cloud endpoint on Ngrok Tunnel
  static const String publicTunnelUrl = 'https://nonpictorial-alysia-seminervously.ngrok-free.dev';

  /// Default API base URL based on runtime platform
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return '$publicCloudflareUrl/api/v1';
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

  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 15);

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

    final candidates = <String>[
      publicCloudflareUrl,
      publicTunnelUrl,
      'http://10.31.181.46:5000',
      'http://127.0.0.1:5000',
      'http://localhost:5000',
    ];

    final probeFutures = candidates.map((host) async {
      try {
        final uri = Uri.parse('$host/health');
        final res = await http.get(uri).timeout(const Duration(milliseconds: 2500));
        if (res.statusCode == 200) {
          return '$host/api/v1';
        }
      } catch (_) {}
      return null;
    });

    final results = await Future.wait(probeFutures);
    for (final responsiveHost in results) {
      if (responsiveHost != null) {
        _customBaseUrl = responsiveHost;
        return _customBaseUrl!;
      }
    }

    _customBaseUrl = defaultBaseUrl;
    return _customBaseUrl!;
  }
}

