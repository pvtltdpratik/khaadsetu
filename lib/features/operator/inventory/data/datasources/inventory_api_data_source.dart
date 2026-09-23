import '../../../../../core/network/api_client.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';

class InventoryApiDataSource {
  const InventoryApiDataSource(this._api);

  final ApiClient _api;

  Future<List<InventoryItem>> fetchItems() async {
    final list = await _api.get('/v1/operator/inventory/items', query: {'limit': '200'}) as List;
    return list.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList();
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

  Future<ReceiveResult> receiveStock({
    required String productId,
    required int quantity,
    int? expectedQuantity,
    String? note,
  }) async {
    final json = await _api.post('/v1/operator/inventory/receive', body: {
      'productId': productId,
      'quantity': quantity,
      'expectedQuantity': ?expectedQuantity,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    }) as Map<String, dynamic>;
    final d = json['discrepancy'] as Map<String, dynamic>?;
    return ReceiveResult(
      item: InventoryItem.fromJson(json),
      discrepancy: d == null ? null : DiscrepancyReport(expected: (d['expected'] as num).toInt(), received: (d['received'] as num).toInt()),
    );
  }

  Future<InventoryItem> updateSettings({
    required String productId,
    int? reorderLevel,
    int? maxCapacity,
    bool clearCapacity = false,
  }) async {
    final json = await _api.patch('/v1/operator/inventory/items/${Uri.encodeComponent(productId)}', body: {
      'reorderLevel': ?reorderLevel,
      if (clearCapacity) 'maxCapacity': null else 'maxCapacity': ?maxCapacity,
    }) as Map<String, dynamic>;
    return InventoryItem.fromJson(json);
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
