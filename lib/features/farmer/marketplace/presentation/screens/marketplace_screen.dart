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
import '../widgets/category_filter_chips.dart';
import '../widgets/product_grid_card.dart';
import '../widgets/product_list_tile.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.preselectedProductId});

  final String? preselectedProductId;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  ProductCategory? _categoryFilter;
  bool _compareMode = false;
  final Set<String> _selectedForCompare = {};

  @override
  void initState() {
    super.initState();
    final preselected = widget.preselectedProductId;
    if (preselected != null) {
      _compareMode = true;
      _selectedForCompare.add(preselected);
    }
  }

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      if (!_compareMode) _selectedForCompare.clear();
    });
  }

  void _toggleSelection(String productId) {
    setState(() {
      if (_selectedForCompare.contains(productId)) {
        _selectedForCompare.remove(productId);
        return;
      }
      if (_selectedForCompare.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only compare 2 products at a time')),
        );
        return;
      }
      _selectedForCompare.add(productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final deficientAsync = ref.watch(deficientNutrientsProvider);
    final deficient = deficientAsync.whenOrNull(data: (d) => d) ?? const <NutrientType>{};

    return ResponsiveScope(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text('Marketplace', style: Theme.of(context).textTheme.titleLarge)),
                  TextButton.icon(
                    onPressed: _toggleCompareMode,
                    icon: Icon(_compareMode ? Icons.close_rounded : Icons.compare_arrows_rounded),
                    label: Text(_compareMode ? 'Cancel' : 'Compare'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: CategoryFilterChips(
                selected: _categoryFilter,
                onChanged: (c) => setState(() => _categoryFilter = c),
              ),
            ),
            AppSpacing.gapSm,
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  final filtered = _categoryFilter == null
                      ? products
                      : products.where((p) => p.category == _categoryFilter).toList();
                  return _ProductsView(
                    products: filtered,
                    deficientNutrients: deficient,
                    compareMode: _compareMode,
                    selectedForCompare: _selectedForCompare,
                    onProductTap: (product) {
                      if (_compareMode) {
                        _toggleSelection(product.id);
                      } else {
                        context.push(RoutePaths.farmerMarketplaceProduct(product.id));
                      }
                    },
                  );
                },
                loading: () => const AppLoadingIndicator(),
                error: (err, _) => AppErrorView(
                  message: '$err',
                  onRetry: () => ref.invalidate(productsProvider),
                ),
              ),
            ),
            if (_compareMode && _selectedForCompare.length == 2)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton.icon(
                  onPressed: () {
                    final ids = _selectedForCompare.toList();
                    context.push(RoutePaths.farmerMarketplaceCompare(ids[0], ids[1]));
                  },
                  icon: const Icon(Icons.compare_arrows_rounded),
                  label: const Text('Compare selected products'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView({
    required this.products,
    required this.deficientNutrients,
    required this.compareMode,
    required this.selectedForCompare,
    required this.onProductTap,
  });

  final List<Product> products;
  final Set<NutrientType> deficientNutrients;
  final bool compareMode;
  final Set<String> selectedForCompare;
  final ValueChanged<Product> onProductTap;

  bool _matchesSoil(Product product) =>
      product.nutrientFocus.any(deficientNutrients.contains);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          'No products in this category',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
        ),
      );
    }

    if (!context.breakpoint.isTabletUp) {
      return ListView.separated(
        padding: context.pagePadding,
        itemCount: products.length,
        separatorBuilder: (_, _) => AppSpacing.gapSm,
        itemBuilder: (context, i) {
          final product = products[i];
          return ProductListTile(
            product: product,
            matchesSoil: _matchesSoil(product),
            compareMode: compareMode,
            isSelectedForCompare: selectedForCompare.contains(product.id),
            onTap: () => onProductTap(product),
          );
        },
      );
    }

    return GridView.builder(
      padding: context.pagePadding,
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, i) {
        final product = products[i];
        return ProductGridCard(
          product: product,
          matchesSoil: _matchesSoil(product),
          compareMode: compareMode,
          isSelectedForCompare: selectedForCompare.contains(product.id),
          onTap: () => onProductTap(product),
        );
      },
    );
  }
}
