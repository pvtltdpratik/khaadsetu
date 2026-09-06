import 'dart:typed_data';

import '../../domain/entities/soil_health_summary.dart';
import '../../domain/entities/soil_scan_result.dart';
import '../../domain/repositories/soil_health_repository.dart';
import '../datasources/soil_health_api_data_source.dart';

class SoilHealthRepositoryImpl implements SoilHealthRepository {
  const SoilHealthRepositoryImpl(this._dataSource, {required this.deviceId});

  final SoilHealthApiDataSource _dataSource;

  /// Captured once (from `deviceIdProvider`) rather than threaded through
  /// every call — which device this is stays an infrastructure detail, not
  /// something the domain interface or UI needs to know about.
  final String deviceId;

  @override
  Future<SoilHealthSummary> getLatestSummary() async {
    final history = await _dataSource.fetchHistory(deviceId);
    if (history.isEmpty) {
      return const SoilHealthSummary(score: null, lastScanDate: null, note: '', scanId: null);
    }
    final latest = history.first;
    return SoilHealthSummary(
      score: latest.overallScore,
      lastScanDate: latest.scannedAt,
      note: latest.recommendations.isNotEmpty ? latest.recommendations.first : '',
      scanId: latest.id,
    );
  }

  @override
  Future<SoilScanResult> analyzeImage({
    required Uint8List imageBytes,
    required String filename,
    String? cropType,
  }) {
    return _dataSource.analyzeImage(
      imageBytes: imageBytes,
      filename: filename,
      deviceId: deviceId,
      cropType: cropType,
    );
  }

  @override
  Future<List<SoilScanResult>> getScanHistory() => _dataSource.fetchHistory(deviceId);

  @override
  Future<SoilScanResult> getScanById(String id) async {
    // The backend has no single-scan endpoint (see server/README — only
    // `/v1/analyze` and `/v1/history`), so this looks the id up within the
    // bounded history list. Fine given the "up to 5 scans" cap; revisit if
    // the backend ever grows a GET /v1/scan/{id}.
    final history = await _dataSource.fetchHistory(deviceId);
    return history.firstWhere((scan) => scan.id == id);
  }
}
