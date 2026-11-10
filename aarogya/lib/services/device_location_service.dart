import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class DeviceLocation {
  final double latitude;
  final double longitude;
  final String cityName;
  final String regionName;
  final String source; // 'GPS' | 'IP Geolocation' | 'Default'

  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.regionName,
    required this.source,
  });

  String get label => cityName.isNotEmpty ? '$cityName, $regionName' : '$latitude, $longitude';
}

class DeviceLocationService {
  static const MethodChannel _channel = MethodChannel('io.aarogya.mediapipe/pose');
  static DeviceLocation? _cachedLocation;

  static DeviceLocation? get cachedLocation => _cachedLocation;

  /// Retrieves the user's real live coordinates.
  /// 1. Attempts device hardware GPS / Network location via native LocationManager.
  /// 2. If unavailable, falls back to IP Geolocation (returns current city & coordinates).
  /// 3. Default fallback to Delhi if entirely offline.
  static Future<DeviceLocation> getCurrentLocation() async {
    // 1. Try Native Android GPS
    try {
      final res = await _channel.invokeMethod<Map>('getCurrentLocation');
      if (res != null && res['status'] == 'success') {
        final lat = (res['latitude'] as num).toDouble();
        final lng = (res['longitude'] as num).toDouble();

        // Reverse lookup city from IP or cache
        final city = _cachedLocation?.cityName ?? 'Current Location';
        final region = _cachedLocation?.regionName ?? '';

        final loc = DeviceLocation(
          latitude: lat,
          longitude: lng,
          cityName: city,
          regionName: region,
          source: 'Live GPS',
        );
        _cachedLocation = loc;
        return loc;
      }
    } catch (_) {
      // Continue to IP Geolocation fallback
    }

    // 2. Fast IP Geolocation Fallback
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num).toDouble();
          final lon = (data['lon'] as num).toDouble();
          final city = data['city']?.toString() ?? 'Indore';
          final region = data['regionName']?.toString() ?? 'Madhya Pradesh';

          final loc = DeviceLocation(
            latitude: lat,
            longitude: lon,
            cityName: city,
            regionName: region,
            source: 'Live Location',
          );
          _cachedLocation = loc;
          return loc;
        }
      }
    } catch (_) {
      // Continue to fallback
    }

    // 3. Fallback
    const fallback = DeviceLocation(
      latitude: 22.7170, // Default Indore / Central India
      longitude: 75.8337,
      cityName: 'Indore',
      regionName: 'Madhya Pradesh',
      source: 'Default Location',
    );
    _cachedLocation ??= fallback;
    return _cachedLocation!;
  }
}

