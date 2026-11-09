import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'aarogya_driver_access_token';
  static const _refreshTokenKey = 'aarogya_driver_refresh_token';
  static const _driverInfoKey = 'aarogya_driver_info';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveDriverInfo(String jsonStr) async {
    await _storage.write(key: _driverInfoKey, value: jsonStr);
  }

  Future<String?> getDriverInfo() async {
    return await _storage.read(key: _driverInfoKey);
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _driverInfoKey);
  }
}
