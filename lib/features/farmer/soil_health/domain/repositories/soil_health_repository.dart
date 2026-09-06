import '../entities/soil_health_summary.dart';
import '../entities/soil_scan_result.dart';

/// Contract the presentation layer depends on. Swapping [FakeSoilHealthDataSource]
/// for a real API client later means writing a new implementation of this
/// interface — no UI or provider code changes.
abstract class SoilHealthRepository {
  Future<SoilHealthSummary> getLatestSummary();

  /// Runs a new scan (stands in for the ML inference) and records it as the
  /// latest result.
  Future<SoilScanResult> captureScan();

  Future<List<SoilScanResult>> getScanHistory();

  Future<SoilScanResult> getScanById(String id);
}
