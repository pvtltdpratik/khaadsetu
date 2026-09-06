import 'package:flutter/material.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/soil_health_gauge.dart';
import '../../../soil_health/domain/entities/soil_health_summary.dart';

/// Home screen's soil health section: the gauge plus a short note and a call
/// to action, which changes depending on whether the farmer has scanned yet.
class SoilHealthSummaryCard extends StatelessWidget {
  const SoilHealthSummaryCard({
    super.key,
    required this.summary,
    this.onScanPressed,
    this.onViewDetails,
  });

  final SoilHealthSummary summary;
  final VoidCallback? onScanPressed;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final band = SoilHealthBand.fromScore(summary.score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SoilHealthGauge(
              size: context.responsive(mobile: 88.0, tablet: 104.0),
              score: summary.score,
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (band != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: band.color(colors).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        band.label,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: band.color(colors)),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    summary.hasScan
                        ? summary.note
                        : 'Scan your soil to get a health score and '
                            'fertilizer guidance.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: summary.hasScan ? 'View details' : 'Scan soil now',
                    icon: summary.hasScan ? null : Icons.camera_alt_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: summary.hasScan ? onViewDetails : onScanPressed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
