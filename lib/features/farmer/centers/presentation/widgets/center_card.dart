import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/nearby_center.dart';
import 'contact_actions.dart';

/// One village center as offered to a farmer: where it is, whether it has what
/// they want, whether it is open, and how to reach the person who runs it.
class CenterCard extends StatelessWidget {
  const CenterCard({super.key, required this.nearby, this.onChoose, this.chooseLabel = 'Choose this center'});

  final NearbyCenter nearby;

  /// When set, a button lets the farmer pick this center.
  final VoidCallback? onChoose;
  final String chooseLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final c = nearby.center;
    final stockColor = switch (nearby.inventory.status) {
      InventoryStatus.all => colors.success,
      InventoryStatus.partial => colors.warning,
      InventoryStatus.none => colors.danger,
      null => colors.textMuted,
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nearby.isRecommended ? colors.primary : colors.border, width: nearby.isRecommended ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nearby.isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.thumb_up_alt_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      nearby.recommendationReason == null ? 'Recommended center' : 'Recommended: ${nearby.recommendationReason}',
                      style: text.labelLarge?.copyWith(color: colors.primary),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: text.titleMedium),
                Text(c.district.isEmpty ? c.village : '${c.village}, ${c.district}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                AppSpacing.gapSm,
                _Line(
                  icon: Icons.directions_walk_rounded,
                  child: Text('${nearby.distanceKm.toStringAsFixed(1)} km away · about ${_travel(nearby.estimatedTravelMinutes)}', style: text.bodyMedium),
                ),
                if (nearby.inventory.label != null)
                  _Line(icon: Icons.inventory_2_outlined, color: stockColor, child: Text(nearby.inventory.label!, style: text.bodyMedium?.copyWith(color: stockColor, fontWeight: FontWeight.w600))),
                _Line(
                  icon: nearby.hours.isOpenNow ? Icons.store_rounded : Icons.storefront_outlined,
                  color: nearby.hours.isOpenNow ? colors.success : colors.textMuted,
                  child: Text(
                    '${nearby.hours.isOpenNow ? 'Open' : 'Closed'} · ${nearby.hours.label} (${nearby.hours.opensAt}–${nearby.hours.closesAt})',
                    style: text.bodyMedium,
                  ),
                ),
                if (nearby.pendingPickups > 0)
                  _Line(icon: Icons.hourglass_bottom_rounded, child: Text('${nearby.pendingPickups} pickup${nearby.pendingPickups == 1 ? '' : 's'} waiting', style: text.bodySmall?.copyWith(color: colors.textMuted))),
                if (c.operatorName.isNotEmpty) _Line(icon: Icons.person_outline_rounded, child: Text('Run by ${c.operatorName}', style: text.bodyMedium)),
                AppSpacing.gapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (c.hasPhone)
                      OutlinedButton.icon(onPressed: () => callPhone(context, c.phone), icon: const Icon(Icons.call_rounded, size: 18), label: const Text('Call')),
                    OutlinedButton.icon(
                      onPressed: () => openInMaps(context, latitude: c.latitude, longitude: c.longitude),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Open in Maps'),
                    ),
                    if (onChoose != null) FilledButton(onPressed: onChoose, child: Text(chooseLabel)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "26 min" / "1 h 5 min"; the "about" in front is the caller's, because
  /// this is an estimate from distance, not real road time.
  static String _travel(int minutes) => minutes < 60 ? '$minutes min' : '${minutes ~/ 60} h ${minutes % 60} min';
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.child, this.color});

  final IconData icon;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? context.colors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}
