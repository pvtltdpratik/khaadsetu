import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/datasources/notifications_api_data_source.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepositoryImpl(
    NotificationsApiDataSource(ref.watch(apiClientProvider)),
  );
});

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) {
    return ref.watch(notificationsRepositoryProvider).getNotifications();
  },
);
