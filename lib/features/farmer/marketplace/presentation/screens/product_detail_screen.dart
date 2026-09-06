import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/responsive/responsive_layout.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/product.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/npk_composition_chart.dart';
import '../widgets/price_format.dart';
import '../widgets/product_category_style.dart';
import '../widgets/product_placeholder_image.dart';
import '../widgets/review_card.dart';
import '../widgets/soil_match_badge.dart';
import '../widgets/star_rating.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));

    return ResponsiveScope(
      child: SafeArea(
        child: productAsync.when(
          data: (product) => _DetailBody(product: product),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(
            message: '$err',
            onRetry: () => ref.invalidate(productProvider(productId)),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final reviewsAsync = ref.watch(productReviewsProvider(product.id));
    final deficientAsync = ref.watch(deficientNutrientsProvider);
    final matchesSoil = deficientAsync.whenOrNull(
          data: (d) => product.nutrientFocus.any(d.contains),
        ) ??
        false;

    return ListView(
      padding: context.pagePadding,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(RoutePaths.farmerMarketplace),
            ),
            AppSpacing.gapSm,
            Expanded(child: Text('Product Details', style: Theme.of(context).textTheme.titleLarge)),
          ],
        ),
        AppSpacing.gapMd,
        ResponsiveRow(
          spacing: AppSpacing.lg,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProductPlaceholderImage(category: product.category, size: 140),
                AppSpacing.gapSm,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.surfaceSunken,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ProductCategoryStyle.labelFor(product.category),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                Text(product.brand, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    StarRating(rating: product.rating),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${product.rating} (${product.reviewCount} reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(formatRupees(product.priceInRupees), style: Theme.of(context).textTheme.headlineSmall),
                Text(product.unitLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                if (matchesSoil) ...[const SizedBox(height: AppSpacing.sm), const SoilMatchBadge()],
                const SizedBox(height: AppSpacing.md),
                Text(product.description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
        AppSpacing.gapLg,
        Text('Nutrient composition', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        NpkCompositionChart(percentages: product.npkPercentages),
        AppSpacing.gapLg,
        Text('Reviews (${product.reviewCount})', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        reviewsAsync.when(
          data: (reviews) => Column(
            children: [
              for (final review in reviews) ...[
                ReviewCard(review: review),
                AppSpacing.gapSm,
              ],
            ],
          ),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err'),
        ),
        AppSpacing.gapMd,
        OutlinedButton.icon(
          onPressed: () => context.push(
            '${RoutePaths.farmerMarketplace}?preselect=${product.id}',
          ),
          icon: const Icon(Icons.compare_arrows_rounded),
          label: const Text('Compare with another product'),
        ),
      ],
    );
  }
}
