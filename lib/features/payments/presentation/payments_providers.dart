import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import '../../farmer/orders/presentation/providers/orders_providers.dart';
import '../data/payments_api_repository.dart';
import '../data/razorpay_checkout.dart';
import '../domain/payment_models.dart';
import '../domain/payments_repository.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) => PaymentsApiRepository(ref.watch(apiClientProvider)));

final paymentCheckoutProvider = Provider<PaymentCheckout>((ref) => const RazorpayCheckout());

/// Whether the "Pay online" button is offered at all. If the server cannot be asked, it is not.
final paymentConfigProvider = FutureProvider.autoDispose<PaymentConfig>((ref) async {
  try {
    return await ref.watch(paymentsRepositoryProvider).config();
  } catch (_) {
    return const PaymentConfig(enabled: false);
  }
});

/// Takes the farmer through paying for the order [farmerOrderId] online: the server prepares the
/// payment, Razorpay's checkout collects it, and the server verifies what came back. Shows the
/// result as a message. Returns true when the order is now paid.
Future<bool> payForOrder(BuildContext context, WidgetRef ref, String farmerOrderId) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger.showSnackBar(SnackBar(content: Text(text)));
  void refresh() => ref
    ..invalidate(myOrdersProvider)
    ..invalidate(orderProvider(farmerOrderId));

  final payments = ref.read(paymentsRepositoryProvider);
  try {
    final session = await payments.start(farmerOrderId);
    final outcome = await ref.read(paymentCheckoutProvider).open(session);
    switch (outcome) {
      case CheckoutCancelled():
        say('Payment cancelled. You can pay now or when you collect.');
        return false;
      case CheckoutFailed(:final message):
        say(message);
        return false;
      case CheckoutPaid(:final paymentId, :final orderId, :final signature):
        try {
          await payments.verify(razorpayOrderId: orderId, razorpayPaymentId: paymentId, signature: signature);
        } catch (err) {
          // Money may have moved. The server also hears from Razorpay, so say so rather than hide it.
          refresh();
          say('We are confirming your payment: $err');
          return false;
        }
        refresh();
        say('Payment received. Thank you!');
        return true;
    }
  } catch (err) {
    say('$err');
    return false;
  }
}
