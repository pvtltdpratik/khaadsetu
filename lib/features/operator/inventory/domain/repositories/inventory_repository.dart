import '../entities/inventory_item.dart';
import '../entities/restock_request.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getItems();
  Future<List<RestockRequest>> getRestockRequests();
  Future<RestockRequest> requestRestock({
    required String itemId,
    required int quantity,
  });
}
