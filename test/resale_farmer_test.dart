import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/providers/document_picker.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/entities/farmer_order.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/providers/orders_providers.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/screens/my_orders_screen.dart';
import 'package:khaadsetu_version1/features/payments/domain/payment_models.dart';
import 'package:khaadsetu_version1/features/payments/presentation/payments_providers.dart';
import 'package:khaadsetu_version1/features/resale/domain/resale_math.dart';
import 'package:khaadsetu_version1/features/resale/domain/resale_models.dart';
import 'package:khaadsetu_version1/features/resale/presentation/farmer/farmer_wallet_screen.dart';
import 'package:khaadsetu_version1/features/resale/presentation/farmer/resale_listing_screen.dart';
import 'package:khaadsetu_version1/features/resale/presentation/farmer/sell_surplus_form_screen.dart';
import 'package:khaadsetu_version1/features/resale/presentation/farmer/sell_surplus_hub_screen.dart';
import 'package:khaadsetu_version1/features/resale/presentation/resale_providers.dart';

import 'payments_test.dart' show FakeCheckout, FakePaymentsRepository;
import 'support/farmer_fakes.dart';
import 'support/resale_fakes.dart';

// A real 1x1 image, so the preview decodes (a trailing byte makes each photo different).
const _png = <int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 248, 255, 255, 63, 0, 5, 254, 2, 254, 167, 53, 129, 132, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];

class FakePhotoPicker implements DocumentPicker {
  int calls = 0;

  @override
  Future<PickedDocument?> pick({required bool camera}) async {
    calls++;
    return PickedDocument(bytes: Uint8List.fromList([..._png, calls]), filename: 'bag$calls.png');
  }
}

Future<void> pump(
  WidgetTester tester,
  Widget screen,
  FakeResaleRepository repo, {
  double height = 3600,
  FakePhotoPicker? picker,
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = Size(430, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, _) => screen),
    GoRoute(path: '/farmer/profile/sell/new', builder: (context, _) => const SellSurplusFormScreen()),
    GoRoute(path: '/farmer/profile/sell/:id', builder: (context, s) => ResaleListingScreen(listingId: s.pathParameters['id']!)),
    GoRoute(path: '/farmer/profile/wallet', builder: (context, _) => const FarmerWalletScreen()),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      resaleRepositoryProvider.overrideWithValue(repo),
      documentPickerProvider.overrideWithValue(picker ?? FakePhotoPicker()),
      centersRepositoryProvider.overrideWithValue(FakeCentersRepository()),
      deviceLocationProvider.overrideWithValue(FakeDeviceLocation(result: shirur)),
      ...extra,
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pumpAndSettle();
}

