import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/operator/farmers/domain/entities/farmer.dart';
import 'package:khaadsetu_version1/features/operator/farmers/presentation/providers/farmers_providers.dart';
import 'package:khaadsetu_version1/features/operator/inventory/presentation/providers/inventory_providers.dart';
import 'package:khaadsetu_version1/features/operator/orders/domain/entities/order.dart';
import 'package:khaadsetu_version1/features/operator/orders/presentation/providers/orders_providers.dart' as op;
import 'package:khaadsetu_version1/features/operator/orders/presentation/screens/order_detail_screen.dart';
import 'package:khaadsetu_version1/features/operator/orders/presentation/screens/walk_in_pos_screen.dart';

import 'support/operator_fakes.dart';

Farmer aFarmer(String id, String name, {String village = 'Shirur'}) => Farmer(id: id, name: name, village: village, phone: '9800000002', activeCrop: 'Soybean', lastVisitDate: DateTime(2026, 9, 20), needsFollowUp: false, notes: '');

Future<FakeOperatorOrdersRepository> pump(WidgetTester tester, {List<Farmer> farmers = const []}) async {
  tester.view.physicalSize = const Size(420, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final orders = FakeOperatorOrdersRepository();
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => const Scaffold(body: WalkInPosScreen())),
    GoRoute(path: RoutePaths.operatorOrderDetailPattern, builder: (context, state) => Text('sale ${state.pathParameters['orderId']}')),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      inventoryRepositoryProvider.overrideWithValue(FakeInventoryRepository(items: [shelfItem('p-neemcake', onHand: 10)])),
      op.ordersRepositoryProvider.overrideWithValue(orders),
      farmersProvider.overrideWith((ref) async => farmers),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
  await tester.pump();
  return orders;
}

void main() {
  testWidgets('a counter sale is paid in cash unless the operator says otherwise', (tester) async {
    final orders = await pump(tester);
    await tester.tap(find.text('Complete sale'));
    await tester.pumpAndSettle();
    expect(orders.walkInPayments.single.mode, 'cash');
    expect(orders.walkInPayments.single.customerId, isNull);
  });

  testWidgets('UPI and card are sent as they were chosen, with the typed name', (tester) async {
    final orders = await pump(tester);
    await tester.enterText(find.byType(TextField).first, 'Ramesh');
    await tester.tap(find.byKey(const Key('walkin-mode-upi')));
    await tester.pump();
    await tester.tap(find.text('Complete sale'));
    await tester.pumpAndSettle();
    expect(orders.walkInPayments.single.mode, 'upi');
    expect(orders.walkInPayments.single.customerName, 'Ramesh');
    expect(orders.walkInPayments.single.customerId, isNull);
  });

  testWidgets('on credit, a farmer must be chosen before the sale can be completed, and the sale is written against him', (tester) async {
    final orders = await pump(tester, farmers: [aFarmer('f1', 'Sunita'), aFarmer('f2', 'Anil', village: 'Pune')]);
    await tester.tap(find.byKey(const Key('walkin-mode-credit')));
    await tester.pump();
    expect(find.byKey(const Key('credit-customer')), findsOneWidget);
    await tester.tap(find.text('Complete sale'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(orders.walkInPayments, isEmpty, reason: 'nobody chosen yet, so nothing is sent');

    await tester.tap(find.byKey(const Key('credit-customer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anil, Pune').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete sale'));
    await tester.pumpAndSettle();
    expect(orders.walkInPayments.single, (mode: 'credit', customerId: 'f2', customerName: 'Anil'));
  });

  testWidgets('with nobody to put on credit, it explains who can be', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('walkin-mode-credit')));
    await tester.pump();
    expect(find.textContaining('Credit is for farmers who have ordered from your center'), findsOneWidget);
  });

  testWidgets('going back to cash forgets the credit choice', (tester) async {
    final orders = await pump(tester, farmers: [aFarmer('f1', 'Sunita')]);
    await tester.tap(find.byKey(const Key('walkin-mode-credit')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('credit-customer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunita, Shirur').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walkin-mode-cash')));
    await tester.pump();
    await tester.tap(find.text('Complete sale'));
    await tester.pumpAndSettle();
    expect(orders.walkInPayments.single.mode, 'cash');
    expect(orders.walkInPayments.single.customerId, isNull);
  });

  group('handover at the counter', () {
    Future<FakeOperatorOrdersRepository> handover(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final orders = FakeOperatorOrdersRepository()
        ..found = Order(id: 'order-9', customerName: 'Ramesh', type: OrderType.appOrder, status: OrderStatus.readyForPickup, items: const [OrderLineItem(productName: 'Neem Cake', quantity: 2, unitPrice: 450)], createdAt: DateTime(2026, 9, 26), pickupOtp: '4821');
      await tester.pumpWidget(ProviderScope(
        overrides: [op.ordersRepositoryProvider.overrideWithValue(orders)],
        child: MaterialApp(theme: AppTheme.light, home: const Scaffold(body: OrderDetailScreen(orderId: 'order-9'))),
      ));
      await tester.pumpAndSettle();
      return orders;
    }
  
    testWidgets('the farmer pays in cash unless the operator says otherwise, and the choice goes with the code', (tester) async {
      final orders = await handover(tester);
      await tester.enterText(find.byType(TextField), '4821');
      await tester.tap(find.text('Verify & complete'));
      await tester.pumpAndSettle();
      expect(orders.handovers.single, (orderId: 'order-9', otp: '4821', mode: 'cash'));
    });
  
    testWidgets('UPI, card or credit can be chosen before completing', (tester) async {
      final orders = await handover(tester);
      await tester.tap(find.byKey(const Key('handover-mode-credit')));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '4821');
      await tester.tap(find.text('Verify & complete'));
      await tester.pumpAndSettle();
      expect(orders.handovers.single.mode, 'credit');
    });
  });
  
}
