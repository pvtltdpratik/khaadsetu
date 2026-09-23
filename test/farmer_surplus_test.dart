import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khaadsetu_version1/core/network/api_client.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/centers/data/centers_api_repository.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/nearby_center.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/surplus_offer.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/repositories/centers_repository.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/screens/surplus_nearby_screen.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/widgets/product_surplus_section.dart';
import 'package:khaadsetu_version1/features/farmer/orders/data/orders_api_repository.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/entities/farmer_order.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/repositories/orders_repository.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/providers/orders_providers.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/widgets/order_card.dart';
import 'package:khaadsetu_version1/features/operator/surplus/domain/entities/surplus_lot.dart';

import 'support/farmer_fakes.dart';

SurplusOffer offer(
  String lotId, {
  String productId = 'p-neemcake',
  String name = 'Neem Cake',
  double price = 450,
  double catalog = 600,
  int available = 5,
  SurplusCondition condition = SurplusCondition.damagedPackaging,
  DateTime? bestBefore,
  String note = '',
  String center = 'Shirur Kendra',
  double km = 2.3,
  bool open = true,
}) =>
    SurplusOffer(
      lotId: lotId,
      productId: productId,
      productName: name,
      unit: '5 kg bag',
      catalogPrice: catalog,
      unitPrice: price,
      available: available,
      condition: condition,
      bestBefore: bestBefore,
      note: note,
      center: SurplusCenter(centerId: 'c-$lotId', name: center, village: 'Shirur', phone: '98220 00000', isOpen: open),
      distanceKm: km,
      estimatedTravelMinutes: 18,
    );

