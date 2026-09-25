import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animation/animated_count.dart';
import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/resale_models.dart';
import '../resale_providers.dart';

/// The platform wallet: money from selling fertilizer and refunds, spent on orders.
class FarmerWalletScreen extends ConsumerWidget {
  const FarmerWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final wallet = ref.watch(farmerWalletProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My wallet')),
      body: ResponsiveScope(
        child: wallet.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(farmerWalletProvider)),
          data: (w) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(farmerWalletProvider),
            child: ListView(
              padding: context.pagePadding,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: Column(children: [
                    Text('Balance', style: text.labelMedium),
                    AnimatedCount(key: const Key('balance'), value: w.balance, format: (v) => formatRupees(v.toDouble()), style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: colors.primary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Pay for an order with it: open the order and choose "Pay from wallet".', textAlign: TextAlign.center, style: text.bodySmall),
                  ]),
                ),
                AppSpacing.gapMd,
                Text('History', style: text.titleMedium),
                AppSpacing.gapSm,
                if (w.entries.isEmpty) Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Center(child: Text('Nothing yet. Sell fertilizer you did not use to add money here.', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted)))),
                for (var i = 0; i < w.entries.length; i++) FadeSlideIn(index: i, child: _EntryTile(entry: w.entries[i])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final credit = entry.amount > 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: (credit ? colors.success : colors.danger).withValues(alpha: 0.14), child: Icon(credit ? Icons.south_west_rounded : Icons.north_east_rounded, color: credit ? colors.success : colors.danger, size: 18)),
      title: Text(entry.title),
      subtitle: Text('${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}${entry.note.isEmpty ? '' : '  ·  ${entry.note}'}'),
      trailing: Text('${credit ? '+' : '−'}${formatRupees(entry.amount.abs())}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: credit ? colors.success : colors.danger)),
    );
  }
}
