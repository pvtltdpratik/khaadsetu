import 'package:equatable/equatable.dart';

import 'nutrient_reading.dart';

/// The full result of one soil scan, matching the Soil Sense backend's
/// `/v1/analyze` and `/v1/history` response shape exactly (see
/// `SoilHealthApiDataSource`) — every field here is real data from that
/// service, not a mock detail. [SoilHealthSummary] is the lighter-weight
/// view of the *latest* one, used on the home screen.
class SoilScanResult extends Equatable {
  const SoilScanResult({
    required this.id,
    required this.scannedAt,
    required this.overallScore,
    required this.soilMoisturePercent,
    required this.nutrients,
    required this.disease,
    required this.diseaseConfidencePercent,
    required this.recommendations,
    required this.cropType,
  });

  final String id;
  final DateTime scannedAt;

  /// 0-100 ("health_score").
  final double overallScore;

  /// 0-100.
  final double soilMoisturePercent;
  final List<NutrientReading> nutrients;

  /// Short label for the most likely disease indicator, e.g. "Leaf spot
  /// indicators" — the backend always returns something here, even if it's
  /// a "no significant indicators" style message.
  final String disease;

  /// 0-100 confidence in [disease].
  final double diseaseConfidencePercent;
  final List<String> recommendations;

  /// From the request metadata (e.g. "tomato") — null if none was given.
  final String? cropType;

  NutrientReading nutrient(NutrientType type) =>
      nutrients.firstWhere((n) => n.type == type);

  @override
  List<Object?> get props => [
        id,
        scannedAt,
        overallScore,
        soilMoisturePercent,
        nutrients,
        disease,
        diseaseConfidencePercent,
        recommendations,
        cropType,
      ];
}
