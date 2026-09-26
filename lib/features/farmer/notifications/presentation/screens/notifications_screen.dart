import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/auth/session_profile.dart';
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
import '../../../../push/domain/push_models.dart';
import '../notification_navigation.dart';
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

    if (!context.mounted) return;
    await openNotificationTarget(GoRouter.of(context), ref.read, n.type, n.refId);
  }

  AppRole? _role(WidgetRef ref) => ref.read(sessionProfileProvider).value?.role;

  String _homeFor(WidgetRef ref) => switch (_role(ref)) {
        AppRole.operator => RoutePaths.operatorDashboard,
        AppRole.admin => RoutePaths.adminOverview,
        _ => RoutePaths.farmerHome,
      };

  String _settingsFor(WidgetRef ref) => switch (_role(ref)) {
        AppRole.operator => RoutePaths.operatorNotificationSettings,
        AppRole.admin => RoutePaths.adminNotificationSettings,
        _ => RoutePaths.farmerNotificationSettings,
      };

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
    // The back button and where a tap leads depend on the role, so keep it loaded.
    ref.watch(sessionProfileProvider);
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
                        : context.go(_homeFor(ref)),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const Key('notification-settings'),
                    tooltip: 'Notification settings',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => context.push(_settingsFor(ref)),
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
                    data: (all) {
                      if (all.isEmpty) return const _EmptyState();
                      final filter = ref.watch(notificationFilterProvider);
                      final items = filter == null ? all : all.where((n) => n.channel == filter).toList();
                      return Column(
                        children: [
                          _FilterChips(all: all, selected: filter),
                          Expanded(
                            child: items.isEmpty
                                ? Center(child: Text('Nothing in this category', key: const Key('none-in-category'), style: Theme.of(context).textTheme.bodyMedium))
                                : RefreshIndicator(
                                    onRefresh: () => ref.refresh(notificationsProvider.future),
                                    child: ListView.separated(
                                      padding: context.pagePadding,
                                      itemCount: items.length,
                                      separatorBuilder: (_, _) => AppSpacing.gapSm,
                                      itemBuilder: (context, i) => NotificationTile(
                                        notification: items[i],
                                        onTap: () => _openNotification(context, ref, items[i]),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
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

/// "All" and one chip per category that has something in it, with how many are unread.
class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.all, required this.selected});

  final List<AppNotification> all;
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final present = pushChannels.where((c) => all.any((n) => n.channel == c.id)).toList();
    if (present.length < 2) return const SizedBox.shrink();
    int unread(String? channel) => all.where((n) => !n.isRead && (channel == null || n.channel == channel)).length;
    Widget chip(String key, String label, String? channel) {
      final count = unread(channel);
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          key: Key(key),
          label: Text(count > 0 ? '$label ($count)' : label),
          selected: selected == channel,
          onSelected: (_) => ref.read(notificationFilterProvider.notifier).choose(channel),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(children: [chip('filter-all', 'All', null), for (final c in present) chip('filter-${c.id}', c.label, c.id)]),
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
