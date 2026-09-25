import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../domain/payment_models.dart';
import '../domain/payments_repository.dart';

/// Razorpay's own checkout, opened on top of the app. It only ever holds the PUBLIC key id and
/// the order the server made; the secret is not in the app.
class RazorpayCheckout implements PaymentCheckout {
  const RazorpayCheckout();

  @override
  Future<CheckoutOutcome> open(PaymentSession session) {
    final done = Completer<CheckoutOutcome>();
    final razorpay = Razorpay();

    void finish(CheckoutOutcome outcome) {
      if (!done.isCompleted) done.complete(outcome);
      razorpay.clear();
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      finish(CheckoutPaid(paymentId: r.paymentId ?? '', orderId: r.orderId ?? session.razorpayOrderId, signature: r.signature ?? ''));
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      finish(r.code == Razorpay.PAYMENT_CANCELLED ? const CheckoutCancelled() : CheckoutFailed(r.message ?? 'The payment did not go through.'));
    });
    // Paying through another wallet app: Razorpay reports it, then the same success or error follows.
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {});

    try {
      razorpay.open({
        'key': session.keyId,
        'order_id': session.razorpayOrderId,
        'amount': session.amountPaise,
        'currency': session.currency,
        'name': session.name,
        'description': session.description,
        'prefill': {'name': session.prefillName, 'email': session.prefillEmail, 'contact': session.prefillContact},
        'theme': {'color': '#4B7530'},
        'retry': {'enabled': true, 'max_count': 2},
      });
    } catch (_) {
      finish(const CheckoutFailed('Could not open the payment screen.'));
    }
    return done.future;
  }
}
