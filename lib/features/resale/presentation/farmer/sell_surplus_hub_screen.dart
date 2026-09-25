import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animation/animated_count.dart';
import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/resale_models.dart';
import '../resale_providers.dart';

Color statusColor(ResaleStatus s, AppColorTokens colors) => switch (s) {
      ResaleStatus.live || ResaleStatus.listed => colors.success,
      ResaleStatus.soldOut => colors.primary,
      ResaleStatus.awaitingHandover || ResaleStatus.inspectionRequired => colors.warning,
      ResaleStatus.rejected => colors.danger,
      ResaleStatus.withdrawn || ResaleStatus.draft => colors.textMuted,
      ResaleStatus.pendingVerification => colors.info,
    };

/// Sell leftover organic fertilizer: how it works, my wallet, and my listings.
class SellSurplusHubScreen extends ConsumerWidget {
  const SellSurplusHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final listings = ref.watch(myListingsProvider);
    final wallet = ref.watch(farmerWalletProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Sell surplus fertilizer')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('start-selling'),
        onPressed: () async {
          await context.push(RoutePaths.farmerSellSurplusNew);
          ref.invalidate(myListingsProvider);
          ref.invalidate(eligibleProductsProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sell fertilizer'),
      ),
      body: ResponsiveScope(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(myListingsProvider)
              ..invalidate(farmerWalletProvider);
          },
          child: ListView(
            padding: context.pagePadding.copyWith(bottom: 96),
            children: [
              FadeSlideIn(
                child: InkWell(
                  key: const Key('wallet-card'),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => context.push(RoutePaths.farmerWallet),
                  child: Ink(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      gradient: LinearGradient(colors: [colors.primary, colors.primary.withValues(alpha: 0.8)]),
                    ),
                    child: Row(children: [
                      Icon(Icons.account_balance_wallet_outlined, color: colors.onPrimary, size: 32),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Your wallet', style: text.labelMedium?.copyWith(color: colors.onPrimary.withValues(alpha: 0.9))),
                          AnimatedCount(value: wallet?.balance ?? 0, format: (v) => formatRupees(v.toDouble()), style: text.headlineSmall?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colors.onPrimary),
                    ]),
                  ),
                ),
              ),
              AppSpacing.gapMd,
              const FadeSlideIn(index: 1, child: _HowItWorks()),
              AppSpacing.gapMd,
              Text('My listings', style: text.titleMedium),
              AppSpacing.gapSm,
              listings.when(
                loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: AppLoadingIndicator()),
                error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myListingsProvider)),
                data: (list) => list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(children: [
                          Icon(Icons.recycling_outlined, size: 48, color: colors.textMuted),
                          AppSpacing.gapSm,
                          Text('Nothing listed yet. Fertilizer you bought here and did not use can be sold to other farmers.', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted)),
                        ]),
                      )
                    : Column(children: [for (var i = 0; i < list.length; i++) FadeSlideIn(index: i, child: _ListingCard(listing: list[i]))]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    Widget step(int n, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 12, backgroundColor: colors.primaryContainer, child: Text('$n', style: text.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w800))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: text.titleSmall), Text(body, style: text.bodySmall?.copyWith(color: colors.textMuted))])),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How it works', style: text.titleMedium),
        AppSpacing.gapSm,
        step(1, 'List it', 'Pick something you bought here, add photos and a price. Only organic fertilizer you collected from us can be sold.'),
        step(2, 'Your center checks it', 'They approve it from the photos, or ask you to bring it in. When a buyer is found you have 48 hours to bring it.'),
        step(3, 'Get paid', 'You keep 89% (86% without proof of purchase). Wallet is instant; UPI takes 1 to 2 days; cash keeps 97% of it.'),
        Text('At least 2 kg or 1 litre. The same product can be listed up to 3 times a season.', style: text.labelSmall?.copyWith(color: colors.textMuted)),
      ]),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final ResaleListing listing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final color = statusColor(listing.status, colors);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          key: Key('listing-${listing.id}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.push(RoutePaths.farmerSellSurplusListing(listing.id)),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(listing.productName, style: text.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(listing.status.label, style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: AppSpacing.xs),
              Text('${listing.units} × ${listing.unit}  ·  ${formatRupees(listing.price)} each  ·  ${listing.centerName}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
              if (listing.unitsSold > 0) Text('${listing.unitsSold} sold', style: text.bodySmall?.copyWith(color: colors.success)),
              if (listing.status == ResaleStatus.awaitingHandover && listing.handoverDue != null)
                Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('Bring it to the center by ${_dueText(listing.handoverDue!)}', style: text.bodySmall?.copyWith(color: colors.warning, fontWeight: FontWeight.w700))),
            ]),
          ),
        ),
      ),
    );
  }
}

String _dueText(DateTime d) => '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
