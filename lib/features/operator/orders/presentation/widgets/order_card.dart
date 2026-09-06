import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_format.dart';
import '../../domain/entities/order.dart';
import 'order_status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final Order order;
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
                  Icon(
                    order.type == OrderType.appOrder ? Icons.smartphone_rounded : Icons.storefront_rounded,
                    size: 14,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.type == OrderType.appOrder ? 'App order' : 'Walk-in',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                  ),
                  const Spacer(),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              AppSpacing.gapSm,
              Text(order.customerName, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              AppSpacing.gapSm,
              Text(formatRupees(order.totalAmount), style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
