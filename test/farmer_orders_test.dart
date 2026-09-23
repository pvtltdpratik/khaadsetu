import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/nearby_center.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/repositories/centers_repository.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/screens/nearby_centers_screen.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/widgets/product_reserve_section.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/entities/farmer_order.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/repositories/orders_repository.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/providers/orders_providers.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/screens/my_orders_screen.dart';

import 'support/farmer_fakes.dart';

class _Harness {
  _Harness({required this.centers, required this.orders, required this.device});

  final FakeCentersRepository centers;
  final FakeOrdersRepository orders;
  final FakeDeviceLocation device;
}

Future<_Harness> _pumpProduct(
  WidgetTester tester, {
  FakeCentersRepository? centers,
  FakeOrdersRepository? orders,
  bool located = true,
}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = centers ?? FakeCentersRepository();
  final o = orders ?? FakeOrdersRepository();
  final d = located ? FakeDeviceLocation(result: shirur) : FakeDeviceLocation(error: const LocationUnavailable('off'));

  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => const Scaffold(body: SingleChildScrollView(child: ProductReserveSection(product: neemCake)))),
    GoRoute(path: RoutePaths.farmerCenters, builder: (context, state) => NearbyCentersScreen(args: state.extra! as NearbyCentersArgs)),
    GoRoute(path: '${RoutePaths.farmerOrders}/:orderId', builder: (context, state) => FarmerOrderDetailScreen(orderId: state.pathParameters['orderId']!)),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      centersRepositoryProvider.overrideWithValue(c),
      ordersRepositoryProvider.overrideWithValue(o),
      deviceLocationProvider.overrideWithValue(d),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return _Harness(centers: c, orders: o, device: d);
}

/// The reserve button shows a spinner while an order is being placed, and that
/// spinner animates forever, so `pumpAndSettle` would time out with the
/// "just went out of stock" dialog open. Pump a few frames instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Stock that depends on how many were asked for: [have] units at each center id.
List<NearbyCenter> Function(Cart) _stock(Map<String, int> have, {Map<String, double> km = const {}, Set<String> closed = const {}}) => (cart) {
      final wanted = cart.lines.single.quantity;
      var first = true;
      return [
        for (final e in have.entries)
          nearbyCenter(e.key, km: km[e.key] ?? 3, have: e.value, wanted: wanted, open: !closed.contains(e.key), hoursLabel: closed.contains(e.key) ? 'Opens tomorrow at 09:00' : 'Open until 18:00', recommended: first && !(first = false)),
      ];
    };

