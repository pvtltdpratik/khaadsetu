import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../inventory/domain/entities/inventory_item.dart';
import '../../inventory/presentation/providers/inventory_providers.dart';
import '../../orders/domain/entities/order.dart';
import '../../orders/presentation/providers/orders_providers.dart';
import '../../orders/presentation/widgets/order_card.dart';

class OperatorDashboardScreen extends ConsumerWidget {
  const OperatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return ResponsiveScope(
      child: SafeArea(
        child: ListView(
          padding: context.pagePadding,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              'Krishi Seva Kendra, Shirur',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
            ),
            AppSpacing.gapLg,
            ordersAsync.when(
              data: (orders) => _SummaryCards(orders: orders, inventoryAsync: inventoryAsync),
              loading: () => const SizedBox(height: 100, child: AppLoadingIndicator()),
              error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(ordersProvider)),
            ),
            AppSpacing.gapLg,
            AppButton(
              label: 'New walk-in sale',
              icon: Icons.add_shopping_cart_rounded,
              expand: true,
              onPressed: () => context.push(RoutePaths.operatorOrdersNew),
            ),
            AppSpacing.gapLg,
            ResponsiveRow(
              spacing: AppSpacing.md,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ordersAsync.when(
                  data: (orders) => _PendingPickups(
                    orders: orders.where((o) => o.status == OrderStatus.readyForPickup).toList(),
                  ),
                  loading: () => const AppLoadingIndicator(),
                  error: (err, _) => AppErrorView(message: '$err'),
                ),
                inventoryAsync.when(
                  data: (items) => _LowStockAlerts(items: items.where((i) => i.isLowStock).toList()),
                  loading: () => const AppLoadingIndicator(),
                  error: (err, _) => AppErrorView(message: '$err'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.orders, required this.inventoryAsync});

  final List<Order> orders;
  final AsyncValue<List<InventoryItem>> inventoryAsync;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    bool isToday(DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;

    final todaysOrders = orders.where((o) => isToday(o.createdAt)).length;
    final walkIns = orders.where((o) => o.type == OrderType.walkIn && isToday(o.createdAt)).length;
    final needsAttention =
        orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.readyForPickup).length;
    final lowStock = inventoryAsync.whenOrNull(data: (items) => items.where((i) => i.isLowStock).length) ?? 0;

    final cards = [
      ('Today\'s orders', '$todaysOrders', Icons.receipt_long_outlined, context.colors.primary),
      ('Walk-ins today', '$walkIns', Icons.storefront_outlined, context.colors.secondary),
      ('Needs attention', '$needsAttention', Icons.pending_actions_outlined, context.colors.warning),
      ('Low stock items', '$lowStock', Icons.inventory_2_outlined, context.colors.danger),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.responsive(mobile: 2, tablet: 4),
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: context.responsive(mobile: 1.6, tablet: 1.3),
      ),
      itemBuilder: (context, i) {
        final (label, value, icon, color) = cards[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: context.colors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.textMuted)),
            ],
          ),
        );
      },
    );
  }
}

class _PendingPickups extends StatelessWidget {
  const _PendingPickups({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pending pickups', style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.gapSm,
          if (orders.isEmpty)
            Text('Nothing waiting for handover', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted))
          else
            for (final order in orders) ...[
              OrderCard(order: order, onTap: () => context.push(RoutePaths.operatorOrderDetail(order.id))),
              AppSpacing.gapSm,
            ],
        ],
      ),
    );
  }
}

class _LowStockAlerts extends StatelessWidget {
  const _LowStockAlerts({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Low stock alerts', style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.gapSm,
          if (items.isEmpty)
            Text('All stock levels look healthy', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted))
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: colors.danger),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item.name, style: Theme.of(context).textTheme.bodyMedium)),
                    Text(
                      '${item.currentStock} ${item.unit}s left',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.danger),
                    ),
                  ],
                ),
              ),
          AppSpacing.gapSm,
          AppButton(
            label: 'View inventory',
            variant: AppButtonVariant.outlined,
            onPressed: () => context.go(RoutePaths.operatorInventory),
          ),
        ],
      ),
    );
  }
}
