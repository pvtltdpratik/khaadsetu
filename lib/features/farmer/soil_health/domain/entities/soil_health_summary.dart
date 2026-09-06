import 'package:equatable/equatable.dart';

/// The farmer's most recent soil health reading, as shown in the home
/// summary card. [score] and [lastScanDate] are both null when the farmer
/// hasn't scanned yet — the UI renders the gauge's empty state in that case.
class SoilHealthSummary extends Equatable {
  const SoilHealthSummary({
    required this.score,
    required this.lastScanDate,
    required this.note,
    required this.scanId,
  });

  /// 0-100. Null means no scan has been recorded yet.
  final double? score;
  final DateTime? lastScanDate;

  /// Short, farmer-facing sentence explaining the score, e.g. "Nitrogen
  /// levels are low — consider a urea top-dressing before the next watering."
  final String note;

  /// Id of the underlying [SoilScanResult], so "View details" can deep-link
  /// straight to it. Null exactly when [score] is null.
  final String? scanId;

  bool get hasScan => score != null;

  @override
  List<Object?> get props => [score, lastScanDate, note, scanId];
}
