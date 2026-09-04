import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Stand-in for the Village Center Operator App dashboard until Phase 6
/// builds it out. Exists so the `/operator` route group is reachable and
/// testable end to end.
class OperatorPlaceholderScreen extends StatelessWidget {
  const OperatorPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operator App')),
      body: ResponsiveScope(
        child: Center(
          child: ContentContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_rounded,
                  size: context.responsive(mobile: 56.0, tablet: 72.0),
                  color: context.colors.secondary,
                ),
                AppSpacing.gapLg,
                Text(
                  'Operator dashboard arrives in Phase 6',
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
