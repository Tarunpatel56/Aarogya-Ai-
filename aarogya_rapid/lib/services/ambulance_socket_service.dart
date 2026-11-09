import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../core/config/api_config.dart';
import '../core/storage/token_storage.dart';

typedef EmergencyBroadcastCallback = void Function(Map<String, dynamic> data);

class AmbulanceSocketService {
  static final AmbulanceSocketService _instance = AmbulanceSocketService._internal();
  factory AmbulanceSocketService() => _instance;

  AmbulanceSocketService._internal();

  socket_io.Socket? _socket;
  final TokenStorage _tokenStorage = TokenStorage();
  EmergencyBroadcastCallback? onEmergencyBroadcast;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _tokenStorage.getAccessToken();
    final socketUrl = ApiConfig.socketUrl;

    _socket = socket_io.io(
      socketUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .setExtraHeaders({'ngrok-skip-browser-warning': 'true'})
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('join_ambulance_drivers');
    });

    _socket!.on('emergency_broadcast', (data) {
      if (data is Map<String, dynamic>) {
        onEmergencyBroadcast?.call(data);
      }
    });
  }

  void joinEmergency(String emergencyId) {
    _socket?.emit('join_emergency', emergencyId);
  }

  void streamLocation({
    required String emergencyId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    int? etaMinutes,
  }) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('update_ambulance_location', {
      'emergencyId': emergencyId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'etaMinutes': etaMinutes,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
