import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animation/animated_count.dart';
import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/animation/motion.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/sign_out_button.dart';
import '../../domain/entities/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

String _query(String base, String key, String value) => '$base?$key=$value';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminOverviewProvider);
    return ResponsiveScope(
      child: RefreshIndicator(
        onRefresh: () async {
          refreshAdminData(ref);
          await ref.read(adminOverviewProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ContentContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Platform overview', style: Theme.of(context).textTheme.headlineSmall)),
                      if (!context.breakpoint.isTabletUp) const SignOutButton(),
                    ],
                  ),
                  AppSpacing.gapMd,
                  overview.when(
                    data: (o) => _OverviewBody(overview: o),
                    loading: () => const SizedBox(height: 200, child: AppLoadingIndicator()),
                    error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(adminOverviewProvider)),
                  ),
                  AppSpacing.gapLg,
                  const _RecentActivity(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.overview});

  final AdminOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final o = overview;

    // Things an admin should act on, most urgent first.
    final attention = <Widget>[
      if (o.operators.unassigned > 0)
        _AttentionTile(
          icon: Icons.hourglass_top_rounded,
          color: colors.warning,
          text: '${o.operators.unassigned} operator${o.operators.unassigned == 1 ? '' : 's'} waiting for a center',
          onTap: () => context.go(_query(RoutePaths.adminOperators, 'segment', 'unassigned')),
        ),
      if (o.centersWithoutOperator > 0)
        _AttentionTile(
          icon: Icons.person_off_outlined,
          color: colors.warning,
          text: '${o.centersWithoutOperator} center${o.centersWithoutOperator == 1 ? '' : 's'} without an operator',
          onTap: () => context.go(_query(RoutePaths.adminCenters, 'filter', 'noOperator')),
        ),
      if (o.restockPending > 0)
        _AttentionTile(icon: Icons.local_shipping_outlined, color: colors.info, text: '${o.restockPending} restock request${o.restockPending == 1 ? '' : 's'} pending approval', onTap: () => context.go(RoutePaths.adminSupply)),
      if (o.lowStockUnattended > 0)
        _AttentionTile(icon: Icons.notification_important_outlined, color: colors.danger, text: '${o.lowStockUnattended} product${o.lowStockUnattended == 1 ? '' : 's'} still low a day after the operator was alerted'),
      if (o.discrepanciesOpen > 0)
        _AttentionTile(icon: Icons.fact_check_outlined, color: colors.warning, text: '${o.discrepanciesOpen} delivery report${o.discrepanciesOpen == 1 ? '' : 's'} to review', onTap: () => context.go(_query(RoutePaths.adminSupply, 'tab', 'discrepancies'))),
      if ((o.delivery?.needDriver ?? 0) > 0)
        _AttentionTile(icon: Icons.local_shipping_outlined, color: colors.warning, text: '${o.delivery!.needDriver} home deliver${o.delivery!.needDriver == 1 ? 'y has' : 'ies have'} no driver yet', onTap: () => context.push(RoutePaths.adminDelivery)),
      if ((o.delivery?.partnersPending ?? 0) > 0)
        _AttentionTile(icon: Icons.badge_outlined, color: colors.info, text: '${o.delivery!.partnersPending} delivery partner${o.delivery!.partnersPending == 1 ? '' : 's'} waiting for a village center to check', onTap: () => context.push(RoutePaths.adminDelivery)),
      if (o.lowStockItems > 0)
        _AttentionTile(icon: Icons.inventory_2_outlined, color: colors.danger, text: '${o.lowStockItems} product${o.lowStockItems == 1 ? '' : 's'} running low across centers'),
    ];

    final cards = [
      _StatCard(
        icon: Icons.storefront_rounded,
        title: 'Operators',
        total: o.operators.total,
        lines: [
          _Line('Active', o.operators.active, colors.success, () => context.go(_query(RoutePaths.adminOperators, 'segment', 'active'))),
          _Line('Awaiting center', o.operators.unassigned, colors.warning, () => context.go(_query(RoutePaths.adminOperators, 'segment', 'unassigned'))),
          _Line('Suspended', o.operators.suspended, colors.danger, () => context.go(_query(RoutePaths.adminOperators, 'segment', 'suspended'))),
        ],
        onTap: () => context.go(RoutePaths.adminOperators),
      ),
      _StatCard(
        icon: Icons.agriculture_rounded,
        title: 'Farmers',
        total: o.farmers.total,
        lines: [
          _Line('Active', o.farmers.active, colors.success, () => context.go(_query(RoutePaths.adminFarmers, 'segment', 'active'))),
          _Line('Suspended', o.farmers.suspended, colors.danger, () => context.go(_query(RoutePaths.adminFarmers, 'segment', 'suspended'))),
        ],
        onTap: () => context.go(RoutePaths.adminFarmers),
      ),
      _StatCard(
        icon: Icons.location_on_rounded,
        title: 'Village centers',
        total: o.centersActive + o.centersSuspended,
        lines: [
          _Line('Active', o.centersActive, colors.success, () => context.go(_query(RoutePaths.adminCenters, 'filter', 'active'))),
          _Line('Suspended', o.centersSuspended, colors.danger, () => context.go(_query(RoutePaths.adminCenters, 'filter', 'suspended'))),
        ],
        onTap: () => context.go(RoutePaths.adminCenters),
      ),
      _StatCard(
        icon: Icons.sell_rounded,
        title: 'Surplus on sale',
        total: o.surplusActiveLots,
        totalLabel: 'offers',
        lines: [
          _Line('Units left', o.surplusUnits, colors.success, () => context.go(_query(RoutePaths.adminSupply, 'tab', 'surplus'))),
        ],
        onTap: () => context.go(_query(RoutePaths.adminSupply, 'tab', 'surplus')),
      ),
      _StatCard(
        icon: Icons.local_shipping_rounded,
        title: 'Home delivery',
        total: o.delivery?.onTheRoad ?? 0,
        totalLabel: 'on the road',
        lines: [
          _Line('Waiting for a driver', o.delivery?.waiting ?? 0, colors.warning, () => context.push(RoutePaths.adminDelivery)),
          _Line('Delivered today', o.delivery?.deliveredToday ?? 0, colors.success, () => context.push(RoutePaths.adminDelivery)),
          _Line('Partners approved', o.delivery?.partnersApproved ?? 0, colors.info, () => context.push(RoutePaths.adminDelivery)),
        ],
        onTap: () => context.push(RoutePaths.adminDelivery),
      ),
      _StatCard(
        icon: Icons.receipt_long_rounded,
        title: 'Orders',
        total: o.ordersToday,
        totalLabel: 'today',
        lines: [
          _Line('Pending', o.ordersPending, colors.warning, null),
          _Line('Ready for pickup', o.ordersReadyForPickup, colors.info, null),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attention.isNotEmpty) ...[
          Text('Needs attention', style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.gapSm,
          for (final (i, tile) in attention.indexed) FadeSlideIn(index: i, child: tile),
          AppSpacing.gapLg,
        ] else ...[
          _AttentionTile(icon: Icons.check_circle_outline_rounded, color: colors.success, text: 'Nothing needs attention right now'),
          AppSpacing.gapLg,
        ],
        Text('People, centers and orders', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        // The cards land one after another, a beat after the attention list.
        ResponsiveRow(spacing: AppSpacing.md, children: [for (var i = 0; i < 2; i++) FadeSlideIn(delay: Motion.delayFor(attention.length + i), child: cards[i])]),
        AppSpacing.gapMd,
        ResponsiveRow(spacing: AppSpacing.md, children: [for (var i = 2; i < 4; i++) FadeSlideIn(delay: Motion.delayFor(attention.length + i), child: cards[i])]),
        AppSpacing.gapMd,
        ResponsiveRow(spacing: AppSpacing.md, children: [for (var i = 4; i < 6; i++) FadeSlideIn(delay: Motion.delayFor(attention.length + i), child: cards[i])]),
      ],
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.icon, required this.color, required this.text, this.onTap});

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
                if (onTap != null) Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line {
  const _Line(this.label, this.count, this.color, this.onTap);

  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.title, required this.total, required this.lines, this.onTap, this.totalLabel});

  final IconData icon;
  final String title;
  final int total;
  final String? totalLabel;
  final List<_Line> lines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(title, style: text.titleSmall)),
                  AnimatedCount(value: total, style: text.headlineSmall),
                  if (totalLabel != null) Text(' $totalLabel', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                ],
              ),
              AppSpacing.gapSm,
              for (final line in lines)
                InkWell(
                  onTap: line.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: line.color, shape: BoxShape.circle)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(line.label, style: text.bodyMedium)),
                        AnimatedCount(value: line.count, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activity = ref.watch(adminRecentActivityProvider);
    return SectionCard(
      title: 'Recent admin activity',
      child: activity.when(
        data: (entries) => entries.isEmpty
            ? Text('Nothing yet. Suspensions, assignments and approvals will appear here.', style: TextStyle(color: colors.textMuted))
            : Column(
                children: [
                  for (final e in entries)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.history_rounded, color: colors.textMuted, size: 20),
                      title: Text(e.summary),
                      subtitle: Text('${e.adminEmail.isEmpty ? 'An admin' : e.adminEmail} · ${_ago(e.createdAt)}'),
                    ),
                ],
              ),
        loading: () => const SizedBox(height: 60, child: AppLoadingIndicator()),
        error: (err, _) => Text('$err', style: TextStyle(color: colors.danger)),
      ),
    );
  }
}

String _ago(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}
