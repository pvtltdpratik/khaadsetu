import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../../data/datasources/farmers_api_data_source.dart';
import '../../data/repositories/farmers_repository_impl.dart';
import '../../domain/entities/farmer.dart';
import '../../domain/repositories/farmers_repository.dart';

final farmersRepositoryProvider = Provider<FarmersRepository>((ref) {
  return FarmersRepositoryImpl(FarmersApiDataSource(ref.watch(apiClientProvider)));
});

final farmersProvider = FutureProvider.autoDispose<List<Farmer>>((ref) {
  return ref.watch(farmersRepositoryProvider).getFarmers();
});

final farmerProvider =
    FutureProvider.autoDispose.family<Farmer, String>((ref, id) {
  return ref.watch(farmersRepositoryProvider).getFarmerById(id);
});
