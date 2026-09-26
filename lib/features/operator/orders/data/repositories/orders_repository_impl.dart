import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_api_data_source.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._dataSource);

  final OrdersApiDataSource _dataSource;

  @override
  Future<List<Order>> getOrders() => _dataSource.fetchOrders();

  @override
  Future<Order> getOrderById(String id) => _dataSource.fetchOrderById(id);

  @override
  Future<Order> markReadyForPickup(String orderId) =>
      _dataSource.markReadyForPickup(orderId);

  @override
  Future<Order> verifyOtpAndComplete(String orderId, String enteredOtp, {String paymentMode = 'cash'}) =>
      _dataSource.verifyOtpAndComplete(orderId, enteredOtp, paymentMode: paymentMode);

  @override
  Future<Order> createWalkInOrder({
    required String customerName,
    required List<OrderLineItem> items,
    String paymentMode = 'cash',
    String? customerId,
    String? clientRef,
    DateTime? soldAt,
  }) =>
      _dataSource.createWalkInOrder(customerName: customerName, items: items, paymentMode: paymentMode, customerId: customerId, clientRef: clientRef, soldAt: soldAt);
}
