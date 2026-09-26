import 'payment_models.dart';

abstract class PaymentsRepository {
  Future<PaymentConfig> config();

  /// Asks the server to prepare a payment for [orderId]. The amount is decided there.
  Future<PaymentSession> start(String orderId);

  /// Pays the order's goods from the platform wallet. The server refuses if the balance is short.
  Future<void> payFromWallet(String orderId);

  /// Asks the server whether the order was paid after all (Razorpay can take the money and still show the app an
  /// error). True when the order is now paid.
  Future<bool> sync(String orderId);

  /// Hands the checkout's answer to the server, which checks its signature with the secret.
  Future<void> verify({required String razorpayOrderId, required String razorpayPaymentId, required String signature});
}

/// The checkout screen itself (Razorpay's). Swappable so tests need no plugin.
abstract class PaymentCheckout {
  Future<CheckoutOutcome> open(PaymentSession session);
}
