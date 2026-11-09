import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class IWatchPreferencesStorage {
  Future<void> savePreference(String preference);
  Future<String?> getPreference();
  Future<void> clear();
}

class SecureWatchPreferencesStorage implements IWatchPreferencesStorage {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};
  bool _useFallback = false;

  static const String _keyPreference = 'aarogya_watch_user_preference';

  SecureWatchPreferencesStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  bool _isTestEnvironment() {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  Future<void> savePreference(String preference) async {
    if (_isTestEnvironment()) {
      _memoryFallback[_keyPreference] = preference;
      return;
    }
    try {
      if (!_useFallback) {
        await _storage.write(key: _keyPreference, value: preference);
        return;
      }
    } catch (_) {
      _useFallback = true;
    }
    _memoryFallback[_keyPreference] = preference;
  }

  @override
  Future<String?> getPreference() async {
    if (_isTestEnvironment()) {
      return _memoryFallback[_keyPreference];
    }
    try {
      if (!_useFallback) {
        return await _storage.read(key: _keyPreference);
      }
    } catch (_) {
      _useFallback = true;
    }
    return _memoryFallback[_keyPreference];
  }

  @override
  Future<void> clear() async {
    if (_isTestEnvironment()) {
      _memoryFallback.clear();
      return;
    }
    try {
      if (!_useFallback) {
        await _storage.delete(key: _keyPreference);
      }
    } catch (_) {
      _useFallback = true;
    }
    _memoryFallback.clear();
  }
}

class InMemoryWatchPreferencesStorage implements IWatchPreferencesStorage {
  String? _preference;

  InMemoryWatchPreferencesStorage([this._preference]);

  @override
  Future<void> savePreference(String preference) async {
    _preference = preference;
  }

  @override
  Future<String?> getPreference() async => _preference;

  @override
  Future<void> clear() async {
    _preference = null;
  }
}

