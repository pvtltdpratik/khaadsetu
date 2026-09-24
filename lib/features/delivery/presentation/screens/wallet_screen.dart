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
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../../domain/entities/delivery_models.dart';
import '../providers/delivery_providers.dart';

/// What the partner has earned, what he still owes which center, and each entry.
/// The buyer pays goods + fee in cash to the partner: the fee is his, the goods
/// money is handed to the center, and the operator marks it settled.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('My money')),
        body: SafeArea(
          child: wallet.when(
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(walletProvider)),
            data: (w) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(walletProvider);
                await ref.read(walletProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [ContentContainer(maxWidth: 720, child: _Body(wallet: w))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text('You have earned', style: text.labelLarge?.copyWith(color: colors.primary)),
              KeyedSubtree(key: const Key('earned'), child: AnimatedCount(value: wallet.earned, format: (v) => formatRupees(v.toDouble()), style: text.displayMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w800))),
              Text('${wallet.deliveriesDone} deliveries${wallet.ratingCount > 0 ? ' · ★ ${wallet.ratingAvg.toStringAsFixed(1)} (${wallet.ratingCount})' : ''}', style: text.bodyMedium?.copyWith(color: colors.primary)),
            ]),
          ),
        ),
        AppSpacing.gapMd,
        FadeSlideIn(
          index: 1,
          child: Container(
            key: const Key('owed-card'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: wallet.owed > 0 ? colors.warning : colors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.storefront_rounded, color: wallet.owed > 0 ? colors.warning : colors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(wallet.owed > 0 ? 'Hand this cash to the village center' : 'You owe nothing to any center', style: text.titleSmall)),
                if (wallet.owed > 0) Text(formatRupees(wallet.owed), key: const Key('owed'), style: text.titleMedium),
              ]),
              if (wallet.owed > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('It is what buyers paid you for the goods. The operator marks it done when you hand it over.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                for (final c in wallet.owedByCenter)
                  Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Row(children: [Expanded(child: Text(c.centerName)), Text(formatRupees(c.owed))])),
              ],
            ]),
          ),
        ),
        AppSpacing.gapLg,
        Text('History', style: text.titleMedium),
        AppSpacing.gapSm,
        if (wallet.entries.isEmpty)
          Text('Nothing yet. Your first delivery will show up here.', style: text.bodyMedium?.copyWith(color: colors.textMuted))
        else
          for (final e in wallet.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(switch (e.kind) { LedgerKind.feeEarned => Icons.add_circle_outline_rounded, LedgerKind.goodsOwed => Icons.storefront_outlined, LedgerKind.goodsSettled => Icons.check_circle_outline_rounded }, color: e.kind == LedgerKind.feeEarned ? colors.success : colors.textMuted),
              title: Text(switch (e.kind) { LedgerKind.feeEarned => 'Delivery fee earned', LedgerKind.goodsOwed => 'Cash for goods, to hand over', LedgerKind.goodsSettled => 'Handed to the center' }),
              subtitle: Text('${formatDay(e.createdAt)}${e.note.isEmpty ? '' : ' · ${e.note}'}'),
              trailing: Text('${e.amount < 0 ? '-' : '+'}${formatRupees(e.amount.abs())}', style: text.titleSmall?.copyWith(color: e.kind == LedgerKind.feeEarned ? colors.success : null)),
            ),
      ],
    );
  }
}
