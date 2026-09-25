import 'package:equatable/equatable.dart';

/// Whether the server can take online payments, and the PUBLIC Razorpay key id.
/// (The secret stays on the server and is never sent to the app.)
class PaymentConfig extends Equatable {
  const PaymentConfig({required this.enabled, this.keyId = ''});

  factory PaymentConfig.fromJson(Map<String, dynamic> json) => PaymentConfig(enabled: json['enabled'] as bool? ?? false, keyId: json['keyId'] as String? ?? '');

  final bool enabled;
  final String keyId;

  @override
  List<Object?> get props => [enabled, keyId];
}

/// What Razorpay's checkout needs, produced by the server for one order. The amount is the
/// server's own figure, in paise.
class PaymentSession extends Equatable {
  const PaymentSession({
    required this.paymentId,
    required this.keyId,
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.name,
    required this.description,
    this.prefillName = '',
    this.prefillEmail = '',
    this.prefillContact = '',
  });

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    final prefill = (json['prefill'] as Map<String, dynamic>?) ?? const {};
    return PaymentSession(
      paymentId: json['paymentId'] as String,
      keyId: json['keyId'] as String,
      razorpayOrderId: json['razorpayOrderId'] as String,
      amountPaise: (json['amount'] as num).toInt(),
      currency: json['currency'] as String? ?? 'INR',
      name: json['name'] as String? ?? 'ShetSamrudhi',
      description: json['description'] as String? ?? '',
      prefillName: prefill['name'] as String? ?? '',
      prefillEmail: prefill['email'] as String? ?? '',
      prefillContact: prefill['contact'] as String? ?? '',
    );
  }

  final String paymentId;
  final String keyId;
  final String razorpayOrderId;
  final int amountPaise;
  final String currency;
  final String name;
  final String description;
  final String prefillName;
  final String prefillEmail;
  final String prefillContact;

  double get rupees => amountPaise / 100;

  @override
  List<Object?> get props => [paymentId, keyId, razorpayOrderId, amountPaise, currency, name, description, prefillName, prefillEmail, prefillContact];
}

/// How the checkout ended.
sealed class CheckoutOutcome {
  const CheckoutOutcome();
}

/// Razorpay took the payment. The server must still verify [signature] before the order counts as paid.
class CheckoutPaid extends CheckoutOutcome {
  const CheckoutPaid({required this.paymentId, required this.orderId, required this.signature});

  final String paymentId;
  final String orderId;
  final String signature;
}

/// The farmer closed the checkout without paying.
class CheckoutCancelled extends CheckoutOutcome {
  const CheckoutCancelled();
}

class CheckoutFailed extends CheckoutOutcome {
  const CheckoutFailed(this.message);

  final String message;
}
