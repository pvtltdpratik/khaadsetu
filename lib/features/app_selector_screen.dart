import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive/responsive.dart';
import '../core/responsive/responsive_layout.dart';
import '../core/routing/route_paths.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_button.dart';

/// Dev-only landing screen for choosing which app to open. Stands in for the
/// role-based redirect a real login would perform once a backend exists.
class AppSelectorScreen extends StatelessWidget {
  const AppSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveScope(
        child: SafeArea(
          child: Center(
            child: ContentContainer(
              maxWidth: 640,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.eco_rounded,
                    size: context.responsive(mobile: 56.0, tablet: 72.0),
                    color: context.colors.primary,
                  ),
                  AppSpacing.gapMd,
                  Text(
                    'ShetSamrudhi',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  AppSpacing.gapXs,
                  Text(
                    'Choose an app to continue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: context.colors.textMuted),
                  ),
                  AppSpacing.gapXl,
                  ResponsiveRow(
                    spacing: AppSpacing.md,
                    children: [
                      AppButton(
                        label: 'Farmer App',
                        icon: Icons.agriculture_rounded,
                        expand: true,
                        onPressed: () => context.go(RoutePaths.farmerHome),
                      ),
                      AppButton(
                        label: 'Village Center Operator App',
                        icon: Icons.storefront_rounded,
                        variant: AppButtonVariant.outlined,
                        expand: true,
                        onPressed: () => context.go(RoutePaths.operatorDashboard),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
