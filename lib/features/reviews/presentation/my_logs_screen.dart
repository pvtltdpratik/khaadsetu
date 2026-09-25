import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animation/animated_count.dart';
import '../../../core/animation/fade_slide_in.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../domain/review_models.dart';
import 'review_providers.dart';

/// My fertilizer log: what I have started, what each step is waiting for, and what I have earned.
class MyLogsScreen extends ConsumerWidget {
  const MyLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final logs = ref.watch(myLogsProvider);
    final rewards = ref.watch(rewardsProvider).value;
    final loggable = ref.watch(loggableProvider).value ?? const <LoggableProduct>[];
    return Scaffold(
      appBar: AppBar(title: const Text('My fertilizer log')),
      body: ResponsiveScope(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(myLogsProvider)
              ..invalidate(rewardsProvider)
              ..invalidate(loggableProvider);
          },
          child: ListView(
            padding: context.pagePadding,
            children: [
              if (rewards != null) FadeSlideIn(child: _RewardsStrip(rewards: rewards)),
              AppSpacing.gapMd,
              if (loggable.isNotEmpty) ...[
                Text('Start a new log', style: text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
                  for (final p in loggable)
                    ActionChip(key: Key('loggable-${p.productId}'), avatar: const Icon(Icons.add_rounded, size: 18), label: Text(p.name), onPressed: () async {
                      await context.push(RoutePaths.farmerLogFertilizer(p.productId));
                      ref.invalidate(myLogsProvider);
                    }),
                ]),
                AppSpacing.gapMd,
              ],
              Text('My logs', style: text.titleMedium),
              AppSpacing.gapSm,
              logs.when(
                loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: AppLoadingIndicator()),
                error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myLogsProvider)),
                data: (list) => list.isEmpty
                    ? Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('Nothing logged yet. Log how you use a fertilizer you bought here, and earn a 5% coupon, coins and badges. Other farmers learn from your harvest.', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted)))
                    : Column(children: [for (var i = 0; i < list.length; i++) FadeSlideIn(index: i, child: _LogCard(log: list[i]))]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsStrip extends StatelessWidget {
  const _RewardsStrip({required this.rewards});

  final Rewards rewards;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return InkWell(
      key: const Key('rewards-strip'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.push(RoutePaths.farmerRewards),
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), gradient: LinearGradient(colors: [colors.secondary, colors.secondary.withValues(alpha: 0.8)])),
        child: Row(children: [
          Icon(Icons.stars_rounded, color: colors.onSecondary, size: 34),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AnimatedCount(key: const Key('coins'), value: rewards.coins, style: text.headlineSmall?.copyWith(color: colors.onSecondary, fontWeight: FontWeight.w800)),
                Text(' coins', style: text.titleSmall?.copyWith(color: colors.onSecondary)),
              ]),
              Text([
                if (rewards.champion) 'Champion Farmer' else if (rewards.verifiedFarmer) 'Verified Farmer',
                if (rewards.streak > 0) '${rewards.streak} season${rewards.streak == 1 ? '' : 's'} in a row',
                if (rewards.usableCoupons.isNotEmpty) '${rewards.usableCoupons.length} coupon${rewards.usableCoupons.length == 1 ? '' : 's'}',
              ].join('  ·  '), style: text.bodySmall?.copyWith(color: colors.onSecondary.withValues(alpha: 0.95))),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.onSecondary),
        ]),
      ),
    );
  }
}

class _LogCard extends ConsumerWidget {
  const _LogCard({required this.log});

  final MyLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final l = log;
    Widget step(int n, String title, bool done, bool current) => Expanded(
          child: Column(children: [
            CircleAvatar(radius: 13, backgroundColor: done ? colors.success : (current ? colors.primary : colors.surfaceSunken), child: done ? Icon(Icons.check_rounded, size: 16, color: colors.onSuccess) : Text('$n', style: text.labelSmall?.copyWith(color: current ? colors.onPrimary : colors.textMuted))),
            const SizedBox(height: 2),
            Text(title, style: text.labelSmall, textAlign: TextAlign.center),
          ]),
        );
    return Container(
      key: Key('log-${l.reviewId}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${l.productName} on ${l.crop}', style: text.titleSmall),
        Text('${l.season[0].toUpperCase()}${l.season.substring(1).replaceAll('-', ' ')}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
        AppSpacing.gapSm,
        Row(children: [step(1, 'Before', true, false), step(2, 'Mid-season', l.phase >= 2, l.phase == 1), step(3, 'Harvest', l.harvestLogged, l.phase == 2 && !l.harvestLogged)]),
        AppSpacing.gapSm,
        if (l.harvestLogged) ...[
          Text('${l.yieldQpa?.toStringAsFixed(1) ?? '—'} q/acre${l.improvementPct == null ? '' : '  ·  ${l.improvementPct! >= 0 ? '+' : ''}${l.improvementPct!.toStringAsFixed(1)}%'}', style: text.titleSmall),
          Text(switch (l.status) { 'flagged' => 'An agronomist is checking this result before it is shown to others.', 'hidden' => 'Not published.', _ => l.featured ? 'A featured success story.' : 'Published: it helps other farmers.' }, key: Key('status-${l.reviewId}'), style: text.bodySmall?.copyWith(color: colors.textMuted)),
        ] else
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
            if (l.phase == 1)
              l.midOpensInDays > 0
                  ? _Locked(key: Key('mid-locked-${l.reviewId}'), text: 'Mid-season notes open in ${l.midOpensInDays} days')
                  : FilledButton(key: Key('mid-${l.reviewId}'), onPressed: () async {
                      await context.push(RoutePaths.farmerLogMid(l.reviewId));
                      ref
                        ..invalidate(myLogsProvider)
                        ..invalidate(rewardsProvider);
                    }, child: const Text('Add mid-season notes (+10 coins)')),
            l.harvestOpensInDays > 0
                ? _Locked(key: Key('harvest-locked-${l.reviewId}'), text: 'Harvest log opens in ${l.harvestOpensInDays} days')
                : FilledButton.tonal(key: Key('harvest-${l.reviewId}'), onPressed: () async {
                    await context.push(RoutePaths.farmerLogHarvest(l.reviewId));
                    ref
                      ..invalidate(myLogsProvider)
                      ..invalidate(rewardsProvider);
                  }, child: const Text('Log my harvest (+50 coins)')),
          ]),
      ]),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Chip(avatar: const Icon(Icons.lock_clock_outlined, size: 16), label: Text(text), visualDensity: VisualDensity.compact);
}
