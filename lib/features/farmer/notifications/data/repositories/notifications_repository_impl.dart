import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_api_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._dataSource);

  final NotificationsApiDataSource _dataSource;

  @override
  Future<List<AppNotification>> getNotifications() =>
      _dataSource.fetchNotifications();

  @override
  Future<void> markRead(String id) => _dataSource.markRead(id);

  @override
  Future<void> markAllRead() => _dataSource.markAllRead();
}
