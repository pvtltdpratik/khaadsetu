import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animation/motion.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../farmer/notifications/presentation/providers/notifications_providers.dart';

/// The operator's inbox: new app orders to prepare, low-stock alerts, and
/// replies from the platform. The badge counts what is still unread, and the
/// bell gives a short shake each time that number changes, so a new order
/// catches the eye without any sound or popup.
class OperatorNotificationBell extends ConsumerWidget {
  const OperatorNotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsProvider).asData?.value.where((n) => !n.isRead).length ?? 0;
    final bell = Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 9 ? '9+' : '$unread'),
      child: const Icon(Icons.notifications_outlined),
    );
    return IconButton(
      tooltip: unread == 0 ? 'Notifications' : '$unread unread notifications',
      onPressed: () => context.push(RoutePaths.operatorNotifications),
      icon: unread == 0 || Motion.reduced(context)
          ? bell
          : TweenAnimationBuilder<double>(
              // A new key restarts the shake whenever the unread count changes.
              key: ValueKey(unread),
              tween: Tween<double>(begin: 0, end: 1),
              duration: Motion.slow,
              builder: (context, t, child) => Transform.rotate(
                angle: math.sin(t * math.pi * 4) * (1 - t) * 0.35,
                alignment: Alignment.topCenter,
                child: child,
              ),
              child: bell,
            ),
    );
  }
}
