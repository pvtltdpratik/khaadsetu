import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../providers/soil_health_providers.dart';
import '../widgets/soil_scan_history_tile.dart';

class SoilScanHistoryScreen extends ConsumerWidget {
  const SoilScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(soilScanHistoryProvider);

    return ResponsiveScope(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go(RoutePaths.farmerSoilScan),
                  ),
                  AppSpacing.gapSm,
                  Text('Scan History', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
                  child: historyAsync.when(
                    data: (scans) => scans.isEmpty
                        ? Center(
                            child: Text(
                              'No scans yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: context.colors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            padding: context.pagePadding,
                            itemCount: scans.length,
                            separatorBuilder: (_, _) => AppSpacing.gapSm,
                            itemBuilder: (context, i) {
                              final scan = scans[i];
                              return SoilScanHistoryTile(
                                result: scan,
                                onTap: () => context.push(RoutePaths.farmerSoilScanResult(scan.id)),
                              );
                            },
                          ),
                    loading: () => const AppLoadingIndicator(),
                    error: (err, _) => AppErrorView(
                      message: '$err',
                      onRetry: () => ref.invalidate(soilScanHistoryProvider),
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
