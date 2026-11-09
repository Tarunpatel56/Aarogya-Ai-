import 'package:flutter/widgets.dart';
import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/watch_preferences_storage.dart';
import '../models/watch_telemetry_model.dart';

class WatchService {
  final ApiClient _apiClient;
  final IWatchPreferencesStorage _preferencesStorage;
  static WatchService? _instance;

  factory WatchService({
    ApiClient? apiClient,
    IWatchPreferencesStorage? preferencesStorage,
  }) {
    if (apiClient != null || preferencesStorage != null) {
      return WatchService._internal(
        apiClient: apiClient,
        preferencesStorage: preferencesStorage,
      );
    }
    return _instance ??= WatchService._internal();
  }

  WatchService._internal({
    ApiClient? apiClient,
    IWatchPreferencesStorage? preferencesStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _preferencesStorage = preferencesStorage ??
            ((apiClient?.tokenStorage is InMemoryTokenStorage ||
                    WidgetsBinding.instance.runtimeType.toString().contains('Test'))
                ? InMemoryWatchPreferencesStorage()
                : SecureWatchPreferencesStorage());

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  final ValueNotifier<WatchTelemetryModel?> telemetryNotifier =
      ValueNotifier<WatchTelemetryModel?>(null);

  final ValueNotifier<WatchConnectionState> connectionStateNotifier =
      ValueNotifier<WatchConnectionState>(WatchConnectionState.notConnected);

  final ValueNotifier<bool> promptDismissedNotifier =
      ValueNotifier<bool>(false);

  WatchTelemetryModel? get currentTelemetry => telemetryNotifier.value;
  WatchConnectionState get connectionState => connectionStateNotifier.value;
  bool get isPromptDismissed => promptDismissedNotifier.value;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Loads saved user preference from local persistent storage
  Future<void> loadPreferences() async {
    final pref = await _preferencesStorage.getPreference();
    if (pref == 'not_now') {
      promptDismissedNotifier.value = true;
      connectionStateNotifier.value = WatchConnectionState.notConnected;
    } else if (pref == 'disconnected') {
      promptDismissedNotifier.value = true;
      connectionStateNotifier.value = WatchConnectionState.disconnected;
    } else if (pref == 'connected') {
      promptDismissedNotifier.value = true;
    } else {
      promptDismissedNotifier.value = false;
      connectionStateNotifier.value = WatchConnectionState.notConnected;
    }
  }

  /// User chooses to skip connecting for now
  Future<void> setNotNow() async {
    promptDismissedNotifier.value = true;
    connectionStateNotifier.value = WatchConnectionState.notConnected;
    await _preferencesStorage.savePreference('not_now');
  }

  /// Resets user preference so connection prompt can be displayed again
  Future<void> resetPreferences() async {
    promptDismissedNotifier.value = false;
    connectionStateNotifier.value = WatchConnectionState.notConnected;
    telemetryNotifier.value = null;
    _lastError = null;
    await _preferencesStorage.clear();
  }

  /// Initiates or retries connection to the smartwatch bridge
  Future<WatchTelemetryModel> connect({String? mac}) async {
    return fetchTelemetry(mac: mac);
  }

  /// Fetches real telemetry from the laptop-connected smartwatch bridge
  Future<WatchTelemetryModel> fetchTelemetry({String? mac}) async {
    connectionStateNotifier.value = WatchConnectionState.connecting;
    _lastError = null;

    try {
      final query = mac != null ? {'mac': mac} : null;
      final res = await _apiClient.get('/wearables/bridge/watch', queryParams: query);

      final map = res is Map<String, dynamic>
          ? (res.containsKey('data') && res['data'] is Map<String, dynamic>
              ? res['data'] as Map<String, dynamic>
              : res)
          : <String, dynamic>{};

      final model = WatchTelemetryModel.fromJson(map);

      if (model.error != null && model.error!.isNotEmpty) {
        final errLow = model.error!.toLowerCase();
        if (errLow.contains('radio') ||
            errLow.contains('bridge') ||
            errLow.contains('powershell') ||
            errLow.contains('timeout') ||
            errLow.contains('unreachable')) {
          connectionStateNotifier.value = WatchConnectionState.bridgeUnavailable;
        } else {
          connectionStateNotifier.value = WatchConnectionState.connectionFailed;
        }
        _lastError = model.error;
      } else if (model.isConnected || model.paired) {
        connectionStateNotifier.value = WatchConnectionState.connected;
        _lastSyncTime = model.timestamp;
        promptDismissedNotifier.value = true;
        await _preferencesStorage.savePreference('connected');
      } else {
        connectionStateNotifier.value = WatchConnectionState.disconnected;
      }

      telemetryNotifier.value = model;
      return model;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socketexception') ||
          errStr.contains('connection refused') ||
          errStr.contains('502') ||
          errStr.contains('503') ||
          errStr.contains('unreachable') ||
          errStr.contains('failed host lookup') ||
          errStr.contains('clientexception') ||
          errStr.contains('network') ||
          errStr.contains('bridge unavailable') ||
          errStr.contains('server error')) {
        connectionStateNotifier.value = WatchConnectionState.bridgeUnavailable;
      } else {
        connectionStateNotifier.value = WatchConnectionState.connectionFailed;
      }
      _lastError = e.toString().replaceAll('ApiException: ', '');
      rethrow;
    }
  }

  /// Fetches documented Bluetooth SIG GATT capabilities of the watch model
  Future<Map<String, dynamic>> fetchCapabilities() async {
    final res = await _apiClient.get('/wearables/capabilities');
    if (res is Map<String, dynamic>) {
      if (res.containsKey('data') && res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
      return res;
    }
    return {};
  }

  /// Disconnects the local session link
  void disconnect() {
    connectionStateNotifier.value = WatchConnectionState.disconnected;
    telemetryNotifier.value = WatchTelemetryModel.disconnected();
    _preferencesStorage.savePreference('disconnected');
  }
}
