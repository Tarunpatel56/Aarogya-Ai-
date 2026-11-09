import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../core/config/api_config.dart';
import '../core/storage/token_storage.dart';

typedef SocketDataCallback = void Function(Map<String, dynamic> data);

class DoctorSocketService {
  static final DoctorSocketService _instance = DoctorSocketService._internal();
  factory DoctorSocketService() => _instance;

  DoctorSocketService._internal();

  socket_io.Socket? _socket;
  final SecureTokenStorage _tokenStorage = SecureTokenStorage();

  SocketDataCallback? onEmergencyBroadcast;
  SocketDataCallback? onAppointmentUpdated;

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
      _socket!.emit('join_doctors');
    });

    _socket!.on('emergency_broadcast', (data) {
      if (data is Map<String, dynamic>) {
        onEmergencyBroadcast?.call(data);
      }
    });

    _socket!.on('appointment_updated', (data) {
      if (data is Map<String, dynamic>) {
        onAppointmentUpdated?.call(data);
      }
    });
  }

  void joinHospital(String hospitalId) {
    _socket?.emit('join_hospital', hospitalId);
  }

  void joinConsultation(String appointmentId) {
    _socket?.emit('join_consultation', appointmentId);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
