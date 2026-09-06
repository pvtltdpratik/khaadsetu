import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/responsive/responsive_layout.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/soil_health_gauge.dart';
import '../../domain/entities/soil_scan_result.dart';
import '../providers/soil_health_providers.dart';
import '../widgets/nutrient_breakdown_section.dart';

class SoilScanResultScreen extends ConsumerWidget {
  const SoilScanResultScreen({super.key, required this.scanId});

  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(soilScanResultProvider(scanId));

    return ResponsiveScope(
      child: SafeArea(
        child: resultAsync.when(
          data: (result) => _ResultBody(result: result),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(
            message: '$err',
            onRetry: () => ref.invalidate(soilScanResultProvider(scanId)),
          ),
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});

  final SoilScanResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final band = SoilHealthBand.fromScore(result.overallScore);

    return ListView(
      padding: context.pagePadding,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(RoutePaths.farmerSoilScan),
            ),
            AppSpacing.gapSm,
            Expanded(
              child: Text('Scan Result', style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        AppSpacing.gapMd,
        ResponsiveRow(
          spacing: AppSpacing.lg,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SoilHealthGauge(
                  size: context.responsive(mobile: 160.0, tablet: 180.0),
                  score: result.overallScore,
                ),
                AppSpacing.gapSm,
                if (band != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: band.color(colors).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      band.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: band.color(colors)),
                    ),
                  ),
                AppSpacing.gapSm,
                Text(
                  'Scanned ${_formatDate(result.scannedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Soil moisture',
                        value: '${result.soilMoisturePercent.round()}%',
                      ),
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: _StatTile(
                        label: 'Disease confidence',
                        value: '${result.diseaseConfidencePercent.round()}%',
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceSunken,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Disease indicators', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(result.disease, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        AppSpacing.gapLg,
        Text('Nutrient breakdown', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        NutrientBreakdownSection(nutrients: result.nutrients),
        AppSpacing.gapLg,
        Text('Recommendations', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        for (final recommendation in result.recommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 6, color: colors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(recommendation, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        AppSpacing.gapLg,
        ResponsiveRow(
          spacing: AppSpacing.sm,
          children: [
            AppButton(
              label: 'Scan again',
              icon: Icons.camera_alt_outlined,
              expand: true,
              onPressed: () => context.go(RoutePaths.farmerSoilScan),
            ),
            AppButton(
              label: 'View history',
              icon: Icons.history_rounded,
              variant: AppButtonVariant.outlined,
              expand: true,
              onPressed: () => context.go(RoutePaths.farmerSoilScanHistory),
            ),
          ],
        ),
      ],
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    return '${date.day} ${_months[date.month - 1]}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
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
