import '../entities/inventory_item.dart';
import '../entities/restock_request.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getItems();
  Future<List<RestockRequest>> getRestockRequests();
  Future<RestockRequest> requestRestock({
    required String itemId,
    required int quantity,
  });

  /// Adds stock that has arrived, creating the shelf entry the first time. Pass
  /// [expectedQuantity] when the count does not match what was expected, so the
  /// platform's supply team can review the difference.
  Future<ReceiveResult> receiveStock({
    required String productId,
    required int quantity,
    int? expectedQuantity,
    String? note,
  });

  /// Changes the reorder level and/or capacity. [clearCapacity] removes the
  /// capacity limit (a null [maxCapacity] alone means "leave it as it is").
  Future<InventoryItem> updateSettings({
    required String productId,
    int? reorderLevel,
    int? maxCapacity,
    bool clearCapacity = false,
  });
}
