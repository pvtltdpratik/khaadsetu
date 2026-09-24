import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/delivery/domain/entities/delivery_models.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/providers/document_picker.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/screens/delivery_hub_screen.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/screens/loads_screens.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/screens/trips_screen.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/screens/wallet_screen.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/nearby_center.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';

import 'support/delivery_fakes.dart';
import 'support/farmer_fakes.dart';

class _FakePicker implements DocumentPicker {
  final picked = <bool>[];

  @override
  Future<PickedDocument?> pick({required bool camera}) async {
    picked.add(camera);
    return PickedDocument(bytes: Uint8List.fromList([1, 2, 3]), filename: 'photo.jpg');
  }
}

const _talegaon = Village(name: 'Talegaon', district: 'Pune', latitude: 18.86, longitude: 74.3);

Future<void> _pump(WidgetTester tester, Widget screen, FakeDeliveryRepository repo, {_FakePicker? picker, GoRouter? router}) async {
  tester.view.physicalSize = const Size(430, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final r = router ??
      GoRouter(routes: [
        GoRoute(path: '/', builder: (context, _) => screen),
        GoRoute(path: RoutePaths.farmerDeliverWallet, builder: (context, _) => const WalletScreen()),
        GoRoute(path: RoutePaths.farmerDeliverTrips, builder: (context, _) => const TripsScreen()),
        GoRoute(path: RoutePaths.farmerLoads, builder: (context, _) => const MyLoadsScreen()),
      ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      deliveryRepositoryProvider.overrideWithValue(repo),
      documentPickerProvider.overrideWithValue(picker ?? _FakePicker()),
      centersRepositoryProvider.overrideWithValue(FakeCentersRepository(villageList: const [_talegaon])),
      deviceLocationProvider.overrideWithValue(FakeDeviceLocation(result: shirur)),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: r),
  ));
  await tester.pumpAndSettle();
}

