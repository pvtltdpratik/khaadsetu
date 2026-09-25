import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/location/place_namer.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/entities/product.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/entities/product_review.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/product_query.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/repositories/marketplace_repository.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/presentation/widgets/market_widgets.dart';
import 'package:khaadsetu_version1/features/farmer/soil_health/domain/entities/nutrient_reading.dart';

import 'support/farmer_fakes.dart';
import 'support/profile_fakes.dart';

Product product(String id, String name, double price, double rating, {ProductCategory category = ProductCategory.organic, String brand = 'GreenGrow', List<NutrientType> focus = const [], int reviews = 10, String description = 'Good for crops.'}) =>
    Product(id: id, name: name, brand: brand, category: category, priceInRupees: price, unitLabel: '5 kg bag', rating: rating, reviewCount: reviews, description: description, nutrientFocus: focus, npkPercentages: const {});

final catalog = [
  product('neem', 'Neem Cake', 600, 4.5, focus: const [NutrientType.nitrogen]),
  product('vermi', 'Vermicompost', 450, 4.8, brand: 'EarthWorks', focus: const [NutrientType.nitrogen, NutrientType.potassium], reviews: 300),
  product('bone', 'Bone Meal', 900, 3.6, focus: const [NutrientType.phosphorus]),
  product('dap', 'DAP 18-46-0', 1350, 4.1, category: ProductCategory.fertilizer, brand: 'IFFCO', focus: const [NutrientType.phosphorus]),
  product('seed', 'Soybean Seed JS-335', 2200, 3.2, category: ProductCategory.seed, brand: 'MahaBeej'),
  product('spray', 'Neem Oil Spray', 380, 4.0, category: ProductCategory.pesticide, brand: 'GreenGrow', description: 'Controls aphids.'),
];

class FakeMarketplace implements MarketplaceRepository {
  FakeMarketplace(this.products);

  final List<Product> products;

  @override
  Future<List<Product>> getProducts() async => products;

  @override
  Future<Product> getProductById(String id) async => products.firstWhere((p) => p.id == id);

  @override
  Future<List<ProductReview>> getReviews(String productId) async => const [];
}

