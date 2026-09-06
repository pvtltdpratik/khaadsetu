import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_fake_data_source.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this._dataSource);

  final OrdersFakeDataSource _dataSource;

  @override
  Future<List<Order>> getOrders() => _dataSource.fetchOrders();

  @override
  Future<Order> getOrderById(String id) => _dataSource.fetchOrderById(id);

  @override
  Future<Order> markReadyForPickup(String orderId) =>
      _dataSource.markReadyForPickup(orderId);

  @override
  Future<Order> verifyOtpAndComplete(String orderId, String enteredOtp) =>
      _dataSource.verifyOtpAndComplete(orderId, enteredOtp);

  @override
  Future<Order> createWalkInOrder({
    required String customerName,
    required List<OrderLineItem> items,
  }) =>
      _dataSource.createWalkInOrder(customerName: customerName, items: items);
}
