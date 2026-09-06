import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Centered icon + message for a route that's reachable but not built out
/// yet. Keeps every not-yet-implemented tab/screen consistent instead of each
/// one hand-rolling its own "coming soon" layout.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScope(
      child: Center(
        child: ContentContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: context.responsive(mobile: 56.0, tablet: 72.0),
                color: context.colors.secondary,
              ),
              AppSpacing.gapLg,
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (subtitle != null) ...[
                AppSpacing.gapSm,
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.colors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
