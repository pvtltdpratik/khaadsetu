import 'package:equatable/equatable.dart';

enum NutrientType { nitrogen, phosphorus, potassium }

enum NutrientLevel { low, medium, high }

/// One nutrient's reading from a soil test, in kg/ha — the unit Indian soil
/// health cards report N/P/K in. [level] is a real agronomic classification
/// (not a mock detail): the cutoffs below follow the low/medium/high bands
/// used on those cards, so this would stay correct once a real lab result
/// replaces the fake data source.
class NutrientReading extends Equatable {
  const NutrientReading({
    required this.type,
    required this.valueKgPerHectare,
    required this.level,
  });

  final NutrientType type;
  final double valueKgPerHectare;
  final NutrientLevel level;

  /// Classifies a raw kg/ha reading into a level for the given nutrient.
  static NutrientLevel classify(NutrientType type, double valueKgPerHectare) {
    final (lowMax, mediumMax) = switch (type) {
      NutrientType.nitrogen => (280.0, 450.0),
      NutrientType.phosphorus => (10.0, 25.0),
      NutrientType.potassium => (110.0, 280.0),
    };
    if (valueKgPerHectare < lowMax) return NutrientLevel.low;
    if (valueKgPerHectare < mediumMax) return NutrientLevel.medium;
    return NutrientLevel.high;
  }

  factory NutrientReading.of(NutrientType type, double valueKgPerHectare) {
    return NutrientReading(
      type: type,
      valueKgPerHectare: valueKgPerHectare,
      level: classify(type, valueKgPerHectare),
    );
  }

  @override
  List<Object?> get props => [type, valueKgPerHectare, level];
}
