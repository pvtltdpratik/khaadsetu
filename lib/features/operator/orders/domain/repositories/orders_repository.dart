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
  ///
  /// [paymentMode] is how the farmer paid at the counter (cash, upi, card or credit); the bill is made from it. An order
  /// already paid on the phone ignores it.
  Future<Order> verifyOtpAndComplete(String orderId, String enteredOtp, {String paymentMode = 'cash'});

  /// [paymentMode] is how the customer paid (cash, upi, card, credit). On credit the sale is written against the
  /// registered farmer [customerId] in the credit book.
  Future<Order> createWalkInOrder({
    required String customerName,
    required List<OrderLineItem> items,
    String paymentMode = 'cash',
    String? customerId,
    String? clientRef,
    DateTime? soldAt,
  });
}
