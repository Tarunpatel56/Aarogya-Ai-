import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _keyAccessToken = 'superadmin_access_token';
  static const _keyRefreshToken = 'superadmin_refresh_token';
  static const _keyAdminInfo = 'superadmin_info';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> saveAdminInfo(String infoJson) async {
    await _storage.write(key: _keyAdminInfo, value: infoJson);
  }

  Future<String?> getAccessToken() async => await _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() async => await _storage.read(key: _keyRefreshToken);
  Future<String?> getAdminInfo() async => await _storage.read(key: _keyAdminInfo);

  Future<void> clearAll() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyAdminInfo);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

