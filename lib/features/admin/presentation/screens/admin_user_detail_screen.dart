import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

String _date(DateTime? d) => d == null ? 'Unknown' : '${d.day}/${d.month}/${d.year}';

/// One operator or farmer: who they are, what they have done, and the admin's
/// controls (suspend / reactivate; for operators, which center they run).
class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminUserDetailProvider(userId));
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Person')),
        body: SafeArea(
          child: detail.when(
            data: (d) => _Body(detail: d),
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(adminUserDetailProvider(userId))),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.detail});

  final AdminUserDetail detail;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  /// Runs an admin action, then refreshes everything and reports the outcome.
  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      refreshAdminData(ref);
      if (mounted) showMessage(context, done);
    } catch (err) {
      if (mounted) showMessage(context, '$err');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleSuspend(AdminUser user) async {
    final suspending = !user.isSuspended;
    final reason = await confirmAction(
      context,
      title: suspending ? 'Suspend ${user.displayName}?' : 'Reactivate ${user.displayName}?',
      message: suspending
          ? 'They will be locked out of the app immediately.${user.role == PersonRole.operator && user.centerId != null ? ' Their center will stop taking orders and will no longer be offered to farmers.' : ''}'
          : 'They will be able to use the app again.',
      confirmLabel: suspending ? 'Suspend' : 'Reactivate',
      destructive: suspending,
      askReason: suspending,
    );
    if (reason == null) return;
    await _run(
      () => ref.read(adminRepositoryProvider).setUserStatus(user.userId, suspended: suspending, reason: reason),
      suspending ? '${user.displayName} suspended' : '${user.displayName} reactivated',
    );
  }

  Future<void> _assignCenter(AdminUser user) async {
    final repo = ref.read(adminRepositoryProvider);
    final centers = await repo.centers(status: 'active', hasOperator: false);
    if (!mounted) return;
    final picked = await pickOne<AdminCenter>(
      context,
      title: 'Assign a center',
      options: centers,
      titleOf: (c) => c.name,
      subtitleOf: (c) => c.place,
      emptyMessage: 'No active centers are without an operator. Create a center first.',
    );
    if (picked == null) return;
    await _run(() => repo.assignOperator(picked.centerId, user.userId), '${user.displayName} now runs ${picked.name}');
  }

  Future<void> _removeFromCenter(AdminUser user) async {
    final ok = await confirmAction(
      context,
      title: 'Remove from ${user.centerName}?',
      message: '${user.displayName} will no longer run this center, and it will not be offered to farmers until you assign someone else.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (ok == null) return;
    await _run(() => ref.read(adminRepositoryProvider).assignOperator(user.centerId!, null), 'Removed from ${user.centerName}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final d = widget.detail;
    final user = d.user;
    final isOperator = user.role == PersonRole.operator;
    final totalOrders = d.ordersByStatus.values.fold<int>(0, (a, b) => a + b);

    return ListView(
      children: [
        ContentContainer(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primaryContainer,
                    child: Text(user.displayName.characters.first.toUpperCase(), style: TextStyle(fontSize: 20, color: colors.primary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: text.titleLarge),
                        if (user.email.isNotEmpty) Text(user.email, style: text.bodySmall?.copyWith(color: colors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  StatusBadge(label: isOperator ? 'Operator' : 'Farmer', color: colors.info),
                  SegmentBadge(segment: user.segment),
                ],
              ),
              AppSpacing.gapLg,
              SectionCard(
                title: 'Details',
                child: Column(
                  children: [
                    InfoRow(label: 'Joined', value: _date(user.createdAt)),
                    InfoRow(label: 'Last seen', value: _date(user.lastSeenAt)),
                    if (isOperator)
                      InfoRow(
                        label: 'Center',
                        value: user.centerName ?? 'None assigned',
                        onTap: user.centerId == null ? null : () => context.push(RoutePaths.adminCenter(user.centerId!)),
                      )
                    else ...[
                      InfoRow(label: 'Village', value: (user.village ?? '').isEmpty ? 'Not set' : user.village!),
                      if (user.landHoldingHectares != null) InfoRow(label: 'Land holding', value: '${user.landHoldingHectares} ha'),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapMd,
              SectionCard(
                title: 'Activity',
                child: Column(
                  children: [
                    InfoRow(label: 'Orders', value: totalOrders == 0 ? 'None' : '$totalOrders'),
                    for (final entry in d.ordersByStatus.entries) InfoRow(label: '  ${entry.key}', value: '${entry.value}'),
                    InfoRow(label: 'Soil scans', value: '${d.scans}'),
                  ],
                ),
              ),
              AppSpacing.gapLg,
              Text('Actions', style: text.titleMedium),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    style: user.isSuspended ? null : FilledButton.styleFrom(backgroundColor: colors.danger, foregroundColor: colors.onDanger),
                    onPressed: _busy ? null : () => _toggleSuspend(user),
                    icon: Icon(user.isSuspended ? Icons.lock_open_rounded : Icons.block_rounded),
                    label: Text(user.isSuspended ? 'Reactivate' : 'Suspend'),
                  ),
                  if (isOperator && user.centerId == null && !user.isSuspended)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _assignCenter(user),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Assign a center'),
                    ),
                  if (isOperator && user.centerId != null)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _removeFromCenter(user),
                      icon: const Icon(Icons.person_remove_outlined),
                      label: const Text('Remove from center'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
