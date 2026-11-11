import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _keyAccessToken = 'superadmin_access_token';
  static const _keyRefreshToken = 'superadmin_refresh_token';
  static const _keyAdminInfo = 'superadmin_info';

  static final Map<String, String> _memoryCache = {};

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _memoryCache[_keyAccessToken] = accessToken;
    _memoryCache[_keyRefreshToken] = refreshToken;
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {}
  }

  Future<void> saveAdminInfo(String infoJson) async {
    _memoryCache[_keyAdminInfo] = infoJson;
    try {
      await _storage.write(key: _keyAdminInfo, value: infoJson);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    if (_memoryCache.containsKey(_keyAccessToken)) {
      return _memoryCache[_keyAccessToken];
    }
    try {
      final token = await _storage.read(key: _keyAccessToken);
      if (token != null) _memoryCache[_keyAccessToken] = token;
      return token;
    } catch (_) {
      return _memoryCache[_keyAccessToken];
    }
  }

  Future<String?> getRefreshToken() async {
    if (_memoryCache.containsKey(_keyRefreshToken)) {
      return _memoryCache[_keyRefreshToken];
    }
    try {
      final token = await _storage.read(key: _keyRefreshToken);
      if (token != null) _memoryCache[_keyRefreshToken] = token;
      return token;
    } catch (_) {
      return _memoryCache[_keyRefreshToken];
    }
  }

  Future<String?> getAdminInfo() async {
    if (_memoryCache.containsKey(_keyAdminInfo)) {
      return _memoryCache[_keyAdminInfo];
    }
    try {
      final info = await _storage.read(key: _keyAdminInfo);
      if (info != null) _memoryCache[_keyAdminInfo] = info;
      return info;
    } catch (_) {
      return _memoryCache[_keyAdminInfo];
    }
  }

  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyAdminInfo);
    } catch (_) {}
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}


