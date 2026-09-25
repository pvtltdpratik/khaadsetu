import 'payment_models.dart';

abstract class PaymentsRepository {
  Future<PaymentConfig> config();

  /// Asks the server to prepare a payment for [orderId]. The amount is decided there.
  Future<PaymentSession> start(String orderId);

  /// Hands the checkout's answer to the server, which checks its signature with the secret.
  Future<void> verify({required String razorpayOrderId, required String razorpayPaymentId, required String signature});
}

/// The checkout screen itself (Razorpay's). Swappable so tests need no plugin.
abstract class PaymentCheckout {
  Future<CheckoutOutcome> open(PaymentSession session);
}