Future<void> pump(WidgetTester tester, {Set<NutrientType> deficient = const {}, List<Product>? products, double height = 3000}) async {
  tester.view.physicalSize = Size(430, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => const Scaffold(body: MarketplaceScreen())),
    GoRoute(path: '/farmer/marketplace/product/:id', builder: (context, s) => Scaffold(body: Text('detail ${s.pathParameters['id']}'))),
    GoRoute(path: '/farmer/marketplace/compare/:a/:b', builder: (context, s) => Scaffold(body: Text('compare ${s.pathParameters['a']} ${s.pathParameters['b']}'))),
    GoRoute(path: '/farmer/marketplace/surplus', builder: (context, _) => const Scaffold(body: Text('surplus deals'))),
    GoRoute(path: '/farmer/marketplace/centers', builder: (context, _) => const Scaffold(body: Text('centers'))),
    GoRoute(path: '/farmer/home/assistant', builder: (context, _) => const Scaffold(body: Text('assistant'))),
    GoRoute(path: '/farmer/marketplace/orders', builder: (context, _) => const Scaffold(body: Text('orders'))),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      marketplaceRepositoryProvider.overrideWithValue(FakeMarketplace(products ?? catalog)),
      centersRepositoryProvider.overrideWithValue(FakeCentersRepository()),
      deficientNutrientsProvider.overrideWith((ref) async => deficient),
      deviceLocationProvider.overrideWithValue(FakeDeviceLocation(result: shirur)),
      placeNamerProvider.overrideWithValue(FakePlaceNamer(const PlaceName(village: 'Shirur', district: 'Pune'))),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

List<String> names(WidgetTester tester) => tester.widgetList<ProductCard>(find.byType(ProductCard)).map((c) => c.product.name).toList();

void main() {
  group('ProductQuery', () {
    const none = <NutrientType>{};

    test('search words must all appear in the name, brand, category, description or nutrient', () {
      expect(const ProductQuery(text: 'neem').apply(catalog, none).map((p) => p.id), ['neem', 'spray']);
      expect(const ProductQuery(text: 'neem spray').apply(catalog, none).map((p) => p.id), ['spray']);
      expect(const ProductQuery(text: 'iffco').apply(catalog, none).map((p) => p.id), ['dap']);
      expect(const ProductQuery(text: 'aphids').apply(catalog, none).map((p) => p.id), ['spray']);
      expect(const ProductQuery(text: 'phosphorus').apply(catalog, none).map((p) => p.id), ['bone', 'dap']);
      expect(const ProductQuery(text: '  ').apply(catalog, none).length, catalog.length);
      expect(const ProductQuery(text: 'zzz').apply(catalog, none), isEmpty);
    });

    test('category, rating and price filters combine', () {
      expect(const ProductQuery(category: ProductCategory.seed).apply(catalog, none).map((p) => p.id), ['seed']);
      expect(const ProductQuery(minRating: 4).apply(catalog, none).map((p) => p.id), ['neem', 'vermi', 'dap', 'spray']);
      expect(const ProductQuery(maxPrice: 500).apply(catalog, none).map((p) => p.id), ['vermi', 'spray']);
      expect(const ProductQuery(minRating: 4, maxPrice: 700, category: ProductCategory.organic).apply(catalog, none).map((p) => p.id), ['neem', 'vermi']);
    });

    test('"matches my soil" keeps only products for the nutrients found low', () {
      const low = {NutrientType.phosphorus};
      expect(const ProductQuery(soilMatchOnly: true).apply(catalog, low).map((p) => p.id), ['bone', 'dap']);
      expect(const ProductQuery(soilMatchOnly: true).apply(catalog, none), isEmpty);
    });

    test('sorting by price and by rating (ties go to the more reviewed)', () {
      expect(const ProductQuery(sort: ProductSort.priceLow).apply(catalog, none).first.id, 'spray');
      expect(const ProductQuery(sort: ProductSort.priceHigh).apply(catalog, none).first.id, 'seed');
      final byRating = const ProductQuery(sort: ProductSort.rating).apply(catalog, none).map((p) => p.id).toList();
      expect(byRating.first, 'vermi');
      expect(byRating.last, 'seed');
      final tie = [product('a', 'A', 1, 4.0, reviews: 5), product('b', 'B', 1, 4.0, reviews: 50)];
      expect(const ProductQuery(sort: ProductSort.rating).apply(tie, none).first.id, 'b');
    });

    test('by default, what the soil needs comes first and the rest keep the catalog order', () {
      final ids = const ProductQuery().apply(catalog, {NutrientType.phosphorus}).map((p) => p.id).toList();
      expect(ids, ['bone', 'dap', 'neem', 'vermi', 'seed', 'spray']);
      expect(const ProductQuery().apply(catalog, none).map((p) => p.id), catalog.map((p) => p.id));
    });

    test('the filter count ignores the search box, category and sort', () {
      expect(const ProductQuery(text: 'x', category: ProductCategory.seed, sort: ProductSort.rating).activeFilterCount, 0);
      expect(const ProductQuery(minRating: 4, soilMatchOnly: true, maxPrice: 900).activeFilterCount, 3);
      expect(const ProductQuery().isDefault, isTrue);
      expect(const ProductQuery(minRating: 3).isDefault, isFalse);
    });

    test('copyWith can set a value back to none', () {
      const q = ProductQuery(category: ProductCategory.seed, maxPrice: 500);
      expect(q.copyWith(category: null).category, isNull);
      expect(q.copyWith(maxPrice: null).maxPrice, isNull);
      expect(q.copyWith(text: 'a').category, ProductCategory.seed);
    });
  });

  group('the marketplace screen', () {
    testWidgets('shows a grid of cards with a green rating pill, a price and the pickup line', (tester) async {
      await pump(tester);
      expect(find.byType(ProductCard), findsNWidgets(catalog.length));
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('₹600'), findsOneWidget);
      expect(find.text('6 products'), findsOneWidget);
      expect(find.text('Pickup at your village center'), findsWidgets);
    });

    testWidgets('the header shows where the farmer is from the GPS, not a made-up village', (tester) async {
      await pump(tester);
      expect(find.text('Shirur, Pune'), findsOneWidget);
    });

    testWidgets('typing in the search box narrows the grid, and the clear button restores it', (tester) async {
      await pump(tester);
      await tester.enterText(find.byKey(const Key('market-search')), 'neem');
      await tester.pumpAndSettle();
      expect(names(tester), ['Neem Cake', 'Neem Oil Spray']);
      expect(find.text('2 products'), findsOneWidget);
      await tester.tap(find.byKey(const Key('market-search-clear')));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsNWidgets(catalog.length));
    });

    testWidgets('a category icon filters, and tapping it again clears it', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('category-seed')));
      await tester.pumpAndSettle();
      expect(names(tester), ['Soybean Seed JS-335']);
      await tester.tap(find.byKey(const Key('category-seed')));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsNWidgets(catalog.length));
    });

    testWidgets('sort by price low to high reorders the grid', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('sort-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sort-priceLow')));
      await tester.pumpAndSettle();
      expect(names(tester).first, 'Neem Oil Spray');
      expect(names(tester).last, 'Soybean Seed JS-335');
      expect(find.text('Price ↑'), findsOneWidget, reason: 'the button says what it is sorted by');
    });

    testWidgets('the filter sheet narrows by rating and shows a count on the button', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rating-4.0')));
      await tester.tap(find.byKey(const Key('filter-apply')));
      await tester.pumpAndSettle();
      expect(names(tester), unorderedEquals(['Neem Cake', 'Vermicompost', 'DAP 18-46-0', 'Neem Oil Spray']));
      expect(find.text('1'), findsWidgets, reason: 'the Filter button shows one active filter');
      // Clear brings everything back.
      await tester.tap(find.byKey(const Key('filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-clear')));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsNWidgets(catalog.length));
    });

    testWidgets('products for a low nutrient are ribboned and listed first; the soil switch keeps only them', (tester) async {
      await pump(tester, deficient: {NutrientType.phosphorus});
      expect(names(tester).take(2), ['Bone Meal', 'DAP 18-46-0']);
      expect(find.byKey(const Key('soil-ribbon')), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('soil-switch')));
      await tester.tap(find.byKey(const Key('filter-apply')));
      await tester.pumpAndSettle();
      expect(names(tester), ['Bone Meal', 'DAP 18-46-0']);
    });

    testWidgets('without a soil scan the soil switch is off and says why', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('filter-button')));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('soil-switch'))).onChanged, isNull);
      expect(find.text('Scan your soil first to use this'), findsOneWidget);
    });

    testWidgets('no match shows an empty state that clears everything', (tester) async {
      await pump(tester);
      await tester.enterText(find.byKey(const Key('market-search')), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('No products match'), findsOneWidget);
      await tester.tap(find.byKey(const Key('clear-filters')));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsNWidgets(catalog.length));
      expect(tester.widget<TextField>(find.byKey(const Key('market-search'))).controller!.text, isEmpty);
    });

    testWidgets('tapping a card opens the product', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('product-vermi')));
      await tester.pumpAndSettle();
      expect(find.text('detail vermi'), findsOneWidget);
    });

    testWidgets('compare mode picks two products and opens the comparison', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('compare-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('product-neem')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compare-selected')), findsNothing);
      await tester.tap(find.byKey(const Key('product-vermi')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compare-selected')));
      await tester.pumpAndSettle();
      expect(find.text('compare neem vermi'), findsOneWidget);
    });

    testWidgets('the promo banners lead to surplus deals, centers and the assistant', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('promo-0')));
      await tester.pumpAndSettle();
      expect(find.text('surplus deals'), findsOneWidget);
    });
  });
}
