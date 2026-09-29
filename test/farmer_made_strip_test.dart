import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/core/widgets/kit.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/nearby_center.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/own_products/farmer_made_strip.dart';
import 'package:khaadsetu_version1/features/own_products/own_api.dart';
import 'package:khaadsetu_version1/features/own_products/own_market_screens.dart';

class _NoLocation extends FarmerLocationNotifier {
  @override
  Future<FarmerLocation?> build() async => null;
}

class FakeOwnMarket implements OwnApi {
  List<Json> items = [];

  @override
  Future<List<Json>> market({String? category, String sort = 'nearest', double? latitude, double? longitude, String? q}) async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pump(WidgetTester tester, FakeOwnMarket fake) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<Override> overrides = [
    ownApiProvider.overrideWithValue(fake),
    apiImageProvider.overrideWith((ref, path) async => throw 'no photos in tests'),
    farmerLocationProvider.overrideWith(_NoLocation.new),
  ];
  await tester.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp(theme: AppTheme.light, home: const Scaffold(body: FarmerMadeStrip()))));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with nothing to sell nearby, the strip takes up no room', (tester) async {
    await pump(tester, FakeOwnMarket());
    expect(find.text('Farmer-made, near you'), findsNothing);
    expect(find.byType(FarmerMadeStrip), findsOneWidget);
  });

  testWidgets('shows a preview with the farmer-made ribbon, and "See all" opens the full market', (tester) async {
    final fake = FakeOwnMarket()
      ..items = [
        {'id': 'l1', 'name': 'Vermicompost', 'pricePerUnit': 20, 'unit': 'kg', 'sellerName': 'Ganesh', 'village': 'Shirur'},
        {'id': 'l2', 'name': 'Jeevamrut', 'pricePerUnit': 40, 'unit': 'litre', 'sellerName': 'Sita', 'village': 'Kasar'},
      ];
    await pump(tester, fake);
    expect(find.text('Farmer-made, near you'), findsOneWidget);
    expect(find.byKey(const Key('strip-l1')), findsOneWidget);
    expect(find.byKey(const Key('strip-l2')), findsOneWidget);
    expect(find.text('Farmer-made'), findsNWidgets(2), reason: 'every card carries the ribbon');

    await tester.tap(find.byKey(const Key('farmer-made-see-all')));
    await tester.pumpAndSettle();
    expect(find.byType(OwnMarketScreen), findsOneWidget);
  });

  testWidgets('tapping a card in the strip opens that product', (tester) async {
    final fake = FakeOwnMarket()..items = [{'id': 'l1', 'name': 'Vermicompost', 'pricePerUnit': 20, 'unit': 'kg', 'sellerName': 'Ganesh', 'village': 'Shirur'}];
    await pump(tester, fake);
    await tester.tap(find.byKey(const Key('strip-l1')));
    await tester.pumpAndSettle();
    expect(find.byType(OwnDetailScreen), findsOneWidget);
  });
}
