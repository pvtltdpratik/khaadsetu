import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/animation/pressable.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_card.dart';

/// Everything the farmer has reserved, newest first.
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final orders = ref.watch(myOrdersProvider);
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('My orders')),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myOrdersProvider);
              await ref.read(myOrdersProvider.future);
            },
            child: orders.when(
              loading: () => const AppLoadingIndicator(),
              error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myOrdersProvider)),
              data: (list) => list.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 48, color: colors.textMuted),
                              AppSpacing.gapMd,
                              Text('No orders yet', style: Theme.of(context).textTheme.titleMedium),
                              AppSpacing.gapXs,
                              Text('Reserve products from the marketplace and collect them at a village center.',
                                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
                              AppSpacing.gapMd,
                              FilledButton(onPressed: () => context.go(RoutePaths.farmerMarketplace), child: const Text('Browse marketplace')),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        ContentContainer(
                          maxWidth: 720,
                          child: Column(
                            children: [
                              for (final (i, o) in list.indexed) ...[
                                FadeSlideIn(
                                  key: ValueKey(o.id),
                                  index: i,
                                  child: Pressable(child: OrderCard(order: o, onTap: () => context.push(RoutePaths.farmerOrder(o.id)))),
                                ),
                                AppSpacing.gapSm,
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One order, e.g. right after reserving it or from a notification.
class FarmerOrderDetailScreen extends ConsumerWidget {
  const FarmerOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(orderId));
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Your order')),
        body: SafeArea(
          child: order.when(
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(orderProvider(orderId))),
            data: (o) => ListView(
              children: [
                ContentContainer(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OrderCard(order: o),
                      AppSpacing.gapMd,
                      OutlinedButton(onPressed: () => context.push(RoutePaths.farmerOrders), child: const Text('See all my orders')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
