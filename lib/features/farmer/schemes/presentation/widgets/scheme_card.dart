import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_eligibility_result.dart';
import 'eligibility_badge.dart';

class SchemeCard extends StatelessWidget {
  const SchemeCard({
    super.key,
    required this.scheme,
    required this.eligibility,
    required this.onTap,
  });

  final GovScheme scheme;

  /// Null while it is still being worked out.
  final SchemeEligibilityResult? eligibility;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
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
              Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                _Tag(scheme.level == 'state' ? 'MAHARASHTRA' : 'CENTRAL'),
                _Tag(scheme.sector.toUpperCase()),
                if (!scheme.isForFarmers) _Tag(scheme.audience == 'group' ? 'GROUPS / FPOs' : 'BUSINESSES'),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Text(scheme.name, style: text.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(scheme.agency, style: text.labelSmall?.copyWith(color: colors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              AppSpacing.gapSm,
              Text(scheme.benefit, style: text.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
              if (eligibility != null && scheme.isForFarmers) ...[
                AppSpacing.gapSm,
                Row(children: [
                  EligibilityBadge(status: eligibility!.status),
                  if (eligibility!.status == EligibilityStatus.possible && eligibility!.missing.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: Text('${eligibility!.missing.length} more to answer', style: text.labelSmall?.copyWith(color: colors.textMuted))),
                  ],
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textSecondary, fontSize: 10)),
    );
  }
}
