import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../farmer/notifications/presentation/providers/notifications_providers.dart';

/// The operator's inbox: new app orders to prepare, low-stock alerts, and
/// replies from the platform. The badge counts what is still unread.
class OperatorNotificationBell extends ConsumerWidget {
  const OperatorNotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).asData?.value.where((n) => !n.isRead).length ?? 0;
    return IconButton(
      tooltip: unread == 0 ? 'Notifications' : '$unread unread notifications',
      onPressed: () => context.push(RoutePaths.operatorNotifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
