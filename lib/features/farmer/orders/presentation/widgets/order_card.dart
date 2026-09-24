import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/animation/pop_in.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_format.dart';
import '../../../../delivery/domain/entities/delivery_models.dart';
import '../../../../delivery/presentation/providers/delivery_providers.dart';
import '../../../../delivery/presentation/widgets/delivery_tracking_card.dart';
import '../../../../delivery/presentation/widgets/rating_sheet.dart';
import '../../../centers/presentation/widgets/contact_actions.dart';
import '../../domain/entities/farmer_order.dart';
import '../providers/orders_providers.dart';

/// One order: what, where to collect it, the code to read out, and the
/// deadline. Used in the list and (with [onTap] null) on the detail page.
class OrderCard extends ConsumerWidget {
  const OrderCard({super.key, required this.order, this.onTap});

  final FarmerOrder order;
  final VoidCallback? onTap;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('Your reserved items go back on the shelf for other farmers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.danger, foregroundColor: context.colors.onDanger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(ordersRepositoryProvider).cancel(order.id);
      ref
        ..invalidate(myOrdersProvider)
        ..invalidate(orderProvider(order.id));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled')));
    } catch (err) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  void _refresh(WidgetRef ref) => ref
    ..invalidate(myOrdersProvider)
    ..invalidate(orderProvider(order.id))
    ..invalidate(deliveryTrackingProvider(order.id));

  Future<void> _switchToPickup(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Collect it yourself?'),
        content: const Text('The delivery is called off and you will not pay the delivery fee. You will get a pickup code to read out at the village center.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep the delivery')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('I will collect it')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(deliveryRepositoryProvider).switchToPickup(order.id);
      _refresh(ref);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery cancelled. Collect it at the center.')));
    } catch (err) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  Future<void> _rate(BuildContext context, WidgetRef ref) async {
    final rating = await showRatingDialog(context, title: 'How was the delivery?');
    if (rating == null) return;
    try {
      await ref.read(deliveryRepositoryProvider).rateDelivery(orderId: order.id, stars: rating.stars, comment: rating.comment);
      _refresh(ref);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for rating')));
    } catch (err) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final delivery = order.delivery;
    final statusColor = switch (order.status) {
      FarmerOrderStatus.pending => colors.info,
      FarmerOrderStatus.readyForPickup => colors.success,
      FarmerOrderStatus.completed => colors.textMuted,
      FarmerOrderStatus.cancelled => colors.danger,
    };
    final center = order.center;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text(order.status.label, style: text.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Text(formatDay(order.createdAt), style: text.bodySmall?.copyWith(color: colors.textMuted)),
                ],
              ),
              AppSpacing.gapSm,
              for (final line in order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text('${line.quantity} × ${line.productName}${line.isSurplus ? ' (surplus)' : ''}', style: text.bodyMedium)),
                      Text(formatRupees(line.quantity * line.unitPrice), style: text.bodyMedium),
                    ],
                  ),
                ),
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  Text('Total', style: text.titleSmall),
                  const Spacer(),
                  Text(formatRupees(order.totalAmount), style: text.titleSmall),
                ],
              ),
              if (order.isHomeDelivery) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(children: [
                  Expanded(child: Text('Home delivery', style: text.bodyMedium)),
                  Text(formatRupees(order.deliveryFee), key: const Key('order-delivery-fee'), style: text.bodyMedium),
                ]),
                const SizedBox(height: AppSpacing.xs),
                Row(children: [
                  Expanded(child: Text('To pay in cash on arrival', style: text.titleSmall)),
                  Text(formatRupees(order.payableAmount), key: const Key('order-payable'), style: text.titleSmall),
                ]),
              ],
              if (center != null) ...[
                AppSpacing.gapSm,
                Row(
                  children: [
                    Icon(Icons.storefront_rounded, size: 18, color: colors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('${order.isHomeDelivery ? 'Comes from' : 'Collect from'} ${center.name}, ${center.village}', style: text.bodyMedium)),
                  ],
                ),
              ],
              if (delivery != null && (order.isHomeDelivery || delivery.status == DeliveryStatus.delivered)) ...[
                AppSpacing.gapMd,
                DeliveryTrackingCard(
                  delivery: delivery,
                  goodsAmount: order.totalAmount,
                  onSwitchToPickup: () => _switchToPickup(context, ref),
                  onRate: () => _rate(context, ref),
                ),
              ],
              if (!order.isHomeDelivery && order.status.isActive && order.pickupOtp != null) ...[
                AppSpacing.gapMd,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('Your pickup code', style: text.labelMedium?.copyWith(color: colors.primary)),
                      // The code arrives with a little pop: it is the thing to remember.
                      PopIn(
                        delay: const Duration(milliseconds: 250),
                        child: Text(order.pickupOtp!, style: text.displaySmall?.copyWith(letterSpacing: 8, color: colors.primary, fontWeight: FontWeight.w800)),
                      ),
                      if (order.reservedUntil != null)
                        Text('Collect by ${formatDay(order.reservedUntil!)}', style: text.bodySmall?.copyWith(color: colors.primary)),
                    ],
                  ),
                ),
              ],
              if ((order.status.isActive && delivery?.status != DeliveryStatus.inTransit) || (center?.phone.isNotEmpty ?? false)) ...[
                AppSpacing.gapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (center != null && center.phone.isNotEmpty)
                      OutlinedButton.icon(onPressed: () => callPhone(context, center.phone), icon: const Icon(Icons.call_rounded, size: 18), label: const Text('Call center')),
                    if (order.status.isActive && delivery?.status != DeliveryStatus.inTransit)
                      TextButton.icon(
                        onPressed: () => _cancel(context, ref),
                        icon: Icon(Icons.close_rounded, size: 18, color: colors.danger),
                        label: Text('Cancel order', style: TextStyle(color: colors.danger)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
