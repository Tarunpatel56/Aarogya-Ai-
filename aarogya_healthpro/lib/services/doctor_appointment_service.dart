import '../core/api/api_client.dart';
import '../models/doctor_appointment_model.dart';

class DoctorAppointmentService {
  final ApiClient _apiClient;

  DoctorAppointmentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Retrieve list of appointments for the authenticated doctor
  Future<List<DoctorAppointmentModel>> getAppointments({
    String? status,
    DateTime? from,
    DateTime? to,
    int limit = 50,
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
          .map((item) => DoctorAppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (res is List) {
      return res
          .map((item) => DoctorAppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Retrieve an individual authorized appointment with patient details
  Future<DoctorAppointmentModel> getAppointmentById(String id) async {
    final res = await _apiClient.get('/appointments/$id');
    final apptData = res is Map<String, dynamic> && res.containsKey('appointment')
        ? res['appointment']
        : res;
    return DoctorAppointmentModel.fromJson(apptData as Map<String, dynamic>);
  }

  /// Confirm an eligible appointment request
  Future<DoctorAppointmentModel> confirmAppointment(String id) async {
    final res = await _apiClient.patch('/appointments/$id/confirm', body: {});
    final apptData = res is Map<String, dynamic> && res.containsKey('appointment')
        ? res['appointment']
        : res;
    return DoctorAppointmentModel.fromJson(apptData as Map<String, dynamic>);
  }

  /// Reject an eligible appointment request with a mandatory reason
  Future<DoctorAppointmentModel> rejectAppointment(String id, {required String reason}) async {
    final res = await _apiClient.patch(
      '/appointments/$id/reject',
      body: {'reason': reason.trim()},
    );
    final apptData = res is Map<String, dynamic> && res.containsKey('appointment')
        ? res['appointment']
        : res;
    return DoctorAppointmentModel.fromJson(apptData as Map<String, dynamic>);
  }

  /// Complete an appointment (mark consultation finished)
  Future<DoctorAppointmentModel> completeAppointment(String id) async {
    final res = await _apiClient.patch('/appointments/$id/complete', body: {});
    final apptData = res is Map<String, dynamic> && res.containsKey('appointment')
        ? res['appointment']
        : res;
    return DoctorAppointmentModel.fromJson(apptData as Map<String, dynamic>);
  }

  /// Mark patient as no-show
  Future<DoctorAppointmentModel> markNoShow(String id) async {
    final res = await _apiClient.patch('/appointments/$id/no-show', body: {});
    final apptData = res is Map<String, dynamic> && res.containsKey('appointment')
        ? res['appointment']
        : res;
    return DoctorAppointmentModel.fromJson(apptData as Map<String, dynamic>);
  }

  /// Cancel an eligible appointment
  Future<DoctorAppointmentModel> cancelAppointment(String id, {required String reason}) async {
    final res = await _apiClient.patch(
      '/appointments/$id/cancel',
      body: {'reason': reason.trim()},
    );
    final apptData = res is Map<String, dynamic> && res.containsKey('appointment')
        ? res['appointment']
        : res;
    return DoctorAppointmentModel.fromJson(apptData as Map<String, dynamic>);
  }
}
