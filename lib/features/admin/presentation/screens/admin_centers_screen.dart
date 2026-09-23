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

/// The categories a centers list can be filtered by.
enum CenterFilter { active, suspended, noOperator }

CenterFilter? centerFilterFromQuery(String? raw) {
  for (final f in CenterFilter.values) {
    if (f.name == raw) return f;
  }
  return null;
}

class AdminCentersScreen extends ConsumerStatefulWidget {
  const AdminCentersScreen({super.key, this.initialFilter});

  final CenterFilter? initialFilter;

  @override
  ConsumerState<AdminCentersScreen> createState() => _AdminCentersScreenState();
}

class _AdminCentersScreenState extends ConsumerState<AdminCentersScreen> {
  late CenterFilter? _filter = widget.initialFilter;
  String _search = '';

  CentersQuery get _query => CentersQuery(
        status: switch (_filter) {
          CenterFilter.active => 'active',
          CenterFilter.suspended => 'suspended',
          _ => null,
        },
        hasOperator: _filter == CenterFilter.noOperator ? false : null,
        q: _search,
      );

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final centers = ref.watch(adminCentersProvider(query));
    final overview = ref.watch(adminOverviewProvider).value;

    return ResponsiveScope(
      child: ContentContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Village centers', style: Theme.of(context).textTheme.headlineSmall)),
                FilledButton.icon(
                  onPressed: () => context.push(RoutePaths.adminCenterNew),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New center'),
                ),
              ],
            ),
            AppSpacing.gapMd,
            DebouncedSearchField(hint: 'Search by name, village or district', onChanged: (v) => setState(() => _search = v)),
            AppSpacing.gapSm,
            FilterChips<CenterFilter>(
              options: const {
                null: 'All',
                CenterFilter.active: 'Active',
                CenterFilter.suspended: 'Suspended',
                CenterFilter.noOperator: 'No operator',
              },
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
              countFor: overview == null
                  ? null
                  : (f) => switch (f) {
                        null => overview.centersActive + overview.centersSuspended,
                        CenterFilter.active => overview.centersActive,
                        CenterFilter.suspended => overview.centersSuspended,
                        CenterFilter.noOperator => overview.centersWithoutOperator,
                      },
            ),
            AppSpacing.gapMd,
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  refreshAdminData(ref);
                  await ref.read(adminCentersProvider(query).future);
                },
                child: centers.when(
                  data: (list) => list.isEmpty
                      ? ListView(children: [_Empty(filtered: _filter != null || _search.isNotEmpty)])
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, _) => AppSpacing.gapSm,
                          itemBuilder: (context, i) => CenterTile(center: list[i], onTap: () => context.push(RoutePaths.adminCenter(list[i].centerId))),
                        ),
                  loading: () => const AppLoadingIndicator(),
                  error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(adminCentersProvider(query))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, size: 40, color: colors.textMuted),
          AppSpacing.gapSm,
          Text(
            filtered ? 'No centers match these filters' : 'No village centers yet. Create the first one.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// One center in a list: where, who runs it, and how it is doing.
class CenterTile extends StatelessWidget {
  const CenterTile({super.key, required this.center, required this.onTap});

  final AdminCenter center;
  final VoidCallback onTap;

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
                  Expanded(child: Text(center.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall)),
                  const SizedBox(width: AppSpacing.sm),
                  center.isSuspended
                      ? StatusBadge(label: 'Suspended', color: colors.danger, icon: Icons.block_rounded)
                      : StatusBadge(label: 'Active', color: colors.success, icon: Icons.check_circle_outline_rounded),
                ],
              ),
              Text(center.place, style: text.bodySmall?.copyWith(color: colors.textMuted)),
              AppSpacing.gapSm,
              Row(
                children: [
                  Icon(center.hasOperator ? Icons.person_outline_rounded : Icons.person_off_outlined, size: 16, color: center.hasOperator ? colors.textMuted : colors.warning),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      center.operatorLabel ?? 'No operator assigned',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: center.hasOperator ? null : colors.warning),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapXs,
              Wrap(
                spacing: AppSpacing.md,
                children: [
                  _Metric(icon: Icons.inventory_2_outlined, label: '${center.productsStocked} products'),
                  if (center.lowStockCount > 0) _Metric(icon: Icons.warning_amber_rounded, label: '${center.lowStockCount} low', color: colors.danger),
                  _Metric(icon: Icons.receipt_long_outlined, label: '${center.pendingOrders} pending'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c)),
      ],
    );
  }
}
