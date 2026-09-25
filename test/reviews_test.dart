import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/providers/document_picker.dart';
import 'package:khaadsetu_version1/features/reviews/domain/profit_math.dart';
import 'package:khaadsetu_version1/features/reviews/domain/review_models.dart';
import 'package:khaadsetu_version1/features/reviews/presentation/log_fertilizer_screen.dart';
import 'package:khaadsetu_version1/features/reviews/presentation/my_logs_screen.dart';
import 'package:khaadsetu_version1/features/reviews/presentation/phase_screens.dart';
import 'package:khaadsetu_version1/features/reviews/presentation/predict_and_calculate_screens.dart';
import 'package:khaadsetu_version1/features/reviews/presentation/review_providers.dart';
import 'package:khaadsetu_version1/features/reviews/presentation/widgets/agronomic_reviews_section.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/entities/product.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/entities/product_review.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/repositories/marketplace_repository.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/presentation/providers/marketplace_providers.dart';

import 'support/review_fakes.dart';

class _Market implements MarketplaceRepository {
  @override
  Future<List<Product>> getProducts() async => const [
        Product(id: 'p-vermicompost', name: 'Vermicompost', brand: 'HaritBhoomi', category: ProductCategory.organic, priceInRupees: 450, unitLabel: '40 kg bag', rating: 4.7, reviewCount: 3, description: '', nutrientFocus: [], npkPercentages: {}),
        Product(id: 'p-neem', name: 'Neem Cake', brand: 'GreenGrow', category: ProductCategory.organic, priceInRupees: 600, unitLabel: '25 kg bag', rating: 4.5, reviewCount: 3, description: '', nutrientFocus: [], npkPercentages: {}),
      ];

  @override
  Future<Product> getProductById(String id) async => (await getProducts()).first;

  @override
  Future<List<ProductReview>> getReviews(String productId) async => const [];
}

const _png = <int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 248, 255, 255, 63, 0, 5, 254, 2, 254, 167, 53, 129, 132, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];

class _Picker implements DocumentPicker {
  @override
  Future<PickedDocument?> pick({required bool camera}) async => PickedDocument(bytes: Uint8List.fromList(_png), filename: 'p.png');
}

