import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../../core/database/app_database.dart';
import '../../domain/entities/order.dart';

/// Local (on-device) persistence for orders, via the shared [AppDatabase].
///
/// This replaces the earlier in-memory `OrdersFakeDataSource` behind the
/// exact same method signatures — `OrdersRepositoryImpl` didn't need to
/// change at all. To swap this for a hosted backend later (e.g. AWS),
/// write a new class implementing these same methods against your REST
/// API instead of the database, then change the one line in
/// `orders_providers.dart` that constructs it.
class OrdersLocalDataSource {
  OrdersLocalDataSource(this._db);

  final AppDatabase _db;

  /// Guards [_ensureSeeded] so the empty-check only runs once per app
  /// session rather than before every single call.
  bool _seeded = false;

  /// Populates the table with starter data the first time it's ever
  /// queried — real usage (walk-in sales, OTP handovers) then persists for
  /// good across restarts. Called at the top of every public read/write
  /// below, so it's safe no matter which method is hit first (e.g. a deep
  /// link straight to an order's detail page).
  Future<void> _ensureSeeded() async {
    if (_seeded) return;
    final hasRows = await _db.select(_db.ordersTable).get().then((rows) => rows.isNotEmpty);
    if (!hasRows) {
      for (final order in _seedData()) {
        await _insert(order);
      }
    }
    _seeded = true;
  }

  Future<List<Order>> fetchOrders() async {
    await _ensureSeeded();
    final rows = await _db.select(_db.ordersTable).get();
    final orders = rows.map(_toOrder).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<Order> fetchOrderById(String id) async {
    await _ensureSeeded();
    final row = await (_db.select(_db.ordersTable)..where((t) => t.id.equals(id))).getSingle();
    return _toOrder(row);
  }

  Future<Order> markReadyForPickup(String orderId) async {
    await _ensureSeeded();
    await (_db.update(_db.ordersTable)..where((t) => t.id.equals(orderId))).write(
      OrdersTableCompanion(status: Value(OrderStatus.readyForPickup.name)),
    );
    return fetchOrderById(orderId);
  }

  Future<Order> verifyOtpAndComplete(String orderId, String enteredOtp) async {
    await _ensureSeeded();
    final order = await fetchOrderById(orderId);
    if (order.pickupOtp != enteredOtp) {
      throw Exception('Incorrect OTP — please check with the farmer and try again.');
    }
    await (_db.update(_db.ordersTable)..where((t) => t.id.equals(orderId))).write(
      OrdersTableCompanion(
        status: Value(OrderStatus.completed.name),
        pickupOtp: const Value(null),
      ),
    );
    return fetchOrderById(orderId);
  }

  Future<Order> createWalkInOrder({
    required String customerName,
    required List<OrderLineItem> items,
  }) async {
    await _ensureSeeded();
    final order = Order(
      id: 'order-${DateTime.now().microsecondsSinceEpoch}',
      customerName: customerName,
      type: OrderType.walkIn,
      status: OrderStatus.completed,
      items: items,
      createdAt: DateTime.now(),
      pickupOtp: null,
    );
    await _insert(order);
    return order;
  }

  Future<void> _insert(Order order) {
    return _db.into(_db.ordersTable).insertOnConflictUpdate(
          OrdersTableCompanion.insert(
            id: order.id,
            customerName: order.customerName,
            type: order.type.name,
            status: order.status.name,
            itemsJson: _encodeItems(order.items),
            createdAt: order.createdAt,
            pickupOtp: Value(order.pickupOtp),
          ),
        );
  }

  Order _toOrder(OrderRow row) {
    return Order(
      id: row.id,
      customerName: row.customerName,
      type: OrderType.values.byName(row.type),
      status: OrderStatus.values.byName(row.status),
      items: _decodeItems(row.itemsJson),
      createdAt: row.createdAt,
      pickupOtp: row.pickupOtp,
    );
  }

  String _encodeItems(List<OrderLineItem> items) {
    return jsonEncode(items
        .map((i) => {
              'productName': i.productName,
              'quantity': i.quantity,
              'unitPrice': i.unitPrice,
            })
        .toList());
  }

  List<OrderLineItem> _decodeItems(String json) {
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    return list
        .map((m) => OrderLineItem(
              productName: m['productName'] as String,
              quantity: m['quantity'] as int,
              unitPrice: (m['unitPrice'] as num).toDouble(),
            ))
        .toList();
  }

  List<Order> _seedData() => [
        Order(
          id: 'order-1',
          customerName: 'Ramesh Patil',
          type: OrderType.appOrder,
          status: OrderStatus.pending,
          items: const [
            OrderLineItem(productName: 'Urea Prill 46%', quantity: 2, unitPrice: 350),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          pickupOtp: '4821',
        ),
        Order(
          id: 'order-2',
          customerName: 'Suresh Jadhav',
          type: OrderType.appOrder,
          status: OrderStatus.pending,
          items: const [
            OrderLineItem(productName: 'DAP 18-46-0', quantity: 1, unitPrice: 1450),
            OrderLineItem(productName: 'Bio-Pesticide Spray', quantity: 1, unitPrice: 320),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          pickupOtp: '7093',
        ),
        Order(
          id: 'order-3',
          customerName: 'Anita Kale',
          type: OrderType.appOrder,
          status: OrderStatus.readyForPickup,
          items: const [
            OrderLineItem(productName: 'NPK 10-26-26 Complex', quantity: 1, unitPrice: 1325),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          pickupOtp: '2246',
        ),
        Order(
          id: 'order-4',
          customerName: 'Vikram Deshmukh',
          type: OrderType.appOrder,
          status: OrderStatus.completed,
          items: const [
            OrderLineItem(productName: 'Vermicompost', quantity: 3, unitPrice: 450),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          pickupOtp: null,
        ),
        Order(
          id: 'order-5',
          customerName: 'Walk-in customer',
          type: OrderType.walkIn,
          status: OrderStatus.completed,
          items: const [
            OrderLineItem(productName: 'Urea Prill 46%', quantity: 1, unitPrice: 350),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          pickupOtp: null,
        ),
        Order(
          id: 'order-6',
          customerName: 'Meera Shinde',
          type: OrderType.walkIn,
          status: OrderStatus.completed,
          items: const [
            OrderLineItem(productName: 'Bio-Pesticide Spray', quantity: 2, unitPrice: 320),
          ],
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
          pickupOtp: null,
        ),
      ];
}
