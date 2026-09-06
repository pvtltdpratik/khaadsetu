import 'package:equatable/equatable.dart';

enum NutrientType { nitrogen, phosphorus, potassium }

enum NutrientLevel { low, medium, high }

/// One nutrient's reading from the soil-scan backend, as a 0-100
/// sufficiency score (not a raw kg/ha lab value — the backend's heuristic
/// model reports N/P/K the same normalized way it reports the overall
/// health score). [level] uses the same <40/40-70/>=70 cutoffs as
/// [SoilHealthBand] for the overall score, so "low/medium/high" means the
/// same thing everywhere in the app.
class NutrientReading extends Equatable {
  const NutrientReading({
    required this.type,
    required this.valuePercent,
    required this.level,
  });

  final NutrientType type;
  final double valuePercent;
  final NutrientLevel level;

  static NutrientLevel classify(double valuePercent) {
    if (valuePercent < 40) return NutrientLevel.low;
    if (valuePercent < 70) return NutrientLevel.medium;
    return NutrientLevel.high;
  }

  factory NutrientReading.of(NutrientType type, double valuePercent) {
    return NutrientReading(
      type: type,
      valuePercent: valuePercent,
      level: classify(valuePercent),
    );
  }

  @override
  List<Object?> get props => [type, valuePercent, level];
}
