import 'package:khaadsetu_version1/features/farmer/notifications/domain/entities/app_notification.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/domain/repositories/notifications_repository.dart';
import 'package:khaadsetu_version1/features/operator/center/domain/entities/operator_center.dart';
import 'package:khaadsetu_version1/features/operator/center/domain/repositories/operator_center_repository.dart';
import 'package:khaadsetu_version1/features/operator/inventory/domain/entities/inventory_item.dart';
import 'package:khaadsetu_version1/features/operator/inventory/domain/entities/restock_request.dart';
import 'package:khaadsetu_version1/features/operator/inventory/domain/repositories/inventory_repository.dart';
import 'package:khaadsetu_version1/features/operator/orders/domain/entities/order.dart';
import 'package:khaadsetu_version1/features/operator/orders/domain/repositories/orders_repository.dart' as op;

InventoryItem shelfItem(
  String id, {
  String name = 'Neem Cake',
  int onHand = 20,
  int reserved = 0,
  int reorder = 5,
  int incoming = 0,
  int? capacity,
  String unit = 'bag',
  double price = 600,
}) =>
    InventoryItem(
      id: id,
      name: name,
      unit: unit,
      unitPrice: price,
      currentStock: onHand,
      lowStockThreshold: reorder,
      reserved: reserved,
      incoming: incoming,
      maxCapacity: capacity,
    );

class FakeInventoryRepository implements InventoryRepository {
  FakeInventoryRepository({List<InventoryItem>? items, List<RestockRequest>? requests})
      : items = items ?? [],
        requests = requests ?? [];

  List<InventoryItem> items;
  List<RestockRequest> requests;
  final receiveCalls = <({String productId, int quantity, int? expected, String? note})>[];
  final settingsCalls = <({String productId, int? reorderLevel, int? maxCapacity, bool clearCapacity})>[];
  Object? receiveError;

  @override
  Future<List<InventoryItem>> getItems() async => items;

  @override
  Future<List<RestockRequest>> getRestockRequests() async => requests;

  @override
  Future<RestockRequest> requestRestock({required String itemId, required int quantity}) async => throw UnimplementedError();

  @override
  Future<ReceiveResult> receiveStock({required String productId, required int quantity, int? expectedQuantity, String? note}) async {
    receiveCalls.add((productId: productId, quantity: quantity, expected: expectedQuantity, note: note));
    if (receiveError != null) throw receiveError!;
    final existing = items.where((i) => i.id == productId).firstOrNull;
    final updated = shelfItem(productId, name: existing?.name ?? 'Neem Cake', onHand: (existing?.currentStock ?? 0) + quantity);
    items = [updated, ...items.where((i) => i.id != productId)];
    return ReceiveResult(
      item: updated,
      discrepancy: expectedQuantity != null && expectedQuantity != quantity ? DiscrepancyReport(expected: expectedQuantity, received: quantity) : null,
    );
  }

  @override
  Future<InventoryItem> updateSettings({required String productId, int? reorderLevel, int? maxCapacity, bool clearCapacity = false}) async {
    settingsCalls.add((productId: productId, reorderLevel: reorderLevel, maxCapacity: maxCapacity, clearCapacity: clearCapacity));
    return items.firstWhere((i) => i.id == productId);
  }
}

OperatorCenter operatorCenter({bool open = true, String phone = '98220 11111', String opens = '09:00', String closes = '18:00'}) => OperatorCenter(
      centerId: 'c1',
      name: 'Shirur Kendra',
      village: 'Shirur',
      district: 'Pune',
      operatorName: 'Olga',
      phone: phone,
      isOpen: open,
      opensAt: opens,
      closesAt: closes,
      status: 'active',
    );

class FakeOperatorCenterRepository implements OperatorCenterRepository {
  FakeOperatorCenterRepository([OperatorCenter? center]) : current = center ?? operatorCenter();

  OperatorCenter current;
  final updates = <Map<String, Object?>>[];

  @override
  Future<OperatorCenter> center() async => current;

  @override
  Future<OperatorCenter> update({bool? isOpen, String? opensAt, String? closesAt, String? phone, String? operatorName}) async {
    updates.add({'isOpen': isOpen, 'opensAt': opensAt, 'closesAt': closesAt, 'phone': phone, 'operatorName': operatorName});
    current = OperatorCenter(
      centerId: current.centerId,
      name: current.name,
      village: current.village,
      district: current.district,
      operatorName: operatorName ?? current.operatorName,
      phone: phone ?? current.phone,
      isOpen: isOpen ?? current.isOpen,
      opensAt: opensAt ?? current.opensAt,
      closesAt: closesAt ?? current.closesAt,
      status: current.status,
    );
    return current;
  }
}

class FakeOperatorOrdersRepository implements op.OrdersRepository {
  final walkIns = <List<OrderLineItem>>[];
  Object? walkInError;

  @override
  Future<List<Order>> getOrders() async => [];

  @override
  Future<Order> getOrderById(String id) async => Order(
        id: id,
        customerName: 'Walk-in customer',
        type: OrderType.walkIn,
        status: OrderStatus.completed,
        items: const [],
        createdAt: DateTime(2026, 9, 24),
        pickupOtp: null,
      );

  @override
  Future<Order> markReadyForPickup(String orderId) async => throw UnimplementedError();

  @override
  Future<Order> verifyOtpAndComplete(String orderId, String enteredOtp) async => throw UnimplementedError();

  @override
  Future<Order> createWalkInOrder({required String customerName, required List<OrderLineItem> items}) async {
    walkIns.add(items);
    if (walkInError != null) throw walkInError!;
    return getOrderById('walk-1');
  }
}

AppNotification note(String id, NotificationType type, {String title = 'Something', bool read = false, String? refId}) => AppNotification(
      id: id,
      type: type,
      title: title,
      body: 'Body of $title',
      createdAt: DateTime(2026, 9, 24),
      isRead: read,
      refId: refId,
    );

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository(this.items);

  List<AppNotification> items;
  final read = <String>[];

  @override
  Future<List<AppNotification>> getNotifications() async => items;

  @override
  Future<void> markRead(String id) async {
    read.add(id);
    items = [for (final n in items) n.id == id ? AppNotification(id: n.id, type: n.type, title: n.title, body: n.body, createdAt: n.createdAt, isRead: true, refId: n.refId) : n];
  }

  @override
  Future<void> markAllRead() async {}
}
