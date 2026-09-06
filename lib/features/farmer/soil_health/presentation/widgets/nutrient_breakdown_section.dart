import 'package:flutter/material.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/nutrient_reading.dart';

/// NPK readings as a row of stat cards: stacked on mobile, 3-across once
/// there's room. Each nutrient's Low/Medium/High badge reuses the same
/// red/yellow/green convention as the overall score gauge.
class NutrientBreakdownSection extends StatelessWidget {
  const NutrientBreakdownSection({super.key, required this.nutrients});

  final List<NutrientReading> nutrients;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(mobile: 1, tablet: 3);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nutrients.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: context.responsive(mobile: 3.2, tablet: 1.4),
      ),
      itemBuilder: (context, i) => _NutrientCard(reading: nutrients[i]),
    );
  }
}

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({required this.reading});

  final NutrientReading reading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final levelColor = _colorFor(reading.level, colors);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_labelFor(reading.type), style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${reading.valuePercent.round()}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _levelLabel(reading.level),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: levelColor),
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(NutrientType type) => switch (type) {
        NutrientType.nitrogen => 'Nitrogen (N)',
        NutrientType.phosphorus => 'Phosphorus (P)',
        NutrientType.potassium => 'Potassium (K)',
      };

  String _levelLabel(NutrientLevel level) => switch (level) {
        NutrientLevel.low => 'Low',
        NutrientLevel.medium => 'Medium',
        NutrientLevel.high => 'High',
      };

  Color _colorFor(NutrientLevel level, AppColorTokens colors) => switch (level) {
        NutrientLevel.low => colors.danger,
        NutrientLevel.medium => colors.warning,
        NutrientLevel.high => colors.success,
      };
}
