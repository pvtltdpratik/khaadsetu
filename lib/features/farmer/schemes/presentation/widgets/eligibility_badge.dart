import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/scheme_eligibility_result.dart';

/// "You are eligible", "Check eligibility", "Not eligible for you" or "Open to all".
class EligibilityBadge extends StatelessWidget {
  const EligibilityBadge({super.key, required this.status});

  final EligibilityStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (color, icon, label) = switch (status) {
      EligibilityStatus.eligible => (colors.success, Icons.check_circle_rounded, 'You are eligible'),
      EligibilityStatus.possible => (colors.warning, Icons.help_outline_rounded, 'Check eligibility'),
      EligibilityStatus.notEligible => (colors.danger, Icons.cancel_outlined, 'Not eligible for you'),
      EligibilityStatus.open => (colors.info, Icons.public_rounded, 'Open to all'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
