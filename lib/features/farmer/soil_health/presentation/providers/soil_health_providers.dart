import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/device/device_id_provider.dart';
import '../../data/datasources/soil_health_api_data_source.dart';
import '../../data/repositories/soil_health_repository_impl.dart';
import '../../domain/entities/soil_health_summary.dart';
import '../../domain/entities/soil_scan_result.dart';
import '../../domain/repositories/soil_health_repository.dart';

/// Async because building the repository needs the device id first (itself
/// async — see `deviceIdProvider`). Everything downstream just awaits
/// `.future` once, same as any other dependency.
final soilHealthRepositoryProvider = FutureProvider<SoilHealthRepository>((ref) async {
  final deviceId = await ref.watch(deviceIdProvider.future);
  return SoilHealthRepositoryImpl(SoilHealthApiDataSource(), deviceId: deviceId);
});

final soilHealthSummaryProvider = FutureProvider.autoDispose<SoilHealthSummary>((ref) async {
  final repository = await ref.watch(soilHealthRepositoryProvider.future);
  return repository.getLatestSummary();
});

final soilScanHistoryProvider = FutureProvider.autoDispose<List<SoilScanResult>>((ref) async {
  final repository = await ref.watch(soilHealthRepositoryProvider.future);
  return repository.getScanHistory();
});

final soilScanResultProvider =
    FutureProvider.autoDispose.family<SoilScanResult, String>((ref, scanId) async {
  final repository = await ref.watch(soilHealthRepositoryProvider.future);
  return repository.getScanById(scanId);
});
