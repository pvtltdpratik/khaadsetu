import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/surplus_offer.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/widgets/surplus_offer_card.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/entities/product.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/entities/product_review.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/repositories/marketplace_repository.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:khaadsetu_version1/features/operator/surplus/domain/entities/surplus_lot.dart';
import 'package:khaadsetu_version1/features/resale/domain/resale_models.dart';
import 'package:khaadsetu_version1/features/resale/presentation/admin/resale_admin_screen.dart';
import 'package:khaadsetu_version1/features/resale/presentation/operator/cash_payouts_screen.dart';
import 'package:khaadsetu_version1/features/resale/presentation/operator/inspection_screen.dart';
import 'package:khaadsetu_version1/features/resale/presentation/operator/resale_queue_screen.dart';
import 'package:khaadsetu_version1/features/resale/presentation/operator/resale_review_screen.dart';
import 'package:khaadsetu_version1/features/resale/presentation/resale_providers.dart';

import 'support/resale_fakes.dart';

class _Market implements MarketplaceRepository {
  @override
  Future<List<Product>> getProducts() async => const [
        Product(id: 'p-vermicompost', name: 'Vermicompost', brand: 'HaritBhoomi', category: ProductCategory.organic, priceInRupees: 450, unitLabel: '40 kg bag', rating: 4.7, reviewCount: 3, description: '', nutrientFocus: [], npkPercentages: {}),
        Product(id: 'p-dap', name: 'DAP', brand: 'IFFCO', category: ProductCategory.fertilizer, priceInRupees: 1350, unitLabel: '50 kg bag', rating: 4, reviewCount: 3, description: '', nutrientFocus: [], npkPercentages: {}),
      ];

  @override
  Future<Product> getProductById(String id) async => (await getProducts()).first;

  @override
  Future<List<ProductReview>> getReviews(String productId) async => const [];
}

