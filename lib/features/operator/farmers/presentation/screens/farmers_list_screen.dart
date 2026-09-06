import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../providers/farmers_providers.dart';
import '../widgets/farmer_card.dart';

class FarmersListScreen extends ConsumerStatefulWidget {
  const FarmersListScreen({super.key});

  @override
  ConsumerState<FarmersListScreen> createState() => _FarmersListScreenState();
}

class _FarmersListScreenState extends ConsumerState<FarmersListScreen> {
  bool _followUpOnly = false;

  @override
  Widget build(BuildContext context) {
    final farmersAsync = ref.watch(farmersProvider);

    return ResponsiveScope(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Farmers', style: Theme.of(context).textTheme.titleLarge)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !_followUpOnly,
                    onSelected: (_) => setState(() => _followUpOnly = false),
                  ),
                  AppSpacing.gapSm,
                  ChoiceChip(
                    label: const Text('Needs follow-up'),
                    selected: _followUpOnly,
                    onSelected: (_) => setState(() => _followUpOnly = true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: farmersAsync.when(
                data: (farmers) {
                  final filtered = _followUpOnly ? farmers.where((f) => f.needsFollowUp).toList() : farmers;
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        _followUpOnly ? 'No farmers need follow-up right now' : 'No farmers yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
                      ),
                    );
                  }
                  if (!context.breakpoint.isTabletUp) {
                    return ListView.separated(
                      padding: context.pagePadding,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => AppSpacing.gapSm,
                      itemBuilder: (context, i) => FarmerCard(
                        farmer: filtered[i],
                        onTap: () => context.push(RoutePaths.operatorFarmerDetail(filtered[i].id)),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: context.pagePadding,
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: context.gridColumns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (context, i) => FarmerCard(
                      farmer: filtered[i],
                      onTap: () => context.push(RoutePaths.operatorFarmerDetail(filtered[i].id)),
                    ),
                  );
                },
                loading: () => const AppLoadingIndicator(),
                error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(farmersProvider)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
