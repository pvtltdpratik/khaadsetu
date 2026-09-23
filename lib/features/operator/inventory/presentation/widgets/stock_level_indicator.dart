import 'package:flutter/material.dart';

import '../../../../../core/animation/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/inventory_item.dart';

/// Shows how much can still be SOLD (stock on hand minus what app orders are
/// holding) against the reorder level: red at or under it, amber up to twice
/// it, green beyond that. The details (on hand / held / incoming) sit below.
class StockLevelIndicator extends StatelessWidget {
  const StockLevelIndicator({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final available = item.available;
    final ratio = item.lowStockThreshold == 0
        ? 1.0
        : (available / (item.lowStockThreshold * 2)).clamp(0.05, 1.0);
    final color = item.isLowStock
        ? colors.danger
        : available <= item.lowStockThreshold * 2
            ? colors.warning
            : colors.success;

    final details = [
      '${item.currentStock} on hand',
      if (item.reserved > 0) '${item.reserved} held for app orders',
      if (item.incoming > 0) '${item.incoming} arriving',
      if (item.maxCapacity != null) 'room for ${item.maxCapacity}',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                available <= 0 ? 'Out of stock' : '$available ${item.unit}${available == 1 ? '' : 's'} to sell',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: available <= 0 ? colors.danger : null),
              ),
            ),
            Text('reorder at ${item.lowStockThreshold}', style: text.labelSmall?.copyWith(color: colors.textMuted)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        // The bar grows to its level when it first appears and glides when the
        // level changes (a delivery arrives, an order is placed).
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(height: 8, decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(999))),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: ratio),
                duration: Motion.reduced(context) ? Duration.zero : Motion.slow,
                curve: Motion.enter,
                builder: (context, value, _) => Container(
                  width: constraints.maxWidth * value,
                  height: 8,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(details, style: text.bodySmall?.copyWith(color: colors.textMuted)),
      ],
    );
  }
}
