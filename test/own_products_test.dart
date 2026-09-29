import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/core/widgets/kit.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/nearby_center.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/own_products/my_listings_screen.dart';
import 'package:khaadsetu_version1/features/own_products/own_api.dart';
import 'package:khaadsetu_version1/features/own_products/own_market_screens.dart';
import 'package:khaadsetu_version1/features/own_products/own_sales_screens.dart';

/// A settled location, so the market never tries a real GPS or network lookup in a test.
class _NoLocation extends FarmerLocationNotifier {
  @override
  Future<FarmerLocation?> build() async => null;
}

class FakeOwn implements OwnApi {
  final marketAsked = <String?>[];
  final calls = <String>[];
  Json saleData = {'id': 's1', 'role': 'buyer', 'status': 'placed', 'listingName': 'Vermicompost', 'quantity': 10, 'unit': 'kg', 'unitPrice': 20, 'total': 200, 'fulfilment': 'farm_pickup', 'sellerName': 'Ganesh', 'sellerPhone': '9822000002', 'pickupCode': '4821', 'reviewed': false};

  @override
  Future<List<Json>> market({String? category, String sort = 'nearest', double? latitude, double? longitude, String? q}) async {
    marketAsked.add('$category|$sort');
    return [{'id': 'l1', 'name': 'Vermicompost', 'pricePerUnit': 20, 'unit': 'kg', 'quantityAvailable': 100, 'sellerName': 'Ganesh', 'village': 'Shirur', 'distanceKm': 3.2, 'ratingCount': 2, 'ratingAvg': 4.5}];
  }

  @override
  Future<List<Json>> mine() async => [
        {'id': 'l1', 'name': 'Vermicompost', 'status': 'rejected', 'pricePerUnit': 20, 'unit': 'kg', 'quantityAvailable': 50, 'soldCount': 0, 'rejectionReason': 'Photos are blurry'},
        {'id': 'l2', 'name': 'Jeevamrut', 'status': 'approved', 'pricePerUnit': 40, 'unit': 'litre', 'quantityAvailable': 20, 'soldCount': 3},
      ];

  @override
  Future<Json> summary() async => {'sales': {'earned': 1500, 'month': 400, 'owed': 60}};

  @override
  Future<Json> sale(String id) async => saleData;

  @override
  Future<List<Json>> sales(String role) async => role == 'buyer' ? [saleData] : [];

  @override
  Future<Json> cancel(String id, {String reason = ''}) async {
    calls.add('cancel');
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pump(WidgetTester tester, Widget home, FakeOwn fake) async {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<Override> overrides = [
    ownApiProvider.overrideWithValue(fake),
    apiImageProvider.overrideWith((ref, path) async => throw 'no photos in tests'),
    farmerLocationProvider.overrideWith(_NoLocation.new),
  ];
  await tester.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp(theme: AppTheme.light, home: home)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the market shows farmer-made products with distance and re-asks when the sort changes', (tester) async {
    final fake = FakeOwn();
    await pump(tester, const OwnMarketScreen(), fake);
    expect(find.text('Farmer-made'), findsOneWidget);
    expect(find.textContaining('3.2 km'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sort-cheapest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cat-compost')));
    await tester.pumpAndSettle();
    expect(fake.marketAsked.last, 'compost|cheapest');
  });

  testWidgets('my products show their check, the reason a listing was sent back, and earnings', (tester) async {
    await pump(tester, const MyListingsScreen(), FakeOwn());
    expect(find.text('Sent back'), findsOneWidget);
    expect(find.text('On sale'), findsOneWidget);
    expect(find.textContaining('Photos are blurry'), findsOneWidget);
    expect(find.text('₹1,500'), findsOneWidget);
  });

  testWidgets('the buyer sees the pickup code and can cancel; the seller side has no code shown', (tester) async {
    final fake = FakeOwn();
    await pump(tester, const OwnSaleScreen(saleId: 's1'), fake);
    expect(find.byKey(const Key('pickup-code')), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('sale-cancel')));
    await tester.tap(find.byKey(const Key('sale-cancel')));
    await tester.pumpAndSettle();
    expect(fake.calls, ['cancel']);
  });

  testWidgets('the seller enters the buyer code and chooses how he was paid', (tester) async {
    final fake = FakeOwn()..saleData = {'id': 's1', 'role': 'seller', 'status': 'ready', 'listingName': 'Vermicompost', 'quantity': 10, 'unit': 'kg', 'unitPrice': 20, 'total': 200, 'fulfilment': 'farm_pickup', 'buyerName': 'Sita', 'commissionPercent': 5, 'commissionAmount': 10, 'sellerNet': 190};
    await pump(tester, const OwnSaleScreen(saleId: 's1'), fake);
    expect(find.byKey(const Key('pickup-code')), findsNothing);
    expect(find.byKey(const Key('sale-otp')), findsOneWidget);
    expect(find.byKey(const Key('pay-upi')), findsOneWidget);
    expect(find.text('₹190'), findsOneWidget);
  });

  testWidgets('my orders split into sold and bought', (tester) async {
    await pump(tester, const OwnSalesScreen(), FakeOwn());
    expect(find.byKey(const Key('sales-empty-seller')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-buying')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sale-s1')), findsOneWidget);
  });
}
