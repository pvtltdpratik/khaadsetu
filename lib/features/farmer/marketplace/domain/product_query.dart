import '../../soil_health/domain/entities/nutrient_reading.dart';
import 'entities/product.dart';

enum ProductSort {
  relevance('Relevance', 'Sort'),
  priceLow('Price: low to high', 'Price ↑'),
  priceHigh('Price: high to low', 'Price ↓'),
  rating('Rating', 'Rating');

  const ProductSort(this.label, this.shortLabel);

  final String label;

  /// What the Sort button says once a sort is chosen: short, so the bar fits a narrow phone.
  final String shortLabel;
}

/// What the farmer typed and picked on the marketplace: search words, category, sort and filters.
/// Pure, so the rules are tested without a screen.
class ProductQuery {
  const ProductQuery({
    this.text = '',
    this.category,
    this.sort = ProductSort.relevance,
    this.minRating = 0,
    this.soilMatchOnly = false,
    this.maxPrice,
  });

  final String text;
  final ProductCategory? category;
  final ProductSort sort;

  /// Show only products rated at least this (0 = any).
  final double minRating;

  /// Only products that address a nutrient the farmer's latest soil scan found low.
  final bool soilMatchOnly;
  final double? maxPrice;

  static const _unset = Object();

  ProductQuery copyWith({String? text, Object? category = _unset, ProductSort? sort, double? minRating, bool? soilMatchOnly, Object? maxPrice = _unset}) => ProductQuery(
        text: text ?? this.text,
        category: identical(category, _unset) ? this.category : category as ProductCategory?,
        sort: sort ?? this.sort,
        minRating: minRating ?? this.minRating,
        soilMatchOnly: soilMatchOnly ?? this.soilMatchOnly,
        maxPrice: identical(maxPrice, _unset) ? this.maxPrice : maxPrice as double?,
      );

  /// Filters chosen in the sheet (not the search box or category strip): drives the dot on "Filter".
  int get activeFilterCount => (minRating > 0 ? 1 : 0) + (soilMatchOnly ? 1 : 0) + (maxPrice != null ? 1 : 0);

  bool get isDefault => text.trim().isEmpty && category == null && sort == ProductSort.relevance && activeFilterCount == 0;

  static bool matchesSoil(Product p, Set<NutrientType> deficient) => p.nutrientFocus.any(deficient.contains);

  bool _matchesText(Product p) {
    final words = text.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return true;
    final haystack = '${p.name} ${p.brand} ${p.category.name} ${p.description} ${p.nutrientFocus.map((n) => n.name).join(' ')}'.toLowerCase();
    return words.every(haystack.contains);
  }

  List<Product> apply(List<Product> all, Set<NutrientType> deficient) {
    final kept = all.where((p) {
      if (category != null && p.category != category) return false;
      if (!_matchesText(p)) return false;
      if (p.rating < minRating) return false;
      if (maxPrice != null && p.priceInRupees > maxPrice!) return false;
      if (soilMatchOnly && !matchesSoil(p, deficient)) return false;
      return true;
    }).toList();

    switch (sort) {
      case ProductSort.priceLow:
        kept.sort((a, b) => a.priceInRupees.compareTo(b.priceInRupees));
      case ProductSort.priceHigh:
        kept.sort((a, b) => b.priceInRupees.compareTo(a.priceInRupees));
      case ProductSort.rating:
        kept.sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          return byRating != 0 ? byRating : b.reviewCount.compareTo(a.reviewCount);
        });
      case ProductSort.relevance:
        // What the farmer's soil needs comes first; otherwise the catalog's own order.
        final soil = kept.where((p) => matchesSoil(p, deficient)).toList();
        return [...soil, ...kept.where((p) => !matchesSoil(p, deficient))];
    }
    return kept;
  }
}
