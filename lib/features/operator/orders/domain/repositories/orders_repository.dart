import '../entities/order.dart';

abstract class OrdersRepository {
  Future<List<Order>> getOrders();
  Future<Order> getOrderById(String id);

  /// Moves a pending app order to [OrderStatus.readyForPickup].
  Future<Order> markReadyForPickup(String orderId);

  /// Completes an app order at handover. Throws if [enteredOtp] doesn't
  /// match — an expected user-input mistake, not a data-loading failure, so
  /// callers should catch this locally rather than treating it like a
  /// repository error.
  Future<Order> verifyOtpAndComplete(String orderId, String enteredOtp);

  Future<Order> createWalkInOrder({
    required String customerName,
    required List<OrderLineItem> items,
  });
}
