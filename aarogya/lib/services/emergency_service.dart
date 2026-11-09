import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/emergency_model.dart';

class EmergencyService {
  final ApiClient _apiClient;

  EmergencyService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Create and dispatch Emergency SOS request
  Future<EmergencyModel> createEmergencySos({
    required double latitude,
    required double longitude,
    String? pickupAddress,
    Map<String, dynamic>? vitalsSnapshot,
  }) async {
    try {
      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (pickupAddress != null) body['pickupAddress'] = pickupAddress;
      if (vitalsSnapshot != null) body['vitalsSnapshot'] = vitalsSnapshot;

      final res = await _apiClient.post('/emergency/sos', body: body);
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data']
          : res;

      if (data is Map<String, dynamic> && data['emergency'] != null) {
        return EmergencyModel.fromJson(data['emergency'] as Map<String, dynamic>);
      }
      throw Exception('Invalid emergency response from server');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Emergency SOS request failed: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Check active emergency dispatch
  Future<EmergencyModel?> getActiveEmergency() async {
    try {
      final res = await _apiClient.get('/emergency/sos/active');
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data']
          : res;

      if (data is Map<String, dynamic> && data['emergency'] != null) {
        return EmergencyModel.fromJson(data['emergency'] as Map<String, dynamic>);
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// Get status & coordinates for single emergency request
  Future<EmergencyModel> getEmergencyById(String id) async {
    try {
      final res = await _apiClient.get('/emergency/sos/$id');
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data']
          : res;

      if (data is Map<String, dynamic> && data['emergency'] != null) {
        return EmergencyModel.fromJson(data['emergency'] as Map<String, dynamic>);
      }
      throw Exception('Emergency request not found');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch emergency status: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Cancel active emergency dispatch
  Future<EmergencyModel> cancelEmergency(String id) async {
    try {
      final res = await _apiClient.patch('/emergency/sos/$id/cancel');
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data']
          : res;

      if (data is Map<String, dynamic> && data['emergency'] != null) {
        return EmergencyModel.fromJson(data['emergency'] as Map<String, dynamic>);
      }
      throw Exception('Failed to cancel emergency');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Cancellation failed: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Step simulation: advance ambulance closer to patient
  Future<EmergencyModel> simulateStep(String id) async {
    try {
      final res = await _apiClient.patch('/emergency/sos/$id/simulate-move');
      final data = res is Map<String, dynamic> && res.containsKey('data')
          ? res['data']
          : res;

      if (data is Map<String, dynamic> && data['emergency'] != null) {
        return EmergencyModel.fromJson(data['emergency'] as Map<String, dynamic>);
      }
      throw Exception('Failed to update live coordinates');
    } catch (e) {
      throw ApiException(
        message: 'Live tracking update failed: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

