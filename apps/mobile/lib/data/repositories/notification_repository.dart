import '../../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> list({bool unreadOnly = false}) async {
    final data = await _api.get<List<dynamic>>('/notifications',
        query: {if (unreadOnly) 'unreadOnly': 'true'});
    return data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> unreadCount() async {
    final data = await _api.get<Map<String, dynamic>>('/notifications/unread-count');
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    await _api.patch<dynamic>('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.patch<dynamic>('/notifications/read-all');
  }
}
