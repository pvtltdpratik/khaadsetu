import '../../domain/entities/soil_health_summary.dart';
import '../../domain/entities/soil_scan_result.dart';
import '../../domain/repositories/soil_health_repository.dart';
import '../datasources/soil_health_fake_data_source.dart';

class SoilHealthRepositoryImpl implements SoilHealthRepository {
  const SoilHealthRepositoryImpl(this._dataSource);

  final SoilHealthFakeDataSource _dataSource;

  @override
  Future<SoilHealthSummary> getLatestSummary() {
    return _dataSource.fetchLatestSummary();
  }

  @override
  Future<SoilScanResult> captureScan() {
    return _dataSource.captureScan();
  }

  @override
  Future<List<SoilScanResult>> getScanHistory() {
    return _dataSource.fetchScanHistory();
  }

  @override
  Future<SoilScanResult> getScanById(String id) {
    return _dataSource.fetchScanById(id);
  }
}