Future<void> pump(WidgetTester tester, Widget screen, FakeResaleRepository repo, {double height = 3400}) async {
  tester.view.physicalSize = Size(430, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => screen),
    GoRoute(path: '/operator/inventory/resale/new', builder: (context, _) => const InspectionScreen()),
    GoRoute(path: '/operator/inventory/resale/cash', builder: (context, _) => const CashPayoutsScreen()),
    GoRoute(
      path: '/operator/inventory/resale/:id',
      builder: (context, s) => ResaleReviewScreen(listingId: s.pathParameters['id']!),
      routes: [GoRoute(path: 'inspect', builder: (context, s) => InspectionScreen(listingId: s.pathParameters['id']!))],
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [resaleRepositoryProvider.overrideWithValue(repo), marketplaceRepositoryProvider.overrideWithValue(_Market())],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

/// Picks the first date offered in the picker, one year on: used for the expiry field.
Future<void> pickExpiry(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('expiry')));
  await tester.tap(find.byKey(const Key('expiry')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

SurplusOffer offer({bool resale = false, bool inspected = true, bool verified = false}) => SurplusOffer(
      lotId: 'lot-1',
      productId: 'p-vermicompost',
      productName: 'Vermicompost',
      unit: '40 kg bag',
      catalogPrice: 450,
      unitPrice: 350,
      available: 2,
      condition: SurplusCondition.sealed,
      center: const SurplusCenter(centerId: 'c1', name: 'Shirur Center', village: 'Shirur', district: 'Pune', phone: '', isOpen: true),
      distanceKm: 3.2,
      estimatedTravelMinutes: 15,
      isFarmerResale: resale,
      inspected: inspected,
      verifiedPurchase: verified,
    );

void main() {
  group('the marketplace card for surplus', () {
    Future<void> pumpCard(WidgetTester tester, SurplusOffer o) async {
      tester.view.physicalSize = const Size(430, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: SingleChildScrollView(child: SurplusOfferCard(offer: o))))));
      await tester.pumpAndSettle();
    }

    testWidgets('a farmer\'s resale carries the SURPLUS tag, where it comes from, and what has been checked', (tester) async {
      await pumpCard(tester, offer(resale: true, inspected: true, verified: true));
      expect(find.byKey(const Key('surplus-tag')), findsOneWidget);
      expect(find.text('SURPLUS'), findsOneWidget);
      expect(find.text('Sold by a farmer from Pune'), findsOneWidget);
      expect(find.text('Original purchase: verified platform order'), findsOneWidget);
      expect(find.text('Inspected by Shirur Center'), findsOneWidget);
      expect(find.text('22% off'), findsOneWidget);
      expect(find.text('₹450'), findsOneWidget, reason: 'the new price, struck through');
    });

    testWidgets('a listing that is live but not yet handed in says so plainly', (tester) async {
      await pumpCard(tester, offer(resale: true, inspected: false, verified: false));
      expect(find.text('Original purchase not verified'), findsOneWidget);
      expect(find.textContaining('Not inspected yet'), findsOneWidget);
    });

    testWidgets('a center\'s own surplus stays as it was', (tester) async {
      await pumpCard(tester, offer());
      expect(find.byKey(const Key('surplus-tag')), findsNothing);
      expect(find.byKey(const Key('trust-inspected')), findsNothing);
    });
  });

  group('the center\'s resale queue', () {
    testWidgets('has three tabs and puts new listings under "To review"', (tester) async {
      final repo = FakeResaleRepository(listings: [
        aListing('a'),
        aListing('b', status: ResaleStatus.inspectionRequired, seller: 'Bapu Shinde', verified: false),
        aListing('c', status: ResaleStatus.awaitingHandover, due: DateTime(2026, 9, 28, 16, 0)),
        aListing('d', status: ResaleStatus.listed),
      ]);
      await pump(tester, const ResaleQueueScreen(), repo);
      expect(find.text('To review (2)'), findsOneWidget);
      expect(find.text('2 × Vermicompost'), findsNWidgets(2));
      expect(find.textContaining('Sunita Jadhav'), findsOneWidget);
      expect(find.textContaining('Bapu Shinde  ·  ₹380 each  ·  no proof of purchase'), findsOneWidget);
      await tester.tap(find.text('On sale'));
      await tester.pumpAndSettle();
      expect(find.text('Seller must bring it by 28/9 16:00'), findsOneWidget);
      await tester.tap(find.text('At center'));
      await tester.pumpAndSettle();
      expect(find.text('Listed at the center'), findsOneWidget);
    });

    testWidgets('an empty tab says what will show up there', (tester) async {
      await pump(tester, const ResaleQueueScreen(), FakeResaleRepository());
      expect(find.textContaining('Nothing waiting'), findsOneWidget);
    });
  });

  group('reviewing a listing', () {
    testWidgets('shows what was claimed, the seller and both photos, and can approve from the photos', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('a')]);
      await pump(tester, const ResaleReviewScreen(listingId: 'a'), repo);
      expect(find.text('2 × Vermicompost'), findsOneWidget);
      expect(find.text('Verified purchase'), findsOneWidget);
      expect(find.text('Sunita Jadhav'), findsOneWidget);
      expect(find.text('Call 9822011111'), findsOneWidget);
      expect(find.textContaining('₹380 each (platform price ₹450)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('preapprove')));
      await tester.pumpAndSettle();
      expect(repo.calls, ['preapprove a']);
      expect(find.text('Approved. It is on sale now.'), findsOneWidget);
    });

    testWidgets('can ask the farmer to bring it in first, with a note', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('a')]);
      await pump(tester, const ResaleReviewScreen(listingId: 'a'), repo);
      await tester.tap(find.byKey(const Key('ask-to-bring')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('reason-field')), 'First sale');
      await tester.tap(find.byKey(const Key('reason-ok')));
      await tester.pumpAndSettle();
      expect(repo.calls, ['request a "First sale"']);
    });

    testWidgets('rejecting needs a reason', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('a')]);
      await pump(tester, const ResaleReviewScreen(listingId: 'a'), repo);
      await tester.ensureVisible(find.byKey(const Key('reject')));
      await tester.tap(find.byKey(const Key('reject')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('reason-ok'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('reason-field')), 'Torn bag, batch scratched');
      await tester.pump();
      await tester.tap(find.byKey(const Key('reason-ok')));
      await tester.pumpAndSettle();
      expect(repo.calls, ['reject a "Torn bag, batch scratched"']);
    });

    testWidgets('a listing that already sold some cannot be rejected', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('a', status: ResaleStatus.listed, sold: 1)]);
      await pump(tester, const ResaleReviewScreen(listingId: 'a'), repo);
      expect(find.byKey(const Key('reject')), findsNothing);
      expect(find.byKey(const Key('preapprove')), findsNothing);
    });

    testWidgets('inspect opens the counter checklist', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('a', status: ResaleStatus.awaitingHandover)]);
      await pump(tester, const ResaleReviewScreen(listingId: 'a'), repo);
      await tester.tap(find.byKey(const Key('inspect')));
      await tester.pumpAndSettle();
      expect(find.text('Inspection checklist'), findsOneWidget);
    });
  });

  group('the counter checklist', () {
    testWidgets('hard blocks are shown as they are entered, and the button is off', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('a')]);
      await pump(tester, const InspectionScreen(listingId: 'a'), repo);
      expect(find.byKey(const Key('blocks')), findsNothing, reason: 'the seller already gave a batch number');
      await tester.enterText(find.byKey(const Key('batch')), '');
      await tester.pump();
      expect(find.byKey(const Key('blocks')), findsOneWidget, reason: 'a batch number is required');
      await tester.enterText(find.byKey(const Key('batch')), 'B-2201');
      await tester.pump();
      expect(find.byKey(const Key('blocks')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('seal-damaged_packaging')));
      await tester.tap(find.byKey(const Key('seal-damaged_packaging')));
      await tester.pump();
      expect(find.text('• The packaging is severely damaged'), findsOneWidget);
      await tester.tap(find.byKey(const Key('seal-sealed')));
      await tester.ensureVisible(find.byKey(const Key('visual-wet')));
      await tester.tap(find.byKey(const Key('visual-wet')));
      await tester.pump();
      expect(find.text('• The product is wet or spoiled'), findsOneWidget);
      await tester.tap(find.byKey(const Key('visual-free_flowing')));
      await tester.ensureVisible(find.byKey(const Key('matches')));
      await tester.tap(find.byKey(const Key('matches')));
      await tester.pump();
      expect(find.text('• The bag cannot be matched to a product sold on the platform'), findsOneWidget);
      expect(find.text('Cannot be accepted'), findsOneWidget);
    });

    test('the blocks match the server\'s rules', () {
      final now = DateTime(2026, 9, 26);
      expect(inspectionBlocks(productMatches: true, seal: 'sealed', visual: 'free_flowing', batch: 'B1', expiry: DateTime(2027, 1, 1), now: now), isEmpty);
      expect(inspectionBlocks(productMatches: true, seal: 'sealed', visual: 'free_flowing', batch: 'B1', expiry: DateTime(2026, 9, 26), now: now), ['The product has expired']);
      expect(inspectionBlocks(productMatches: true, seal: 'sealed', visual: 'free_flowing', batch: 'B1', expiry: DateTime(2026, 9, 25), now: now), ['The product has expired']);
      expect(inspectionBlocks(productMatches: true, seal: 'sealed', visual: 'free_flowing', batch: '', expiry: null, now: now), ['The batch number is missing or unreadable']);
      expect(inspectionBlocks(productMatches: false, seal: 'damaged_packaging', visual: 'wet', batch: '', expiry: DateTime(2020), now: now).length, 5);
    });

    testWidgets('a listing is accepted with what the operator saw, and the price cannot go up', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('a', askingPrice: 380, verified: false)]);
      await pump(tester, const InspectionScreen(listingId: 'a'), repo);
      // The price starts at the lower of the asking price and the suggestion (both 383 and 380: 380).
      expect(find.text('Price per unit: ₹380'), findsOneWidget);
      expect(find.textContaining('it can only be lowered from ₹380'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('batch')), 'B-2201');
      await tester.ensureVisible(find.byKey(const Key('units-minus')));
      await tester.tap(find.byKey(const Key('units-minus')));
      await tester.tap(find.byKey(const Key('proof')));
      await pickExpiry(tester);
      await tester.ensureVisible(find.text('Accept the goods'));
      await tester.tap(find.text('Accept the goods'));
      await tester.pumpAndSettle();
      final done = repo.inspections.single;
      expect(done.id, 'a');
      expect(done.checklist.units, 1);
      expect(done.checklist.batchNumber, 'B-2201');
      expect(done.checklist.seal, 'sealed');
      expect(done.checklist.visual, 'free_flowing');
      expect(done.checklist.productMatches, isTrue);
      expect(done.checklist.unitPrice, lessThanOrEqualTo(380));
    });

    testWidgets('the server\'s refusal is shown and nothing is lost', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('a')])..inspectError = '3 units are already reserved by buyers. You cannot accept fewer.';
      await pump(tester, const InspectionScreen(listingId: 'a'), repo);
      await tester.enterText(find.byKey(const Key('batch')), 'B-2201');
      await tester.ensureVisible(find.text('Accept the goods'));
      await tester.tap(find.text('Accept the goods'));
      await tester.pumpAndSettle();
      expect(find.textContaining('already reserved by buyers'), findsOneWidget);
      expect(repo.inspections, isEmpty);
    });

    testWidgets('a liquid is judged as clear, cloudy or separated', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('a', unit: '1 L bottle')]);
      await pump(tester, const InspectionScreen(listingId: 'a'), repo);
      expect(find.byKey(const Key('visual-cloudy')), findsOneWidget);
      expect(find.byKey(const Key('visual-clumped')), findsNothing);
    });
  });

  group('taking in goods at the counter', () {
    testWidgets('finds a registered farmer by name, then the product, and sends both', (tester) async {
      final repo = FakeResaleRepository()..sellers = const [SellerMatch(sellerId: 'u1', name: 'Sunita Jadhav', village: 'Shirur', phone: '9822011111')];
      await pump(tester, const InspectionScreen(), repo);
      await tester.enterText(find.byKey(const Key('seller-search')), 'sun');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('seller-u1')));
      await tester.pump();
      expect(find.text('Selling: Sunita Jadhav'), findsOneWidget);
      expect(find.byKey(const Key('walkin-product-p-vermicompost')), findsOneWidget);
      expect(find.byKey(const Key('walkin-product-p-dap')), findsNothing, reason: 'only organic products');
      await tester.ensureVisible(find.byKey(const Key('walkin-product-p-vermicompost')));
      await tester.tap(find.byKey(const Key('walkin-product-p-vermicompost')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('batch')), 'B-77');
      await pickExpiry(tester);
      await tester.ensureVisible(find.byKey(const Key('payout-wallet')));
      await tester.tap(find.byKey(const Key('payout-cash')));
      await tester.pump();
      await tester.ensureVisible(find.text('Accept and list for sale'));
      await tester.tap(find.text('Accept and list for sale'));
      await tester.pumpAndSettle();
      final w = repo.walkIns.single;
      expect((w.sellerId, w.sellerName, w.productId, w.mode), ('u1', null, 'p-vermicompost', PayoutMode.cash));
      expect(w.checklist.batchNumber, 'B-77');
    });

    testWidgets('a seller with no account needs a name and phone, and is paid in cash', (tester) async {
      final repo = FakeResaleRepository();
      await pump(tester, const InspectionScreen(), repo);
      await tester.tap(find.byKey(const Key('no-account')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('walkin-product-p-vermicompost')));
      await tester.tap(find.byKey(const Key('walkin-product-p-vermicompost')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('batch')), 'B-9');
      await pickExpiry(tester);
      await tester.ensureVisible(find.text('Accept and list for sale'));
      await tester.tap(find.text('Accept and list for sale'));
      await tester.pump();
      expect(find.text('Enter the seller\'s name and phone number'), findsOneWidget);
      expect(repo.walkIns, isEmpty);
      await tester.ensureVisible(find.byKey(const Key('new-name')));
      await tester.enterText(find.byKey(const Key('new-name')), 'Bapu Shinde');
      await tester.enterText(find.byKey(const Key('new-phone')), '9822000000');
      await tester.ensureVisible(find.text('Accept and list for sale'));
      await tester.tap(find.text('Accept and list for sale'));
      await tester.pumpAndSettle();
      final w = repo.walkIns.single;
      expect((w.sellerId, w.sellerName, w.sellerPhone, w.mode), (null, 'Bapu Shinde', '9822000000', PayoutMode.cash));
    });
  });

  group('cash payouts', () {
    testWidgets('lists what is owed, and marks it paid only after confirming', (tester) async {
      final repo = FakeResaleRepository()
        ..cash = [
          const PayoutDue(saleId: 's1', amount: 639, sellerName: 'Bapu Shinde', productName: 'Vermicompost', sellerPhone: '9822000000'),
          const PayoutDue(saleId: 's2', amount: 100, sellerName: 'Asha', productName: 'Neem Cake'),
        ];
      await pump(tester, const CashPayoutsScreen(), repo);
      expect(find.text('₹739'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cash-paid-s1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hand ₹639 to Bapu Shinde?'), findsOneWidget);
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      await tester.tap(find.byKey(const Key('cash-paid-s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-cash')));
      await tester.pumpAndSettle();
      expect(repo.calls, ['cash-paid s1']);
      expect(find.byKey(const Key('cash-s1')), findsNothing);
      expect(find.byKey(const Key('cash-s2')), findsOneWidget);
    });

    testWidgets('nothing owed says so', (tester) async {
      await pump(tester, const CashPayoutsScreen(), FakeResaleRepository());
      expect(find.textContaining('No cash to hand over'), findsOneWidget);
    });
  });

  group('the admin', () {
    const dispute = ResaleDispute(disputeId: 'd1', reason: 'It was damp and clumped', status: 'open', productName: 'Vermicompost', centerName: 'Shirur Center', gross: 380, batchNumber: 'B-2201', centerQuality: 90);

    testWidgets('sees a complaint with the center\'s inspection score and refunds part of it', (tester) async {
      final repo = FakeResaleRepository()..openDisputes = [dispute];
      await pump(tester, const ResaleAdminScreen(), repo);
      expect(find.text('Complaints (1)'), findsOneWidget);
      expect(find.text('"It was damp and clumped"'), findsOneWidget);
      expect(find.textContaining('inspection score 90/100'), findsOneWidget);
      await tester.tap(find.byKey(const Key('uphold-d1')));
      await tester.pumpAndSettle();
      expect(find.text('Refund ₹380 (100%)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('percent-50')));
      await tester.pump();
      expect(find.text('Refund ₹190 (50%)'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('note')), 'Partly damp');
      await tester.tap(find.byKey(const Key('resolve-confirm')));
      await tester.pumpAndSettle();
      expect(repo.resolved.single, (id: 'd1', uphold: true, percent: 50, note: 'Partly damp'));
      expect(find.byKey(const Key('dispute-d1')), findsNothing);
    });

    testWidgets('can reject a complaint without a refund', (tester) async {
      final repo = FakeResaleRepository()..openDisputes = [dispute];
      await pump(tester, const ResaleAdminScreen(), repo);
      await tester.tap(find.byKey(const Key('reject-d1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('refund-label')), findsNothing);
      await tester.tap(find.byKey(const Key('resolve-confirm')));
      await tester.pumpAndSettle();
      expect(repo.resolved.single.uphold, isFalse);
      expect(repo.resolved.single.percent, isNull);
    });

    testWidgets('marks a UPI payout as sent with its reference', (tester) async {
      final repo = FakeResaleRepository()..upi = [const PayoutDue(saleId: 'u1', amount: 340.87, sellerName: 'Sunita Jadhav', productName: 'Vermicompost', upiId: 'sunita@okbank')];
      await pump(tester, const ResaleAdminScreen(), repo);
      await tester.tap(find.text('UPI payouts (1)'));
      await tester.pumpAndSettle();
      expect(find.text('sunita@okbank'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sent-u1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('utr')), 'UTR123');
      await tester.tap(find.byKey(const Key('utr-confirm')));
      await tester.pumpAndSettle();
      expect(repo.calls, ['upi-paid u1 "UTR123"']);
    });
  });
}
