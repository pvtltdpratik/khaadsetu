import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/scheme_application.dart';

class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _colorFor(status, colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(_labelFor(status), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }

  String _labelFor(ApplicationStatus status) => switch (status) {
        ApplicationStatus.notApplied => 'Not applied',
        ApplicationStatus.submitted => 'Submitted',
        ApplicationStatus.underReview => 'Under review',
        ApplicationStatus.approved => 'Approved',
        ApplicationStatus.rejected => 'Rejected',
      };

  Color _colorFor(ApplicationStatus status, AppColorTokens colors) => switch (status) {
        ApplicationStatus.notApplied => colors.textMuted,
        ApplicationStatus.submitted => colors.info,
        ApplicationStatus.underReview => colors.warning,
        ApplicationStatus.approved => colors.success,
        ApplicationStatus.rejected => colors.danger,
      };
}
