import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/gov_scheme.dart';
import 'eligibility_badge.dart';

class SchemeCard extends StatelessWidget {
  const SchemeCard({
    super.key,
    required this.scheme,
    required this.isEligible,
    required this.onTap,
  });

  final GovScheme scheme;
  final bool isEligible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(scheme.name, style: Theme.of(context).textTheme.titleSmall)),
                  EligibilityBadge(isEligible: isEligible),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(scheme.agency, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted)),
              AppSpacing.gapSm,
              Text(scheme.benefit, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