void main() {
  group('offers from the server', () {
    test('parse, and work out the discount', () {
      final o = SurplusOffer.fromJson({
        'id': 'lot-1', 'productId': 'p-neemcake', 'productName': 'Neem Cake', 'unit': '5 kg bag',
        'catalogPrice': 600, 'unitPrice': 450, 'available': 3, 'condition': 'near_expiry', 'bestBefore': '2026-11-30', 'note': 'Torn',
        'center': {'centerId': 'c1', 'name': 'Shirur Kendra', 'village': 'Shirur', 'phone': '', 'isOpen': false},
        'distanceKm': 2.3, 'estimatedTravelMinutes': 18,
      });
      expect(o.discountPercent, 25);
      expect(o.condition, SurplusCondition.nearExpiry);
      expect(o.bestBefore, DateTime(2026, 11, 30));
      expect(o.center.isOpen, isFalse);
      expect(o.center.phone, '');
    });

    test('an unknown condition never breaks the list', () {
      final o = SurplusOffer.fromJson({
        'id': 'l', 'productId': 'p', 'productName': 'P', 'catalogPrice': 10, 'unitPrice': 5, 'available': 1, 'condition': 'from-the-future',
        'center': {'centerId': 'c', 'name': 'C', 'village': 'V'}, 'distanceKm': 1, 'estimatedTravelMinutes': 1,
      });
      expect(o.condition, SurplusCondition.other);
      expect(o.center.isOpen, isTrue, reason: 'assume open when the server does not say');
    });
  });

  group('API repositories', () {
    ApiClient client(MockClient mock) => ApiClient(client: mock, deviceId: () async => 'farmer');

    test('surplusNearby sends the location and product, and reads the lots', () async {
      late http.Request seen;
      final repo = CentersApiRepository(client(MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'location': {},
            'lots': [
              {
                'id': 'lot-1', 'productId': 'p-neemcake', 'productName': 'Neem Cake', 'unit': 'bag', 'catalogPrice': 600, 'unitPrice': 450, 'available': 3,
                'condition': 'opened', 'bestBefore': null, 'note': '',
                'center': {'centerId': 'c1', 'name': 'K', 'village': 'V', 'phone': '', 'isOpen': true}, 'distanceKm': 1.5, 'estimatedTravelMinutes': 10,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      })));
      final offers = await repo.surplusNearby(location: shirur, productId: 'p-neemcake');
      expect(seen.url.path, '/v1/centers/surplus');
      expect(jsonDecode(seen.body), {'latitude': 18.83, 'longitude': 74.37, 'locationSource': 'gps', 'productId': 'p-neemcake'});
      expect(offers.single.lotId, 'lot-1');

      await repo.surplusNearby(location: shirur);
      expect((jsonDecode(seen.body) as Map).containsKey('productId'), isFalse, reason: 'no product means every product');
    });

    test('placeSurplus orders the lot by id and never sends a price', () async {
      late http.Request seen;
      final repo = OrdersApiRepository(client(MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'id': 'order-1', 'status': 'pending', 'createdAt': '2026-09-24T05:00:00Z', 'totalAmount': 900, 'pickupOtp': '4821',
            'items': [{'productName': 'Neem Cake', 'quantity': 2, 'unitPrice': 450, 'surplusLotId': 'lot-1'}],
            'center': {'centerId': 'c1', 'name': 'K', 'village': 'V', 'phone': ''},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      })));
      final order = await repo.placeSurplus(lotId: 'lot-1', quantity: 2, location: shirur);
      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['items'], [
        {'surplusLotId': 'lot-1', 'quantity': 2},
      ]);
      expect(body.containsKey('centerId'), isFalse);
      expect(order.items.single.isSurplus, isTrue);
      expect(order.totalAmount, 900);
    });

    test('an offer that sold out becomes its own exception, other errors pass through', () async {
      final gone = OrdersApiRepository(client(MockClient((req) async => http.Response(
            jsonEncode({'error': 'That surplus offer just sold out or is no longer available.', 'code': 'surplus_unavailable'}),
            409,
            headers: {'content-type': 'application/json'},
          ))));
      await expectLater(
        gone.placeSurplus(lotId: 'lot-1', quantity: 1),
        throwsA(isA<SurplusUnavailableException>().having((e) => e.message, 'message', contains('sold out'))),
      );

      final other = OrdersApiRepository(client(MockClient((req) async => http.Response(jsonEncode({'error': 'Server broke'}), 500, headers: {'content-type': 'application/json'}))));
      await expectLater(other.placeSurplus(lotId: 'lot-1', quantity: 1), throwsA(isA<ApiException>()));
    });
  });

  group('surplus deals screen', () {
    Future<({FakeCentersRepository centers, FakeOrdersRepository orders, GoRouter router})> pump(
      WidgetTester tester, {
      List<SurplusOffer> offers = const [],
      FarmerLocation? at = shirur,
      Size size = const Size(420, 2200),
      Widget? home,
      Object? error,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final centers = FakeCentersRepository()
        ..surplus = [...offers]
        ..surplusError = error;
      final orders = FakeOrdersRepository();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => home ?? const SurplusNearbyScreen()),
        GoRoute(path: '/farmer/marketplace/surplus', builder: (context, state) => const SurplusNearbyScreen()),
        GoRoute(path: '/farmer/marketplace/orders/:id', builder: (context, state) => Scaffold(body: Text('ORDER ${state.pathParameters['id']}'))),
      ]);
      addTearDown(router.dispose);
      final List<Override> overrides = [
        centersRepositoryProvider.overrideWithValue(centers),
        ordersRepositoryProvider.overrideWithValue(orders),
        deviceLocationProvider.overrideWithValue(at == null ? FakeDeviceLocation(error: const LocationUnavailable('off')) : FakeDeviceLocation(result: at)),
      ];
      await tester.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp.router(theme: AppTheme.light, routerConfig: router)));
      await tester.pumpAndSettle();
      return (centers: centers, orders: orders, router: router);
    }

    testWidgets('each deal shows the price against the regular one, why it is cheaper, what is left, and where', (tester) async {
      await pump(tester, offers: [
        offer('a', bestBefore: DateTime(2026, 11, 30), note: 'Torn stitching'),
        offer('b', name: 'Vermicompost', productId: 'p-verm', price: 300, catalog: 450, condition: SurplusCondition.nearExpiry, center: 'Paithan Kendra', km: 8.4, available: 1),
      ]);
      expect(find.text('Neem Cake'), findsOneWidget);
      expect(find.text('₹450'), findsWidgets);
      expect(find.text('₹600'), findsOneWidget, reason: 'the regular price, struck through');
      expect(find.text('25% off'), findsOneWidget);
      expect(find.text('Damaged packaging · best before 30/11/2026 · 5 available'), findsOneWidget);
      expect(find.text('Torn stitching'), findsOneWidget);
      expect(find.text('Shirur Kendra, Shirur · 2.3 km · about 18 min'), findsOneWidget);
      expect(find.text('33% off'), findsOneWidget);
      expect(find.text('Near expiry · 1 available'), findsOneWidget, reason: 'no best-before date: none is shown');
      expect(find.text('Reserve'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a closed center can still be reserved from, and the button says so', (tester) async {
      await pump(tester, offers: [offer('a', open: false)]);
      expect(find.text('Reserve, collect later'), findsOneWidget);
    });

    testWidgets('nothing on offer: says so kindly', (tester) async {
      await pump(tester);
      expect(find.textContaining('No surplus deals near you'), findsOneWidget);
    });

    testWidgets('without a location it asks for one and lists nothing', (tester) async {
      final r = await pump(tester, offers: [offer('a')], at: null);
      expect(find.text('Neem Cake'), findsNothing);
      expect(r.centers.surplusCalls, isEmpty, reason: 'nothing to ask the server without a place');
    });

    testWidgets('a failed load explains and offers a retry', (tester) async {
      await pump(tester, offers: [offer('a')], error: Exception('offline'));
      expect(find.textContaining('offline'), findsOneWidget);
    });

    testWidgets('reserving: pick how many (never more than are left), see the total, and land on the order with its code', (tester) async {
      final r = await pump(tester, offers: [offer('lot-7', available: 3, price: 450)]);
      await tester.tap(find.text('Reserve'));
      await tester.pumpAndSettle();
      expect(find.text('Reserve surplus'), findsOneWidget);
      expect(find.textContaining('Only 3 units are left at this price'), findsOneWidget);
      expect(find.text('₹450'), findsWidgets);

      await tester.tap(find.byTooltip('More'));
      await tester.tap(find.byTooltip('More'));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('₹1,350'), findsOneWidget);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_rounded)).onPressed, isNull, reason: 'only 3 are left');

      await tester.tap(find.byTooltip('Fewer'));
      await tester.pump();
      await tester.tap(find.text('Reserve for pickup'));
      await tester.pumpAndSettle();

      expect(r.orders.surplusPlaced.single, (lotId: 'lot-7', quantity: 2));
      expect(find.text('ORDER order-surplus-1'), findsOneWidget);
    });

    testWidgets('cancelling the dialog reserves nothing', (tester) async {
      final r = await pump(tester, offers: [offer('a')]);
      await tester.tap(find.text('Reserve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(r.orders.surplusPlaced, isEmpty);
      expect(find.text('Reserve surplus'), findsNothing);
    });

    testWidgets('someone else took the last units: the reason is shown, reserving is closed off, and the list refreshes', (tester) async {
      final r = await pump(tester, offers: [offer('a')]);
      r.orders.surplusError = const SurplusUnavailableException('That surplus offer just sold out or is no longer available.');
      final callsBefore = r.centers.surplusCalls.length;
      await tester.tap(find.text('Reserve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reserve for pickup'));
      await tester.pumpAndSettle();

      expect(find.text('That surplus offer just sold out or is no longer available.'), findsOneWidget);
      expect(find.text('Reserve for pickup'), findsNothing, reason: 'there is nothing left to reserve');
      expect(find.text('Close'), findsOneWidget);
      expect(r.centers.surplusCalls.length, greaterThan(callsBefore), reason: 'the list behind was refreshed');
    });

    testWidgets('any other failure stays on the dialog so the farmer can try again', (tester) async {
      final r = await pump(tester, offers: [offer('a')]);
      r.orders.surplusError = Exception('Could not reach the server');
      await tester.tap(find.text('Reserve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reserve for pickup'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not reach the server'), findsOneWidget);
      expect(find.text('Reserve for pickup'), findsOneWidget);
    });

    testWidgets('tablet width has no overflow', (tester) async {
      await pump(tester, offers: [offer('a', note: 'x' * 150), offer('b', name: 'A Product With A Really Rather Long Name Indeed', center: 'A Center With A Long Name')], size: const Size(1100, 900));
      expect(tester.takeException(), isNull);
    });
  });

  group('cheaper units on a product page', () {
    Future<FakeCentersRepository> pump(WidgetTester tester, List<SurplusOffer> offers) async {
      tester.view.physicalSize = const Size(420, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final centers = FakeCentersRepository()..surplus = offers;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          centersRepositoryProvider.overrideWithValue(centers),
          ordersRepositoryProvider.overrideWithValue(FakeOrdersRepository()),
          deviceLocationProvider.overrideWithValue(FakeDeviceLocation(result: shirur)),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const Scaffold(body: SingleChildScrollView(child: ProductSurplusSection(productId: 'p-neemcake')))),
      ));
      await tester.pumpAndSettle();
      return centers;
    }

    testWidgets('a product with no deals looks exactly as it did before: nothing is added', (tester) async {
      await pump(tester, [offer('other', productId: 'p-other', name: 'Other Product')]);
      expect(find.text('Cheaper units nearby'), findsNothing);
      expect(find.byType(Card), findsNothing);
      expect(find.text('Other Product'), findsNothing);
    });

    testWidgets('only this product\'s deals are asked for and shown', (tester) async {
      final repo = await pump(tester, [offer('mine'), offer('other', productId: 'p-other', name: 'Other Product')]);
      expect(repo.surplusCalls, ['p-neemcake']);
      expect(find.text('Cheaper units nearby'), findsOneWidget);
      expect(find.text('Neem Cake'), findsOneWidget);
      expect(find.text('Other Product'), findsNothing);
      expect(find.text('See all'), findsNothing, reason: 'two or fewer: nothing more to see');
    });

    testWidgets('more than two show a preview and a way to see them all', (tester) async {
      await pump(tester, [offer('a', center: 'Center A'), offer('b', center: 'Center B'), offer('c', center: 'Center C')]);
      expect(find.text('Shirur Kendra, Shirur · 2.3 km · about 18 min'), findsNothing);
      expect(find.textContaining('Center A'), findsOneWidget);
      expect(find.textContaining('Center B'), findsOneWidget);
      expect(find.textContaining('Center C'), findsNothing, reason: 'only a preview');
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('a failed lookup adds nothing rather than an error on the product page', (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final centers = FakeCentersRepository()..surplusError = Exception('offline');
      await tester.pumpWidget(ProviderScope(
        overrides: [centersRepositoryProvider.overrideWithValue(centers), deviceLocationProvider.overrideWithValue(FakeDeviceLocation(result: shirur))],
        child: MaterialApp(theme: AppTheme.light, home: const Scaffold(body: ProductSurplusSection(productId: 'p-neemcake'))),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('offline'), findsNothing);
      expect(find.text('Cheaper units nearby'), findsNothing);
    });
  });

  group('orders', () {
    testWidgets('a line bought from a surplus lot says so, a regular line does not', (tester) async {
      final order = FarmerOrder(
        id: 'o1',
        status: FarmerOrderStatus.pending,
        createdAt: DateTime(2026, 9, 24),
        items: const [
          OrderLine(productName: 'Neem Cake', quantity: 2, unitPrice: 450, surplusLotId: 'lot-1'),
          OrderLine(productName: 'Vermicompost', quantity: 1, unitPrice: 450),
        ],
        totalAmount: 1350,
        pickupOtp: '4821',
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [ordersRepositoryProvider.overrideWithValue(FakeOrdersRepository())],
        child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: SingleChildScrollView(child: OrderCard(order: order)))),
      ));
      expect(find.text('2 × Neem Cake (surplus)'), findsOneWidget);
      expect(find.text('1 × Vermicompost'), findsOneWidget);
    });
  });
}
