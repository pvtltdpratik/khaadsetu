import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khaadsetu_version1/core/auth/session_profile.dart';
import 'package:khaadsetu_version1/core/network/api_client.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/entities/product.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/data/datasources/notifications_api_data_source.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/domain/entities/app_notification.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/presentation/providers/notifications_providers.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/presentation/screens/notifications_screen.dart';
import 'package:khaadsetu_version1/features/operator/center/domain/entities/operator_center.dart';
import 'package:khaadsetu_version1/features/operator/center/presentation/providers/operator_center_providers.dart';
import 'package:khaadsetu_version1/features/operator/center/presentation/widgets/my_center_card.dart';
import 'package:khaadsetu_version1/features/operator/farmers/data/datasources/farmers_api_data_source.dart';
import 'package:khaadsetu_version1/features/operator/farmers/domain/entities/farmer.dart';
import 'package:khaadsetu_version1/features/operator/farmers/presentation/widgets/farmer_card.dart';
import 'package:khaadsetu_version1/features/operator/inventory/data/datasources/inventory_api_data_source.dart';
import 'package:khaadsetu_version1/features/operator/inventory/domain/entities/inventory_item.dart';
import 'package:khaadsetu_version1/features/operator/inventory/domain/entities/restock_request.dart';
import 'package:khaadsetu_version1/features/operator/inventory/presentation/providers/inventory_providers.dart';
import 'package:khaadsetu_version1/features/operator/inventory/presentation/screens/inventory_screen.dart';
import 'package:khaadsetu_version1/features/operator/inventory/presentation/widgets/item_settings_sheet.dart';
import 'package:khaadsetu_version1/features/operator/orders/presentation/providers/orders_providers.dart' as op;
import 'package:khaadsetu_version1/features/operator/orders/presentation/screens/walk_in_pos_screen.dart';
import 'package:khaadsetu_version1/features/operator/presentation/widgets/operator_notification_bell.dart';
import 'package:khaadsetu_version1/core/responsive/responsive_layout.dart';

import 'support/farmer_fakes.dart' show neemCake;
import 'support/operator_fakes.dart';

