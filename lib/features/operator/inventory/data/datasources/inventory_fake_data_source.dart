import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';

class InventoryFakeDataSource {
  static final List<InventoryItem> _items = [
    const InventoryItem(
      id: 'inv-urea',
      name: 'Urea Prill 46%',
      unit: 'bag',
      unitPrice: 350,
      currentStock: 8,
      lowStockThreshold: 10,
    ),
    const InventoryItem(
      id: 'inv-dap',
      name: 'DAP 18-46-0',
      unit: 'bag',
      unitPrice: 1450,
      currentStock: 25,
      lowStockThreshold: 10,
    ),
    const InventoryItem(
      id: 'inv-npk',
      name: 'NPK 10-26-26 Complex',
      unit: 'bag',
      unitPrice: 1325,
      currentStock: 5,
      lowStockThreshold: 8,
    ),
    const InventoryItem(
      id: 'inv-vermicompost',
      name: 'Vermicompost',
      unit: 'bag',
      unitPrice: 450,
      currentStock: 40,
      lowStockThreshold: 15,
    ),
    const InventoryItem(
      id: 'inv-biopesticide',
      name: 'Bio-Pesticide Spray',
      unit: 'bottle',
      unitPrice: 320,
      currentStock: 12,
      lowStockThreshold: 5,
    ),
  ];

  final List<RestockRequest> _restockRequests = [
    RestockRequest(
      id: 'restock-1',
      itemId: 'inv-urea',
      itemName: 'Urea Prill 46%',
      requestedQuantity: 30,
      status: RestockRequestStatus.approved,
      requestedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  int _restockCounter = 0;

  Future<List<InventoryItem>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_items);
  }

  Future<List<RestockRequest>> fetchRestockRequests() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_restockRequests.reversed);
  }

  Future<RestockRequest> requestRestock({
    required String itemId,
    required int quantity,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _restockCounter++;
    final item = _items.firstWhere((i) => i.id == itemId);
    final request = RestockRequest(
      id: 'restock-new-$_restockCounter',
      itemId: itemId,
      itemName: item.name,
      requestedQuantity: quantity,
      status: RestockRequestStatus.pending,
      requestedDate: DateTime.now(),
    );
    _restockRequests.add(request);
    return request;
  }
}
