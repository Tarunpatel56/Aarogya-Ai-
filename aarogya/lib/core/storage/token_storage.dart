import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ITokenStorage {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUser(Map<String, dynamic> user);
  Future<Map<String, dynamic>?> getUser();
  Future<void> clear();
}

class SecureTokenStorage implements ITokenStorage {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};
  bool _useFallback = false;

  static const String _keyAccessToken = 'aarogya_access_token';
  static const String _keyRefreshToken = 'aarogya_refresh_token';
  static const String _keyUserData = 'aarogya_user_data';

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      if (!_useFallback) {
        await _storage.write(key: _keyAccessToken, value: accessToken);
        await _storage.write(key: _keyRefreshToken, value: refreshToken);
        return;
      }
    } catch (_) {
      _useFallback = true;
    }
    _memoryFallback[_keyAccessToken] = accessToken;
    _memoryFallback[_keyRefreshToken] = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      if (!_useFallback) {
        return await _storage.read(key: _keyAccessToken);
      }
    } catch (_) {
      _useFallback = true;
    }
    return _memoryFallback[_keyAccessToken];
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      if (!_useFallback) {
        return await _storage.read(key: _keyRefreshToken);
      }
    } catch (_) {
      _useFallback = true;
    }
    return _memoryFallback[_keyRefreshToken];
  }

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    final encoded = jsonEncode(user);
    try {
      if (!_useFallback) {
        await _storage.write(key: _keyUserData, value: encoded);
        return;
      }
    } catch (_) {
      _useFallback = true;
    }
    _memoryFallback[_keyUserData] = encoded;
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    try {
      String? data;
      if (!_useFallback) {
        data = await _storage.read(key: _keyUserData);
      } else {
        data = _memoryFallback[_keyUserData];
      }
      if (data != null && data.isNotEmpty) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
    } catch (_) {
      _useFallback = true;
      final data = _memoryFallback[_keyUserData];
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Future<void> clear() async {
    try {
      if (!_useFallback) {
        await _storage.delete(key: _keyAccessToken);
        await _storage.delete(key: _keyRefreshToken);
        await _storage.delete(key: _keyUserData);
      }
    } catch (_) {
      _useFallback = true;
    }
    _memoryFallback.clear();
  }
}

class InMemoryTokenStorage implements ITokenStorage {
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    _user = user;
  }

  @override
  Future<Map<String, dynamic>?> getUser() async => _user;

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
  }
}
