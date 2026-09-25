import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/delivery/domain/entities/delivery_models.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/entities/farmer_order.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/providers/orders_providers.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/screens/my_orders_screen.dart';
import 'package:khaadsetu_version1/features/payments/domain/payment_models.dart';
import 'package:khaadsetu_version1/features/payments/domain/payments_repository.dart';
import 'package:khaadsetu_version1/features/payments/presentation/payments_providers.dart';

import 'support/delivery_fakes.dart';
import 'support/farmer_fakes.dart';

class FakePaymentsRepository implements PaymentsRepository {
  FakePaymentsRepository({this.enabled = true});

  final bool enabled;
  final started = <String>[];
  final verified = <({String order, String payment, String signature})>[];
  Object? verifyError;
  Object? startError;

  @override
  Future<PaymentConfig> config() async => PaymentConfig(enabled: enabled, keyId: enabled ? 'rzp_test_public' : '');

  @override
  Future<PaymentSession> start(String orderId) async {
    if (startError != null) throw startError!;
    started.add(orderId);
    return PaymentSession(
      paymentId: 'pay-1',
      keyId: 'rzp_test_public',
      razorpayOrderId: 'order_RZP1',
      amountPaise: 120000,
      currency: 'INR',
      name: 'ShetSamrudhi',
      description: 'Order $orderId',
    );
  }

  @override
  Future<void> verify({required String razorpayOrderId, required String razorpayPaymentId, required String signature}) async {
    if (verifyError != null) throw verifyError!;
    verified.add((order: razorpayOrderId, payment: razorpayPaymentId, signature: signature));
  }
}

class FakeCheckout implements PaymentCheckout {
  FakeCheckout(this.outcome);

  CheckoutOutcome outcome;
  final opened = <PaymentSession>[];

  @override
  Future<CheckoutOutcome> open(PaymentSession session) async {
    opened.add(session);
    return outcome;
  }
}

Future<({FakePaymentsRepository payments, FakeCheckout checkout, FakeOrdersRepository orders})> pump(
  WidgetTester tester,
  FarmerOrder order, {
  FakePaymentsRepository? payments,
  CheckoutOutcome outcome = const CheckoutPaid(paymentId: 'pay_RZP', orderId: 'order_RZP1', signature: 'sig'),
}) async {
  tester.view.physicalSize = const Size(430, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final pay = payments ?? FakePaymentsRepository();
  final checkout = FakeCheckout(outcome);
  final orders = FakeOrdersRepository()..orders = [order];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ordersRepositoryProvider.overrideWithValue(orders),
      paymentsRepositoryProvider.overrideWithValue(pay),
      paymentCheckoutProvider.overrideWithValue(checkout),
    ],
    child: MaterialApp(theme: AppTheme.light, home: FarmerOrderDetailScreen(orderId: order.id)),
  ));
  await tester.pumpAndSettle();
  return (payments: pay, checkout: checkout, orders: orders);
}

