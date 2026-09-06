import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Shown when a product's [Product.nutrientFocus] overlaps the nutrients
/// the farmer's latest soil scan flagged as low — see
/// `deficientNutrientsProvider`.
class SoilMatchBadge extends StatelessWidget {
  const SoilMatchBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: colors.success),
          const SizedBox(width: 4),
          Text(
            'Matches your soil',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.success),
          ),
        ],
      ),
    );
  }
}
