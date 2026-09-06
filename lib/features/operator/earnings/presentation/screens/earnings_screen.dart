import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_format.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../providers/earnings_providers.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final rateAsync = ref.watch(commissionRateProvider);

    return ResponsiveScope(
      child: SafeArea(
        child: ListView(
          padding: context.pagePadding,
          children: [
            Text('Earnings', style: Theme.of(context).textTheme.headlineSmall),
            AppSpacing.gapLg,
            ordersAsync.when(
              data: (orders) => rateAsync.when(
                data: (rate) => _EarningsBody(orders: orders, commissionRatePercent: rate),
                loading: () => const AppLoadingIndicator(),
                error: (err, _) => AppErrorView(message: '$err'),
              ),
              loading: () => const AppLoadingIndicator(),
              error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(ordersProvider)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsBody extends StatelessWidget {
  const _EarningsBody({required this.orders, required this.commissionRatePercent});

  final List<Order> orders;
  final double commissionRatePercent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    bool isToday(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;
    bool isThisMonth(DateTime d) => d.year == now.year && d.month == now.month;

    final completed = orders.where((o) => o.status == OrderStatus.completed).toList();
    final todaySales = completed.where((o) => isToday(o.createdAt)).fold<double>(0, (s, o) => s + o.totalAmount);
    final monthSales = completed.where((o) => isThisMonth(o.createdAt)).fold<double>(0, (s, o) => s + o.totalAmount);
    double commission(double sales) => sales * commissionRatePercent / 100;

    final cards = [
      ('Today\'s commission', formatRupees(commission(todaySales)), Icons.today_outlined),
      ('This month\'s commission', formatRupees(commission(monthSales)), Icons.calendar_month_outlined),
      ('Commission rate', '${commissionRatePercent.toStringAsFixed(0)}%', Icons.percent_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.responsive(mobile: 1, tablet: 3),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: context.responsive(mobile: 3.2, tablet: 1.6),
          ),
          itemBuilder: (context, i) {
            final (label, value, icon) = cards[i];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: colors.primary),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.textMuted)),
                ],
              ),
            );
          },
        ),
        AppSpacing.gapLg,
        Text('Recent completed sales', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        if (completed.isEmpty)
          Text('No completed sales yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted))
        else
          for (final order in completed.take(10)) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(order.customerName, style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          formatRupees(order.totalAmount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${formatRupees(commission(order.totalAmount))}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.success),
                  ),
                ],
              ),
            ),
            AppSpacing.gapSm,
          ],
      ],
    );
  }
}
