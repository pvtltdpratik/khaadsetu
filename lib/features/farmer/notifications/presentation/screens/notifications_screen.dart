import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (!n.isRead) {
      try {
        await ref.read(notificationsRepositoryProvider).markRead(n.id);
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$err')));
        }
        return;
      }
      if (!context.mounted) return;
      _refreshUnreadState(ref);
    }

    final refId = n.refId;
    if (refId == null || !context.mounted) return;
    switch (n.type) {
      case NotificationType.scan:
        context.go(RoutePaths.farmerSoilScanResult(refId));
      case NotificationType.scheme:
        context.go(RoutePaths.farmerCommunityScheme(refId));
      case NotificationType.order:
        // The farmer app has no order screen yet; the notification text
        // already carries the pickup code, so opening it just marks it read.
        break;
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$err')));
      }
      return;
    }
    if (context.mounted) _refreshUnreadState(ref);
  }

  void _refreshUnreadState(WidgetRef ref) {
    ref.invalidate(notificationsProvider);
    ref.invalidate(farmerProfileProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final hasUnread =
        notificationsAsync.asData?.value.any((n) => !n.isRead) ?? false;

    return ResponsiveScope(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(RoutePaths.farmerHome),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (hasUnread)
                    TextButton(
                      onPressed: () => _markAllRead(context, ref),
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Breakpoints.maxContentWidth,
                  ),
                  child: notificationsAsync.when(
                    data: (items) => items.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.refresh(notificationsProvider.future),
                            child: ListView.separated(
                              padding: context.pagePadding,
                              itemCount: items.length,
                              separatorBuilder: (_, _) => AppSpacing.gapSm,
                              itemBuilder: (context, i) => NotificationTile(
                                notification: items[i],
                                onTap: () =>
                                    _openNotification(context, ref, items[i]),
                              ),
                            ),
                          ),
                    loading: () => const AppLoadingIndicator(),
                    error: (err, _) => AppErrorView(
                      message: '$err',
                      onRetry: () => ref.invalidate(notificationsProvider),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: colors.textMuted,
            ),
            AppSpacing.gapMd,
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.gapSm,
            Text(
              'Updates about your soil scans, orders and scheme applications will show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
