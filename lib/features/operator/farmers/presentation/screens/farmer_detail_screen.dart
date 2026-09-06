import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/farmer.dart';
import '../providers/farmers_providers.dart';

class FarmerDetailScreen extends ConsumerWidget {
  const FarmerDetailScreen({super.key, required this.farmerId});

  final String farmerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmerAsync = ref.watch(farmerProvider(farmerId));

    return ResponsiveScope(
      child: SafeArea(
        child: farmerAsync.when(
          data: (farmer) => _FarmerBody(farmer: farmer),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(
            message: '$err',
            onRetry: () => ref.invalidate(farmerProvider(farmerId)),
          ),
        ),
      ),
    );
  }
}

class _FarmerBody extends StatelessWidget {
  const _FarmerBody({required this.farmer});

  final Farmer farmer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: context.pagePadding,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(RoutePaths.operatorFarmers),
            ),
            AppSpacing.gapSm,
            Expanded(child: Text('Farmer Details', style: Theme.of(context).textTheme.titleLarge)),
            if (farmer.needsFollowUp)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                child: Text('Follow up', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.warning)),
              ),
          ],
        ),
        AppSpacing.gapMd,
        Text(farmer.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(farmer.village, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
        AppSpacing.gapLg,
        Row(
          children: [
            Expanded(child: _InfoTile(label: 'Active crop', value: farmer.activeCrop)),
            AppSpacing.gapSm,
            Expanded(child: _InfoTile(label: 'Phone', value: farmer.phone)),
          ],
        ),
        AppSpacing.gapSm,
        _InfoTile(label: 'Last visit', value: _formatDate(farmer.lastVisitDate)),
        AppSpacing.gapLg,
        Text('Notes', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
          child: Text(farmer.notes, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
