import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/inventory_fake_data_source.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Plain (non-`autoDispose`) `Provider` so the fake data source's in-memory
/// stock levels and restock requests persist across navigation.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(InventoryFakeDataSource());
});

final inventoryItemsProvider = FutureProvider.autoDispose<List<InventoryItem>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getItems();
});

final restockRequestsProvider = FutureProvider.autoDispose<List<RestockRequest>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getRestockRequests();
});
