import '../../domain/entities/nutrient_reading.dart';
import '../../domain/entities/soil_health_summary.dart';
import '../../domain/entities/soil_scan_result.dart';

/// Stands in for a remote soil-health API. Holds an in-memory list of past
/// scans, seeded with history so the result/history screens have something
/// to show immediately; [captureScan] appends a new one, simulating what a
/// real ML inference call would record.
class SoilHealthFakeDataSource {
  final List<SoilScanResult> _scans = [
    _scan(
      id: 'scan-1',
      daysAgo: 30,
      score: 42,
      n: 180,
      p: 8,
      k: 140,
      ph: 6.1,
      organicMatter: 0.4,
      recommendation: 'Nitrogen and Phosphorus are both low. Consider a '
          'balanced NPK fertilizer application.',
    ),
    _scan(
      id: 'scan-2',
      daysAgo: 20,
      score: 51,
      n: 210,
      p: 14,
      k: 160,
      ph: 6.3,
      organicMatter: 0.5,
      recommendation: 'Phosphorus has improved. Nitrogen is still low — '
          'plan a urea application.',
    ),
    _scan(
      id: 'scan-3',
      daysAgo: 10,
      score: 60,
      n: 250,
      p: 18,
      k: 190,
      ph: 6.5,
      organicMatter: 0.6,
      recommendation: 'Steady improvement. Nitrogen remains the main gap '
          'before the next crop stage.',
    ),
    _scan(
      id: 'scan-4',
      daysAgo: 4,
      score: 68,
      n: 270,
      p: 20,
      k: 210,
      ph: 6.7,
      organicMatter: 0.65,
      recommendation: 'Nitrogen is a little low — a urea top-dressing '
          'before the next watering should help.',
    ),
  ];

  int _captureCount = 0;

  Future<SoilHealthSummary> fetchLatestSummary() async {
    await Future.delayed(const Duration(milliseconds: 700));
    final latest = _latest();
    return SoilHealthSummary(
      score: latest.overallScore,
      lastScanDate: latest.scannedAt,
      note: latest.recommendation,
      scanId: latest.id,
    );
  }

  Future<SoilScanResult> captureScan() async {
    // Simulated ML processing latency.
    await Future.delayed(const Duration(milliseconds: 1800));
    _captureCount++;
    final result = _scan(
      id: 'scan-new-$_captureCount',
      daysAgo: 0,
      score: 76,
      n: 320,
      p: 22,
      k: 300,
      ph: 6.9,
      organicMatter: 0.7,
      recommendation: 'Nutrient levels are looking good — maintain your '
          'current fertilization schedule.',
    );
    _scans.add(result);
    return result;
  }

  Future<List<SoilScanResult>> fetchScanHistory() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_scans.reversed);
  }

  Future<SoilScanResult> fetchScanById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _scans.firstWhere((s) => s.id == id);
  }

  SoilScanResult _latest() => _scans.last;

  static SoilScanResult _scan({
    required String id,
    required int daysAgo,
    required double score,
    required double n,
    required double p,
    required double k,
    required double ph,
    required double organicMatter,
    required String recommendation,
  }) {
    return SoilScanResult(
      id: id,
      scannedAt: DateTime.now().subtract(Duration(days: daysAgo)),
      overallScore: score,
      nutrients: [
        NutrientReading.of(NutrientType.nitrogen, n),
        NutrientReading.of(NutrientType.phosphorus, p),
        NutrientReading.of(NutrientType.potassium, k),
      ],
      phLevel: ph,
      organicMatterPercent: organicMatter,
      recommendation: recommendation,
    );
  }
}
