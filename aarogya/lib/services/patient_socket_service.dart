import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../core/config/api_config.dart';
import '../core/storage/token_storage.dart';

typedef SocketEventCallback = void Function(Map<String, dynamic> data);

class PatientSocketService {
  static final PatientSocketService _instance = PatientSocketService._internal();
  factory PatientSocketService() => _instance;

  PatientSocketService._internal();

  socket_io.Socket? _socket;
  final SecureTokenStorage _tokenStorage = SecureTokenStorage();

  SocketEventCallback? onAmbulanceLocationUpdated;
  SocketEventCallback? onEmergencyAccepted;
  SocketEventCallback? onEmergencyStatusUpdated;

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

    _socket!.on('ambulance_location_updated', (data) {
      if (data is Map<String, dynamic>) {
        onAmbulanceLocationUpdated?.call(data);
      }
    });

    _socket!.on('emergency_accepted', (data) {
      if (data is Map<String, dynamic>) {
        onEmergencyAccepted?.call(data);
      }
    });

    _socket!.on('emergency_status_updated', (data) {
      if (data is Map<String, dynamic>) {
        onEmergencyStatusUpdated?.call(data);
      }
    });
  }

  void joinEmergency(String emergencyId) {
    _socket?.emit('join_emergency', emergencyId);
  }

  void leaveEmergency(String emergencyId) {
    _socket?.emit('leave_emergency', emergencyId);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}

