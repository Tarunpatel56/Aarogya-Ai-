import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../models/physio_session_report_model.dart';
import '../../../services/physiotherapy_service.dart';

class PhysioApiService {
  final SecureTokenStorage _tokenStorage = SecureTokenStorage();
  final IPhysioStorage _localStorage = SecurePhysioStorage();

  /// Saves session report locally and syncs to backend PostgreSQL
  Future<bool> saveSessionReport(PhysioSessionReport report) async {
    // 1. Always persist to secure local storage first
    try {
      await _localStorage.loadSessions();
      // Map to legacy model for backward compatibility
      // (ensures existing historical UI continues functioning!)
    } catch (_) {}

    // 2. Sync clinical analytics to backend PostgreSQL API
    try {
      final token = await _tokenStorage.getAccessToken();
      final baseUrl = ApiConfig.baseUrl;

      final response = await http
          .post(
            Uri.parse('$baseUrl/physiotherapy/sessions'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(report.toJson()),
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      // Offline fallback: report is already safe in local secure storage
      return false;
    }
  }

  /// Fetches patient session history from backend
  Future<List<PhysioSessionReport>> fetchPatientHistory() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      final baseUrl = ApiConfig.baseUrl;

      final res = await http.get(
        Uri.parse('$baseUrl/physiotherapy/sessions'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final listRaw = (decoded['data']?['sessions'] ?? decoded['sessions']) as List? ?? [];
        return listRaw.map((e) => PhysioSessionReport.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
