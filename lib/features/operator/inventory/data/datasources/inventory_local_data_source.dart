import '../../../../../core/database/app_database.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';

/// The item catalog is static seed data — nothing in the app mutates stock
/// levels yet, so it stays an in-memory list rather than a table. Restock
/// requests are the real, user-driven operation, backed by the shared
/// [AppDatabase] so they survive a restart. Replaces the earlier in-memory
/// `InventoryFakeDataSource` behind the same method signatures.
class InventoryLocalDataSource {
  InventoryLocalDataSource(this._db);

  final AppDatabase _db;

  static const List<InventoryItem> _items = [
    InventoryItem(
      id: 'inv-urea',
      name: 'Urea Prill 46%',
      unit: 'bag',
      unitPrice: 350,
      currentStock: 8,
      lowStockThreshold: 10,
    ),
    InventoryItem(
      id: 'inv-dap',
      name: 'DAP 18-46-0',
      unit: 'bag',
      unitPrice: 1450,
      currentStock: 25,
      lowStockThreshold: 10,
    ),
    InventoryItem(
      id: 'inv-npk',
      name: 'NPK 10-26-26 Complex',
      unit: 'bag',
      unitPrice: 1325,
      currentStock: 5,
      lowStockThreshold: 8,
    ),
    InventoryItem(
      id: 'inv-vermicompost',
      name: 'Vermicompost',
      unit: 'bag',
      unitPrice: 450,
      currentStock: 40,
      lowStockThreshold: 15,
    ),
    InventoryItem(
      id: 'inv-biopesticide',
      name: 'Bio-Pesticide Spray',
      unit: 'bottle',
      unitPrice: 320,
      currentStock: 12,
      lowStockThreshold: 5,
    ),
  ];

  bool _seeded = false;

  Future<void> _ensureSeeded() async {
    if (_seeded) return;
    final hasRows = await _db
        .select(_db.restockRequestsTable)
        .get()
        .then((rows) => rows.isNotEmpty);
    if (!hasRows) {
      await _insert(RestockRequest(
        id: 'restock-1',
        itemId: 'inv-urea',
        itemName: 'Urea Prill 46%',
        requestedQuantity: 30,
        status: RestockRequestStatus.approved,
        requestedDate: DateTime.now().subtract(const Duration(days: 2)),
      ));
    }
    _seeded = true;
  }

  Future<List<InventoryItem>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _items;
  }

  Future<List<RestockRequest>> fetchRestockRequests() async {
    await _ensureSeeded();
    final rows = await _db.select(_db.restockRequestsTable).get();
    final requests = rows.map(_toRequest).toList();
    requests.sort((a, b) => b.requestedDate.compareTo(a.requestedDate));
    return requests;
  }

  Future<RestockRequest> requestRestock({
    required String itemId,
    required int quantity,
  }) async {
    await _ensureSeeded();
    final item = _items.firstWhere((i) => i.id == itemId);
    final request = RestockRequest(
      id: 'restock-${DateTime.now().microsecondsSinceEpoch}',
      itemId: itemId,
      itemName: item.name,
      requestedQuantity: quantity,
      status: RestockRequestStatus.pending,
      requestedDate: DateTime.now(),
    );
    await _insert(request);
    return request;
  }

  Future<void> _insert(RestockRequest request) {
    return _db.into(_db.restockRequestsTable).insertOnConflictUpdate(
          RestockRequestsTableCompanion.insert(
            id: request.id,
            itemId: request.itemId,
            itemName: request.itemName,
            requestedQuantity: request.requestedQuantity,
            status: request.status.name,
            requestedDate: request.requestedDate,
          ),
        );
  }

  RestockRequest _toRequest(RestockRequestRow row) {
    return RestockRequest(
      id: row.id,
      itemId: row.itemId,
      itemName: row.itemName,
      requestedQuantity: row.requestedQuantity,
      status: RestockRequestStatus.values.byName(row.status),
      requestedDate: row.requestedDate,
    );
  }
}
