import '../../../../../core/network/api_client.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';

class InventoryApiDataSource {
  const InventoryApiDataSource(this._api);

  final ApiClient _api;

  Future<List<InventoryItem>> fetchItems() async {
    final list = await _api.get('/v1/operator/inventory/items') as List;
    return list.map((e) => _parseItem(e as Map<String, dynamic>)).toList();
  }

  Future<List<RestockRequest>> fetchRestockRequests() async {
    final list = await _api.get('/v1/operator/inventory/restock-requests') as List;
    return list.map((e) => _parseRequest(e as Map<String, dynamic>)).toList();
  }

  Future<RestockRequest> requestRestock({
    required String itemId,
    required int quantity,
  }) async {
    final json = await _api.post(
      '/v1/operator/inventory/restock-requests',
      body: {'itemId': itemId, 'quantity': quantity},
    ) as Map<String, dynamic>;
    return _parseRequest(json);
  }

  InventoryItem _parseItem(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      currentStock: (json['currentStock'] as num).toInt(),
      lowStockThreshold: (json['lowStockThreshold'] as num).toInt(),
    );
  }

  RestockRequest _parseRequest(Map<String, dynamic> json) {
    return RestockRequest(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      requestedQuantity: (json['requestedQuantity'] as num).toInt(),
      status: RestockRequestStatus.values.byName(json['status'] as String),
      requestedDate: DateTime.parse(json['requestedDate'] as String).toLocal(),
    );
  }
}
