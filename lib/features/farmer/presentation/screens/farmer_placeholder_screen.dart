import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/soil_health_gauge.dart';

/// Stand-in for the Farmer App home screen until Phase 2 builds it out.
/// Exists so the `/farmer` route group is reachable and testable end to end.
class FarmerPlaceholderScreen extends StatelessWidget {
  const FarmerPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer App')),
      body: ResponsiveScope(
        child: Center(
          child: ContentContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SoilHealthGauge(
                  size: context.responsive(mobile: 120.0, tablet: 160.0),
                ),
                AppSpacing.gapLg,
                Text(
                  'Farmer home arrives in Phase 2',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                AppSpacing.gapSm,
                Text(
                  'Breakpoint: ${context.breakpoint.name}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
