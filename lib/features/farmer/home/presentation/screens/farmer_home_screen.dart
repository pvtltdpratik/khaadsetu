import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/responsive/responsive_layout.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../soil_health/presentation/providers/soil_health_providers.dart';
import '../../../weather/presentation/providers/weather_providers.dart';
import '../../../weather/presentation/widgets/weather_strip.dart';
import '../providers/home_providers.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions_row.dart';
import '../widgets/smart_action_card.dart';
import '../widgets/soil_health_summary_card.dart';

class FarmerHomeScreen extends ConsumerWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(farmerProfileProvider);

    return ResponsiveScope(
      child: SafeArea(
        child: ListView(
          padding: context.pagePadding,
          children: [
            profileAsync.when(
              data: (profile) => HomeHeader(profile: profile),
              loading: () => const SizedBox(
                height: 56,
                child: AppLoadingIndicator(),
              ),
              error: (err, _) => AppErrorView(
                message: '$err',
                onRetry: () => ref.invalidate(farmerProfileProvider),
              ),
            ),
            AppSpacing.gapLg,
            _SmartActionSection(ref: ref),
            AppSpacing.gapLg,
            ResponsiveRow(
              spacing: AppSpacing.md,
              children: [
                _WeatherSection(ref: ref),
                _SoilHealthSection(ref: ref),
              ],
            ),
            AppSpacing.gapLg,
            QuickActionsRow(
              actions: [
                QuickAction(
                  icon: Icons.camera_alt_outlined,
                  label: 'Scan Soil',
                  onTap: () => context.go(RoutePaths.farmerSoilScan),
                ),
                QuickAction(
                  icon: Icons.storefront_outlined,
                  label: 'Marketplace',
                  onTap: () => context.go(RoutePaths.farmerMarketplace),
                ),
                QuickAction(
                  icon: Icons.groups_outlined,
                  label: 'Community',
                  onTap: () => context.go(RoutePaths.farmerCommunity),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartActionSection extends StatelessWidget {
  const _SmartActionSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final recommendationAsync = ref.watch(smartRecommendationProvider);
    return recommendationAsync.when(
      data: (recommendation) => SmartActionCard(
        recommendation: recommendation,
        onAction: () {
          final scanId = ref
              .read(soilHealthSummaryProvider)
              .whenOrNull(data: (summary) => summary.scanId);
          context.go(
            scanId != null
                ? RoutePaths.farmerSoilScanResult(scanId)
                : RoutePaths.farmerSoilScan,
          );
        },
      ),
      loading: () => const SizedBox(height: 180, child: AppLoadingIndicator()),
      error: (err, _) => AppErrorView(
        message: '$err',
        onRetry: () => ref.invalidate(smartRecommendationProvider),
      ),
    );
  }
}

class _WeatherSection extends StatelessWidget {
  const _WeatherSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final forecastAsync = ref.watch(weatherForecastProvider);
    return forecastAsync.when(
      data: (forecast) => WeatherStrip(forecast: forecast),
      loading: () => const SizedBox(height: 174, child: AppLoadingIndicator()),
      error: (err, _) => AppErrorView(
        message: '$err',
        onRetry: () => ref.invalidate(weatherForecastProvider),
      ),
    );
  }
}

class _SoilHealthSection extends StatelessWidget {
  const _SoilHealthSection({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(soilHealthSummaryProvider);
    return summaryAsync.when(
      data: (summary) => SoilHealthSummaryCard(
        summary: summary,
        onScanPressed: () => context.go(RoutePaths.farmerSoilScan),
        onViewDetails: summary.scanId == null
            ? null
            : () => context.go(RoutePaths.farmerSoilScanResult(summary.scanId!)),
      ),
      loading: () => const SizedBox(height: 174, child: AppLoadingIndicator()),
      error: (err, _) => AppErrorView(
        message: '$err',
        onRetry: () => ref.invalidate(soilHealthSummaryProvider),
      ),
    );
  }
}
