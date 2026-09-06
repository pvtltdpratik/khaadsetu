import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/farmer.dart';

class FarmerCard extends StatelessWidget {
  const FarmerCard({super.key, required this.farmer, required this.onTap});

  final Farmer farmer;
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(farmer.name, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${farmer.village} · ${farmer.activeCrop}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Last visit: ${_formatRelative(farmer.lastVisitDate)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              if (farmer.needsFollowUp)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    'Follow up',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.warning),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelative(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}
