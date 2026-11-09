import '../core/api/api_client.dart';
import '../models/notification_model.dart';

class DoctorNotificationService {
  final ApiClient _apiClient;

  DoctorNotificationService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Retrieve authenticated doctor's in-app notifications
  Future<List<NotificationModel>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'unreadOnly': unreadOnly,
    };

    final res = await _apiClient.get('/notifications', queryParams: query);
    if (res is Map<String, dynamic> && res['notifications'] is List) {
      return (res['notifications'] as List)
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    await _apiClient.patch('/notifications/$id/read');
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _apiClient.patch('/notifications/read-all');
  }
}