Future<void> _mobile(WidgetTester tester, {double height = 1200}) async {
  tester.view.physicalSize = Size(420, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, List<Override> overrides) =>
    ProviderScope(overrides: overrides, child: MaterialApp(theme: AppTheme.light, home: home));

void main() {
  group('notifications the app has not seen before', () {
    test('every type the server sends parses, and an unknown one is "other", never an error', () {
      for (final t in ['scan', 'scheme', 'order', 'stock', 'restock', 'account']) {
        expect(NotificationType.parse(t).name, t);
      }
      expect(NotificationType.parse('brand-new-type'), NotificationType.other);
      expect(NotificationType.parse(null), NotificationType.other);
    });

    test('a list mixing known and new types loads whole', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode([
              {'id': 'n1', 'type': 'order', 'title': 'a', 'body': 'b', 'createdAt': '2026-09-24T05:00:00Z', 'read': false, 'refId': 'o1'},
              {'id': 'n2', 'type': 'account', 'title': 'Your account was reactivated', 'body': 'b', 'createdAt': '2026-09-24T05:00:00Z', 'read': false, 'refId': null},
              {'id': 'n3', 'type': 'stock', 'title': 'Low stock: Neem Cake', 'body': 'b', 'createdAt': '2026-09-24T05:00:00Z', 'read': true, 'refId': 'p-neemcake'},
              {'id': 'n4', 'type': 'something-new', 'title': 'x', 'body': 'b', 'createdAt': '2026-09-24T05:00:00Z', 'read': true, 'refId': null},
            ]),
            200,
          ));
      final list = await NotificationsApiDataSource(ApiClient(client: client, deviceId: () async => 'd')).fetchNotifications();
      expect(list.map((n) => n.type), [NotificationType.order, NotificationType.account, NotificationType.stock, NotificationType.other]);
    });
  });

  group('inventory model', () {
    test('low stock is judged on what can be SOLD, not what is on the shelf', () {
      final held = shelfItem('p', onHand: 10, reserved: 7, reorder: 5);
      expect(held.available, 3);
      expect(held.isLowStock, isTrue, reason: '10 on the shelf but 7 promised to app orders');
      expect(shelfItem('p', onHand: 10, reserved: 0, reorder: 5).isLowStock, isFalse);
      expect(shelfItem('p', onHand: 5, reserved: 0, reorder: 5).isLowStock, isTrue, reason: 'at the level counts');
    });

    test('parses the server fields, and tolerates the older shape without the new ones', () {
      final full = InventoryItem.fromJson({
        'id': 'p1', 'name': 'Neem Cake', 'unit': 'bag', 'unitPrice': 600, 'currentStock': 10, 'lowStockThreshold': 5,
        'reserved': 3, 'available': 7, 'maxCapacity': 40, 'incoming': 12, 'lastRestockedAt': '2026-09-20T05:00:00Z', 'isLowStock': false,
      });
      expect([full.available, full.reserved, full.incoming, full.maxCapacity], [7, 3, 12, 40]);
      expect(full.lastRestockedAt, isNotNull);
      final old = InventoryItem.fromJson({'id': 'p1', 'name': 'N', 'unit': 'bag', 'unitPrice': 1, 'currentStock': 4, 'lowStockThreshold': 2});
      expect([old.reserved, old.incoming, old.maxCapacity], [0, 0, null]);
    });
  });

  group('what goes over the wire', () {
    late List<http.Request> seen;
    ApiClient client(Map<String, Object?> reply) {
      seen = [];
      return ApiClient(
        deviceId: () async => 'op',
        client: MockClient((req) async {
          seen.add(req);
          return http.Response(jsonEncode(reply), 201);
        }),
      );
    }

    const shelf = {'id': 'p1', 'name': 'Neem Cake', 'unit': 'bag', 'unitPrice': 600, 'currentStock': 18, 'lowStockThreshold': 5};

    test('receiving sends the count, and reports a mismatch with the note', () async {
      final ds = InventoryApiDataSource(client({...shelf, 'discrepancy': {'id': 'd1', 'expected': 10, 'received': 8}}));
      final result = await ds.receiveStock(productId: 'p1', quantity: 8, expectedQuantity: 10, note: '  2 bags torn ');
      final body = jsonDecode(seen.single.body) as Map<String, dynamic>;
      expect(seen.single.url.path, '/v1/operator/inventory/receive');
      expect(body, {'productId': 'p1', 'quantity': 8, 'expectedQuantity': 10, 'note': '2 bags torn'});
      expect(result.discrepancy, const DiscrepancyReport(expected: 10, received: 8));
      expect(result.item.currentStock, 18);
    });

    test('a plain receipt sends no expected count and no note', () async {
      final ds = InventoryApiDataSource(client(shelf));
      final result = await ds.receiveStock(productId: 'p1', quantity: 8, note: '   ');
      expect(jsonDecode(seen.single.body), {'productId': 'p1', 'quantity': 8});
      expect(result.discrepancy, isNull);
    });

    test('settings: a value is sent as given, and "no limit" is an explicit null', () async {
      final ds = InventoryApiDataSource(client(shelf));
      await ds.updateSettings(productId: 'p1', reorderLevel: 8, maxCapacity: 50);
      expect(seen.last.method, 'PATCH');
      expect(jsonDecode(seen.last.body), {'reorderLevel': 8, 'maxCapacity': 50});
      await ds.updateSettings(productId: 'p1', reorderLevel: 8, clearCapacity: true);
      expect(jsonDecode(seen.last.body), {'reorderLevel': 8, 'maxCapacity': null});
      await ds.updateSettings(productId: 'p1', reorderLevel: 8);
      expect(jsonDecode(seen.last.body), {'reorderLevel': 8}, reason: 'leaving capacity alone sends nothing about it');
    });

    test('the farmer list parses real customers (no crop or phone) and keeps the order count', () async {
      final ds = FarmersApiDataSource(client({}));
      final http = MockClient((req) async => _json([
            {'id': 'u1', 'name': 'Asha Patil', 'village': 'Shirur, Pune', 'phone': '', 'activeCrop': '', 'notes': '', 'lastVisitDate': '2026-09-20T05:00:00Z', 'ordersCount': 3, 'needsFollowUp': false},
          ]));
      final farmers = await FarmersApiDataSource(ApiClient(client: http, deviceId: () async => 'op')).fetchFarmers();
      expect(farmers.single.ordersCount, 3);
      expect(farmers.single.activeCrop, '');
      expect(ds, isNotNull);
    });
  });

  group('receive stock', () {
    Future<FakeInventoryRepository> pumpHost(WidgetTester tester, {InventoryItem? existing, FakeInventoryRepository? repo}) async {
      await _mobile(tester, height: 1400);
      final fake = repo ?? FakeInventoryRepository(items: [?existing]);
      await tester.pumpWidget(_app(
        Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => showReceiveStock(context, item: existing), child: const Text('open')))),
        [
          inventoryRepositoryProvider.overrideWithValue(fake),
          productsProvider.overrideWith((ref) async => [neemCake]),
        ],
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return fake;
    }

    Future<void> field(WidgetTester tester, String label, String value) async {
      await tester.enterText(find.widgetWithText(TextField, label), value);
      await tester.pump();
    }

    Future<void> chooseProduct(WidgetTester tester) async {
      await tester.tap(find.byType(DropdownButtonFormField<Product>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neem Cake (5 kg bag)').last);
      await tester.pumpAndSettle();
    }

    testWidgets('a product the center has never stocked is picked from the catalog and added', (tester) async {
      final repo = await pumpHost(tester);
      expect(find.text('Receive stock'), findsOneWidget);
      await chooseProduct(tester);
      await field(tester, 'How many arrived', '8');
      await tester.tap(find.text('Add to stock'));
      await tester.pumpAndSettle();

      expect(repo.receiveCalls.single, (productId: 'p-neemcake', quantity: 8, expected: null, note: null));
      expect(find.text('Neem Cake stock is now 8'), findsOneWidget);
      expect(find.text('Add to stock'), findsNothing, reason: 'the sheet closed');
    });

    testWidgets('an existing product has no picker and shows what is on hand', (tester) async {
      final repo = await pumpHost(tester, existing: shelfItem('p-neemcake', onHand: 12));
      expect(find.byType(DropdownButtonFormField<Product>), findsNothing);
      expect(find.text('Neem Cake: 12 on hand now'), findsOneWidget);
      await field(tester, 'How many arrived', '5');
      await tester.tap(find.text('Add to stock'));
      await tester.pumpAndSettle();
      expect(repo.receiveCalls.single.productId, 'p-neemcake');
      expect(find.text('Neem Cake stock is now 17'), findsOneWidget);
    });

    testWidgets('missing or impossible input is explained and nothing is sent', (tester) async {
      final repo = await pumpHost(tester);
      await tester.tap(find.text('Add to stock'));
      await tester.pump();
      expect(find.text('Choose a product.'), findsOneWidget);

      await chooseProduct(tester);
      await tester.tap(find.text('Add to stock'));
      await tester.pump();
      expect(find.text('Enter how many arrived (at least 1).'), findsOneWidget);

      await field(tester, 'How many arrived', '8');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('Add to stock'));
      await tester.pump();
      expect(find.text('Enter how many you expected.'), findsOneWidget);

      await field(tester, 'How many you expected', '8');
      await tester.tap(find.text('Add to stock'));
      await tester.pump();
      expect(find.textContaining('nothing to report'), findsOneWidget);
      expect(repo.receiveCalls, isEmpty);
    });

    testWidgets('a count that differs from what was expected is reported, and the farmer-facing shelf still gets what arrived', (tester) async {
      final repo = await pumpHost(tester);
      await chooseProduct(tester);
      await field(tester, 'How many arrived', '8');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await field(tester, 'How many you expected', '10');
      await field(tester, 'What happened (optional)', '2 bags were torn');
      await tester.tap(find.text('Add to stock'));
      await tester.pumpAndSettle();

      expect(repo.receiveCalls.single, (productId: 'p-neemcake', quantity: 8, expected: 10, note: '2 bags were torn'));
      expect(find.textContaining('Reported: expected 10, counted 8'), findsOneWidget);
    });

    testWidgets('a server refusal (over capacity) stays on the sheet with the input intact', (tester) async {
      final repo = FakeInventoryRepository(items: [shelfItem('p-neemcake', onHand: 38, capacity: 40)])
        ..receiveError = ApiException("That would exceed this center's storage capacity for the product", statusCode: 409);
      await pumpHost(tester, existing: shelfItem('p-neemcake', onHand: 38, capacity: 40), repo: repo);
      await field(tester, 'How many arrived', '9');
      await tester.tap(find.text('Add to stock'));
      await tester.pumpAndSettle();
      expect(find.textContaining('exceed'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('Add to stock'), findsOneWidget);
    });
  });

  group('item settings', () {
    Future<FakeInventoryRepository> pump(WidgetTester tester, InventoryItem item) async {
      await _mobile(tester);
      final repo = FakeInventoryRepository(items: [item]);
      await tester.pumpWidget(_app(
        Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => showAdaptiveModal<bool>(context: context, builder: (_) => ItemSettingsSheet(item: item)), child: const Text('open')))),
        [inventoryRepositoryProvider.overrideWithValue(repo)],
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('saves a new reorder level and capacity', (tester) async {
      final repo = await pump(tester, shelfItem('p1', onHand: 10, reorder: 5));
      await tester.enterText(find.widgetWithText(TextField, 'Reorder level'), '8');
      await tester.enterText(find.widgetWithText(TextField, 'Storage capacity (optional)'), '50');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.settingsCalls.single, (productId: 'p1', reorderLevel: 8, maxCapacity: 50, clearCapacity: false));
    });

    testWidgets('emptying the capacity removes the limit', (tester) async {
      final repo = await pump(tester, shelfItem('p1', onHand: 10, capacity: 40));
      await tester.enterText(find.widgetWithText(TextField, 'Storage capacity (optional)'), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.settingsCalls.single.clearCapacity, isTrue);
      expect(repo.settingsCalls.single.maxCapacity, isNull);
    });

    testWidgets('a capacity below what is on hand is refused before asking the server', (tester) async {
      final repo = await pump(tester, shelfItem('p1', onHand: 30));
      await tester.enterText(find.widgetWithText(TextField, 'Storage capacity (optional)'), '10');
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Capacity cannot be below the 30 you have on hand.'), findsOneWidget);
      expect(repo.settingsCalls, isEmpty);
    });
  });

  group('inventory screen', () {
    Future<void> pump(WidgetTester tester, FakeInventoryRepository repo, {Size size = const Size(420, 2000)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const InventoryScreen(), [
        inventoryRepositoryProvider.overrideWithValue(repo),
        productsProvider.overrideWith((ref) async => [neemCake]),
      ]));
      await tester.pumpAndSettle();
    }

    testWidgets('a new center starts with empty shelves and a clear way to fill them', (tester) async {
      await pump(tester, FakeInventoryRepository());
      expect(find.text('Your shelves are empty'), findsOneWidget);
      expect(find.text('Receive stock'), findsNWidgets(2), reason: 'the header button and the empty-state button');
    });

    testWidgets('each product shows what can be sold, what is held, and what is on its way; low stock comes first', (tester) async {
      await pump(
        tester,
        FakeInventoryRepository(items: [
          shelfItem('healthy', name: 'Healthy Product', onHand: 100, reorder: 5),
          shelfItem('low', name: 'Low Product', onHand: 10, reserved: 7, reorder: 5, incoming: 30, capacity: 60),
          shelfItem('gone', name: 'Gone Product', onHand: 0, reorder: 5),
        ]),
      );
      expect(find.text('3 bags to sell'), findsOneWidget);
      expect(find.text('10 on hand · 7 held for app orders · 30 arriving · room for 60'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('100 bags to sell'), findsOneWidget);
      final lowY = tester.getTopLeft(find.text('Low Product')).dy;
      final healthyY = tester.getTopLeft(find.text('Healthy Product')).dy;
      expect(lowY, lessThan(healthyY));
      expect(find.text('Receive'), findsNWidgets(3));
      expect(find.byTooltip('Reorder level and capacity'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('restock requests say where they stand', (tester) async {
      await pump(
        tester,
        FakeInventoryRepository(
          items: [shelfItem('p')],
          requests: [
            RestockRequest(id: 'r1', itemId: 'p', itemName: 'Neem Cake', requestedQuantity: 20, status: RestockRequestStatus.pending, requestedDate: DateTime(2026, 9, 24)),
            RestockRequest(id: 'r2', itemId: 'p', itemName: 'Vermicompost', requestedQuantity: 10, status: RestockRequestStatus.approved, requestedDate: DateTime(2026, 9, 24)),
            RestockRequest(id: 'r3', itemId: 'p', itemName: 'Old One', requestedQuantity: 5, status: RestockRequestStatus.fulfilled, requestedDate: DateTime(2026, 9, 20)),
          ],
        ),
      );
      expect(find.text('Waiting for approval'), findsOneWidget);
      expect(find.text('Approved, on its way'), findsOneWidget);
      expect(find.textContaining('Old One'), findsNothing, reason: 'delivered ones are done');
    });

    testWidgets('tablet width lays tiles out without overflow', (tester) async {
      await pump(tester, FakeInventoryRepository(items: [shelfItem('a', reserved: 4, incoming: 9, capacity: 50), shelfItem('b', name: 'Second')]), size: const Size(1100, 900));
      expect(tester.takeException(), isNull);
    });
  });

  group('my center', () {
    Future<FakeOperatorCenterRepository> pump(WidgetTester tester, {OperatorCenter? center}) async {
      await _mobile(tester);
      final repo = FakeOperatorCenterRepository(center);
      await tester.pumpWidget(_app(const Scaffold(body: SingleChildScrollView(child: MyCenterCard())), [operatorCenterRepositoryProvider.overrideWithValue(repo)]));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('shows the real center, not a hard-coded one', (tester) async {
      await pump(tester);
      expect(find.text('Shirur Kendra'), findsOneWidget);
      expect(find.text('Shirur, Pune'), findsOneWidget);
      expect(find.text('Open for farmers'), findsOneWidget);
      expect(find.text('Hours 09:00 – 18:00 · 98220 11111'), findsOneWidget);
    });

    testWidgets('the open/closed switch tells the server and confirms', (tester) async {
      final repo = await pump(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(repo.updates.single['isOpen'], false);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('You are now closed to farmers'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(repo.updates.last['isOpen'], true);
      expect(find.text('Open for farmers'), findsOneWidget);
    });

    testWidgets('contact details can be edited; the hours already set are kept', (tester) async {
      final repo = await pump(tester, center: operatorCenter(opens: '08:30', closes: '17:00'));
      await tester.tap(find.byTooltip('Edit hours and contact'));
      await tester.pumpAndSettle();
      expect(find.text('Opens 08:30'), findsOneWidget);
      expect(find.text('Closes 17:00'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Phone (farmers can call this)'), '99999 22222');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.updates.single, {'isOpen': null, 'opensAt': '08:30', 'closesAt': '17:00', 'phone': '99999 22222', 'operatorName': 'Olga'});
      expect(find.textContaining('99999 22222'), findsOneWidget);
    });
  });

  group('walk-in sales', () {
    Future<({FakeInventoryRepository inventory, FakeOperatorOrdersRepository orders})> pump(WidgetTester tester, List<InventoryItem> items) async {
      await _mobile(tester, height: 1600);
      final inventory = FakeInventoryRepository(items: items);
      final orders = FakeOperatorOrdersRepository();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, _) => const Scaffold(body: WalkInPosScreen())),
        GoRoute(path: RoutePaths.operatorOrderDetailPattern, builder: (context, state) => Text('sale ${state.pathParameters['orderId']}')),
        GoRoute(path: RoutePaths.operatorInventory, builder: (context, _) => const Text('inventory page')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [inventoryRepositoryProvider.overrideWithValue(inventory), op.ordersRepositoryProvider.overrideWithValue(orders)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ));
      await tester.pumpAndSettle();
      return (inventory: inventory, orders: orders);
    }

    testWidgets('sells by product, so the shelf can be reduced', (tester) async {
      final h = await pump(tester, [shelfItem('p-neemcake', onHand: 10)]);
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pump();
      await tester.tap(find.text('Complete sale'));
      await tester.pumpAndSettle();
      expect(h.orders.walkIns.single.single.productId, 'p-neemcake');
      expect(h.orders.walkIns.single.single.quantity, 2);
      expect(find.text('sale walk-1'), findsOneWidget);
    });

    testWidgets('cannot add more than can be sold, and says what is held back', (tester) async {
      await pump(tester, [shelfItem('p-neemcake', onHand: 5, reserved: 3)]);
      expect(find.text('2 to sell (3 held for app orders)'), findsOneWidget);
      final add = find.widgetWithIcon(IconButton, Icons.add_circle_outline_rounded);
      await tester.tap(add);
      await tester.tap(add);
      await tester.pump();
      expect(find.text('2'), findsWidgets);
      expect(tester.widget<IconButton>(add).onPressed, isNull, reason: 'two is all that is not spoken for');
    });

    testWidgets('an item with nothing to sell cannot be added', (tester) async {
      await pump(tester, [shelfItem('p-neemcake', onHand: 3, reserved: 3)]);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_circle_outline_rounded)).onPressed, isNull);
    });

    testWidgets("the server's refusal is shown and the cart is kept", (tester) async {
      final h = await pump(tester, [shelfItem('p-neemcake', onHand: 10)]);
      h.orders.walkInError = ApiException('Only 2 of Neem Cake available (3 more reserved for app orders), you asked for 3', statusCode: 409);
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pump();
      await tester.tap(find.text('Complete sale'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Only 2 of Neem Cake available'), findsOneWidget);
      expect(find.text('Complete sale'), findsOneWidget);
    });

    testWidgets('empty shelves lead to the inventory instead of a blank till', (tester) async {
      await pump(tester, []);
      expect(find.text('Your shelves are empty'), findsOneWidget);
      await tester.tap(find.text('Go to inventory'));
      await tester.pumpAndSettle();
      expect(find.text('inventory page'), findsOneWidget);
    });
  });

  group('notifications for the operator', () {
    SessionProfile me(AppRole role) => SessionProfile(userId: 'u', email: 'e', name: 'n', role: role, requestedRole: role.name, status: 'active');

    Future<FakeNotificationsRepository> pump(WidgetTester tester, AppRole role, List<AppNotification> items) async {
      await _mobile(tester);
      final repo = FakeNotificationsRepository(items);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, _) => const Scaffold(body: NotificationsScreen())),
        GoRoute(path: RoutePaths.operatorOrderDetailPattern, builder: (context, state) => Text('operator order ${state.pathParameters['orderId']}')),
        GoRoute(path: RoutePaths.operatorInventory, builder: (context, _) => const Text('operator inventory')),
        GoRoute(path: '${RoutePaths.farmerOrders}/:orderId', builder: (context, state) => Text('farmer order ${state.pathParameters['orderId']}')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [notificationsRepositoryProvider.overrideWithValue(repo), sessionProfileProvider.overrideWith((ref) async => me(role))],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('every kind of notification renders, including ones the app has no special handling for', (tester) async {
      await pump(tester, AppRole.operator, [
        note('1', NotificationType.order, title: 'New app order'),
        note('2', NotificationType.stock, title: 'Low stock: Neem Cake'),
        note('3', NotificationType.restock, title: 'Restock approved'),
        note('4', NotificationType.account, title: 'Your account was reactivated'),
        note('5', NotificationType.other, title: 'Something new'),
      ]);
      for (final t in ['New app order', 'Low stock: Neem Cake', 'Restock approved', 'Your account was reactivated', 'Something new']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('an operator opening an order notification goes to that order to prepare it', (tester) async {
      final repo = await pump(tester, AppRole.operator, [note('1', NotificationType.order, title: 'New app order', refId: 'order-42')]);
      await tester.tap(find.text('New app order'));
      await tester.pumpAndSettle();
      expect(repo.read, ['1']);
      expect(find.text('operator order order-42'), findsOneWidget);
    });

    testWidgets('a farmer opening the same kind goes to their own order, with the pickup code', (tester) async {
      await pump(tester, AppRole.farmer, [note('1', NotificationType.order, title: 'Order placed', refId: 'order-42')]);
      await tester.tap(find.text('Order placed'));
      await tester.pumpAndSettle();
      expect(find.text('farmer order order-42'), findsOneWidget);
    });

    testWidgets('a low-stock alert takes the operator to the inventory; an account notice goes nowhere', (tester) async {
      await pump(tester, AppRole.operator, [
        note('1', NotificationType.stock, title: 'Low stock: Neem Cake', refId: 'p-neemcake'),
        note('2', NotificationType.account, title: 'Your account was reactivated'),
      ]);
      await tester.tap(find.text('Your account was reactivated'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget, reason: 'stayed on the list');
      await tester.tap(find.text('Low stock: Neem Cake'));
      await tester.pumpAndSettle();
      expect(find.text('operator inventory'), findsOneWidget);
    });

    testWidgets('the bell shows how many are unread', (tester) async {
      await _mobile(tester);
      final repo = FakeNotificationsRepository([note('1', NotificationType.order), note('2', NotificationType.stock), note('3', NotificationType.stock, read: true)]);
      await tester.pumpWidget(_app(const Scaffold(body: OperatorNotificationBell()), [notificationsRepositoryProvider.overrideWithValue(repo)]));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(find.byTooltip('2 unread notifications'), findsOneWidget);
    });

    testWidgets('no badge when everything has been read', (tester) async {
      await _mobile(tester);
      final repo = FakeNotificationsRepository([note('1', NotificationType.order, read: true)]);
      await tester.pumpWidget(_app(const Scaffold(body: OperatorNotificationBell()), [notificationsRepositoryProvider.overrideWithValue(repo)]));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsOneWidget);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    });
  });

  group('farmer list', () {
    Farmer farmer({String crop = '', String village = 'Shirur, Pune', int orders = 2}) => Farmer(
          id: 'u1',
          name: 'Asha Patil',
          village: village,
          phone: '',
          activeCrop: crop,
          lastVisitDate: DateTime.now().subtract(const Duration(days: 3)),
          needsFollowUp: false,
          notes: '',
          ordersCount: orders,
        );

    testWidgets('a real customer shows their village and order count, with no dangling crop separator', (tester) async {
      await _mobile(tester);
      await tester.pumpWidget(_app(Scaffold(body: FarmerCard(farmer: farmer(), onTap: () {})), []));
      expect(find.text('Shirur, Pune · 2 orders'), findsOneWidget);
      expect(find.text('Last order: 3 days ago'), findsOneWidget);
    });

    testWidgets('a crop, when known, is still shown; one order is singular', (tester) async {
      await _mobile(tester);
      await tester.pumpWidget(_app(Scaffold(body: FarmerCard(farmer: farmer(crop: 'Wheat', orders: 1), onTap: () {})), []));
      expect(find.text('Shirur, Pune · Wheat · 1 order'), findsOneWidget);
    });
  });
}

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});