/// Timers from live-refreshing screens end when the tree goes away.
Future<void> _end(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  group('becoming a delivery partner', () {
    testWidgets('fill the form, save, add both papers, then send it for checking', (tester) async {
      final repo = FakeDeliveryRepository();
      final picker = _FakePicker();
      await _pump(tester, const DeliveryHubScreen(), repo, picker: picker);

      expect(find.text('Earn by delivering for other farmers'), findsOneWidget);
      // Nothing can be sent yet, and the photo buttons wait for the details to be saved.
      expect(tester.widget<FilledButton>(find.byKey(const Key('submit-application'))).onPressed, isNull);
      expect(tester.widget<IconButton>(find.byKey(const Key('gallery-licence'))).onPressed, isNull);
      expect(find.textContaining('Still needed: the type of vehicle'), findsOneWidget);

      await tester.tap(find.byKey(const Key('vehicle-pickup')));
      await tester.enterText(find.byKey(const Key('vehicle-number')), 'MH12AB1234');
      await tester.enterText(find.byKey(const Key('vehicle-capacity')), '600');
      await tester.enterText(find.byKey(const Key('partner-phone')), '9876543210');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('review-center')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Center a · 3.0 km').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-details')));
      await tester.pumpAndSettle();
      final saved = repo.saved.single;
      expect(saved['vehicleType'], 'pickup');
      expect(saved['vehicleNumber'], 'MH12AB1234');
      expect(saved['capacityKg'], 600);
      expect(saved['phone'], '9876543210');
      expect(saved['reviewCenterId'], 'a');
      expect(saved['days'], [0, 1, 2, 3, 4, 5, 6]);
      expect(saved['maxDistanceKm'], 10);

      // Now the papers can be added, and the send button follows.
      expect(find.textContaining('Still needed: a photo of your driving licence, a photo of the RC'), findsOneWidget);
      await tester.tap(find.byKey(const Key('gallery-licence')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('camera-rc')));
      await tester.pumpAndSettle();
      expect(repo.uploads, ['licence', 'rc']);
      expect(picker.picked, [false, true]);
      expect(find.text('Added (1 KB)'), findsNWidgets(2));
      expect(tester.widget<FilledButton>(find.byKey(const Key('submit-application'))).onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('submit-application')));
      await tester.pumpAndSettle();
      expect(repo.calls, containsAllInOrder(['savePartner', 'upload:licence', 'upload:rc', 'savePartner', 'submit']));
      expect(find.byKey(const Key('waiting-card')), findsOneWidget);
      expect(find.text('Waiting for the village center'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('a server refusal is shown, not swallowed', (tester) async {
      final repo = FakeDeliveryRepository();
      await _pump(tester, const DeliveryHubScreen(), repo);
      repo.error = Exception('A pickup can carry 100 to 1500 kg');
      await tester.tap(find.byKey(const Key('save-details')));
      await tester.pumpAndSettle();
      expect(find.textContaining('A pickup can carry 100 to 1500 kg'), findsOneWidget);
    });

    testWidgets('a rejected application says why, and can be fixed and sent again', (tester) async {
      final repo = FakeDeliveryRepository()
        ..profile = partnerProfile(status: PartnerStatus.rejected, vehicle: VehicleType.pickup, number: 'MH12AB1234', capacity: 600, phone: '9876543210', licence: true, rc: true, centerId: 'a', rejection: 'The RC photo is blurred');
      await _pump(tester, const DeliveryHubScreen(), repo);
      expect(find.byKey(const Key('rejected-note')), findsOneWidget);
      expect(find.text('The RC photo is blurred'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('submit-application'))).onPressed, isNotNull, reason: 'everything is on file, so it can go again');
    });

    testWidgets('while it waits there is nothing to edit, just a note', (tester) async {
      final repo = FakeDeliveryRepository()..profile = partnerProfile(status: PartnerStatus.pending, vehicle: VehicleType.tractor, number: 'MH12XX9999', capacity: 2000, phone: '9876543210', licence: true, rc: true, centerId: 'a');
      await _pump(tester, const DeliveryHubScreen(), repo);
      expect(find.byKey(const Key('waiting-card')), findsOneWidget);
      expect(find.textContaining('Center a is checking your licence and RC'), findsOneWidget);
      expect(find.byKey(const Key('vehicle-number')), findsNothing);
      await _end(tester);
    });

    testWidgets('a suspended partner is told to talk to their center', (tester) async {
      final repo = FakeDeliveryRepository()..profile = partnerProfile(status: PartnerStatus.suspended, vehicle: VehicleType.bike, number: 'MH12AA1', capacity: 40, phone: '9876543210', licence: true, rc: true);
      await _pump(tester, const DeliveryHubScreen(), repo);
      expect(find.byKey(const Key('suspended-card')), findsOneWidget);
      expect(find.textContaining('contact your village center'), findsOneWidget);
    });
  });

  group('working as a delivery partner', () {
    FakeDeliveryRepository approved({bool online = true}) => FakeDeliveryRepository()
      ..profile = partnerProfile(status: PartnerStatus.approved, vehicle: VehicleType.pickup, number: 'MH12AB1234', capacity: 600, phone: '9876543210', licence: true, rc: true, online: online, centerId: 'a');

    testWidgets('the free-now switch turns jobs on and off, and tells the server where I am', (tester) async {
      final repo = approved(online: false);
      await _pump(tester, const DeliveryHubScreen(), repo);
      expect(find.text('Switch on "I can deliver now" to get jobs near you.'), findsOneWidget);
      expect(repo.locations, isEmpty, reason: 'off: nothing is shared');

      await tester.tap(find.byKey(const Key('online-switch')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('online:true'));
      expect(repo.locations.single.latitude, shirur.latitude, reason: 'going on shares where I am');
      expect(find.textContaining('You are on.'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('an offer shows the money and the way; accepting it makes it my job with a handover code', (tester) async {
      final repo = approved()..offerList = [partnerJob('job-1')];
      await _pump(tester, const DeliveryHubScreen(), repo);

      expect(find.text('₹60'), findsWidgets);
      expect(find.text('40 kg · 6.5 km'), findsOneWidget);
      expect(find.text('1 x Vermicompost'), findsOneWidget);
      expect(find.text('Shirur'), findsOneWidget);
      expect(find.textContaining('Answer within'), findsOneWidget);
      expect(find.byKey(const Key('handover-code')), findsNothing, reason: 'the code appears only once it is mine');

      await tester.tap(find.byKey(const Key('accept-job-1')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('accept:job-1'));
      expect(find.byKey(const Key('active-job-1')), findsOneWidget);
      expect(find.text('Collect from Center a'), findsOneWidget);
      expect(find.text('4821'), findsOneWidget);
      expect(find.textContaining('Read this code to the operator'), findsOneWidget);
      expect(find.byKey(const Key('offer-job-1')), findsNothing);
      expect(find.textContaining('Keep your fee ₹60; hand the rest, ₹1,200, to the village center'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('losing the race to another partner shows their message and clears the offer', (tester) async {
      final repo = approved()..offerList = [partnerJob('job-1')];
      await _pump(tester, const DeliveryHubScreen(), repo);
      repo.error = Exception('Another partner already took this job');
      repo.offerList = [];
      await tester.tap(find.byKey(const Key('accept-job-1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Another partner already took this job'), findsOneWidget);
      expect(find.byKey(const Key('offer-job-1')), findsNothing);
      await _end(tester);
    });

    testWidgets('not now turns an offer down', (tester) async {
      final repo = approved()..offerList = [partnerJob('job-1'), partnerJob('job-2')];
      await _pump(tester, const DeliveryHubScreen(), repo);
      await tester.tap(find.byKey(const Key('decline-job-1')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('decline:job-1'));
      expect(find.byKey(const Key('offer-job-1')), findsNothing);
      expect(find.byKey(const Key('offer-job-2')), findsOneWidget);
      await _end(tester);
    });

    testWidgets('two jobs on one trip are called out, each with its own code', (tester) async {
      final repo = approved()
        ..activeList = [partnerJob('job-1', status: DeliveryStatus.assigned, mine: true, handover: '1111'), partnerJob('job-2', status: DeliveryStatus.assigned, mine: true, handover: '2222')];
      await _pump(tester, const DeliveryHubScreen(), repo);
      expect(find.byKey(const Key('batch-banner')), findsOneWidget);
      expect(find.textContaining('You are carrying 2 orders'), findsOneWidget);
      expect(find.text('1111'), findsOneWidget);
      expect(find.text('2222'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('on the road: the drop, the note and the cash; the buyer\'s code delivers it and pays the fee', (tester) async {
      final repo = approved()..activeList = [partnerJob('job-1', status: DeliveryStatus.inTransit, mine: true)];
      await _pump(tester, const DeliveryHubScreen(), repo);

      expect(find.text('Deliver to Suresh'), findsOneWidget);
      expect(find.textContaining('Near the temple, Shirur'), findsOneWidget);
      expect(find.text('Note: Blue gate'), findsOneWidget);
      expect(find.textContaining('Collect ₹1,260 in cash from the buyer'), findsOneWidget);
      expect(find.byKey(const Key('handover-code')), findsNothing, reason: 'the goods are already his');

      await tester.tap(find.byKey(const Key('enter-drop-code')));
      await tester.pumpAndSettle();
      // Only four digits can go in, and the button waits for all four.
      await tester.enterText(find.byKey(const Key('code-field')), '73ab91234');
      await tester.pump();
      expect(tester.widget<TextField>(find.byKey(const Key('code-field'))).controller!.text, '7391');
      await tester.tap(find.byKey(const Key('code-submit')));
      await tester.pumpAndSettle();

      expect(repo.delivered.single, (jobId: 'job-1', otp: '7391'));
      expect(find.textContaining('Delivered. ₹60 is yours.'), findsOneWidget);
      // He is asked to rate the farmer.
      expect(find.text('How was the farmer?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('star-5')));
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(repo.buyerRatings.single, (jobId: 'job-1', stars: 5));
      expect(find.byKey(const Key('active-job-1')), findsNothing);
      await _end(tester);
    });

    testWidgets('a wrong delivery code shows how many tries are left, and the job stays', (tester) async {
      final repo = approved()..activeList = [partnerJob('job-1', status: DeliveryStatus.inTransit, mine: true)];
      await _pump(tester, const DeliveryHubScreen(), repo);
      await tester.tap(find.byKey(const Key('enter-drop-code')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('code-field')), '0000');
      await tester.pump();
      repo.error = wrongCodeError(4);
      await tester.tap(find.byKey(const Key('code-submit')));
      await tester.pumpAndSettle();
      expect(find.text('That code is wrong. 4 tries left.'), findsOneWidget);
      expect(find.byKey(const Key('active-job-1')), findsOneWidget);
      expect(find.text('How was the farmer?'), findsNothing);
      await _end(tester);
    });

    testWidgets('giving a job back asks first', (tester) async {
      final repo = approved()..activeList = [partnerJob('job-1', status: DeliveryStatus.assigned, mine: true)];
      await _pump(tester, const DeliveryHubScreen(), repo);
      await tester.tap(find.byKey(const Key('give-back')));
      await tester.pumpAndSettle();
      expect(find.text('Give this job back?'), findsOneWidget);
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(repo.calls, isNot(contains('decline:job-1')));

      await tester.tap(find.byKey(const Key('give-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Give it back'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('decline:job-1'));
      await _end(tester);
    });

    testWidgets('farmer-to-farmer jobs read differently: the sender types the code and pays the fee', (tester) async {
      final repo = approved()..activeList = [partnerJob('load-1', status: DeliveryStatus.assigned, mine: true, p2p: true, fee: 45, items: 'Two sacks of seed potatoes')];
      await _pump(tester, const DeliveryHubScreen(), repo);
      expect(find.text('Collect from the sender'), findsOneWidget);
      expect(find.textContaining('Give this code to the sender'), findsOneWidget);
      expect(find.textContaining('The sender pays your fee, ₹45'), findsOneWidget);
      expect(find.text('Call sender'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('changing my details warns that a new vehicle means a new check', (tester) async {
      final repo = approved();
      await _pump(tester, const DeliveryHubScreen(), repo);
      await tester.tap(find.byKey(const Key('edit-details')));
      await tester.pumpAndSettle();
      expect(find.textContaining('sends you back to the village center to be checked again'), findsOneWidget);
      expect(find.byKey(const Key('submit-application')), findsNothing, reason: 'nothing to send again');
      await tester.tap(find.byKey(const Key('save-details')));
      await tester.pumpAndSettle();
      expect(repo.saved.single['maxDistanceKm'], 10);
      await _end(tester);
    });

    testWidgets('the dashboard links to money, trips and loads', (tester) async {
      final repo = approved();
      await _pump(tester, const DeliveryHubScreen(), repo);
      await tester.tap(find.byKey(const Key('open-wallet')));
      await tester.pumpAndSettle();
      expect(find.text('You have earned'), findsOneWidget);
      await _end(tester);
    });
  });

  group('the wallet', () {
    testWidgets('shows what I earned, what I owe which center, and each entry', (tester) async {
      final repo = FakeDeliveryRepository()
        ..walletAnswer = aWallet(entries: [
          WalletEntry(kind: LedgerKind.feeEarned, amount: 60, note: 'Delivery fee', createdAt: DateTime(2026, 9, 24)),
          WalletEntry(kind: LedgerKind.goodsOwed, amount: 1200, note: 'Cash for the goods', createdAt: DateTime(2026, 9, 24)),
          WalletEntry(kind: LedgerKind.goodsSettled, amount: -400, note: 'Handed over', createdAt: DateTime(2026, 9, 25)),
        ]);
      await _pump(tester, const WalletScreen(), repo);
      expect(find.text('₹240'), findsOneWidget);
      expect(find.text('9 deliveries · ★ 4.5 (4)'), findsOneWidget);
      expect(find.text('Hand this cash to the village center'), findsOneWidget);
      expect(find.byKey(const Key('owed')), findsOneWidget);
      expect(find.text('₹1,200'), findsWidgets);
      expect(find.text('Delivery fee earned'), findsOneWidget);
      expect(find.text('+₹60'), findsOneWidget);
      expect(find.text('-₹400'), findsOneWidget);
      expect(find.text('Handed to the center'), findsOneWidget);
    });

    testWidgets('owing nothing is said plainly, and an empty history has a note', (tester) async {
      final repo = FakeDeliveryRepository()..walletAnswer = aWallet(earned: 0, owed: 0, entries: const []);
      await _pump(tester, const WalletScreen(), repo);
      expect(find.text('You owe nothing to any center'), findsOneWidget);
      expect(find.byKey(const Key('owed')), findsNothing);
      expect(find.textContaining('Your first delivery will show up here'), findsOneWidget);
    });
  });

  group('trips', () {
    testWidgets('an empty list explains what a trip is', (tester) async {
      await _pump(tester, const TripsScreen(), FakeDeliveryRepository());
      expect(find.byKey(const Key('no-trips')), findsOneWidget);
    });

    testWidgets('post a trip: pick both places, the room, and it is on the list', (tester) async {
      final repo = FakeDeliveryRepository();
      await _pump(tester, const TripsScreen(), repo);
      await tester.tap(find.byKey(const Key('post-trip')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('trip-submit'))).onPressed, isNull);

      // From: where I am.
      await tester.tap(find.byKey(const Key('trip-from')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('use-my-location')));
      await tester.pumpAndSettle();
      // To: a village from the list.
      await tester.tap(find.byKey(const Key('trip-to')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Talegaon'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('trip-spare')), '80');
      await tester.enterText(find.byKey(const Key('trip-note')), 'Going to the market');
      await tester.pump();
      await tester.tap(find.byKey(const Key('trip-submit')));
      await tester.pumpAndSettle();

      final t = repo.posted.single;
      expect(t.from.latitude, shirur.latitude);
      expect(t.to.label, 'Talegaon');
      expect(t.spareKg, 80);
      expect(t.note, 'Going to the market');
      expect(find.text('Talegaon'), findsNothing, reason: 'the sheet is closed');
      expect(find.byKey(const Key('trip-trip-1')), findsOneWidget);
      expect(find.text('80 of 80 kg left · 0 bookings'), findsOneWidget);
    });

    testWidgets('cancelling a trip asks first', (tester) async {
      final repo = FakeDeliveryRepository()..trips = [trip('t1', spare: 60, left: 20)];
      await _pump(tester, const TripsScreen(), repo);
      expect(find.text('20 of 60 kg left · 1 booking'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel-t1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Farmers who booked room are told'), findsOneWidget);
      await tester.tap(find.text('Cancel trip').last);
      await tester.pumpAndSettle();
      expect(repo.calls, contains('cancelTrip:t1'));
      expect(find.byKey(const Key('trip-t1')), findsNothing);
    });
  });

  group('carrying a load for another farmer', () {
    Future<void> fillLoad(WidgetTester tester, {bool toVillage = true}) async {
      await tester.tap(find.byKey(const Key('load-from')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('use-my-location')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('load-from-phone')), '98220 12345');
      await tester.tap(find.byKey(const Key('load-to')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Talegaon'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('load-to-phone')), '98220 54321');
      await tester.enterText(find.byKey(const Key('load-what')), 'Two sacks of seed potatoes');
      await tester.enterText(find.byKey(const Key('load-weight')), '30');
      await tester.pumpAndSettle();
    }

    testWidgets('the fee is quoted, and the request goes off when everything is filled in', (tester) async {
      final repo = FakeDeliveryRepository();
      final router = GoRouter(initialLocation: RoutePaths.farmerLoadNew, routes: [
        GoRoute(path: RoutePaths.farmerLoadNew, builder: (context, _) => const SendLoadScreen()),
        GoRoute(path: '${RoutePaths.farmerLoads}/:id', builder: (context, state) => LoadDetailScreen(jobId: state.pathParameters['id']!)),
      ]);
      await _pump(tester, const SizedBox(), repo, router: router);
      expect(tester.widget<FilledButton>(find.byKey(const Key('send-submit'))).onPressed, isNull);

      await fillLoad(tester);
      expect(find.byKey(const Key('load-fee')), findsOneWidget);
      expect(find.text('₹45'), findsOneWidget);
      expect(find.textContaining('A delivery partner nearby is free right now.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('fee-payer')).first);
      await tester.tap(find.text('Receiver pays'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('send-submit')));
      await tester.pumpAndSettle();

      final sent = repo.sent.single;
      expect(sent.weightKg, 30);
      expect(sent.description, 'Two sacks of seed potatoes');
      expect(sent.feePayer, 'receiver');
      expect(sent.fromPhone, '98220 12345');
      expect(sent.toPhone, '98220 54321');
      expect(sent.to.label, 'Talegaon');
      expect(sent.tripId, isNull);
      // Straight to following it.
      expect(find.text('Your load'), findsOneWidget);
      expect(find.text('Finding a delivery partner'), findsWidgets);
      await _end(tester);
    });

    testWidgets('a distance that is too far cannot be sent, and says so', (tester) async {
      final repo = FakeDeliveryRepository()..loadQuoteAnswer = const LoadQuote(available: false, fee: null, roadKm: 40, partnersFree: 0, note: 'A delivery goes up to 20 km by road. This one is about 40 km.');
      await _pump(tester, const SendLoadScreen(), repo);
      await fillLoad(tester);
      expect(find.textContaining('up to 20 km by road'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('send-submit'))).onPressed, isNull);
    });

    testWidgets('a farmer already going that way can be chosen, and the load books his trip', (tester) async {
      final repo = FakeDeliveryRepository()
        ..board = [
          Trip(
            id: 'trip-9',
            from: GeoPoint(latitude: shirur.latitude + 0.001, longitude: shirur.longitude, label: 'Shirur'),
            to: const GeoPoint(latitude: 18.865, longitude: 74.3, label: 'Talegaon'),
            date: DateTime(2026, 9, 25),
            spareKg: 60,
            leftKg: 60,
            bookings: 0,
            partnerName: 'Ganesh',
            vehicleType: VehicleType.pickup,
            ratingAvg: 4.4,
            fromKm: 0.1,
          ),
          // Starts near me but goes the wrong way: not offered.
          Trip(id: 'trip-far', from: const GeoPoint(latitude: 18.83, longitude: 74.37, label: 'Shirur'), to: const GeoPoint(latitude: 19.5, longitude: 75, label: 'Nashik'), date: DateTime(2026, 9, 25), spareKg: 10, leftKg: 10, bookings: 0, partnerName: 'Other'),
        ];
      await _pump(tester, const SendLoadScreen(), repo);
      await fillLoad(tester);
      expect(find.byKey(const Key('board-trip-9')), findsOneWidget);
      expect(find.byKey(const Key('board-trip-far')), findsNothing);
      expect(find.text('Ask for a delivery partner'), findsOneWidget);

      await tester.tap(find.byKey(const Key('board-trip-9')));
      await tester.pumpAndSettle();
      expect(find.text('Book this trip'), findsOneWidget);
      await tester.tap(find.byKey(const Key('send-submit')));
      await tester.pump();
      expect(repo.sent.single.tripId, 'trip-9');
      await tester.pumpAndSettle();
    });

    testWidgets('following a load: hand it over with the partner\'s code, or call it off', (tester) async {
      final repo = FakeDeliveryRepository()..loads = [aTracking(jobId: 'load-1', status: DeliveryStatus.assigned, p2p: true, canCancel: true, dropCode: '5150')];
      final router = GoRouter(initialLocation: RoutePaths.farmerLoad('load-1'), routes: [
        GoRoute(path: '${RoutePaths.farmerLoads}/:id', builder: (context, state) => LoadDetailScreen(jobId: state.pathParameters['id']!)),
      ]);
      await _pump(tester, const SizedBox(), repo, router: router);

      expect(find.text('Ramesh Patil'), findsOneWidget);
      expect(find.text('5150'), findsOneWidget, reason: 'the sender holds the drop code for the receiver');
      expect(find.text('Two sacks of seed potatoes · 40 kg'), findsOneWidget);
      expect(find.textContaining('You pay the delivery fee, ₹60'), findsOneWidget);

      await tester.tap(find.text('Hand over the load'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('code-field')), '4821');
      await tester.pump();
      await tester.tap(find.byKey(const Key('code-submit')));
      await tester.pumpAndSettle();
      expect(repo.handedOver.single, (jobId: 'load-1', otp: '4821'));
      expect(find.text('On its way to the receiver'), findsWidgets);
      expect(find.text('Hand over the load'), findsNothing);
      await _end(tester);
    });

    testWidgets('a wrong handover code is reported and nothing changes', (tester) async {
      final repo = FakeDeliveryRepository()..loads = [aTracking(jobId: 'load-1', status: DeliveryStatus.assigned, p2p: true, canCancel: true)];
      final router = GoRouter(initialLocation: RoutePaths.farmerLoad('load-1'), routes: [
        GoRoute(path: '${RoutePaths.farmerLoads}/:id', builder: (context, state) => LoadDetailScreen(jobId: state.pathParameters['id']!)),
      ]);
      await _pump(tester, const SizedBox(), repo, router: router);
      await tester.tap(find.text('Hand over the load'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('code-field')), '0000');
      await tester.pump();
      repo.error = wrongCodeError(3);
      await tester.tap(find.byKey(const Key('code-submit')));
      await tester.pumpAndSettle();
      expect(find.text('That code is wrong. 3 tries left.'), findsOneWidget);
      expect(find.text('Hand over the load'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('cancelling a load asks first', (tester) async {
      final repo = FakeDeliveryRepository()..loads = [aTracking(jobId: 'load-1', status: DeliveryStatus.open, p2p: true, canCancel: true)];
      final router = GoRouter(initialLocation: RoutePaths.farmerLoad('load-1'), routes: [
        GoRoute(path: '${RoutePaths.farmerLoads}/:id', builder: (context, state) => LoadDetailScreen(jobId: state.pathParameters['id']!)),
      ]);
      await _pump(tester, const SizedBox(), repo, router: router);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this request?'), findsOneWidget);
      await tester.tap(find.text('Cancel request'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('cancelLoad:load-1'));
      await _end(tester);
    });

    testWidgets('the list of loads: empty explains itself; a load opens its page', (tester) async {
      final empty = FakeDeliveryRepository();
      await _pump(tester, const MyLoadsScreen(), empty);
      expect(find.byKey(const Key('no-loads')), findsOneWidget);

      final repo = FakeDeliveryRepository()..loads = [aTracking(jobId: 'load-1', status: DeliveryStatus.inTransit, p2p: true)];
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, _) => const MyLoadsScreen()),
        GoRoute(path: '${RoutePaths.farmerLoads}/:id', builder: (context, state) => LoadDetailScreen(jobId: state.pathParameters['id']!)),
      ]);
      await _pump(tester, const SizedBox(), repo, router: router);
      expect(find.text('Two sacks of seed potatoes'), findsOneWidget);
      expect(find.text('On its way to the receiver'), findsOneWidget);
      await tester.tap(find.byKey(const Key('load-load-1')));
      await tester.pumpAndSettle();
      expect(find.text('Your load'), findsOneWidget);
      await _end(tester);
    });
  });
}
