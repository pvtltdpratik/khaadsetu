import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animation/animated_count.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/price_format.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import 'approvals_screen.dart' show StaffScope;
import 'farmer_card_screen.dart';

final operatorEarningsProvider = FutureProvider.autoDispose<Json>((ref) async => asJson(await ref.watch(apiClientProvider).get('/v1/operator/earnings')));

/// What the center earned: today, this week and month, where it came from, which farmers bring the most, the target, and
/// a monthly statement to compare against payouts.
class OperatorEarningsScreen extends ConsumerWidget {
  const OperatorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final earnings = ref.watch(operatorEarningsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ResponsiveScope(
        child: earnings.when(
          skipLoadingOnReload: true,
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(operatorEarningsProvider)),
          data: (e) {
            final today = e.obj('today');
            final week = e.obj('week');
            final month = e.obj('month');
            final target = e.obj('target');
            final daily = e.list('daily');
            final biggest = daily.fold<double>(1, (m, d) => d.num_('sales') > m ? d.num_('sales') : m);
            final rank = e.obj('leaderboard');
            Widget period(String label, Json p, {int index = 0}) => Expanded(
                  child: KitCard(
                    index: index,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: text.labelMedium?.copyWith(color: colors.textMuted)),
                      AnimatedCount(value: p.num_('commission'), format: (v) => formatRupeesExact(v.toDouble()), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: colors.primary)),
                      Text('${formatRupeesExact(p.num_('sales'))} sold', style: text.bodySmall),
                    ]),
                  ),
                );
            return ListView(padding: context.pagePadding, children: [
              Text('Your commission at ${e.num_('commissionRatePercent').toStringAsFixed(1)}% of sales', style: text.bodySmall?.copyWith(color: colors.textMuted)),
              AppSpacing.gapSm,
              Row(children: [period('Today', today), AppSpacing.gapSm, period('7 days', week, index: 1), AppSpacing.gapSm, period('This month', month, index: 2)]),
              if (target.num_('monthlySales') > 0)
                KitCard(
                  index: 3,
                  title: 'Monthly target',
                  icon: Icons.flag_outlined,
                  trailing: StatusPill('${target.int_('percent')}%', tone: target.int_('percent') >= 100 ? Tone.good : Tone.info),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(key: const Key('target-bar'), value: target.num_('percent') / 100, minHeight: 10)),
                    const SizedBox(height: 6),
                    Text('${formatRupeesExact(target.num_('achieved'))} of ${formatRupeesExact(target.num_('monthlySales'))}', style: text.bodyMedium),
                  ]),
                ),
              KitCard(
                index: 4,
                title: 'Last 7 days',
                icon: Icons.bar_chart_rounded,
                child: SizedBox(
                  height: 120,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    for (final d in daily)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: d.num_('sales') / biggest),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              builder: (_, t, _) => Container(height: 4 + 80 * t, decoration: BoxDecoration(color: colors.primary.withValues(alpha: d.num_('sales') > 0 ? 1 : 0.25), borderRadius: BorderRadius.circular(4))),
                            ),
                            const SizedBox(height: 4),
                            Text(d.str('day').length >= 10 ? d.str('day').substring(8, 10) : '', style: text.labelSmall),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
              KitCard(
                index: 5,
                title: 'Where it came from (this month)',
                icon: Icons.pie_chart_outline,
                child: e.list('sources').isEmpty
                    ? Text('No completed sales yet this month.', style: text.bodyMedium)
                    : Column(children: [for (final s in e.list('sources')) KitRow(s.str('source') == 'walkIn' ? 'Walk-in sales' : 'App orders', '${formatRupeesExact(s.num_('sales'))} · ${s.int_('orders')} orders')]),
              ),
              if (e.num_('farmerProductCommissionToCollect') > 0)
                KitCard(
                  index: 6,
                  title: 'Farmer-made products',
                  icon: Icons.eco_outlined,
                  child: Text('${formatRupeesExact(e.num_('farmerProductCommissionToCollect'))} of platform share is waiting to be collected from sellers you checked.', style: text.bodyMedium),
                ),
              KitCard(
                index: 7,
                title: 'Farmers who bring the most',
                icon: Icons.groups_outlined,
                child: e.list('farmerWise').isEmpty
                    ? Text('Nobody yet this month.', style: text.bodyMedium)
                    : Column(children: [
                        for (final f in e.list('farmerWise').take(10))
                          ListTile(
                            key: Key('farmer-${f.str('farmerId')}'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(f.str('name', 'Farmer')),
                            subtitle: Text('${f.int_('orders')} orders'),
                            trailing: Text(formatRupeesExact(f.num_('sales')), style: text.titleSmall),
                            onTap: f.str('farmerId') == 'walk-in' ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FarmerCardScreen(scope: StaffScope.operator, farmerId: f.str('farmerId')))),
                          ),
                      ]),
              ),
              if (rank['rank'] != null)
                KitCard(
                  index: 8,
                  title: 'Your standing',
                  icon: Icons.emoji_events_outlined,
                  child: Text('#${rank.int_('rank')} of ${rank.int_('of')} centers this month by sales.', key: const Key('rank'), style: text.bodyLarge),
                ),
              KitCard(
                index: 9,
                title: 'Monthly statement',
                icon: Icons.receipt_long_outlined,
                child: Column(children: [
                  for (final s in e.list('statement')) KitRow(s.str('month'), '${formatRupeesExact(s.num_('commission'))} on ${formatRupeesExact(s.num_('sales'))}'),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
