import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khaadsetu_version1/core/network/api_client.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/entities/product.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:khaadsetu_version1/features/operator/inventory/presentation/providers/inventory_providers.dart';
import 'package:khaadsetu_version1/features/operator/surplus/data/surplus_api_repository.dart';
import 'package:khaadsetu_version1/features/operator/surplus/domain/entities/surplus_lot.dart';
import 'package:khaadsetu_version1/features/operator/surplus/presentation/providers/surplus_providers.dart';
import 'package:khaadsetu_version1/features/operator/surplus/presentation/screens/surplus_screen.dart';
import 'package:khaadsetu_version1/features/operator/surplus/presentation/widgets/create_surplus_sheet.dart';

import 'support/farmer_fakes.dart' show neemCake;
import 'support/operator_fakes.dart';

Widget _app(Widget home, List<Override> overrides) =>
    ProviderScope(overrides: overrides, child: MaterialApp(theme: AppTheme.light, home: home));

Future<void> _size(WidgetTester tester, {Size size = const Size(420, 2000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('the rules for a new lot', () {
    String? problem({bool hasProduct = true, int? qty = 3, double? price = 400, double? catalog = 600, bool fromShelf = false, int free = 10}) =>
        surplusProblem(hasProduct: hasProduct, quantity: qty, price: price, catalogPrice: catalog, fromShelf: fromShelf, shelfAvailable: free);

    test('a complete, cheaper offer is fine', () => expect(problem(), isNull));

    test('each missing piece is named', () {
      expect(problem(hasProduct: false), 'Choose a product.');
      expect(problem(qty: null), contains('how many'));
      expect(problem(qty: 0), contains('how many'));
      expect(problem(price: null), contains('price'));
    });

    test('the price must be below the regular price, and says what that is', () {
      expect(problem(price: 600), 'The surplus price must be lower than the regular price (Rs 600).');
      expect(problem(price: 700), contains('lower than the regular price'));
      expect(problem(price: 0), isNull, reason: 'free is still cheaper');
      expect(problem(catalog: 599.5, price: 599.5), contains('Rs 599.50'));
    });

    test('taking from the shelf is limited to what is free there', () {
      expect(problem(fromShelf: true, qty: 10, free: 10), isNull);
      expect(problem(fromShelf: true, qty: 11, free: 10), contains('Only 10 are free'));
      expect(problem(fromShelf: true, qty: 1, free: 0), contains('None of this product'));
      expect(problem(fromShelf: false, qty: 99, free: 0), isNull, reason: 'outside units are not limited by the shelf');
    });
  });

  group('lots from the server', () {
    SurplusLot lot(Map<String, Object?> extra) => SurplusLot.fromJson({
          'id': 'lot-1', 'productId': 'p-neemcake', 'productName': 'Neem Cake', 'unit': '5 kg bag',
          'catalogPrice': 600, 'unitPrice': 450, 'quantity': 5, 'reserved': 2, 'available': 3,
          'condition': 'damaged_packaging', 'bestBefore': '2026-11-30', 'note': 'Torn', 'fromShelf': true, 'status': 'active',
          ...extra,
        });

    test('parses, and works out the discount and what is left', () {
      final l = lot({});
      expect(l.discountPercent, 25);
      expect(l.available, 3);
      expect(l.condition, SurplusCondition.damagedPackaging);
      expect(l.bestBefore, DateTime(2026, 11, 30));
      expect(l.fromShelf, isTrue);
      expect(l.isOnSale, isTrue);
    });

    test('an unknown condition or status never breaks the list', () {
      final l = lot({'condition': 'from-the-future', 'status': 'mystery', 'bestBefore': null});
      expect(l.condition, SurplusCondition.other);
      expect(l.status, SurplusStatus.active);
      expect(l.bestBefore, isNull);
    });

    test('the API repository sends the right requests', () async {
      final seen = <String>[];
      final client = MockClient((req) async {
        seen.add('${req.method} ${req.url.path} ${req.body}');
        final body = jsonEncode({
          'id': 'lot-1', 'productId': 'p-neemcake', 'productName': 'Neem Cake', 'unit': 'bag', 'catalogPrice': 600, 'unitPrice': 450,
          'quantity': 5, 'reserved': 0, 'condition': 'other', 'status': 'active', 'bestBefore': null, 'note': '', 'fromShelf': false,
        });
        return http.Response(req.method == 'GET' ? '[$body]' : body, 200, headers: {'content-type': 'application/json'});
      });
      final repo = SurplusApiRepository(ApiClient(client: client, deviceId: () async => 'op'));
      expect((await repo.lots()).single.id, 'lot-1');
      await repo.create(productId: 'p-neemcake', quantity: 5, unitPrice: 450, condition: SurplusCondition.nearExpiry, bestBefore: DateTime(2026, 3, 9), note: ' Torn ', fromShelf: true);
      await repo.update('lot-1', unitPrice: 300);
      await repo.withdraw('lot-1');

      expect(seen[0], 'GET /v1/operator/surplus ');
      final create = jsonDecode(seen[1].substring(seen[1].indexOf('{'))) as Map<String, dynamic>;
      expect(seen[1], startsWith('POST /v1/operator/surplus '));
      expect(create, {'productId': 'p-neemcake', 'quantity': 5, 'unitPrice': 450.0, 'condition': 'near_expiry', 'bestBefore': '2026-03-09', 'note': 'Torn', 'fromShelf': true});
      expect(seen[2], 'PATCH /v1/operator/surplus/lot-1 {"unitPrice":300.0}');
      expect(seen[3], startsWith('POST /v1/operator/surplus/lot-1/withdraw'));
    });
  });

  group('surplus screen', () {
    Future<FakeSurplusRepository> pump(WidgetTester tester, List<SurplusLot> lots, {Size size = const Size(420, 2000)}) async {
      await _size(tester, size: size);
      final repo = FakeSurplusRepository(lots);
      await tester.pumpWidget(_app(const Scaffold(body: SurplusScreen()), [
        surplusRepositoryProvider.overrideWithValue(repo),
        inventoryRepositoryProvider.overrideWithValue(FakeInventoryRepository(items: [shelfItem('p-neemcake', onHand: 20, reserved: 5)])),
        productsProvider.overrideWith((ref) async => [neemCake]),
      ]));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('no lots: explains what surplus is and how to start', (tester) async {
      await pump(tester, []);
      expect(find.text('No surplus on sale'), findsOneWidget);
      expect(find.textContaining('near-expiry'), findsWidgets);
      expect(find.text('List surplus'), findsOneWidget);
    });

    testWidgets('an offer shows the price against the regular one, the discount, what is left and why it is cheaper', (tester) async {
      await pump(tester, [
        surplusLot('a', price: 450, quantity: 5, reserved: 2, condition: SurplusCondition.damagedPackaging, bestBefore: DateTime(2026, 11, 30), note: 'Torn stitching', fromShelf: true),
      ]);
      expect(find.text('Neem Cake'), findsOneWidget);
      expect(find.text('Rs 450'), findsOneWidget);
      expect(find.text('Rs 600'), findsOneWidget);
      expect(find.text('25% off'), findsOneWidget);
      expect(find.text('3 available, 2 held by orders · bag'), findsOneWidget);
      expect(find.text('Damaged packaging · best before 30/11/2026 · from your shelf'), findsOneWidget);
      expect(find.text('Torn stitching'), findsOneWidget);
      expect(find.text('On sale'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ended offers are kept apart and cannot be edited or withdrawn', (tester) async {
      await pump(tester, [
        surplusLot('live', name: 'Live One'),
        surplusLot('gone', name: 'Gone One', status: SurplusStatus.withdrawn, quantity: 0),
        surplusLot('old', name: 'Old One', status: SurplusStatus.expired),
      ]);
      expect(find.text('On sale (1)'), findsOneWidget);
      expect(find.text('Ended (2)'), findsOneWidget);
      expect(find.text('Live One'), findsOneWidget);
      expect(find.text('Gone One'), findsNothing);

      await tester.tap(find.text('Ended (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Gone One'), findsOneWidget);
      expect(find.text('Old One'), findsOneWidget);
      expect(find.text('Withdrawn'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Withdraw'), findsNothing);
    });

    testWidgets('withdrawing asks first, says what happens to held and shelf units, and only then does it', (tester) async {
      final repo = await pump(tester, [surplusLot('a', reserved: 2, fromShelf: true)]);
      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();
      expect(find.text('Withdraw this offer?'), findsOneWidget);
      expect(find.textContaining('2 units are held by orders'), findsOneWidget);
      expect(find.textContaining('go back on your shelf'), findsOneWidget);

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(repo.withdrawn, isEmpty);

      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Withdraw'));
      await tester.pumpAndSettle();
      expect(repo.withdrawn, ['a']);
      expect(find.text('Offer withdrawn'), findsOneWidget);
      expect(find.text('On sale (0)'), findsOneWidget);
    });

    testWidgets('editing the price checks it is below the regular price, then saves only what changed', (tester) async {
      final repo = await pump(tester, [surplusLot('a', price: 450)]);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Edit surplus offer'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Price each (Rs)'), '600');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('must be lower than the regular price'), findsOneWidget);
      expect(repo.updates, isEmpty);

      await tester.enterText(find.widgetWithText(TextField, 'Price each (Rs)'), '300');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.updates, ['a:300.0:-']);
      expect(find.text('Rs 300'), findsOneWidget);
      expect(find.text('50% off'), findsOneWidget);
    });

    testWidgets('a load failure offers a retry', (tester) async {
      await _size(tester);
      await tester.pumpWidget(_app(const Scaffold(body: SurplusScreen()), [surplusLotsProvider.overrideWith((ref) async => throw Exception('offline'))]));
      await tester.pumpAndSettle();
      expect(find.textContaining('offline'), findsOneWidget);
    });

    testWidgets('tablet width has no overflow', (tester) async {
      await pump(tester, [surplusLot('a', note: 'x' * 120), surplusLot('b', name: 'A Product With A Rather Long Name Indeed')], size: const Size(1100, 900));
      expect(tester.takeException(), isNull);
    });
  });

  group('list surplus sheet', () {
    Future<FakeSurplusRepository> pumpSheet(WidgetTester tester, {FakeSurplusRepository? repo, bool fromShelf = false}) async {
      await _size(tester, size: const Size(420, 2200));
      final fake = repo ?? FakeSurplusRepository();
      final shelf = shelfItem('p-neemcake', onHand: 20, reserved: 5); // 15 free
      await tester.pumpWidget(_app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => CreateSurplusSheet(shelfItem: fromShelf ? shelf : null)),
              child: const Text('open'),
            ),
          ),
        ),
        [
          surplusRepositoryProvider.overrideWithValue(fake),
          inventoryRepositoryProvider.overrideWithValue(FakeInventoryRepository(items: [shelf])),
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

    testWidgets('outside units: pick a product, see the regular price, and list them', (tester) async {
      final repo = await pumpSheet(tester);
      await chooseProduct(tester);
      expect(find.text('Regular: Rs 600'), findsOneWidget);
      await field(tester, 'How many', '4');
      await field(tester, 'Price each (Rs)', '450');
      await tester.tap(find.text('List surplus').last);
      await tester.pumpAndSettle();

      expect(repo.created, hasLength(1));
      expect(repo.created.single['productId'], 'p-neemcake');
      expect(repo.created.single['quantity'], 4);
      expect(repo.created.single['price'], 450.0);
      expect(repo.created.single['condition'], SurplusCondition.nearExpiry);
      expect(repo.created.single['fromShelf'], false);
      expect(find.text('Sell as surplus'), findsNothing, reason: 'the sheet closed');
    });

    testWidgets('a price at or above the regular one is refused before asking the server', (tester) async {
      final repo = await pumpSheet(tester);
      await chooseProduct(tester);
      await field(tester, 'How many', '4');
      await field(tester, 'Price each (Rs)', '600');
      await tester.tap(find.text('List surplus').last);
      await tester.pumpAndSettle();
      expect(find.text('The surplus price must be lower than the regular price (Rs 600).'), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('nothing chosen yet: says so instead of sending', (tester) async {
      final repo = await pumpSheet(tester);
      await tester.tap(find.text('List surplus').last);
      await tester.pumpAndSettle();
      expect(find.text('Choose a product.'), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('from a shelf product: no picker, the switch is on, and it will not take more than is free', (tester) async {
      final repo = await pumpSheet(tester, fromShelf: true);
      expect(find.byType(DropdownButtonFormField<Product>), findsNothing);
      expect(find.text('15 free on your shelf now. They come off the shelf and go back if you withdraw the offer.'), findsOneWidget);

      await field(tester, 'How many', '16');
      await field(tester, 'Price each (Rs)', '300');
      await tester.tap(find.text('List surplus').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Only 15 are free'), findsOneWidget);
      expect(repo.created, isEmpty);

      await field(tester, 'How many', '15');
      await tester.tap(find.text('List surplus').last);
      await tester.pumpAndSettle();
      expect(repo.created.single['fromShelf'], true);
      expect(repo.created.single['quantity'], 15);
    });

    testWidgets('the condition and note are sent; a server refusal stays on the sheet with the input intact', (tester) async {
      final repo = await pumpSheet(tester, repo: FakeSurplusRepository()..createError = Exception('A surplus price must be lower than the regular price (Rs 600)'));
      await chooseProduct(tester);
      await field(tester, 'How many', '2');
      await field(tester, 'Price each (Rs)', '100');
      await field(tester, 'Note for farmers (optional)', 'Opened, half used');
      await tester.tap(find.byType(DropdownButtonFormField<SurplusCondition>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Opened pack').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('List surplus').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('A surplus price must be lower'), findsOneWidget);
      expect(find.text('Sell as surplus'), findsOneWidget, reason: 'still open so nothing is lost');
      expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Price each (Rs)')).controller!.text, '100');

      repo.createError = null;
      await tester.tap(find.text('List surplus').last);
      await tester.pumpAndSettle();
      expect(repo.created.single['condition'], SurplusCondition.opened);
      expect(repo.created.single['note'], 'Opened, half used');
    });
  });
}
