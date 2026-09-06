import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../soil_health/domain/entities/nutrient_reading.dart';

/// Simple horizontal bar per nutrient, scaled to the highest of the three —
/// a lightweight placeholder chart rather than a full charting library,
/// since this is just showing 1-3 static values.
class NpkCompositionChart extends StatelessWidget {
  const NpkCompositionChart({super.key, required this.percentages});

  final Map<NutrientType, double> percentages;

  @override
  Widget build(BuildContext context) {
    if (percentages.isEmpty) {
      return Text(
        'Not applicable for this product.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
      );
    }
    final maxValue = percentages.values.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final type in NutrientType.values)
          if (percentages.containsKey(type)) ...[
            _NutrientBar(type: type, value: percentages[type]!, maxValue: maxValue),
            AppSpacing.gapSm,
          ],
      ],
    );
  }
}

class _NutrientBar extends StatelessWidget {
  const _NutrientBar({required this.type, required this.value, required this.maxValue});

  final NutrientType type;
  final double value;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fraction = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.05, 1.0);
    final color = switch (type) {
      NutrientType.nitrogen => colors.primary,
      NutrientType.phosphorus => colors.secondary,
      NutrientType.potassium => colors.info,
    };
    final label = switch (type) {
      NutrientType.nitrogen => 'N',
      NutrientType.phosphorus => 'P',
      NutrientType.potassium => 'K',
    };

    return Row(
      children: [
        SizedBox(width: 16, child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
        AppSpacing.gapSm,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.surfaceSunken,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Container(
                    width: constraints.maxWidth * fraction,
                    height: 10,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                  ),
                ],
              );
            },
          ),
        ),
        AppSpacing.gapSm,
        SizedBox(
          width: 44,
          child: Text('${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%',
              style: Theme.of(context).textTheme.labelMedium),
        ),
      ],
    );
  }
}
