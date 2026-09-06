import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_fake_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._dataSource);

  final InventoryFakeDataSource _dataSource;

  @override
  Future<List<InventoryItem>> getItems() => _dataSource.fetchItems();

  @override
  Future<List<RestockRequest>> getRestockRequests() =>
      _dataSource.fetchRestockRequests();

  @override
  Future<RestockRequest> requestRestock({
    required String itemId,
    required int quantity,
  }) =>
      _dataSource.requestRestock(itemId: itemId, quantity: quantity);
}
