import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiConfig {
  static String? _customBaseUrl;

  /// Active production cloud endpoint on Ngrok Tunnel
  static const String publicTunnelUrl = 'https://nonpictorial-alysia-seminervously.ngrok-free.dev';

  /// Default API base URL based on runtime platform
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }

    // Connect directly to unified cloud backend across both Web and Mobile
    return '$publicTunnelUrl/api/v1';
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

  /// Override base URL at runtime (for testing or physical device LAN IP)
  static void setBaseUrl(String? url) {
    _customBaseUrl = url;
  }

  /// Request timeout duration (90s for multimodal AI and medical image processing)
  static const Duration timeout = Duration(seconds: 90);

  /// Auto-probe candidate URLs to find the active backend host in under a second
  static Future<String> autoDetectBaseUrl() async {
    if (_customBaseUrl != null) return _customBaseUrl!;

    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      _customBaseUrl = fromEnv;
      return fromEnv;
    }

    // On Web, use unified cloud backend directly without triggering browser CORS probes
    if (kIsWeb) {
      _customBaseUrl = defaultBaseUrl;
      return _customBaseUrl!;
    }

    // Candidate endpoints:
    // 1. USB Loopback via ADB reverse (127.0.0.1:5000) - ultra-fast (<5ms)
    // 2. Local Wi-Fi LAN IP (10.116.92.46:5000)
    // 3. Ethernet LAN IP (172.16.49.9:5000)
    // 4. Android Studio Emulator loopback (10.0.2.2:5000)
    // 5. Desktop Localhost (localhost:5000)
    // 6. Active Public Ngrok Tunnel (works on any network: 5G, Wi-Fi, hotspot)
    final candidates = <String>[
      'http://127.0.0.1:5000',
      'http://10.116.92.46:5000',
      'http://172.16.49.9:5000',
      'http://localhost:5000',
      'http://10.0.2.2:5000',
      publicTunnelUrl,
    ];

    // Probe all candidate endpoints concurrently for ultra-fast startup (<2s)
    final probeFutures = candidates.map((host) async {
      try {
        final uri = Uri.parse('$host/health');
        final res = await http.get(uri, headers: {
          'ngrok-skip-browser-warning': 'true',
        }).timeout(const Duration(milliseconds: 2500));
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
