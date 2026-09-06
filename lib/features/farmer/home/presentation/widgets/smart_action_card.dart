import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../domain/entities/smart_recommendation.dart';

/// The hero element of the home screen: the single most relevant piece of
/// advice for the farmer right now, in a highlighted primary-colored card so
/// it reads as the obvious first thing to look at.
class SmartActionCard extends StatelessWidget {
  const SmartActionCard({
    super.key,
    required this.recommendation,
    this.onAction,
  });

  final SmartRecommendation recommendation;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(recommendation.category), color: colors.onPrimary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Suggested for you',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: colors.onPrimary.withValues(alpha: 0.85)),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Text(
            recommendation.title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: colors.onPrimary),
          ),
          AppSpacing.gapSm,
          Text(
            recommendation.description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.onPrimary.withValues(alpha: 0.9)),
          ),
          AppSpacing.gapLg,
          AppButton(
            label: recommendation.actionLabel,
            icon: Icons.arrow_forward_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(RecommendationCategory category) => switch (category) {
        RecommendationCategory.nutrient => Icons.science_outlined,
        RecommendationCategory.water => Icons.water_drop_outlined,
        RecommendationCategory.pest => Icons.bug_report_outlined,
        RecommendationCategory.harvest => Icons.agriculture_outlined,
      };
}
