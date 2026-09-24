import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/delivery/domain/entities/delivery_models.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/widgets/delivery_option.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/widgets/product_reserve_section.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/entities/farmer_order.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/providers/orders_providers.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/screens/my_orders_screen.dart';

import 'support/delivery_fakes.dart';
import 'support/farmer_fakes.dart';

Future<({FakeOrdersRepository orders, FakeDeliveryRepository delivery})> _pumpProduct(WidgetTester tester, {FakeDeliveryRepository? delivery}) async {
  tester.view.physicalSize = const Size(430, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final orders = FakeOrdersRepository();
  final d = delivery ?? FakeDeliveryRepository();
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => const Scaffold(body: SingleChildScrollView(child: ProductReserveSection(product: neemCake)))),
    GoRoute(path: '${RoutePaths.farmerOrders}/:orderId', builder: (context, state) => FarmerOrderDetailScreen(orderId: state.pathParameters['orderId']!)),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      centersRepositoryProvider.overrideWithValue(FakeCentersRepository()),
      ordersRepositoryProvider.overrideWithValue(orders),
      deliveryRepositoryProvider.overrideWithValue(d),
      deviceLocationProvider.overrideWithValue(FakeDeviceLocation(result: shirur)),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return (orders: orders, delivery: d);
}

Future<void> _pumpOrder(WidgetTester tester, FarmerOrder order, FakeDeliveryRepository delivery, {FakeOrdersRepository? orders}) async {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = orders ?? (FakeOrdersRepository()..orders = [order]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ordersRepositoryProvider.overrideWithValue(repo),
      deliveryRepositoryProvider.overrideWithValue(delivery),
    ],
    child: MaterialApp(theme: AppTheme.light, home: FarmerOrderDetailScreen(orderId: order.id)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('choosing home delivery', () {
    testWidgets('asks for a quote, shows the fee, and waits for a phone number', (tester) async {
      final h = await _pumpProduct(tester);
      expect(find.text('Reserve for pickup'), findsOneWidget);
      expect(h.delivery.quotes, isEmpty, reason: 'no quote until the farmer asks for delivery');

      await tester.tap(find.text('Bring to my farm'));
      await tester.pumpAndSettle();

      expect(h.delivery.quotes.single.centerId, 'a');
      expect(h.delivery.quotes.single.items.single.productId, 'p-neemcake');
      expect(find.byKey(const Key('delivery-fee')), findsOneWidget);
      expect(find.text('₹60'), findsWidgets);
      expect(find.textContaining('A delivery partner nearby is free right now.'), findsOneWidget);
      expect(find.textContaining('in cash to the delivery partner'), findsOneWidget);

      // The button names the fee but stays off until there is a number to call.
      expect(find.text('Order home delivery · ₹60'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.ancestor(of: find.text('Order home delivery · ₹60'), matching: find.byType(FilledButton))).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('delivery-phone')), '12345');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.ancestor(of: find.text('Order home delivery · ₹60'), matching: find.byType(FilledButton))).onPressed, isNull, reason: 'not a mobile number');

      await tester.enterText(find.byKey(const Key('delivery-phone')), '98765 43210');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.ancestor(of: find.text('Order home delivery · ₹60'), matching: find.byType(FilledButton))).onPressed, isNotNull);
    });

    testWidgets('placing it sends where to bring it and who to call', (tester) async {
      final h = await _pumpProduct(tester);
      await tester.tap(find.text('Bring to my farm'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('delivery-phone')), '98765 43210');
      await tester.enterText(find.byKey(const Key('delivery-note')), 'Blue gate');
      await tester.pump();

      await tester.tap(find.text('Order home delivery · ₹60'));
      await tester.pumpAndSettle();

      final sent = h.orders.placed.single;
      expect(sent.delivery, isNotNull);
      expect(sent.delivery!.phone, '98765 43210');
      expect(sent.delivery!.note, 'Blue gate');
      expect(sent.delivery!.latitude, shirur.latitude);
      expect(sent.delivery!.longitude, shirur.longitude);
      expect(sent.centerId, 'a');
    });

    testWidgets('collecting at the center still sends no delivery', (tester) async {
      final h = await _pumpProduct(tester);
      await tester.tap(find.text('Reserve for pickup'));
      await tester.pumpAndSettle();
      expect(h.orders.placed.single.delivery, isNull);
    });

    testWidgets('a farm too far from the center cannot be ordered for delivery, and says why', (tester) async {
      final d = FakeDeliveryRepository()..quoteAnswer = deliveryQuote(available: false);
      final h = await _pumpProduct(tester, delivery: d);
      await tester.tap(find.text('Bring to my farm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('only available within 20 km'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('delivery-phone')), '98765 43210');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.ancestor(of: find.textContaining('Order home delivery'), matching: find.byType(FilledButton))).onPressed, isNull);
      expect(h.orders.placed, isEmpty);
    });

    testWidgets('switching back to collecting goes back to the plain button', (tester) async {
      await _pumpProduct(tester);
      await tester.tap(find.text('Bring to my farm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Collect'));
      await tester.pumpAndSettle();
      expect(find.text('Reserve for pickup'), findsOneWidget);
      expect(find.byKey(const Key('delivery-phone')), findsNothing);
    });
  });

  group('phone numbers', () {
    test('accept what the server accepts', () {
      expect(isValidMobile('9876543210'), isTrue);
      expect(isValidMobile('98765 43210'), isTrue);
      expect(isValidMobile('+91 98765-43210'), isTrue);
      expect(isValidMobile('098765 43210'), isTrue);
      expect(isValidMobile('1234567890'), isFalse);
      expect(isValidMobile('98765'), isFalse);
      expect(isValidMobile(''), isFalse);
    });
  });

  group('following a delivery', () {
    testWidgets('finding a partner: the steps, the fee, the cash to pay, and the way out', (tester) async {
      final d = FakeDeliveryRepository();
      final order = farmerOrder('order-1', otp: null, delivery: aTracking(), deliveryFee: 60);
      await _pumpOrder(tester, order, d);

      expect(find.text('Finding a delivery partner'), findsWidgets);
      expect(find.byKey(const Key('order-delivery-fee')), findsOneWidget);
      expect(find.text('₹1,260'), findsWidgets, reason: 'goods 1200 + delivery 60');
      expect(find.textContaining('Pay ₹1,260 in cash on arrival (goods ₹1,200 + delivery ₹60)'), findsOneWidget);
      expect(find.text('Your pickup code'), findsNothing, reason: 'a delivery has no counter code');
      expect(find.text('I will collect it instead'), findsOneWidget);
      expect(find.byKey(const Key('drop-code')), findsNothing, reason: 'nobody is coming yet');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a partner is on the way: who, how far, and the code to read out', (tester) async {
      final order = farmerOrder('order-1', otp: null, delivery: aTracking(status: DeliveryStatus.inTransit, etaMinutes: 25, dropCode: '7391'), deliveryFee: 60);
      await _pumpOrder(tester, order, FakeDeliveryRepository());

      expect(find.text('Ramesh Patil'), findsOneWidget);
      expect(find.textContaining('MH12AB1234'), findsOneWidget);
      expect(find.textContaining('★ 4.6 (12)'), findsOneWidget);
      expect(find.text('About 25 min · 4.2 km from you'), findsOneWidget);
      expect(find.text('7391'), findsOneWidget);
      expect(find.text('Call partner'), findsOneWidget);
      expect(find.text('See on map'), findsOneWidget);
      expect(find.text('I will collect it instead'), findsNothing, reason: 'it is already on the road');
      expect(find.text('Cancel order'), findsNothing, reason: 'too late to cancel once it is on the road');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('choosing to collect it instead asks first, then calls it off', (tester) async {
      final d = FakeDeliveryRepository();
      await _pumpOrder(tester, farmerOrder('order-1', otp: null, delivery: aTracking(status: DeliveryStatus.assigned), deliveryFee: 60), d);

      await tester.tap(find.text('I will collect it instead'));
      await tester.pumpAndSettle();
      expect(find.text('Collect it yourself?'), findsOneWidget);
      await tester.tap(find.text('Keep the delivery'));
      await tester.pumpAndSettle();
      expect(d.calls, isEmpty);

      await tester.tap(find.text('I will collect it instead'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I will collect it'));
      await tester.pumpAndSettle();
      expect(d.calls, ['switchToPickup:order-1']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('when nobody was free the order is a plain pickup again, with its code', (tester) async {
      final order = farmerOrder('order-1', otp: '4821', delivery: aTracking(status: DeliveryStatus.fallback));
      await _pumpOrder(tester, order, FakeDeliveryRepository());
      expect(find.text('Your pickup code'), findsOneWidget);
      expect(find.text('4821'), findsOneWidget);
      expect(find.byKey(const Key('delivery-card')), findsNothing);
      expect(find.text('Comes from Center a, Village a'), findsNothing);
      expect(find.text('Collect from Center a, Village a'), findsOneWidget);
    });

    testWidgets('after it is delivered the farmer can rate the partner, once', (tester) async {
      final d = FakeDeliveryRepository();
      final order = farmerOrder('order-1', status: FarmerOrderStatus.completed, delivery: aTracking(status: DeliveryStatus.delivered), deliveryFee: 60);
      await _pumpOrder(tester, order, d);

      expect(find.text('Delivered'), findsWidgets);
      expect(find.byKey(const Key('delivered-check')), findsOneWidget, reason: 'a finished delivery gets its moment');
      await tester.tap(find.text('Rate the delivery'));
      await tester.pumpAndSettle();
      expect(find.text('Send'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.ancestor(of: find.text('Send'), matching: find.byType(FilledButton))).onPressed, isNull, reason: 'pick stars first');
      await tester.tap(find.byKey(const Key('star-4')));
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(d.orderRatings.single.stars, 4);
      expect(d.orderRatings.single.orderId, 'order-1');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an already rated delivery has no rate button', (tester) async {
      final order = farmerOrder('order-1', status: FarmerOrderStatus.completed, delivery: aTracking(status: DeliveryStatus.delivered, rated: true), deliveryFee: 60);
      await _pumpOrder(tester, order, FakeDeliveryRepository());
      expect(find.text('Rate the delivery'), findsNothing);
    });
  });

  group('parsing an order that has a delivery', () {
    test('the delivery, the fee and the cash to pay come through', () {
      final o = FarmerOrder.fromJson({
        'id': 'o1',
        'status': 'pending',
        'createdAt': '2026-09-24T10:00:00Z',
        'items': [
          {'productName': 'Vermicompost', 'quantity': 1, 'unitPrice': 1200},
        ],
        'totalAmount': 1200,
        'deliveryFee': 60,
        'pickupOtp': null,
        'delivery': {
          'jobId': 'job-1',
          'status': 'in_transit',
          'stage': 'Your order is on its way to you',
          'fee': 60,
          'weightKg': 40,
          'distanceKm': 6.5,
          'payableAmount': 1260,
          'pickup': {'latitude': 18.8, 'longitude': 74.3, 'label': 'Center a'},
          'drop': {'latitude': 18.83, 'longitude': 74.37, 'label': ''},
          'partner': {'name': 'Ramesh', 'vehicleLabel': 'Tractor', 'vehicleNumber': 'MH12', 'ratingAvg': 4.5, 'ratingCount': 2, 'deliveriesDone': 3, 'phone': '9876500000'},
          'partnerLocation': {'latitude': 18.81, 'longitude': 74.31},
          'dropCode': '1234',
          'nextStop': 'you',
          'distanceToNextStopKm': 2.5,
          'etaMinutes': 12,
          'canSwitchToPickup': false,
          'rated': false,
        },
      });
      expect(o.isHomeDelivery, isTrue);
      expect(o.payableAmount, 1260);
      expect(o.delivery!.status, DeliveryStatus.inTransit);
      expect(o.delivery!.dropCode, '1234');
      expect(o.delivery!.partner!.name, 'Ramesh');
      expect(o.delivery!.etaMinutes, 12);
      expect(o.delivery!.canSwitchToPickup, isFalse);
    });

    test('an ordinary pickup order has no delivery', () {
      final o = FarmerOrder.fromJson({
        'id': 'o1',
        'status': 'pending',
        'createdAt': '2026-09-24T10:00:00Z',
        'items': const [],
        'totalAmount': 100,
      });
      expect(o.isHomeDelivery, isFalse);
      expect(o.deliveryFee, 0);
      expect(o.payableAmount, 100);
    });
  });
}
