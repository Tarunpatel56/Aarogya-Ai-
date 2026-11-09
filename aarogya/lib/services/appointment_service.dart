import '../core/api/api_client.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final ApiClient _apiClient;

  AppointmentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Create an appointment request
  Future<AppointmentModel> requestAppointment({
    required String doctorProfileId,
    required DateTime startTime,
    DateTime? endTime,
    int? durationMinutes,
    String mode = 'IN_PERSON',
    String? reason,
    List<Map<String, dynamic>>? vitals,
  }) async {
    final body = <String, dynamic>{
      'doctorProfileId': doctorProfileId,
      'startTime': startTime.toIso8601String(),
      'mode': mode,
    };
    if (endTime != null) {
      body['endTime'] = endTime.toIso8601String();
    } else if (durationMinutes != null) {
      body['durationMinutes'] = durationMinutes;
    } else {
      body['durationMinutes'] = 30; // default 30 min
    }
    if (reason != null && reason.trim().isNotEmpty) {
      body['reason'] = reason.trim();
    }
    if (vitals != null && vitals.isNotEmpty) {
      body['vitals'] = vitals;
    }

    final res = await _apiClient.post('/appointments', body: body);
    final apptData = res is Map<String, dynamic> && res.containsKey('appointment')
        ? res['appointment']
        : res;
    return AppointmentModel.fromJson(apptData as Map<String, dynamic>);
  }

  /// List authenticated patient's appointments
  Future<List<AppointmentModel>> getAppointments({
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (from != null) query['from'] = from.toIso8601String();
    if (to != null) query['to'] = to.toIso8601String();

    final res = await _apiClient.get('/appointments', queryParams: query);
    if (res is Map<String, dynamic> && res['appointments'] is List) {
      return (res['appointments'] as List)
          .map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Retrieve individual appointment details
  Future<AppointmentModel> getAppointmentById(String id) async {
    final res = await _apiClient.get('/appointments/$id');
    final apptData = res is Map<String, dynamic> && res.containsKey('appointment')
        ? res['appointment']
        : res;
    return AppointmentModel.fromJson(apptData as Map<String, dynamic>);
  }

  /// Cancel an eligible appointment
  Future<AppointmentModel> cancelAppointment(String id, {String? reason}) async {
    final body = <String, dynamic>{};
    if (reason != null && reason.trim().isNotEmpty) {
      body['reason'] = reason.trim();
    }

    final res = await _apiClient.patch('/appointments/$id/cancel', body: body);
    final apptData = res is Map<String, dynamic> && res.containsKey('appointment')
        ? res['appointment']
        : res;
    return AppointmentModel.fromJson(apptData as Map<String, dynamic>);
  }
}
