import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  /// Newest first.
  Future<List<AppNotification>> getNotifications();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}
