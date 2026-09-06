import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/tag_filter_row.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_card.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  OrderStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return ResponsiveScope(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Orders', style: Theme.of(context).textTheme.titleLarge)),
                  AppButton(
                    label: 'New walk-in sale',
                    icon: Icons.add_shopping_cart_rounded,
                    onPressed: () => context.push(RoutePaths.operatorOrdersNew),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TagFilterRow<OrderStatus>(
                label: 'Status',
                options: OrderStatus.values,
                selected: _statusFilter,
                labelBuilder: _statusLabel,
                onChanged: (s) => setState(() => _statusFilter = s),
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                  final filtered = _statusFilter == null
                      ? orders
                      : orders.where((o) => o.status == _statusFilter).toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No orders match this filter',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
                      ),
                    );
                  }
                  if (!context.breakpoint.isTabletUp) {
                    return ListView.separated(
                      padding: context.pagePadding,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => AppSpacing.gapSm,
                      itemBuilder: (context, i) => OrderCard(
                        order: filtered[i],
                        onTap: () => context.push(RoutePaths.operatorOrderDetail(filtered[i].id)),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: context.pagePadding,
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: context.gridColumns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (context, i) => OrderCard(
                      order: filtered[i],
                      onTap: () => context.push(RoutePaths.operatorOrderDetail(filtered[i].id)),
                    ),
                  );
                },
                loading: () => const AppLoadingIndicator(),
                error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(ordersProvider)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(OrderStatus status) => switch (status) {
        OrderStatus.pending => 'Pending',
        OrderStatus.readyForPickup => 'Ready for pickup',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };
}
