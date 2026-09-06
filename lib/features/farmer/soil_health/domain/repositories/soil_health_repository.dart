import 'dart:typed_data';

import '../entities/soil_health_summary.dart';
import '../entities/soil_scan_result.dart';

/// Contract the presentation layer depends on. [SoilHealthApiDataSource]
/// implements this against the real Soil Sense backend; swapping to a
/// different backend later means writing a new implementation of this
/// interface — no UI or provider code changes.
abstract class SoilHealthRepository {
  Future<SoilHealthSummary> getLatestSummary();

  /// Uploads a captured image for analysis. [cropType] is optional context
  /// (e.g. "tomato") sent alongside the device id.
  Future<SoilScanResult> analyzeImage({
    required Uint8List imageBytes,
    required String filename,
    String? cropType,
  });

  /// Up to 5 scans from the last 15 days, newest first (the backend's own
  /// retention policy — see `server/README`).
  Future<List<SoilScanResult>> getScanHistory();

  Future<SoilScanResult> getScanById(String id);
}
