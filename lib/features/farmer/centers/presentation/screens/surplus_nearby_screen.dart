import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../providers/centers_providers.dart';
import '../widgets/location_banner.dart';
import '../widgets/surplus_offer_card.dart';

/// Discounted units (near expiry, opened, returned or in damaged packs) that
/// village centers near the farmer are selling cheaper, nearest first.
class SurplusNearbyScreen extends ConsumerWidget {
  const SurplusNearbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final offers = ref.watch(surplusNearbyProvider(null));
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Surplus deals near you')),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(surplusNearbyProvider);
              await ref.read(surplusNearbyProvider(null).future);
            },
            child: ListView(
              children: [
                ContentContainer(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LocationBanner(),
                      AppSpacing.gapMd,
                      Text(
                        'Cheaper units that are near expiry, opened, returned or in damaged packs. Check the condition before you reserve.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                      ),
                      AppSpacing.gapMd,
                      offers.when(
                        loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: AppLoadingIndicator()),
                        error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(surplusNearbyProvider)),
                        data: (list) {
                          if (list == null) return const SizedBox.shrink();
                          if (list.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                children: [
                                  Icon(Icons.sell_outlined, size: 40, color: colors.textMuted),
                                  AppSpacing.gapSm,
                                  Text(
                                    'No surplus deals near you right now. Check back soon.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (final offer in list) ...[
                                SurplusOfferCard(offer: offer),
                                AppSpacing.gapMd,
                              ],
                            ],
                          );
                        },
                      ),
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
