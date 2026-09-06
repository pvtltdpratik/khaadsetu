import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/inventory_fake_data_source.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(InventoryFakeDataSource());
});

final inventoryItemsProvider = FutureProvider.autoDispose<List<InventoryItem>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getItems();
});
