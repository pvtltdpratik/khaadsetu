import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/resale_models.dart';
import '../farmer/sell_surplus_hub_screen.dart' show statusColor;
import '../resale_providers.dart';

/// The village center's list of farmers' fertilizer: what to review, what is on sale, and what is at the center.
class ResaleQueueScreen extends ConsumerWidget {
  const ResaleQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(resaleQueueProvider(resaleToReview));
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Farmer resale'),
          actions: [
            IconButton(key: const Key('cash-payouts'), tooltip: 'Cash to hand over', icon: const Icon(Icons.payments_outlined), onPressed: () => context.push(RoutePaths.operatorResaleCash)),
          ],
          bottom: TabBar(tabs: [
            Tab(text: 'To review${review.hasValue && review.value!.isNotEmpty ? ' (${review.value!.length})' : ''}'),
            const Tab(text: 'On sale'),
            const Tab(text: 'At center'),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('walk-in-intake'),
          onPressed: () async {
            await context.push(RoutePaths.operatorResaleWalkIn);
            ref
              ..invalidate(resaleQueueProvider(resaleToReview))
              ..invalidate(resaleQueueProvider(resaleOnSale))
              ..invalidate(resaleQueueProvider(resaleAtCenter));
          },
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Take in goods'),
        ),
        body: const TabBarView(children: [
          _Tab(statuses: resaleToReview, empty: 'Nothing waiting. New listings from farmers appear here.'),
          _Tab(statuses: resaleOnSale, empty: 'Nothing on sale that still needs to be brought in.'),
          _Tab(statuses: resaleAtCenter, empty: 'No inspected farmer goods at your center right now.'),
        ]),
      ),
    );
  }
}

class _Tab extends ConsumerWidget {
  const _Tab({required this.statuses, required this.empty});

  final List<ResaleStatus> statuses;
  final String empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(resaleQueueProvider(statuses));
    return list.when(
      loading: () => const AppLoadingIndicator(),
      error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(resaleQueueProvider(statuses))),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(resaleQueueProvider(statuses)),
        child: items.isEmpty
            ? ListView(children: [Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Center(child: Text(empty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted))))])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
                itemCount: items.length,
                itemBuilder: (context, i) => FadeSlideIn(index: i, child: _Card(listing: items[i])),
              ),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.listing});

  final ResaleListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final l = listing;
    final color = statusColor(l.status, colors);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          key: Key('queue-${l.id}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () async {
            await context.push(RoutePaths.operatorResaleListing(l.id));
            for (final s in [resaleToReview, resaleOnSale, resaleAtCenter]) {
              ref.invalidate(resaleQueueProvider(s));
            }
          },
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${l.units} × ${l.productName}', style: text.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(l.status.label, style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 2),
              Text('${l.sellerDisplayName.isEmpty ? 'Farmer' : l.sellerDisplayName}  ·  ${formatRupees(l.price)} each  ·  ${l.verifiedPurchase ? 'verified purchase' : 'no proof of purchase'}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
              if (l.status == ResaleStatus.awaitingHandover && l.handoverDue != null)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text('Seller must bring it by ${l.handoverDue!.day}/${l.handoverDue!.month} ${l.handoverDue!.hour.toString().padLeft(2, '0')}:${l.handoverDue!.minute.toString().padLeft(2, '0')}', style: text.bodySmall?.copyWith(color: colors.warning, fontWeight: FontWeight.w700))),
            ]),
          ),
        ),
      ),
    );
  }
}
