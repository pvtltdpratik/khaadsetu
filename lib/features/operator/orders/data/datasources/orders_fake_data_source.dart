import '../../domain/entities/order.dart';

/// Stands in for a remote orders API. Holds orders in memory so marking an
/// order ready, verifying OTP, or ringing up a walk-in sale all actually
/// change what a later read sees.
class OrdersFakeDataSource {
  final List<Order> _orders = [
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

  int _walkInCounter = 0;

  Future<List<Order>> fetchOrders() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return List.unmodifiable(_orders.reversed);
  }

  Future<Order> fetchOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _orders.firstWhere((o) => o.id == id);
  }

  Future<Order> markReadyForPickup(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _orders.indexWhere((o) => o.id == orderId);
    final updated = _orders[index].copyWith(status: OrderStatus.readyForPickup);
    _orders[index] = updated;
    return updated;
  }

  Future<Order> verifyOtpAndComplete(String orderId, String enteredOtp) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _orders.indexWhere((o) => o.id == orderId);
    final order = _orders[index];
    if (order.pickupOtp != enteredOtp) {
      throw Exception('Incorrect OTP — please check with the farmer and try again.');
    }
    final updated = order.copyWith(status: OrderStatus.completed, pickupOtp: null);
    _orders[index] = updated;
    return updated;
  }

  Future<Order> createWalkInOrder({
    required String customerName,
    required List<OrderLineItem> items,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _walkInCounter++;
    final order = Order(
      id: 'order-walkin-$_walkInCounter',
      customerName: customerName,
      type: OrderType.walkIn,
      status: OrderStatus.completed,
      items: items,
      createdAt: DateTime.now(),
      pickupOtp: null,
    );
    _orders.add(order);
    return order;
  }
}
