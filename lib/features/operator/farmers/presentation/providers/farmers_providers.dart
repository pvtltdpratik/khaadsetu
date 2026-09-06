import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/farmers_fake_data_source.dart';
import '../../data/repositories/farmers_repository_impl.dart';
import '../../domain/entities/farmer.dart';
import '../../domain/repositories/farmers_repository.dart';

final farmersRepositoryProvider = Provider<FarmersRepository>((ref) {
  return FarmersRepositoryImpl(FarmersFakeDataSource());
});

final farmersProvider = FutureProvider.autoDispose<List<Farmer>>((ref) {
  return ref.watch(farmersRepositoryProvider).getFarmers();
});

final farmerProvider =
    FutureProvider.autoDispose.family<Farmer, String>((ref, id) {
  return ref.watch(farmersRepositoryProvider).getFarmerById(id);
});
