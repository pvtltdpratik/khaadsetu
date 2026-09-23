import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_api_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._dataSource);

  final InventoryApiDataSource _dataSource;

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

  @override
  Future<ReceiveResult> receiveStock({
    required String productId,
    required int quantity,
    int? expectedQuantity,
    String? note,
  }) =>
      _dataSource.receiveStock(productId: productId, quantity: quantity, expectedQuantity: expectedQuantity, note: note);

  @override
  Future<InventoryItem> updateSettings({
    required String productId,
    int? reorderLevel,
    int? maxCapacity,
    bool clearCapacity = false,
  }) =>
      _dataSource.updateSettings(productId: productId, reorderLevel: reorderLevel, maxCapacity: maxCapacity, clearCapacity: clearCapacity);
}
