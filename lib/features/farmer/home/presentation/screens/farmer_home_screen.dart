import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/responsive/responsive_layout.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/sign_out_button.dart';
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
            if (!context.breakpoint.isTabletUp) const Align(alignment: Alignment.centerRight, child: SignOutButton()),
            profileAsync.when(
              data: (profile) => HomeHeader(
                profile: profile,
                onNotificationsTap: () => context.push(RoutePaths.farmerNotifications),
              ),
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
            // The home page settles in section by section, top to bottom.
            FadeSlideIn(index: 1, child: _SmartActionSection(ref: ref)),
            AppSpacing.gapLg,
            FadeSlideIn(
              index: 2,
              child: ResponsiveRow(
                spacing: AppSpacing.md,
                children: [
                  _WeatherSection(ref: ref),
                  _SoilHealthSection(ref: ref),
                ],
              ),
            ),
            AppSpacing.gapLg,
            FadeSlideIn(
              index: 3,
              child: QuickActionsRow(
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
                  icon: Icons.smart_toy_outlined,
                  label: 'Ask AI',
                  onTap: () => context.push(RoutePaths.farmerAssistant),
                ),
                QuickAction(
                  icon: Icons.groups_outlined,
                  label: 'Community',
                  onTap: () => context.go(RoutePaths.farmerCommunity),
                ),
                QuickAction(
                  icon: Icons.location_on_outlined,
                  label: 'Nearby Centers',
                  onTap: () => context.push(RoutePaths.farmerCenters),
                ),
                QuickAction(
                  icon: Icons.receipt_long_outlined,
                  label: 'My Orders',
                  onTap: () => context.push(RoutePaths.farmerOrders),
                ),
                QuickAction(
                  icon: Icons.local_shipping_outlined,
                  label: 'Deliver & Earn',
                  onTap: () => context.push(RoutePaths.farmerDeliver),
                ),
                QuickAction(
                  icon: Icons.inventory_2_outlined,
                  label: 'Send a Load',
                  onTap: () => context.push(RoutePaths.farmerLoads),
                ),
              ],
            ),
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
