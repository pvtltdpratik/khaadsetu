import 'package:flutter/material.dart';

import '../../../../../core/animation/pressable.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_format.dart';
import '../../domain/entities/product.dart';
import '../../domain/product_query.dart';
import 'product_category_style.dart';

/// The rounded search box at the top, like a shopping app's.
class MarketSearchBar extends StatelessWidget {
  const MarketSearchBar({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      key: const Key('market-search'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search fertilizers, seeds, neem, vermicompost…',
        prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                key: const Key('market-search-clear'),
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide(color: colors.border)),
      ),
    );
  }
}

/// Round category icons with a label under each, in a row that scrolls sideways.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({super.key, required this.selected, required this.onChanged});

  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget tile(String key, IconData icon, String label, Color color, bool on, VoidCallback tap) => InkWell(
          key: Key(key),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: tap,
          child: SizedBox(
            width: 72,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: on ? 0.28 : 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: on ? color : Colors.transparent, width: 2),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
            ]),
          ),
        );

    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          tile('category-all', Icons.apps_rounded, 'All', colors.primary, selected == null, () => onChanged(null)),
          for (final c in ProductCategory.values)
            tile('category-${c.name}', ProductCategoryStyle.iconFor(c), ProductCategoryStyle.labelFor(c), ProductCategoryStyle.colorFor(c, colors), selected == c, () => onChanged(selected == c ? null : c)),
        ],
      ),
    );
  }
}

class PromoBanner {
  const PromoBanner({required this.title, required this.subtitle, required this.icon, required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

/// A row of promotional banners you swipe through, with dots showing where you are.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.banners});

  final List<PromoBanner> banners;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final gradients = [
      [colors.primary, colors.primary.withValues(alpha: 0.75)],
      [colors.secondary, colors.secondary.withValues(alpha: 0.75)],
      [colors.info, colors.info.withValues(alpha: 0.75)],
    ];
    return Column(children: [
      SizedBox(
        height: 112,
        child: PageView.builder(
          key: const Key('promo-carousel'),
          controller: _controller,
          itemCount: widget.banners.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) {
            final b = widget.banners[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Pressable(
                child: Material(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: Key('promo-$i'),
                    onTap: b.onTap,
                    child: Ink(
                      decoration: BoxDecoration(gradient: LinearGradient(colors: gradients[i % gradients.length], begin: Alignment.centerLeft, end: Alignment.centerRight)),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(children: [
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(b.title, style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(b.subtitle, style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.92)), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        Icon(b.icon, size: 46, color: Colors.white.withValues(alpha: 0.85)),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < widget.banners.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: i == _page ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(color: i == _page ? colors.primary : colors.border, borderRadius: BorderRadius.circular(3)),
          ),
      ]),
    ]);
  }
}

/// "Sort" and "Filter" buttons with a result count, kept at the top while the list scrolls.
class SortFilterBar extends StatelessWidget {
  const SortFilterBar({super.key, required this.query, required this.count, required this.onSort, required this.onFilter});

  final ProductQuery query;
  final int count;
  final VoidCallback onSort;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      color: colors.background,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(children: [
        Expanded(child: Text('$count product${count == 1 ? '' : 's'}', key: const Key('product-count'), maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelMedium?.copyWith(color: colors.textMuted))),
        OutlinedButton.icon(
          key: const Key('sort-button'),
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 36)),
          onPressed: onSort,
          icon: const Icon(Icons.swap_vert_rounded, size: 18),
          label: Text(query.sort.shortLabel),
        ),
        const SizedBox(width: AppSpacing.xs),
        Badge(
          isLabelVisible: query.activeFilterCount > 0,
          label: Text('${query.activeFilterCount}'),
          child: OutlinedButton.icon(key: const Key('filter-button'), style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 36)), onPressed: onFilter, icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('Filter')),
        ),
      ]),
    );
  }
}

/// A product as a shopping app shows it: a picture area, a green rating pill, the name, and a big price.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.matchesSoil,
    required this.onTap,
    this.compareMode = false,
    this.isSelectedForCompare = false,
  });

  final Product product;
  final bool matchesSoil;
  final VoidCallback onTap;
  final bool compareMode;
  final bool isSelectedForCompare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final tint = ProductCategoryStyle.colorFor(product.category, colors);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: Key('product-${product.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: isSelectedForCompare ? colors.primary : colors.border, width: isSelectedForCompare ? 2 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: Stack(children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md - 1)),
                      gradient: LinearGradient(colors: [tint.withValues(alpha: 0.22), tint.withValues(alpha: 0.06)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Center(child: Icon(ProductCategoryStyle.iconFor(product.category), size: 54, color: tint)),
                  ),
                ),
                if (matchesSoil)
                  Positioned(
                    left: 0,
                    top: 8,
                    child: Container(
                      key: const Key('soil-ribbon'),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: colors.success, borderRadius: const BorderRadius.horizontal(right: Radius.circular(6))),
                      child: Text('Matches your soil', style: text.labelSmall?.copyWith(color: colors.onSuccess, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (compareMode)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Icon(isSelectedForCompare ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: isSelectedForCompare ? colors.primary : colors.textMuted),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(product.brand, style: text.labelSmall?.copyWith(color: colors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(product.name, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Row(children: [
                  Container(
                    key: const Key('rating-pill'),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: product.rating >= 3.5 ? colors.success : colors.warning, borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(product.rating.toStringAsFixed(1), style: text.labelSmall?.copyWith(color: colors.onSuccess, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 2),
                      Icon(Icons.star_rounded, size: 11, color: colors.onSuccess),
                    ]),
                  ),
                  const SizedBox(width: 6),
                  Text('(${product.reviewCount})', style: text.labelSmall?.copyWith(color: colors.textMuted)),
                ]),
                const SizedBox(height: AppSpacing.xs),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatRupees(product.priceInRupees), key: const Key('price'), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Expanded(child: Text('/ ${product.unitLabel}', style: text.labelSmall?.copyWith(color: colors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 2),
                Text('Pickup at your village center', style: text.labelSmall?.copyWith(color: colors.success)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
