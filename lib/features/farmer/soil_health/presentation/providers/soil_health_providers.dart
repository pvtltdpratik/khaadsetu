import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/soil_health_fake_data_source.dart';
import '../../data/repositories/soil_health_repository_impl.dart';
import '../../domain/entities/soil_health_summary.dart';
import '../../domain/entities/soil_scan_result.dart';
import '../../domain/repositories/soil_health_repository.dart';

/// Plain (non-`autoDispose`) `Provider`, so this stays a single instance for
/// the app's lifetime — the fake data source's in-memory scan history
/// persists across navigation instead of resetting on every read.
final soilHealthRepositoryProvider = Provider<SoilHealthRepository>((ref) {
  return SoilHealthRepositoryImpl(SoilHealthFakeDataSource());
});

/// Latest soil health summary for the home screen. `autoDispose` so
/// invalidating it (e.g. after a new scan) refetches instead of serving a
/// stale cached value.
final soilHealthSummaryProvider =
    FutureProvider.autoDispose<SoilHealthSummary>((ref) {
  return ref.watch(soilHealthRepositoryProvider).getLatestSummary();
});

final soilScanHistoryProvider =
    FutureProvider.autoDispose<List<SoilScanResult>>((ref) {
  return ref.watch(soilHealthRepositoryProvider).getScanHistory();
});

final soilScanResultProvider =
    FutureProvider.autoDispose.family<SoilScanResult, String>((ref, scanId) {
  return ref.watch(soilHealthRepositoryProvider).getScanById(scanId);
});