Future<void> pumpAt(WidgetTester tester, Widget screen, FakeReviewRepository repo, {double height = 3600, bool scroll = true}) async {
  tester.view.physicalSize = Size(430, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => scroll ? Scaffold(body: SingleChildScrollView(child: screen)) : screen),
    GoRoute(path: '/farmer/profile/log/new/:id', builder: (context, s) => Scaffold(body: Text('log ${s.pathParameters['id']}'))),
    GoRoute(path: '/farmer/profile/log/:id/mid', builder: (context, s) => MidSeasonScreen(reviewId: s.pathParameters['id']!)),
    GoRoute(path: '/farmer/profile/log/:id/harvest', builder: (context, s) => HarvestScreen(reviewId: s.pathParameters['id']!)),
    GoRoute(path: '/farmer/profile/predict/:id', builder: (context, s) => Scaffold(body: Text('predict ${s.pathParameters['id']}'))),
    GoRoute(path: '/farmer/profile/calculator', builder: (context, s) => Scaffold(body: Text('calculator ${s.uri.queryParameters['product']}'))),
    GoRoute(path: '/farmer/profile/rewards', builder: (context, _) => const RewardsScreen()),
    GoRoute(path: '/farmer/profile/farm', builder: (context, _) => const Scaffold(body: Text('farm details'))),
    GoRoute(path: '/farmer/profile/log', builder: (context, _) => const MyLogsScreen()),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      reviewRepositoryProvider.overrideWithValue(repo),
      documentPickerProvider.overrideWithValue(_Picker()),
      marketplaceRepositoryProvider.overrideWithValue(_Market()),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

Future<void> pump(WidgetTester tester, Widget screen, FakeReviewRepository repo) => pumpAt(tester, screen, repo);

/// Full-screen widgets are the page itself.
Future<void> pumpScreen(WidgetTester tester, Widget screen, FakeReviewRepository repo) => pumpAt(tester, screen, repo, scroll: false);

void main() {
  group('the profit calculator', () {
    test('cost, extra harvest, income, profit and break-even', () {
      // 2 acres, 2 bags an acre at ₹450, a 9.2 q/acre soybean crop lifted 20%, sold at ₹5,328 a quintal.
      final r = ProfitMath.calculate(acres: 2, bagsPerAcre: 2, pricePerBag: 450, baselineQpa: 9.2, gainPercent: 20, pricePerQuintal: 5328);
      expect(r.cost, 1800);
      expect(r.extraQuintals, closeTo(3.68, 0.001));
      expect(r.extraRevenue, closeTo(19607.04, 0.01));
      expect(r.net, closeTo(17807.04, 0.01));
      expect(r.pays, isTrue);
      expect(r.roiPercent, closeTo(989.3, 0.1));
      expect(r.breakEvenPercent, closeTo(1.84, 0.01));
    });

    test('a fertilizer that does not pay shows a loss, and nothing spent has no return figure', () {
      final loss = ProfitMath.calculate(acres: 1, bagsPerAcre: 3, pricePerBag: 1350, baselineQpa: 5.5, gainPercent: 3, pricePerQuintal: 5650);
      expect(loss.net, lessThan(0));
      expect(loss.pays, isFalse);
      expect(loss.breakEvenPercent, greaterThan(3));
      final free = ProfitMath.calculate(acres: 1, bagsPerAcre: 0, pricePerBag: 450, baselineQpa: 9, gainPercent: 10, pricePerQuintal: 5000);
      expect(free.cost, 0);
      expect(free.roiPercent, isNull);
      expect(free.breakEvenPercent, 0);
    });
  });

  group('parsing what the server sends', () {
    test('the summary turns the best group into a sentence', () {
      final s = ReviewSummary.fromJson({
        'count': 3, 'overall': 4.2, 'improvementAvg': 18.4, 'best': {'soil': 'black', 'crop': 'Soybean', 'season': 'kharif', 'averagePct': 22, 'reviews': 3},
        'topRatedFor': ['Value for money'], 'watchOutFor': [],
      });
      expect(s.bestLine, 'Black cotton soil + Soybean + Kharif season');
      expect(s.topRatedFor, ['Value for money']);
    });

    test('a card shows the nutrient levels as one line, and a filter can be cleared field by field', () {
      final card = ReviewCard.fromJson({
        'reviewId': 'r', 'farmer': 'Ramesh from Yavatmal', 'crop': 'Soybean', 'soilType': 'black', 'acres': 3, 'irrigation': 'rainfed', 'season': 'kharif-2026', 'qtyPerAcre': 25,
        'growthStage': 'vegetative', 'method': 'broadcasting', 'npkBefore': {'n': 'low', 'p': 'medium', 'k': 'high'}, 'starsOverall': 5,
      });
      expect(card.npkBefore, 'N low / P medium / K high');
      const f = ReviewFilter(soil: 'black', improved: true);
      expect(f.copyWith(soil: null).soil, isNull);
      expect(f.copyWith(soil: null).improved, isTrue);
      expect(f.copyWith(crop: 'Wheat').soil, 'black');
      expect(const ReviewFilter().isEmpty, isTrue);
      expect(f.isEmpty, isFalse);
    });

    test('a coupon is usable until it is used or expires; a harvest result says whether it was held', () {
      expect(usableCoupon.usable, isTrue);
      expect(Coupon.fromJson({'code': 'X', 'percent': 5, 'used': true, 'expired': false, 'expiresAt': '2030-01-01T00:00:00Z'}).usable, isFalse);
      expect(HarvestResult.fromJson({'earned': ['50 coins'], 'streak': 1, 'review': {'status': 'flagged'}}).heldForCheck, isTrue);
    });
  });

  group('reviews on a product page', () {
    testWidgets('a summary from real harvests, then a structured card per farmer', (tester) async {
      final repo = FakeReviewRepository(reviews: ProductReviews(summary: goodSummary, reviews: [aCard('r1', agronomist: true, featured: true), aCard('r2', farmer: 'Sunita from Pune', gain: -5)], matching: 2));
      await pump(tester, const AgronomicReviewsSection(productId: 'p-vermicompost', productName: 'Vermicompost'), repo);
      expect(find.text('4.2'), findsOneWidget);
      expect(find.text('from 4 harvests'), findsOneWidget);
      expect(find.text('+18.4%'), findsOneWidget);
      expect(find.text('Best results on: Black cotton soil + Soybean + Kharif season'), findsOneWidget);
      expect(find.text('Value for money'), findsOneWidget);
      expect(find.text('Less effective on sandy soil'), findsOneWidget);
      expect(find.text('2 reviews'), findsOneWidget);
      expect(find.text('Ramesh from Yavatmal'), findsOneWidget);
      expect(find.text('Crop: Soybean (JS 335)  ·  Soil: Black cotton'), findsWidgets);
      expect(find.textContaining('Before: N low / P medium / K medium  ·  soil score 48/100'), findsWidgets);
      expect(find.text('11.2 q/acre'), findsWidgets);
      expect(find.text('+33.3%'), findsWidgets);
      expect(find.text('-5.0%'), findsOneWidget);
      expect(find.textContaining('Last season 8.4  ·  District average 9.2  ·  Soil score after 61/100'), findsWidgets);
      expect(find.text('पिकाचा रंग बदलला.'), findsWidgets, reason: 'Marathi text is shown as written');
      expect(find.text('Verified Purchase'), findsWidgets);
      expect(find.text('Agronomist Reviewed'), findsOneWidget);
      expect(find.text('Has crop photo'), findsWidgets);
    });

    testWidgets('with no harvest logged yet it invites the first one', (tester) async {
      await pump(tester, const AgronomicReviewsSection(productId: 'p-vermicompost', productName: 'Vermicompost'), FakeReviewRepository());
      expect(find.byKey(const Key('no-agronomic-reviews')), findsOneWidget);
      expect(find.byKey(const Key('review-summary')), findsNothing);
      expect(find.byKey(const Key('log-my-use')), findsOneWidget);
    });

    testWidgets('the filter chips ask the server for farmers like you', (tester) async {
      final repo = FakeReviewRepository(reviews: ProductReviews(summary: goodSummary, reviews: [aCard('r1')], matching: 1));
      await pump(tester, const AgronomicReviewsSection(productId: 'p-vermicompost', productName: 'Vermicompost'), repo);
      await tester.tap(find.byKey(const Key('filter-soil-black')));
      await tester.pumpAndSettle();
      expect(repo.filters.last.soil, 'black');
      await tester.tap(find.byKey(const Key('filter-improved')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('filter-season-kharif')));
      await tester.tap(find.byKey(const Key('filter-season-kharif')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('filter-size-small')));
      await tester.tap(find.byKey(const Key('filter-size-small')));
      await tester.pumpAndSettle();
      expect(repo.filters.last, const ReviewFilter(soil: 'black', improved: true, season: 'kharif', size: 'small'));
      expect(find.text('1 review match your filters'), findsOneWidget);
      await tester.tap(find.byKey(const Key('filter-soil-black')));
      await tester.pumpAndSettle();
      expect(repo.filters.last.soil, isNull, reason: 'tapping again clears it');
    });

    testWidgets('a filter with no match says so, and the summary stays', (tester) async {
      final repo = FakeReviewRepository(reviews: const ProductReviews(summary: goodSummary, reviews: [], matching: 0));
      await pump(tester, const AgronomicReviewsSection(productId: 'p-vermicompost', productName: 'Vermicompost'), repo);
      expect(find.text('No farmer like that has logged a harvest yet.'), findsOneWidget);
      expect(find.byKey(const Key('review-summary')), findsOneWidget);
    });

    testWidgets('the three actions open the log, the prediction and the calculator', (tester) async {
      final repo = FakeReviewRepository(reviews: ProductReviews(summary: goodSummary, reviews: [aCard('r1')], matching: 1));
      await pump(tester, const AgronomicReviewsSection(productId: 'p-vermicompost', productName: 'Vermicompost'), repo);
      await tester.ensureVisible(find.byKey(const Key('log-my-use')));
      await tester.tap(find.byKey(const Key('log-my-use')));
      await tester.pumpAndSettle();
      expect(find.text('log p-vermicompost'), findsOneWidget);
    });
  });

  group('phase 1: the baseline', () {
    testWidgets('shows what the app knows about the farm and asks only what is new', (tester) async {
      await pumpScreen(tester, const LogFertilizerScreen(productId: 'p-vermicompost'), FakeReviewRepository());
      expect(tester.widget<Text>(find.byKey(const Key('known-soil'))).data, 'Soil: Black cotton  ·  District: Yavatmal');
      expect(find.text('Latest soil scan: N low, P medium, K medium  ·  score 48/100'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('acres'))).controller!.text, '3.0', reason: 'from the farm profile');
      expect(find.byKey(const Key('crop-Soybean')), findsOneWidget);
    });

    testWidgets('a product not bought here cannot be logged', (tester) async {
      final repo = FakeReviewRepository(prefillData: const ReviewPrefill(eligible: false, acres: null, soilType: null, irrigation: null, district: '', crops: [], scan: null, cropNames: []));
      await pumpScreen(tester, const LogFertilizerScreen(productId: 'p-vermicompost'), repo);
      expect(find.text('Only for products you bought here'), findsOneWidget);
    });

    testWidgets('with no soil type on the profile it sends the farmer to add it, and does not offer to make one up', (tester) async {
      final repo = FakeReviewRepository(prefillData: const ReviewPrefill(eligible: true, acres: 3, soilType: null, irrigation: null, district: '', crops: [], scan: null, cropNames: ['Soybean']));
      await pumpScreen(tester, const LogFertilizerScreen(productId: 'p-vermicompost'), repo);
      expect(find.text('Tell us your soil type first'), findsOneWidget);
      expect(find.byKey(const Key('qty')), findsNothing);
      await tester.tap(find.byKey(const Key('add-soil')));
      await tester.pumpAndSettle();
      expect(find.text('farm details'), findsOneWidget);
    });

    testWidgets('it will not send until the crop, the dose and the irrigation are given', (tester) async {
      final repo = FakeReviewRepository();
      await pumpScreen(tester, const LogFertilizerScreen(productId: 'p-vermicompost'), repo);
      await tester.tap(find.byKey(const Key('crop-Cotton')));
      await tester.ensureVisible(find.text('Save baseline and get 5% off'));
      await tester.tap(find.text('Save baseline and get 5% off'));
      await tester.pump();
      expect(find.text('Enter how much you applied per acre'), findsOneWidget);
      expect(repo.started, isEmpty);
    });

    testWidgets('a complete baseline is sent, and the coupon is shown', (tester) async {
      final repo = FakeReviewRepository();
      await pumpScreen(tester, const LogFertilizerScreen(productId: 'p-vermicompost'), repo);
      await tester.enterText(find.byKey(const Key('variety')), 'JS 335');
      await tester.enterText(find.byKey(const Key('qty')), '25');
      await tester.ensureVisible(find.byKey(const Key('method-banding')));
      await tester.tap(find.byKey(const Key('method-banding')));
      await tester.tap(find.byKey(const Key('stage-flowering')));
      await tester.tap(find.byKey(const Key('reason-used_before')));
      await tester.ensureVisible(find.text('Save baseline and get 5% off'));
      await tester.tap(find.text('Save baseline and get 5% off'));
      await tester.pumpAndSettle();
      final b = repo.started.single;
      expect((b.productId, b.crop, b.variety, b.acres, b.qtyPerAcre), ('p-vermicompost', 'Soybean', 'JS 335', 3.0, 25.0));
      expect((b.method, b.growthStage, b.reason, b.irrigation), ('banding', 'flowering', 'used_before', 'rainfed'));
      expect(find.textContaining('SAMRUDHI-A1B2C3'), findsOneWidget);
    });

    testWidgets('a refusal from the server is shown', (tester) async {
      final repo = FakeReviewRepository()..startError = 'You have already logged this fertilizer for Soybean this season';
      await pumpScreen(tester, const LogFertilizerScreen(productId: 'p-vermicompost'), repo);
      await tester.enterText(find.byKey(const Key('qty')), '25');
      await tester.ensureVisible(find.text('Save baseline and get 5% off'));
      await tester.tap(find.text('Save baseline and get 5% off'));
      await tester.pumpAndSettle();
      expect(find.textContaining('already logged this fertilizer'), findsOneWidget);
    });
  });

  group('my log', () {
    testWidgets('each step shows what it is waiting for, and a step that is open can be started', (tester) async {
      final repo = FakeReviewRepository(logs: [aLog('a', mid: 12, harvest: 60), aLog('b', mid: 0, harvest: 30), aLog('c', phase: 2, harvest: 0), aLog('d', phase: 3, status: 'published', yieldQpa: 11.2, gain: 33.3)]);
      await pumpScreen(tester, const MyLogsScreen(), repo);
      expect(find.text('Mid-season notes open in 12 days'), findsOneWidget);
      expect(find.text('Harvest log opens in 60 days'), findsOneWidget);
      expect(find.byKey(const Key('mid-b')), findsOneWidget);
      expect(find.text('Add mid-season notes (+10 coins)'), findsOneWidget);
      expect(find.byKey(const Key('harvest-c')), findsOneWidget);
      expect(find.byKey(const Key('mid-c')), findsNothing, reason: 'mid-season notes are already in');
      expect(find.text('11.2 q/acre  ·  +33.3%'), findsOneWidget);
      expect(find.text('Published: it helps other farmers.'), findsOneWidget);
    });

    testWidgets('a held result says an agronomist is checking it', (tester) async {
      await pumpScreen(tester, const MyLogsScreen(), FakeReviewRepository(logs: [aLog('a', phase: 3, status: 'flagged', yieldQpa: 40, gain: 300)]));
      expect(find.text('An agronomist is checking this result before it is shown to others.'), findsOneWidget);
    });

    testWidgets('the rewards strip shows coins, the badge and the streak; new logs start from what was bought', (tester) async {
      final repo = FakeReviewRepository(rewardsData: Rewards(coins: 160, coinBatch: 100, coinBatchRupees: 25, badges: const ['verified_farmer'], coupons: [usableCoupon], streak: 2));
      await pumpScreen(tester, const MyLogsScreen(), repo);
      expect(find.text('160'), findsOneWidget);
      expect(find.text('Verified Farmer  ·  2 seasons in a row  ·  1 coupon'), findsOneWidget);
      expect(find.byKey(const Key('loggable-p-vermicompost')), findsOneWidget);
      await tester.tap(find.byKey(const Key('rewards-strip')));
      await tester.pumpAndSettle();
      expect(find.text('My rewards'), findsOneWidget);
    });

    testWidgets('an empty log explains what logging is worth', (tester) async {
      await pumpScreen(tester, const MyLogsScreen(), FakeReviewRepository(loggableProducts: const []));
      expect(find.textContaining('Nothing logged yet'), findsOneWidget);
    });
  });

  group('phase 2 and 3', () {
    testWidgets('the mid-season notes need an answer to each tap question, and earn coins', (tester) async {
      final repo = FakeReviewRepository();
      await pumpScreen(tester, const MidSeasonScreen(reviewId: 'a'), repo);
      await tester.ensureVisible(find.text('Send (+10 coins)'));
      await tester.tap(find.text('Send (+10 coins)'));
      await tester.pump();
      expect(find.text('Tap an answer for each question'), findsOneWidget);
      await tester.tap(find.byKey(const Key('color-improved')));
      await tester.tap(find.byKey(const Key('leaf-greener')));
      await tester.ensureVisible(find.byKey(const Key('soil-better')));
      await tester.tap(find.byKey(const Key('soil-better')));
      await tester.ensureVisible(find.byKey(const Key('pest')));
      await tester.tap(find.byKey(const Key('pest')));
      await tester.enterText(find.byKey(const Key('unexpected')), 'Fewer weeds');
      await tester.ensureVisible(find.byKey(const Key('photo')));
      await tester.tap(find.byKey(const Key('photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send (+10 coins)'));
      await tester.tap(find.text('Send (+10 coins)'));
      await tester.pumpAndSettle();
      final m = repo.mids.single;
      expect(m.id, 'a');
      expect((m.notes.colorChange, m.notes.leafHealth, m.notes.soilFeel, m.notes.pestDisease, m.notes.unexpected), ('improved', 'greener', 'better', true, 'Fewer weeds'));
      expect(m.photo, isNotNull);
    });

    testWidgets('the harvest shows the district average next to the yield box and needs every rating', (tester) async {
      final repo = FakeReviewRepository(logs: [aLog('a', phase: 2)]);
      await pumpScreen(tester, const HarvestScreen(reviewId: 'a'), repo);
      expect(find.text('District average for soybean: 9.2 quintals/acre'), findsOneWidget);
      expect(find.text('Vermicompost on Soybean'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('yield')), '11.2');
      await tester.ensureVisible(find.text('Send my harvest (+50 coins)'));
      await tester.tap(find.text('Send my harvest (+50 coins)'));
      await tester.pump();
      expect(find.text('Give all three star ratings'), findsOneWidget);
      expect(repo.harvests, isEmpty);
    });

    testWidgets('a complete harvest is sent and the rewards are listed', (tester) async {
      final repo = FakeReviewRepository(logs: [aLog('a', phase: 2)]);
      await pumpScreen(tester, const HarvestScreen(reviewId: 'a'), repo);
      await tester.enterText(find.byKey(const Key('yield')), '11.2');
      await tester.enterText(find.byKey(const Key('last-season')), '8.4');
      for (final k in ['overall-5', 'value-4', 'ease-5']) {
        await tester.ensureVisible(find.byKey(Key(k)));
        await tester.tap(find.byKey(Key(k)));
      }
      await tester.ensureVisible(find.byKey(const Key('again-yes')));
      await tester.tap(find.byKey(const Key('again-yes')));
      await tester.tap(find.byKey(const Key('recommend-yes')));
      await tester.enterText(find.byKey(const Key('comment')), 'खूप चांगला अनुभव होता.');
      await tester.ensureVisible(find.text('Send my harvest (+50 coins)'));
      await tester.tap(find.text('Send my harvest (+50 coins)'));
      await tester.pumpAndSettle();
      final h = repo.harvests.single.input;
      expect((h.yieldQpa, h.lastSeasonQpa, h.starsOverall, h.starsValue, h.starsEase, h.useAgain, h.recommend), (11.2, 8.4, 5, 4, 5, 'yes', true));
      expect(h.comment, 'खूप चांगला अनुभव होता.');
      expect(find.text('Your harvest is logged'), findsOneWidget);
      expect(find.text('Your yield was +33.3% against last season.'), findsOneWidget);
      expect(find.text('• 50 coins'), findsOneWidget);
      expect(find.text('• the Verified Farmer badge'), findsOneWidget);
    });

    testWidgets('an unusual result says an agronomist will check it', (tester) async {
      final repo = FakeReviewRepository(logs: [aLog('a', phase: 2)])..harvestResult = const HarvestResult(earned: ['50 coins'], streak: 1, status: 'flagged', improvementPct: 240);
      await pumpScreen(tester, const HarvestScreen(reviewId: 'a'), repo);
      await tester.enterText(find.byKey(const Key('yield')), '31');
      for (final k in ['overall-5', 'value-5', 'ease-5']) {
        await tester.ensureVisible(find.byKey(Key(k)));
        await tester.tap(find.byKey(Key(k)));
      }
      await tester.ensureVisible(find.byKey(const Key('again-yes')));
      await tester.tap(find.byKey(const Key('again-yes')));
      await tester.tap(find.byKey(const Key('recommend-no')));
      await tester.ensureVisible(find.text('Send my harvest (+50 coins)'));
      await tester.tap(find.text('Send my harvest (+50 coins)'));
      await tester.pumpAndSettle();
      expect(find.text('Thank you: we will check it'), findsOneWidget);
      expect(find.textContaining('agronomist checks unusual results'), findsOneWidget);
    });
  });

  group('rewards', () {
    testWidgets('coins can be redeemed in hundreds', (tester) async {
      final repo = FakeReviewRepository(rewardsData: const Rewards(coins: 250, coinBatch: 100, coinBatchRupees: 25, badges: [], coupons: [], streak: 0));
      await pumpScreen(tester, const RewardsScreen(), repo);
      expect(find.text('Redeem 200 coins'), findsOneWidget);
      await tester.tap(find.byKey(const Key('redeem')));
      await tester.pumpAndSettle();
      expect(repo.redeemed, [200]);
      expect(find.textContaining('added to your wallet'), findsOneWidget);
    });

    testWidgets('with too few coins the button says how many more are needed', (tester) async {
      await pumpScreen(tester, const RewardsScreen(), FakeReviewRepository(rewardsData: const Rewards(coins: 60, coinBatch: 100, coinBatchRupees: 25, badges: [], coupons: [], streak: 0)));
      expect(find.text('Earn 40 more coins to redeem'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('redeem'))).onPressed, isNull);
    });

    testWidgets('badges, the streak, priority access and coupons are all shown', (tester) async {
      final repo = FakeReviewRepository(
        rewardsData: Rewards(coins: 0, coinBatch: 100, coinBatchRupees: 25, badges: const ['verified_farmer', 'champion_farmer'], coupons: [usableCoupon, Coupon(code: 'SAMRUDHI-OLD000', percent: 5, source: '', used: true, expired: false, expiresAt: DateTime(2030, 1, 1))], streak: 3, priorityUntil: DateTime(2027, 3, 1)),
      );
      await pumpScreen(tester, const RewardsScreen(), repo);
      expect(find.text('Champion Farmer'), findsOneWidget);
      expect(find.text('Verified Farmer'), findsOneWidget);
      expect(find.text('3 seasons in a row'), findsOneWidget);
      expect(find.textContaining('Priority access to next season\'s recommendations until 1/3/2027'), findsOneWidget);
      expect(find.text('SAMRUDHI-A1B2C3'), findsOneWidget);
      expect(find.textContaining('valid until 1/1/2030'), findsOneWidget);
      expect(find.textContaining('used'), findsWidgets);
    });
  });

  group('the yield prediction', () {
    testWidgets('asks the server for the crop and acres and shows the range with where it came from', (tester) async {
      final repo = FakeReviewRepository();
      await pumpScreen(tester, const YieldPredictionScreen(productId: 'p-vermicompost'), repo);
      expect(tester.widget<TextField>(find.byKey(const Key('acres'))).controller!.text, '3.0', reason: 'the farm size from the profile');
      expect(find.byKey(const Key('prediction')), findsNothing);
      await tester.tap(find.byKey(const Key('crop-Soybean')));
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();
      expect(repo.predictCalls.single, (productId: 'p-vermicompost', acres: 3.0, crop: 'Soybean'));
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('22%'), findsOneWidget);
      expect(find.textContaining('we expect 15% to 22% more yield'), findsOneWidget);
      expect(find.text('About 2.8 to 4.0 extra quintals on your farm.'), findsOneWidget);
      expect(find.text('Based on 6 farmers with your crop and soil type.'), findsOneWidget);
    });

    testWidgets('an early estimate says it is not from farmers yet', (tester) async {
      final repo = FakeReviewRepository(prediction: const YieldPrediction(lowPct: 12, highPct: 20, message: 'm', disclaimer: 'An early estimate from how the product works, not from other farmers yet.', basis: 'agronomy', sampleSize: 0, baselineQpa: 9.2, extraLow: 2, extraHigh: 3));
      await pumpScreen(tester, const YieldPredictionScreen(productId: 'p-vermicompost'), repo);
      await tester.tap(find.byKey(const Key('crop-Soybean')));
      await tester.tap(find.text('Predict'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not from other farmers yet'), findsOneWidget);
    });

    testWidgets('it needs a crop first', (tester) async {
      final repo = FakeReviewRepository(prefillData: const ReviewPrefill(eligible: true, acres: 3, soilType: 'black', irrigation: 'rainfed', district: '', crops: [], scan: null, cropNames: ['Soybean', 'Cotton']));
      await pumpScreen(tester, const YieldPredictionScreen(productId: 'p-vermicompost'), repo);
      await tester.tap(find.text('Predict'));
      await tester.pump();
      expect(find.text('Choose your crop'), findsOneWidget);
      expect(repo.predictCalls, isEmpty);
    });
  });

  group('the calculator screen', () {
    Future<void> setUpCalc(WidgetTester tester, FakeReviewRepository repo, {String? productId = 'p-vermicompost'}) async {
      await pumpScreen(tester, ProfitCalculatorScreen(productId: productId), repo);
    }

    testWidgets('choosing a product and a crop fills the price, the usual yield and the mandi price', (tester) async {
      await setUpCalc(tester, FakeReviewRepository());
      expect(tester.widget<TextField>(find.byKey(const Key('price'))).controller!.text, '450', reason: 'the product from the page it was opened from');
      await tester.tap(find.byKey(const Key('crop-Soybean')));
      await tester.pump();
      expect(tester.widget<TextField>(find.byKey(const Key('baseline'))).controller!.text, '9.2');
      expect(tester.widget<TextField>(find.byKey(const Key('mandi'))).controller!.text, '5328');
    });

    testWidgets('shows the cost, the extra income and the profit, and a break-even', (tester) async {
      await setUpCalc(tester, FakeReviewRepository());
      await tester.tap(find.byKey(const Key('crop-Soybean')));
      await tester.enterText(find.byKey(const Key('acres')), '2');
      await tester.pump();
      expect(find.text('₹1,800'), findsOneWidget);
      expect(find.text('Estimated profit'), findsOneWidget);
      expect(find.byKey(const Key('break-even')), findsOneWidget);
      expect(find.textContaining('return on what you spend'), findsOneWidget);
      // At a very low expected gain it does not pay, and says so.
      await tester.ensureVisible(find.byKey(const Key('gain')));
      final slider = tester.getRect(find.byKey(const Key('gain')));
      await tester.tapAt(Offset(slider.left + 8, slider.center.dy));
      await tester.pump();
      expect(find.text('Estimated loss'), findsOneWidget);
    });

    testWidgets('"use the prediction" takes the middle of the predicted range', (tester) async {
      final repo = FakeReviewRepository();
      await setUpCalc(tester, repo);
      await tester.tap(find.byKey(const Key('crop-Soybean')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('use-prediction')));
      await tester.tap(find.byKey(const Key('use-prediction')));
      await tester.pumpAndSettle();
      expect(repo.predictCalls.single.crop, 'Soybean');
      expect(find.text('Expected extra yield: 19%'), findsOneWidget);
      expect(find.text('Using the middle of the prediction: 15% to 22%'), findsOneWidget);
    });

    testWidgets('until the boxes are filled it says so instead of guessing', (tester) async {
      await setUpCalc(tester, FakeReviewRepository(), productId: null);
      expect(find.text('Fill in the boxes to see the numbers.'), findsOneWidget);
      expect(find.byKey(const Key('profit-result')), findsNothing);
    });
  });
}
