import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../soil_health/domain/entities/nutrient_reading.dart';
import '../../domain/entities/product.dart';
import '../providers/marketplace_providers.dart';
import '../../../../../core/utils/price_format.dart';
import '../widgets/product_placeholder_image.dart';
import '../widgets/star_rating.dart';

class ProductComparisonScreen extends ConsumerWidget {
  const ProductComparisonScreen({super.key, required this.idA, required this.idB});

  final String idA;
  final String idB;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productA = ref.watch(productProvider(idA));
    final productB = ref.watch(productProvider(idB));

    return ResponsiveScope(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go(RoutePaths.farmerMarketplace),
                  ),
                  AppSpacing.gapSm,
                  Text('Compare Products', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: productA.when(
                data: (a) => productB.when(
                  data: (b) => _ComparisonTable(productA: a, productB: b),
                  loading: () => const AppLoadingIndicator(),
                  error: (err, _) => AppErrorView(message: '$err'),
                ),
                loading: () => const AppLoadingIndicator(),
                error: (err, _) => AppErrorView(message: '$err'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.productA, required this.productB});

  final Product productA;
  final Product productB;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: context.pagePadding,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.1), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
        children: [
          _headerRow(context),
          _row(context, 'Brand', productA.brand, productB.brand),
          _row(context, 'Price', formatRupees(productA.priceInRupees), formatRupees(productB.priceInRupees)),
          _row(context, 'Unit', productA.unitLabel, productB.unitLabel),
          _ratingRow(context),
          _row(context, 'Nitrogen (N)', _pct(productA, NutrientType.nitrogen), _pct(productB, NutrientType.nitrogen)),
          _row(context, 'Phosphorus (P)', _pct(productA, NutrientType.phosphorus), _pct(productB, NutrientType.phosphorus)),
          _row(context, 'Potassium (K)', _pct(productA, NutrientType.potassium), _pct(productB, NutrientType.potassium)),
        ],
      ),
    );
  }

  String _pct(Product product, NutrientType type) {
    final value = product.npkPercentages[type];
    return value == null ? '—' : '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';
  }

  TableRow _headerRow(BuildContext context) {
    final colors = context.colors;
    Widget cell(Product product) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProductPlaceholderImage(category: product.category, size: 48),
              const SizedBox(height: AppSpacing.xs),
              Text(
                product.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        );
    return TableRow(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.divider))),
      children: [const SizedBox.shrink(), cell(productA), cell(productB)],
    );
  }

  TableRow _ratingRow(BuildContext context) {
    Widget cell(Product product) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(child: StarRating(rating: product.rating, size: 14)),
        );
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text('Rating', style: Theme.of(context).textTheme.labelMedium),
        ),
        cell(productA),
        cell(productB),
      ],
    );
  }

  TableRow _row(BuildContext context, String label, String valueA, String valueB) {
    final colors = context.colors;
    Widget cell(String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(value, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        );
    return TableRow(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.divider))),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        cell(valueA),
        cell(valueB),
      ],
    );
  }
}
