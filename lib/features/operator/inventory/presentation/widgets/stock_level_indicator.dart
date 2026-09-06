import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/inventory_item.dart';

/// Small bar showing stock level relative to the low-stock threshold —
/// red once at/under threshold, amber up to 2x threshold, green beyond that.
class StockLevelIndicator extends StatelessWidget {
  const StockLevelIndicator({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ratio = item.lowStockThreshold == 0
        ? 1.0
        : (item.currentStock / (item.lowStockThreshold * 2)).clamp(0.05, 1.0);
    final color = item.isLowStock
        ? colors.danger
        : item.currentStock <= item.lowStockThreshold * 2
            ? colors.warning
            : colors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '${item.currentStock} ${item.unit}s in stock',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              'reorder at ${item.lowStockThreshold}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                ),
                Container(
                  width: constraints.maxWidth * ratio,
                  height: 8,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
