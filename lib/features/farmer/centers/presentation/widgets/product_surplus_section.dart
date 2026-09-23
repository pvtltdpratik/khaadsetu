import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../providers/centers_providers.dart';
import 'surplus_offer_card.dart';

/// On a product page: cheaper surplus units of THIS product near the farmer.
/// Shows nothing at all when there are none (or we cannot tell), so a product
/// with no deals looks exactly as it did before.
class ProductSurplusSection extends ConsumerWidget {
  const ProductSurplusSection({super.key, required this.productId});

  final String productId;

  static const _preview = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(surplusNearbyProvider(productId)).value;
    if (offers == null || offers.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.gapLg,
        Row(
          children: [
            Icon(Icons.sell_outlined, size: 20, color: colors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Cheaper units nearby', style: Theme.of(context).textTheme.titleMedium)),
            if (offers.length > _preview) TextButton(onPressed: () => context.push(RoutePaths.farmerSurplus), child: const Text('See all')),
          ],
        ),
        AppSpacing.gapSm,
        for (final (i, offer) in offers.take(_preview).indexed) ...[
          FadeSlideIn(key: ValueKey(offer.lotId), index: i, child: SurplusOfferCard(offer: offer)),
          AppSpacing.gapSm,
        ],
      ],
    );
  }
}
