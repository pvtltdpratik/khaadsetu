import 'package:equatable/equatable.dart';

import '../../../soil_health/domain/entities/nutrient_reading.dart';

enum ProductCategory { fertilizer, organic, pesticide, seed, equipment }

/// A marketplace listing. Kept free of any Flutter import — the
/// presentation layer maps [category] to an icon/color and formats
/// [priceInRupees] for display.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.priceInRupees,
    required this.unitLabel,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.nutrientFocus,
    required this.npkPercentages,
  });

  final String id;
  final String name;
  final String brand;
  final ProductCategory category;
  final double priceInRupees;

  /// e.g. "50 kg bag", "1 L bottle".
  final String unitLabel;

  /// 0-5 average.
  final double rating;
  final int reviewCount;
  final String description;

  /// Which nutrient deficiencies this product addresses — used to flag
  /// "Matches your soil" against the farmer's latest scan. Empty for
  /// products that aren't fertilizers (seeds, equipment, pesticides).
  final List<NutrientType> nutrientFocus;

  /// N/P/K composition as percentages, e.g. {nitrogen: 10, phosphorus: 26,
  /// potassium: 26} for a "10-26-26" grade. Empty when not applicable.
  final Map<NutrientType, double> npkPercentages;

  @override
  List<Object?> get props => [
        id,
        name,
        brand,
        category,
        priceInRupees,
        unitLabel,
        rating,
        reviewCount,
        description,
        nutrientFocus,
        npkPercentages,
      ];
}
