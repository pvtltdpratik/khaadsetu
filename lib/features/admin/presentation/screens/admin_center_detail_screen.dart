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

/// One village center: its details, who runs it, the admin's controls, and
/// what is on its shelves.
class AdminCenterDetailScreen extends ConsumerWidget {
  const AdminCenterDetailScreen({super.key, required this.centerId});

  final String centerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.watch(adminCenterProvider(centerId));
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Village center')),
        body: SafeArea(
          child: center.when(
            data: (c) => _Body(center: c),
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(adminCenterProvider(centerId))),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.center});

  final AdminCenter center;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

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

  Future<void> _toggleSuspend(AdminCenter c) async {
    final suspending = !c.isSuspended;
    final ok = await confirmAction(
      context,
      title: suspending ? 'Suspend ${c.name}?' : 'Reactivate ${c.name}?',
      message: suspending
          ? 'It will stop taking orders and will no longer be offered to farmers. Orders already placed stay as they are.'
          : 'It will be offered to farmers again.',
      confirmLabel: suspending ? 'Suspend' : 'Reactivate',
      destructive: suspending,
    );
    if (ok == null) return;
    await _run(() => ref.read(adminRepositoryProvider).setCenterSuspended(c.centerId, suspended: suspending), suspending ? '${c.name} suspended' : '${c.name} reactivated');
  }

  Future<void> _assign(AdminCenter c) async {
    final repo = ref.read(adminRepositoryProvider);
    final operators = await repo.users(role: PersonRole.operator, segment: PersonSegment.unassigned);
    if (!mounted) return;
    final picked = await pickOne<AdminUser>(
      context,
      title: 'Choose an operator',
      options: operators,
      titleOf: (u) => u.displayName,
      subtitleOf: (u) => u.email,
      emptyMessage: 'No operators are waiting for a center. Ask the operator to sign up first.',
    );
    if (picked == null) return;
    await _run(() => repo.assignOperator(c.centerId, picked.userId), '${picked.displayName} now runs ${c.name}');
  }

  Future<void> _unassign(AdminCenter c) async {
    final ok = await confirmAction(
      context,
      title: 'Remove ${c.operatorLabel}?',
      message: 'This center will have no operator, so it will not be offered to farmers until you assign someone.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (ok == null) return;
    await _run(() => ref.read(adminRepositoryProvider).assignOperator(c.centerId, null), 'Operator removed');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final c = widget.center;
    final stock = ref.watch(adminCenterStockProvider(c.centerId));

    return ListView(
      children: [
        ContentContainer(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name, style: text.headlineSmall),
              Text(c.place, style: text.bodyMedium?.copyWith(color: colors.textMuted)),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  c.isSuspended
                      ? StatusBadge(label: 'Suspended', color: colors.danger, icon: Icons.block_rounded)
                      : StatusBadge(label: 'Active', color: colors.success, icon: Icons.check_circle_outline_rounded),
                  c.isOpen
                      ? StatusBadge(label: 'Open for business', color: colors.info)
                      : StatusBadge(label: 'Closed by operator', color: colors.textMuted),
                  if (!c.hasOperator) StatusBadge(label: 'No operator', color: colors.warning, icon: Icons.person_off_outlined),
                ],
              ),
              AppSpacing.gapLg,
              SectionCard(
                title: 'Details',
                child: Column(
                  children: [
                    InfoRow(label: 'Hours', value: '${c.opensAt} – ${c.closesAt}'),
                    InfoRow(label: 'Phone', value: c.phone.isEmpty ? 'Not set' : c.phone),
                    InfoRow(label: 'Location', value: '${c.latitude.toStringAsFixed(4)}, ${c.longitude.toStringAsFixed(4)}'),
                    InfoRow(label: 'Pending orders', value: '${c.pendingOrders}'),
                    InfoRow(
                      label: 'Operator',
                      value: c.operatorLabel ?? 'None assigned',
                      onTap: c.operatorId == null ? null : () => context.push(RoutePaths.adminOperator(c.operatorId!)),
                    ),
                    if (c.operatorStatus == 'suspended') InfoRow(label: '', value: 'This operator is suspended, so the center cannot serve farmers.'),
                  ],
                ),
              ),
              AppSpacing.gapMd,
              SectionCard(
                title: 'Stock',
                child: stock.when(
                  data: (items) => items.isEmpty
                      ? Text('Nothing on the shelves yet.', style: TextStyle(color: colors.textMuted))
                      : Column(children: [for (final i in items) _StockRow(item: i)]),
                  loading: () => const SizedBox(height: 60, child: AppLoadingIndicator()),
                  error: (err, _) => Text('$err', style: TextStyle(color: colors.danger)),
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
                    style: c.isSuspended ? null : FilledButton.styleFrom(backgroundColor: colors.danger, foregroundColor: colors.onDanger),
                    onPressed: _busy ? null : () => _toggleSuspend(c),
                    icon: Icon(c.isSuspended ? Icons.lock_open_rounded : Icons.block_rounded),
                    label: Text(c.isSuspended ? 'Reactivate center' : 'Suspend center'),
                  ),
                  if (!c.hasOperator)
                    OutlinedButton.icon(onPressed: _busy ? null : () => _assign(c), icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text('Assign operator')),
                  if (c.hasOperator)
                    OutlinedButton.icon(onPressed: _busy ? null : () => _unassign(c), icon: const Icon(Icons.person_remove_outlined), label: const Text('Remove operator')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: text.bodyMedium),
                Text(
                  [
                    '${item.onHand} on hand',
                    if (item.reserved > 0) '${item.reserved} reserved',
                    if (item.incoming > 0) '${item.incoming} incoming',
                  ].join(' · '),
                  style: text.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          if (item.isLow) StatusBadge(label: 'Low', color: colors.danger, icon: Icons.warning_amber_rounded),
          const SizedBox(width: AppSpacing.sm),
          Text('${item.available} ${item.unit}', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
