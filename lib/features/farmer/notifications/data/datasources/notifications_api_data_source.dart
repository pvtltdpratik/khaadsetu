import '../../../../../core/network/api_client.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsApiDataSource {
  const NotificationsApiDataSource(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> fetchNotifications() async {
    final list = await _api.get('/v1/farmer/notifications') as List;
    return list.map((e) => _parse(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) async {
    await _api.post('/v1/farmer/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.post('/v1/farmer/notifications/read-all');
  }

  AppNotification _parse(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.parse(json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      isRead: json['read'] as bool,
      refId: json['refId'] as String?,
    );
  }
}