Future<void> fillForm(WidgetTester tester, {bool photos = true, bool expiry = true}) async {
  await tester.tap(find.byKey(const Key('product-p-vermicompost')));
  await tester.pumpAndSettle();
  if (expiry) {
    await tester.ensureVisible(find.byKey(const Key('expiry-date')));
    await tester.tap(find.byKey(const Key('expiry-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }
  if (photos) {
    for (final side in ['front', 'back']) {
      await tester.ensureVisible(find.byKey(Key('photo-$side')));
      await tester.tap(find.byKey(Key('photo-$side')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();
    }
  }
  await tester.ensureVisible(find.byKey(const Key('center-a')));
  await tester.tap(find.byKey(const Key('center-a')));
  await tester.pump();
}

void main() {
  group('what a seller keeps', () {
    test('89% with proof of purchase, 86% without, and cash keeps 97% of that', () {
      expect(ResaleMath.split(verified: true), (platformPct: 8, centerPct: 3, keepPct: 89));
      expect(ResaleMath.split(verified: false), (platformPct: 10, centerPct: 4, keepPct: 86));
      expect(ResaleMath.sellerNet(gross: 1000, verified: true, mode: PayoutMode.wallet), 890);
      expect(ResaleMath.sellerNet(gross: 1000, verified: true, mode: PayoutMode.upi), 890);
      expect(ResaleMath.sellerNet(gross: 1000, verified: true, mode: PayoutMode.cash), 863.3);
      expect(ResaleMath.sellerNet(gross: 1000, verified: false, mode: PayoutMode.cash), 834.2);
      expect(ResaleMath.savingPercent(catalogPrice: 450, price: 350), 22);
    });

    test('status and payout words come from the server values', () {
      expect(ResaleStatus.parse('awaiting_handover'), ResaleStatus.awaitingHandover);
      expect(ResaleStatus.parse('nonsense'), ResaleStatus.draft);
      expect(ResaleStatus.live.isOpen, isTrue);
      expect(ResaleStatus.rejected.isOpen, isFalse);
      expect(PayoutMode.parse('cash'), PayoutMode.cash);
      expect(ResaleCondition.parse('partially_used'), ResaleCondition.partiallyUsed);
    });
  });

  group('the sell hub', () {
    testWidgets('shows the wallet, how it works, and my listings with their state', (tester) async {
      final repo = FakeResaleRepository(
        walletState: const WalletState(balance: 676.4, entries: []),
        listings: [aListing('a', status: ResaleStatus.live), aListing('b', status: ResaleStatus.awaitingHandover, due: DateTime(2026, 9, 28, 14, 30)), aListing('c', status: ResaleStatus.soldOut, sold: 2)],
      );
      await pump(tester, const SellSurplusHubScreen(), repo);
      expect(find.text('₹676'), findsOneWidget);
      expect(find.text('How it works'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Buyer found: bring it in'), findsOneWidget);
      expect(find.text('Bring it to the center by 28/9 14:30'), findsOneWidget);
      expect(find.text('2 sold'), findsOneWidget);
    });

    testWidgets('with nothing listed it says what can be sold', (tester) async {
      await pump(tester, const SellSurplusHubScreen(), FakeResaleRepository());
      expect(find.textContaining('Nothing listed yet'), findsOneWidget);
      expect(find.byKey(const Key('start-selling')), findsOneWidget);
    });
  });

  group('the sell form', () {
    testWidgets('lists only what was bought and collected, and greys out what cannot be listed again', (tester) async {
      await pump(tester, const SellSurplusFormScreen(), FakeResaleRepository(eligibleProducts: [vermicompost, usedUp, tooOften]));
      expect(find.text('Vermicompost'), findsOneWidget);
      expect(find.textContaining('You can list up to 5'), findsOneWidget);
      expect(find.textContaining('All of it is already listed'), findsOneWidget);
      expect(find.textContaining('Already listed 3 times this season'), findsOneWidget);
      await tester.tap(find.byKey(const Key('product-p-neemcake')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('units')), findsNothing, reason: 'a greyed-out product cannot be chosen');
    });

    testWidgets('nothing bought yet: an explanation instead of a form', (tester) async {
      await pump(tester, const SellSurplusFormScreen(), FakeResaleRepository(eligibleProducts: const []));
      expect(find.text('Nothing to sell yet'), findsOneWidget);
    });

    testWidgets('choosing a product asks the server for the price range and shows what the seller receives', (tester) async {
      final repo = FakeResaleRepository();
      await pump(tester, const SellSurplusFormScreen(), repo);
      await tester.tap(find.byKey(const Key('product-p-vermicompost')));
      await tester.pumpAndSettle();
      expect(repo.suggested.single.productId, 'p-vermicompost');
      expect(repo.suggested.single.condition, ResaleCondition.sealed);
      expect(find.text('₹383'), findsWidgets);
      expect(find.textContaining('Lowest ₹180'), findsOneWidget);
      expect(find.textContaining('Highest ₹405'), findsOneWidget);
      // 383 x 89% = 340.87, rounded to the rupee for display.
      expect(find.textContaining('You receive ₹341 for each'), findsOneWidget);
      // Cash keeps 97% of it.
      await tester.ensureVisible(find.byKey(const Key('payout-cash')));
      await tester.tap(find.byKey(const Key('payout-cash')));
      await tester.pump();
      expect(find.textContaining('You receive ₹331 for each'), findsOneWidget);
      expect(find.textContaining('Cash payout keeps 97%'), findsOneWidget);
    });

    testWidgets('changing the condition asks for a new suggestion', (tester) async {
      final repo = FakeResaleRepository();
      await pump(tester, const SellSurplusFormScreen(), repo);
      await tester.tap(find.byKey(const Key('product-p-vermicompost')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('condition-opened')));
      await tester.tap(find.byKey(const Key('condition-opened')));
      await tester.pumpAndSettle();
      expect(repo.suggested.last.condition, ResaleCondition.opened);
    });

    testWidgets('it will not send without both photos, the expiry date and a center', (tester) async {
      final repo = FakeResaleRepository();
      await pump(tester, const SellSurplusFormScreen(), repo);
      await tester.tap(find.byKey(const Key('product-p-vermicompost')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send for verification'));
      await tester.tap(find.text('Send for verification'));
      await tester.pump();
      expect(find.text('Enter the expiry date from the bag'), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('a complete form creates the listing with both photos and the chosen payout', (tester) async {
      final repo = FakeResaleRepository();
      final picker = FakePhotoPicker();
      await pump(tester, const SellSurplusFormScreen(), repo, picker: picker);
      await fillForm(tester);
      await tester.ensureVisible(find.byKey(const Key('units-plus')));
      await tester.tap(find.byKey(const Key('units-plus')));
      await tester.enterText(find.byKey(const Key('batch')), 'B-2201');
      await tester.ensureVisible(find.byKey(const Key('payout-upi')));
      await tester.tap(find.byKey(const Key('payout-upi')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('upi')), 'sunita@okbank');
      await tester.ensureVisible(find.text('Send for verification'));
      await tester.tap(find.text('Send for verification'));
      // The button keeps a spinner up while the dialog is open, so step through rather than settle.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final made = repo.created.single;
      expect(made.listing.productId, 'p-vermicompost');
      expect(made.listing.units, 2);
      expect(made.listing.askingPrice, 383);
      expect(made.listing.centerId, 'a');
      expect(made.listing.payoutMode, PayoutMode.upi);
      expect(made.listing.upiId, 'sunita@okbank');
      expect(made.listing.batchNumber, 'B-2201');
      expect(made.front, isNot(equals(made.back)), reason: 'two different photos');
      expect(find.text('Sent to your village center'), findsOneWidget);
    });

    testWidgets('UPI needs a real id, and a server refusal is shown', (tester) async {
      final repo = FakeResaleRepository()..createError = 'You have listed this product 3 times this season, which is the most allowed';
      await pump(tester, const SellSurplusFormScreen(), repo);
      await fillForm(tester);
      await tester.ensureVisible(find.byKey(const Key('payout-upi')));
      await tester.tap(find.byKey(const Key('payout-upi')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('upi')), 'nope');
      await tester.ensureVisible(find.text('Send for verification'));
      await tester.tap(find.text('Send for verification'));
      await tester.pump();
      expect(find.text('Enter your UPI id, like name@bank'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('upi')), 'asha@okbank');
      await tester.tap(find.text('Send for verification'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 times this season'), findsOneWidget);
      expect(repo.created, isEmpty);
    });
  });

  group('one listing', () {
    testWidgets('says what happens next for each stage', (tester) async {
      for (final (status, expected) in [
        (ResaleStatus.pendingVerification, 'Your village center is checking your photos.'),
        (ResaleStatus.inspectionRequired, 'Bring the bags to Shirur Center so they can be checked before they go on sale.'),
        (ResaleStatus.listed, 'Checked and at Shirur Center. Buyers can reserve it now.'),
        (ResaleStatus.rejected, 'Not accepted: batch number scratched off'),
      ]) {
        final repo = FakeResaleRepository(listings: [aListing('x', status: status, rejectReason: 'batch number scratched off')]);
        await pump(tester, const ResaleListingScreen(listingId: 'x'), repo);
        expect(find.text(expected), findsOneWidget, reason: status.name);
      }
    });

    testWidgets('a buyer is waiting: the deadline is shown prominently', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('x', status: ResaleStatus.awaitingHandover, due: DateTime(2026, 9, 28, 9, 5), reserved: 1)]);
      await pump(tester, const ResaleListingScreen(listingId: 'x'), repo);
      expect(find.byKey(const Key('due')), findsOneWidget);
      expect(find.text('Bring it by 28/9 at 09:05'), findsOneWidget);
      expect(find.byKey(const Key('withdraw')), findsNothing, reason: 'a buyer has reserved some');
    });

    testWidgets('shows the price, what the seller receives and each sale with its payout', (tester) async {
      final sale = ResaleSale(saleId: 's1', units: 1, gross: 380, sellerNet: 338.2, verified: true, payoutStatus: 'pending', createdAt: DateTime(2026, 9, 25));
      final repo = FakeResaleRepository(listings: [aListing('x', status: ResaleStatus.listed, finalPrice: 350, sold: 1, sales: [sale])]);
      await pump(tester, const ResaleListingScreen(listingId: 'x'), repo);
      expect(find.textContaining('₹350 each (lowered from ₹380)'), findsOneWidget);
      expect(find.text('₹338 for each'), findsOneWidget);
      expect(find.text('1 sold for ₹380  →  you earn ₹338'), findsOneWidget);
      expect(find.text('On its way (UPI)'), findsOneWidget);
    });

    testWidgets('an unsold listing can be withdrawn after confirming', (tester) async {
      final repo = FakeResaleRepository(listings: [aListing('x', status: ResaleStatus.live)]);
      await pump(tester, const ResaleListingScreen(listingId: 'x'), repo);
      await tester.ensureVisible(find.byKey(const Key('withdraw')));
      await tester.tap(find.byKey(const Key('withdraw')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-withdraw')));
      await tester.pumpAndSettle();
      expect(repo.calls, ['withdraw x']);
      expect(find.text('Withdrawn'), findsWidgets);
    });
  });

  group('the wallet', () {
    testWidgets('shows the balance and each credit and debit', (tester) async {
      final wallet = WalletState(balance: 250, entries: [
        WalletEntry(amount: 338.2, kind: 'resale_earning', note: 'Sold 1 x Vermicompost', createdAt: DateTime(2026, 9, 25)),
        WalletEntry(amount: -450, kind: 'order_payment', note: '', createdAt: DateTime(2026, 9, 26)),
      ]);
      await pump(tester, const FarmerWalletScreen(), FakeResaleRepository(walletState: wallet));
      expect(find.text('₹250'), findsOneWidget);
      expect(find.text('Fertilizer sold'), findsOneWidget);
      expect(find.text('+₹338'), findsOneWidget);
      expect(find.text('Paid for an order'), findsOneWidget);
      expect(find.text('−₹450'), findsOneWidget);
    });

    testWidgets('an empty wallet invites selling', (tester) async {
      await pump(tester, const FarmerWalletScreen(), FakeResaleRepository());
      expect(find.textContaining('Nothing yet'), findsOneWidget);
    });
  });

  group('on an order', () {
    Future<FakePaymentsRepository> pumpOrder(WidgetTester tester, FarmerOrder order, FakeResaleRepository resale) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final pay = FakePaymentsRepository();
      final orders = FakeOrdersRepository()..orders = [order];
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(orders),
          paymentsRepositoryProvider.overrideWithValue(pay),
          paymentCheckoutProvider.overrideWithValue(FakeCheckout(const CheckoutCancelled())),
          resaleRepositoryProvider.overrideWithValue(resale),
        ],
        child: MaterialApp(theme: AppTheme.light, home: FarmerOrderDetailScreen(orderId: order.id)),
      ));
      await tester.pumpAndSettle();
      return pay;
    }

    testWidgets('"Pay from wallet" appears only when the wallet covers the goods', (tester) async {
      await pumpOrder(tester, farmerOrder('o1'), FakeResaleRepository(walletState: const WalletState(balance: 1199, entries: [])));
      expect(find.byKey(const Key('pay-wallet')), findsNothing);
      await pumpOrder(tester, farmerOrder('o1'), FakeResaleRepository(walletState: const WalletState(balance: 1500, entries: [])));
      expect(find.byKey(const Key('pay-wallet')), findsOneWidget);
    });

    testWidgets('paying from the wallet asks the server and confirms', (tester) async {
      final pay = await pumpOrder(tester, farmerOrder('o1'), FakeResaleRepository(walletState: const WalletState(balance: 5000, entries: [])));
      await tester.tap(find.byKey(const Key('pay-wallet')));
      await tester.pumpAndSettle();
      expect(pay.walletPaid, ['o1']);
      expect(find.text('Paid from your wallet.'), findsOneWidget);
    });

    testWidgets('a collected surplus order offers "Report a problem", which needs a real reason', (tester) async {
      final surplus = FarmerOrder(
        id: 's1',
        status: FarmerOrderStatus.completed,
        createdAt: DateTime(2026, 9, 24),
        items: const [OrderLine(productName: 'Vermicompost', quantity: 1, unitPrice: 380, surplusLotId: 'lot-1')],
        totalAmount: 380,
      );
      final resale = FakeResaleRepository();
      await pumpOrder(tester, surplus, resale);
      await tester.tap(find.byKey(const Key('report-problem')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('problem-send'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('problem-reason')), 'Damp and clumped');
      await tester.pump();
      await tester.tap(find.byKey(const Key('problem-send')));
      await tester.pumpAndSettle();
      expect(resale.disputesRaised.single, (orderId: 's1', reason: 'Damp and clumped'));
      expect(find.textContaining('platform will review it'), findsOneWidget);
    });

    testWidgets('an ordinary collected order has no "Report a problem"', (tester) async {
      await pumpOrder(tester, farmerOrder('o1', status: FarmerOrderStatus.completed), FakeResaleRepository());
      expect(find.byKey(const Key('report-problem')), findsNothing);
    });
  });
}