void main() {
  group('paying for an order online', () {
    testWidgets('an open unpaid order offers "Pay online" for the goods', (tester) async {
      await pump(tester, farmerOrder('o1'));
      expect(find.byKey(const Key('pay-online')), findsOneWidget);
      expect(find.text('Pay ₹1,200 online'), findsOneWidget);
    });

    testWidgets('the checkout is opened with the server\'s session, then the answer is verified by the server', (tester) async {
      final h = await pump(tester, farmerOrder('o1'));
      await tester.tap(find.byKey(const Key('pay-online')));
      await tester.pumpAndSettle();
      expect(h.payments.started, ['o1']);
      expect(h.checkout.opened.single.keyId, 'rzp_test_public');
      expect(h.checkout.opened.single.amountPaise, 120000);
      expect(h.payments.verified.single.order, 'order_RZP1');
      expect(h.payments.verified.single.payment, 'pay_RZP');
      expect(h.payments.verified.single.signature, 'sig');
      expect(find.text('Payment received. Thank you!'), findsOneWidget);
    });

    testWidgets('closing the checkout pays nothing and verifies nothing', (tester) async {
      final h = await pump(tester, farmerOrder('o1'), outcome: const CheckoutCancelled());
      await tester.tap(find.byKey(const Key('pay-online')));
      await tester.pumpAndSettle();
      expect(h.payments.verified, isEmpty);
      expect(find.textContaining('Payment cancelled'), findsOneWidget);
      expect(find.byKey(const Key('pay-online')), findsOneWidget, reason: 'they can try again');
    });

    testWidgets('a failed payment shows Razorpay\'s reason', (tester) async {
      final h = await pump(tester, farmerOrder('o1'), outcome: const CheckoutFailed('Your bank declined the payment.'));
      await tester.tap(find.byKey(const Key('pay-online')));
      await tester.pumpAndSettle();
      expect(h.payments.verified, isEmpty);
      expect(find.text('Your bank declined the payment.'), findsOneWidget);
    });

    testWidgets('if the server cannot verify, the farmer is told it is being confirmed, not that it failed', (tester) async {
      final payments = FakePaymentsRepository()..verifyError = 'The payment could not be verified.';
      await pump(tester, farmerOrder('o1'), payments: payments);
      await tester.tap(find.byKey(const Key('pay-online')));
      await tester.pumpAndSettle();
      expect(find.textContaining('We are confirming your payment'), findsOneWidget);
    });

    testWidgets('a server that refuses to start the payment shows why, and no checkout opens', (tester) async {
      final payments = FakePaymentsRepository()..startError = 'This order is already paid';
      final h = await pump(tester, farmerOrder('o1'), payments: payments);
      await tester.tap(find.byKey(const Key('pay-online')));
      await tester.pumpAndSettle();
      expect(h.checkout.opened, isEmpty);
      expect(find.text('This order is already paid'), findsOneWidget);
    });

    testWidgets('the button is not offered when the server has online payment off', (tester) async {
      await pump(tester, farmerOrder('o1'), payments: FakePaymentsRepository(enabled: false));
      expect(find.byKey(const Key('pay-online')), findsNothing);
    });

    testWidgets('a paid order says so and owes nothing for the goods', (tester) async {
      await pump(tester, farmerOrder('o1', paymentStatus: PaymentStatus.paid));
      expect(find.byKey(const Key('pay-online')), findsNothing);
      expect(find.text('Paid online ₹1,200. Nothing to pay for the goods.'), findsOneWidget);
    });

    testWidgets('a refunded order says the money is on its way back', (tester) async {
      await pump(tester, farmerOrder('o1', status: FarmerOrderStatus.cancelled, paymentStatus: PaymentStatus.refunded));
      expect(find.byKey(const Key('pay-online')), findsNothing);
      expect(find.textContaining('Refund of ₹1,200 is on its way'), findsOneWidget);
    });

    testWidgets('a cancelled or collected order cannot be paid', (tester) async {
      await pump(tester, farmerOrder('o1', status: FarmerOrderStatus.completed));
      expect(find.byKey(const Key('pay-online')), findsNothing);
    });
  });

  group('what is still to pay in cash', () {
    test('the server\'s figure is used, with the same sum as a fallback', () {
      final unpaid = farmerOrder('o', deliveryFee: 45);
      expect(unpaid.payableAmount, 1245);
      final paid = farmerOrder('o', deliveryFee: 45, paymentStatus: PaymentStatus.paid);
      expect(paid.payableAmount, 45, reason: 'only the delivery fee is left');
      final fromServer = FarmerOrder.fromJson({
        'id': 'x', 'status': 'pending', 'createdAt': '2026-09-24T00:00:00Z', 'items': [], 'totalAmount': 1200, 'deliveryFee': 45, 'paymentStatus': 'paid', 'payableAmount': 45,
      });
      expect(fromServer.paymentStatus, PaymentStatus.paid);
      expect(fromServer.payableAmount, 45);
      expect(fromServer.isPaidOnline, isTrue);
    });

    test('an order on its way can no longer be paid online', () {
      final onTheWay = farmerOrder('o', delivery: aTracking(status: DeliveryStatus.inTransit));
      expect(onTheWay.canPayOnline, isFalse);
      expect(farmerOrder('o').canPayOnline, isTrue);
    });
  });
}
