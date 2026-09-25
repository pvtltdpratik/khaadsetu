import 'package:flutter/material.dart';

import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../orders/domain/entities/order.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Completed sales per day for the last seven days, oldest first, ending today.
List<({DateTime day, double sales})> weeklySales(List<Order> orders, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    for (var i = 6; i >= 0; i--)
      (
        day: today.subtract(Duration(days: i)),
        sales: orders
            .where((o) => o.status == OrderStatus.completed && o.createdAt.year == today.subtract(Duration(days: i)).year && o.createdAt.month == today.subtract(Duration(days: i)).month && o.createdAt.day == today.subtract(Duration(days: i)).day)
            .fold<double>(0, (s, o) => s + o.totalAmount),
      ),
  ];
}

/// "5 min ago", "3 h ago", "2 days ago".
String ago(DateTime then, DateTime now) {
  final d = now.difference(then);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
}

/// A seven-day bar chart of sales, drawn with plain boxes so it needs no chart package.
class WeeklySalesChart extends StatelessWidget {
  const WeeklySalesChart({super.key, required this.orders, this.now});

  final List<Order> orders;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final week = weeklySales(orders, now ?? DateTime.now());
    final peak = week.fold<double>(0, (m, d) => d.sales > m ? d.sales : m);
    final total = week.fold<double>(0, (s, d) => s + d.sales);
    return Container(
      key: const Key('weekly-chart'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Last 7 days', style: text.titleSmall)),
          Text(formatRupees(total), key: const Key('weekly-total'), style: text.titleSmall?.copyWith(color: colors.primary)),
        ]),
        AppSpacing.gapSm,
        SizedBox(
          height: 120,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < week.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: peak == 0 ? 0 : week[i].sales / peak),
                      duration: Duration(milliseconds: 350 + i * 60),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Container(key: Key('bar-$i'), height: 4 + 80 * v, decoration: BoxDecoration(color: week[i].sales > 0 ? colors.primary : colors.surfaceSunken, borderRadius: BorderRadius.circular(6))),
                    ),
                    const SizedBox(height: 4),
                    Text(_weekdays[week[i].day.weekday - 1], style: text.labelSmall?.copyWith(color: colors.textMuted)),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// The latest few orders, newest first, so the operator sees what just happened.
class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key, required this.orders, this.now});

  final List<Order> orders;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final clock = now ?? DateTime.now();
    final latest = [...orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    String what(Order o) => switch (o.status) {
          OrderStatus.pending => 'placed an order',
          OrderStatus.readyForPickup => 'has an order ready for pickup',
          OrderStatus.completed => o.type == OrderType.walkIn ? 'bought at the counter' : 'collected an order',
          OrderStatus.cancelled => 'cancelled an order',
        };
    return Container(
      key: const Key('recent-activity'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Recent activity', style: text.titleMedium),
        AppSpacing.gapSm,
        if (latest.isEmpty)
          Text('Nothing yet today', style: text.bodySmall?.copyWith(color: colors.textMuted))
        else
          for (var i = 0; i < latest.take(5).length; i++)
            FadeSlideIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(children: [
                  Icon(Icons.circle, size: 8, color: latest[i].status == OrderStatus.cancelled ? colors.danger : colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('${latest[i].customerName} ${what(latest[i])}', style: text.bodyMedium)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(ago(latest[i].createdAt, clock), style: text.labelSmall?.copyWith(color: colors.textMuted)),
                ]),
              ),
            ),
      ]),
    );
  }
}
