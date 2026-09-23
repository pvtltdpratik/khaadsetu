import 'package:flutter/material.dart';

import '../animation/fade_slide_in.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Centered spinner with an optional message, for full-screen or
/// section-level loading states.
///
/// It fades in after a short beat, so a load that finishes quickly never
/// flashes a spinner at the person.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 200),
      offset: Offset.zero,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            if (message != null) ...[
              AppSpacing.gapMd,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
