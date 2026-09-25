import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/animation/pressable.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_format.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../home/presentation/widgets/home_header.dart';
import '../../../soil_health/domain/entities/nutrient_reading.dart';
import '../../domain/entities/product.dart';
import '../../domain/product_query.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/market_widgets.dart';

/// The marketplace, laid out like a shopping app: search on top, round category icons, promo banners,
/// sort and filter, then a two-column grid of product cards.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.preselectedProductId});

  final String? preselectedProductId;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _search = TextEditingController();
  ProductQuery _query = const ProductQuery();
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only compare 2 products at a time')));
        return;
      }
      _selectedForCompare.add(productId);
    });
  }

  Future<void> _openSort() async {
    final picked = await showModalBottomSheet<ProductSort>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Align(alignment: Alignment.centerLeft, child: Text('Sort by', style: Theme.of(context).textTheme.titleMedium))),
          for (final s in ProductSort.values)
            ListTile(
              key: Key('sort-${s.name}'),
              title: Text(s.label),
              trailing: _query.sort == s ? Icon(Icons.check_circle_rounded, color: context.colors.primary) : const Icon(Icons.radio_button_unchecked),
              onTap: () => Navigator.pop(context, s),
            ),
        ]),
      ),
    );
    if (picked != null) setState(() => _query = _query.copyWith(sort: picked));
  }

  Future<void> _openFilter(List<Product> all, bool hasSoilScan) async {
    final highest = all.isEmpty ? 1000.0 : all.map((p) => p.priceInRupees).reduce((a, b) => a > b ? a : b);
    final ceiling = (highest / 100).ceil() * 100.0;
    final result = await showModalBottomSheet<ProductQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FilterSheet(initial: _query, ceiling: ceiling, hasSoilScan: hasSoilScan),
    );
    if (result != null) setState(() => _query = result);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final deficient = ref.watch(deficientNutrientsProvider).whenOrNull(data: (d) => d) ?? const <NutrientType>{};
    final colors = context.colors;

    return ResponsiveScope(
      child: SafeArea(
        child: Column(children: [
          Expanded(
            child: productsAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(productsProvider)),
              data: (all) {
                final shown = _query.apply(all, deficient);
                final columns = context.breakpoint.isTabletUp ? context.gridColumns : 2;
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(productsProvider),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, 0),
                          child: Row(children: [
                            Expanded(child: MarketSearchBar(controller: _search, onChanged: (v) => setState(() => _query = _query.copyWith(text: v)))),
                            IconButton(tooltip: 'My orders', onPressed: () => context.push(RoutePaths.farmerOrders), icon: const Icon(Icons.receipt_long_outlined)),
                          ]),
                        ),
                      ),
                      const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0), child: CurrentLocationLine())),
                      SliverToBoxAdapter(child: AppSpacing.gapSm),
                      SliverToBoxAdapter(child: CategoryStrip(selected: _query.category, onChanged: (c) => setState(() => _query = _query.copyWith(category: c)))),
                      SliverToBoxAdapter(
                        child: PromoCarousel(banners: [
                          PromoBanner(title: 'Surplus deals near you', subtitle: 'Farmers\' unused fertilizer, inspected at your center, at a lower price', icon: Icons.sell_rounded, onTap: () => context.push(RoutePaths.farmerSurplus)),
                          PromoBanner(title: 'Find a village center', subtitle: 'See who has your product in stock and how far it is', icon: Icons.location_on_rounded, onTap: () => context.push(RoutePaths.farmerCenters)),
                          PromoBanner(title: 'Not sure what to buy?', subtitle: 'Ask the farming assistant about your crop and soil', icon: Icons.smart_toy_rounded, onTap: () => context.push(RoutePaths.farmerAssistant)),
                        ]),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedBar(
                          height: 52,
                          child: Container(
                            color: colors.background,
                            alignment: Alignment.center,
                            child: Row(children: [
                              Expanded(
                                child: SortFilterBar(
                                  query: _query,
                                  count: shown.length,
                                  onSort: _openSort,
                                  onFilter: () => _openFilter(all, deficient.isNotEmpty),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.sm),
                                child: IconButton(
                                  key: const Key('compare-toggle'),
                                  tooltip: _compareMode ? 'Stop comparing' : 'Compare products',
                                  onPressed: _toggleCompareMode,
                                  icon: Icon(_compareMode ? Icons.close_rounded : Icons.compare_arrows_rounded),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      if (shown.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _NoResults(onClear: () => setState(() { _search.clear(); _query = const ProductQuery(); })),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) => SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: AppSpacing.sm,
                                mainAxisSpacing: AppSpacing.sm,
                                mainAxisExtent: _cardHeight(constraints.crossAxisExtent, columns),
                              ),
                              delegate: SliverChildBuilderDelegate(
                                childCount: shown.length,
                                (context, i) {
                                  final product = shown[i];
                                  return FadeSlideIn(
                                    key: ValueKey(product.id),
                                    index: i,
                                    child: Pressable(
                                      child: ProductCard(
                                        product: product,
                                        matchesSoil: ProductQuery.matchesSoil(product, deficient),
                                        compareMode: _compareMode,
                                        isSelectedForCompare: _selectedForCompare.contains(product.id),
                                        onTap: () => _compareMode ? _toggleSelection(product.id) : context.push(RoutePaths.farmerMarketplaceProduct(product.id)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_compareMode && _selectedForCompare.length == 2)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: FilledButton.icon(
                key: const Key('compare-selected'),
                onPressed: () {
                  final ids = _selectedForCompare.toList();
                  context.push(RoutePaths.farmerMarketplaceCompare(ids[0], ids[1]));
                },
                icon: const Icon(Icons.compare_arrows_rounded),
                label: const Text('Compare selected products'),
              ),
            ),
        ]),
      ),
    );
  }

  /// A card is a picture (1.25 wide to 1 high) plus room for the text (brand, two-line name, rating, price, pickup line).
  double _cardHeight(double gridWidth, int columns) {
    final cardWidth = (gridWidth - AppSpacing.sm * (columns - 1)) / columns;
    return cardWidth / 1.25 + 172;
  }
}

class _PinnedBar extends SliverPersistentHeaderDelegate {
  const _PinnedBar({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _PinnedBar oldDelegate) => true;
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 52, color: colors.textMuted),
          AppSpacing.gapSm,
          Text('No products match', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Try a different word or remove a filter.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
          AppSpacing.gapSm,
          TextButton(key: const Key('clear-filters'), onPressed: onClear, child: const Text('Clear search and filters')),
        ]),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.ceiling, required this.hasSoilScan});

  final ProductQuery initial;
  final double ceiling;
  final bool hasSoilScan;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _minRating = widget.initial.minRating;
  late bool _soil = widget.initial.soilMatchOnly;
  late double _maxPrice = widget.initial.maxPrice ?? widget.ceiling;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Filter', style: text.titleMedium),
            AppSpacing.gapMd,
            Text('Customer rating', style: text.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, children: [
              for (final r in const [0.0, 3.0, 4.0])
                ChoiceChip(key: Key('rating-$r'), label: Text(r == 0 ? 'Any' : '${r.toStringAsFixed(0)}★ & up'), selected: _minRating == r, onSelected: (_) => setState(() => _minRating = r)),
            ]),
            AppSpacing.gapMd,
            Text('Price up to ${formatRupees(_maxPrice)}', key: const Key('price-label'), style: text.labelLarge),
            Slider(
              key: const Key('price-slider'),
              value: _maxPrice.clamp(100, widget.ceiling),
              min: 100,
              max: widget.ceiling < 200 ? 200 : widget.ceiling,
              divisions: ((widget.ceiling - 100) / 100).round().clamp(1, 100),
              onChanged: (v) => setState(() => _maxPrice = v),
            ),
            SwitchListTile(
              key: const Key('soil-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Matches my soil'),
              subtitle: Text(widget.hasSoilScan ? 'Only products for the nutrients your latest scan found low' : 'Scan your soil first to use this', style: text.bodySmall?.copyWith(color: colors.textMuted)),
              value: _soil,
              onChanged: widget.hasSoilScan ? (v) => setState(() => _soil = v) : null,
            ),
            AppSpacing.gapSm,
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('filter-clear'),
                  onPressed: () => Navigator.pop(context, widget.initial.copyWith(minRating: 0, soilMatchOnly: false, maxPrice: null)),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  key: const Key('filter-apply'),
                  onPressed: () => Navigator.pop(
                    context,
                    widget.initial.copyWith(minRating: _minRating, soilMatchOnly: _soil, maxPrice: _maxPrice >= widget.ceiling ? null : _maxPrice),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

