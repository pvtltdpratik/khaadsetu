import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/order.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = _colorFor(status, colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(_labelFor(status), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }

  String _labelFor(OrderStatus status) => switch (status) {
        OrderStatus.pending => 'Pending',
        OrderStatus.readyForPickup => 'Ready for pickup',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };

  Color _colorFor(OrderStatus status, AppColorTokens colors) => switch (status) {
        OrderStatus.pending => colors.warning,
        OrderStatus.readyForPickup => colors.info,
        OrderStatus.completed => colors.success,
        OrderStatus.cancelled => colors.danger,
      };
}
