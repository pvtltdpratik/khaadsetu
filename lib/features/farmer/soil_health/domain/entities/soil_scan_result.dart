import 'package:equatable/equatable.dart';

import 'nutrient_reading.dart';

/// The full result of one soil scan — what the result and history screens
/// show. [SoilHealthSummary] is the lighter-weight view of the *latest* one,
/// used on the home screen.
class SoilScanResult extends Equatable {
  const SoilScanResult({
    required this.id,
    required this.scannedAt,
    required this.overallScore,
    required this.nutrients,
    required this.phLevel,
    required this.organicMatterPercent,
    required this.recommendation,
  });

  final String id;
  final DateTime scannedAt;

  /// 0-100.
  final double overallScore;
  final List<NutrientReading> nutrients;
  final double phLevel;
  final double organicMatterPercent;
  final String recommendation;

  NutrientReading nutrient(NutrientType type) =>
      nutrients.firstWhere((n) => n.type == type);

  @override
  List<Object?> get props => [
        id,
        scannedAt,
        overallScore,
        nutrients,
        phLevel,
        organicMatterPercent,
        recommendation,
      ];
}
