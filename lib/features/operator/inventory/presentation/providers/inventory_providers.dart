import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/database_provider.dart';
import '../../data/datasources/inventory_local_data_source.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return InventoryRepositoryImpl(InventoryLocalDataSource(db));
});

final inventoryItemsProvider = FutureProvider.autoDispose<List<InventoryItem>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getItems();
});

final restockRequestsProvider = FutureProvider.autoDispose<List<RestockRequest>>((ref) {
  return ref.watch(inventoryRepositoryProvider).getRestockRequests();
});