void main() {
  testWidgets('reserving takes the recommended center, sends where the farmer is, and shows the pickup code', (tester) async {
    final h = await _pumpProduct(tester);
    expect(find.text('Available at Center a, 3.0 km away. Ready for pickup.'), findsOneWidget);
    expect(find.text('₹600'), findsOneWidget);

    await tester.tap(find.text('Reserve for pickup'));
    await tester.pumpAndSettle();

    final placed = h.orders.placed.single;
    expect(placed.centerId, 'a');
    expect(placed.items, [const CartLine('p-neemcake', 1)]);
    expect(placed.location, shirur);
    expect(find.text('Your order'), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    expect(find.text('Collect by 29 Sep'), findsOneWidget);
    expect(find.text('Collect from Center a, Village a'), findsOneWidget);
  });

  testWidgets('changing the quantity re-checks stock, updates the price, and blocks an order nobody can fill', (tester) async {
    final h = await _pumpProduct(tester, centers: FakeCentersRepository()..centers = _stock({'a': 3, 'b': 1}, km: {'a': 2, 'b': 4}));
    expect(find.text('₹600'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
    }
    expect(find.text('4'), findsOneWidget);
    expect(find.text('₹2,400'), findsOneWidget);
    expect(h.centers.nearbyCalls.last.lines.single.quantity, 4);
    expect(find.textContaining('Only 3 available at Center a'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Reserve for pickup')).onPressed, isNull);

    await tester.tap(find.byTooltip('Fewer'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Reserve for pickup')).onPressed, isNotNull);
    expect(find.byTooltip('Fewer'), findsOneWidget);
  });

  testWidgets('the farmer can choose a different center than the recommended one', (tester) async {
    final h = await _pumpProduct(tester, centers: FakeCentersRepository()..centers = _stock({'a': 5, 'b': 5}, km: {'a': 2, 'b': 6}));
    expect(find.textContaining('Center a · 2.0 km'), findsOneWidget);

    await tester.tap(find.text('Choose a different center'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a center'), findsOneWidget);
    // Two "Choose this center" buttons; the second belongs to Center b.
    await tester.tap(find.text('Choose this center').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Center b · 6.0 km'), findsOneWidget);
    await tester.tap(find.text('Reserve for pickup'));
    await tester.pumpAndSettle();
    expect(h.orders.placed.single.centerId, 'b');
  });

  testWidgets('a closed center can still be reserved, worded honestly', (tester) async {
    await _pumpProduct(tester, centers: FakeCentersRepository()..centers = _stock({'a': 5}, closed: {'a'}));
    expect(find.textContaining('Opens tomorrow at 09:00'), findsWidgets);
    expect(find.text('Reserve now, collect later'), findsOneWidget);
  });

  testWidgets('the last unit goes while ordering: offered the centers that still have it, and it retries there', (tester) async {
    final orders = FakeOrdersRepository()
      ..onPlace = (attempt, centerId) {
        if (attempt == 1) {
          throw const OutOfStockException('That center just went out of stock of one or more items. Please choose another center.', [
            CenterAlternative(centerId: 'gone', name: 'Empty Center', village: 'V', distanceKm: 1, inventoryStatus: InventoryStatus.none),
            CenterAlternative(centerId: 'b', name: 'Backup Center', village: 'Village b', distanceKm: 6.5, inventoryStatus: InventoryStatus.all),
          ]);
        }
        return farmerOrder('order-2', centerName: 'Backup Center');
      };
    final h = await _pumpProduct(tester, orders: orders);

    await tester.tap(find.text('Reserve for pickup'));
    await _settle(tester);
    expect(find.text('Just went out of stock'), findsOneWidget);
    expect(find.text('Backup Center'), findsOneWidget);
    expect(find.text('Empty Center'), findsNothing, reason: 'only centers that can fill the order are offered');

    await tester.tap(find.text('Backup Center'));
    await _settle(tester);
    await tester.pumpAndSettle();
    expect(h.orders.placed.map((p) => p.centerId), ['a', 'b']);
    expect(find.text('Collect from Backup Center, Village a'), findsOneWidget);
  });

  testWidgets('when nowhere else has it, the dialog says so and nothing is ordered', (tester) async {
    final orders = FakeOrdersRepository()
      ..onPlace = (_, _) => throw const OutOfStockException('None of the centers near you have all of these items right now.', []);
    final h = await _pumpProduct(tester, orders: orders);
    await tester.tap(find.text('Reserve for pickup'));
    await _settle(tester);
    expect(find.textContaining('No other center nearby has it right now.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await _settle(tester);
    await tester.pumpAndSettle();
    expect(h.orders.placed.length, 1);
    expect(find.text('Your order'), findsNothing);
  });

  testWidgets('any other failure is shown and the farmer can try again', (tester) async {
    var fail = true;
    final orders = FakeOrdersRepository()
      ..onPlace = (_, _) {
        if (fail) throw Exception("Couldn't reach the server");
        return farmerOrder('order-3');
      };
    await _pumpProduct(tester, orders: orders);
    await tester.tap(find.text('Reserve for pickup'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't reach the server"), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Reserve for pickup')).onPressed, isNotNull);
    fail = false;
    await tester.tap(find.text('Reserve for pickup'));
    await tester.pumpAndSettle();
    expect(find.text('Your order'), findsOneWidget);
  });

  testWidgets('out of stock everywhere: no reserve, but they can ask to be told when it is back', (tester) async {
    final h = await _pumpProduct(tester, centers: FakeCentersRepository()..centers = _stock({'a': 0, 'b': 0}));
    expect(find.text('Currently out of stock at centers near you.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Reserve for pickup')).onPressed, isNull);

    await tester.tap(find.text('Notify me when available'));
    await tester.pumpAndSettle();
    expect(h.centers.notifyMe.keys, ['p-neemcake']);
    expect(h.centers.notifyMe['p-neemcake'], shirur, reason: 'remembers where the farmer asked from');
    expect(find.text("We'll tell you when it's back in stock near you."), findsOneWidget);
    expect(find.text('Notify me when available'), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(h.centers.notifyMe, isEmpty);
    expect(find.text('Notify me when available'), findsOneWidget);
  });

  testWidgets('it is also offered when there is some stock but not enough, and remembers a request made earlier', (tester) async {
    final centers = FakeCentersRepository()
      ..centers = _stock({'a': 1})
      ..notifyMe['p-neemcake'] = shirur;
    await _pumpProduct(tester, centers: centers);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Only 1 available'), findsOneWidget);
    expect(find.text("We'll tell you when it's back in stock near you."), findsOneWidget, reason: 'already subscribed');
  });

  testWidgets('when it can be reserved there is no reason to ask to be told', (tester) async {
    await _pumpProduct(tester);
    expect(find.text('Notify me when available'), findsNothing);
  });

  testWidgets('a failed request is reported and can be retried', (tester) async {
    final centers = FakeCentersRepository()..centers = _stock({'a': 0});
    await _pumpProduct(tester, centers: centers);
    centers.notifyMeError = Exception("Couldn't reach the server");
    await tester.tap(find.text('Notify me when available'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't reach the server"), findsOneWidget);
    expect(find.text('Notify me when available'), findsOneWidget);
    expect(centers.notifyMe, isEmpty);
  });

  testWidgets('without a location the farmer is asked for one instead of shown an error', (tester) async {
    await _pumpProduct(tester, located: false);
    expect(find.text('Tell us where you are so we can find the nearest village centers.'), findsOneWidget);
    expect(find.text('Reserve for pickup'), findsNothing);
  });

  group('my orders', () {
    Future<FakeOrdersRepository> pumpList(WidgetTester tester, List<FarmerOrder> orders) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = FakeOrdersRepository()..orders = orders;
      await tester.pumpWidget(ProviderScope(
        overrides: [ordersRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(theme: AppTheme.light, home: const MyOrdersScreen()),
      ));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('shows each order\'s status, and the pickup code only while it is live', (tester) async {
      await pumpList(tester, [
        farmerOrder('o1', otp: '1111'),
        farmerOrder('o2', status: FarmerOrderStatus.readyForPickup, otp: '2222'),
        farmerOrder('o3', status: FarmerOrderStatus.completed),
        farmerOrder('o4', status: FarmerOrderStatus.cancelled),
      ]);
      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('Ready for pickup'), findsOneWidget);
      expect(find.text('Collected'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('1111'), findsOneWidget);
      expect(find.text('2222'), findsOneWidget);
      expect(find.text('Your pickup code'), findsNWidgets(2), reason: 'not for collected or cancelled orders');
      expect(find.text('Cancel order'), findsNWidgets(2));
      expect(find.text('₹1,200'), findsWidgets);
    });

    testWidgets('cancelling asks first and releases the reservation', (tester) async {
      final repo = await pumpList(tester, [farmerOrder('o1')]);
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this order?'), findsOneWidget);
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, isEmpty);

      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel order'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, ['o1']);
      expect(find.text('Order cancelled'), findsOneWidget);
    });

    testWidgets('the center\'s phone number is one tap away, and orders with no phone offer no call button', (tester) async {
      await pumpList(tester, [farmerOrder('o1'), farmerOrder('o2', phone: '')]);
      expect(find.text('Call center'), findsOneWidget);
    });

    testWidgets('an empty list says how to start', (tester) async {
      await pumpList(tester, []);
      expect(find.text('No orders yet'), findsOneWidget);
      expect(find.text('Browse marketplace'), findsOneWidget);
    });
  });

  test('an order parses as the server sends it', () {
    final o = FarmerOrder.fromJson({
      'id': 'order-1',
      'status': 'readyForPickup',
      'createdAt': '2026-09-24T05:00:00.000Z',
      'reservedUntil': '2026-09-29T05:00:00.000Z',
      'pickupOtp': '4821',
      'totalAmount': 1200,
      'itemCount': 2,
      'centerId': 'c1',
      'items': [{'productId': 'p1', 'productName': 'Neem Cake', 'quantity': 2, 'unitPrice': 600}],
      'center': {'centerId': 'c1', 'name': 'Kendra', 'village': 'Shirur', 'phone': '98220'},
    });
    expect(o.status, FarmerOrderStatus.readyForPickup);
    expect(o.status.isActive, isTrue);
    expect(o.itemCount, 2);
    expect(o.center!.name, 'Kendra');
    expect(o.pickupOtp, '4821');
    // An order from before centers existed has no center.
    expect(FarmerOrder.fromJson({'id': 'x', 'status': 'completed', 'createdAt': '2026-01-01T00:00:00Z', 'items': [], 'totalAmount': 0, 'center': null}).center, isNull);
  });
}
