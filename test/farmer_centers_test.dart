import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/availability_message.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/nearby_center.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/repositories/centers_repository.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/screens/nearby_centers_screen.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/screens/village_picker_screen.dart';

import 'support/farmer_fakes.dart';

NearbyResult _result(List<NearbyCenter> centers) => NearbyResult(location: shirur, radiusKm: 10, centers: centers);

void main() {
  group('describeAvailability', () {
    test('the nearest center has it and is open: ready for pickup', () {
      final m = describeAvailability(_result([nearbyCenter('a', km: 2.3, recommended: true), nearbyCenter('b', km: 8.1)]), quantity: 1);
      expect(m.kind, AvailabilityKind.readyForPickup);
      expect(m.text, 'Available at Center a, 2.3 km away. Ready for pickup.');
      expect(m.centerId, 'a');
      expect(m.canReserve, isTrue);
    });

    test('the nearest has it but is closed: reserve now, collect when it opens', () {
      final m = describeAvailability(_result([nearbyCenter('a', open: false, hoursLabel: 'Opens tomorrow at 09:00')]), quantity: 1);
      expect(m.kind, AvailabilityKind.closedNow);
      expect(m.text, contains('Opens tomorrow at 09:00'));
      expect(m.text, contains('collect it when they open'));
      expect(m.centerId, 'a');
    });

    test('the nearest lacks it but another has it: points to the other one', () {
      final m = describeAvailability(_result([nearbyCenter('a', km: 2, have: 0), nearbyCenter('b', km: 8.1)]), quantity: 1);
      expect(m.kind, AvailabilityKind.elsewhere);
      expect(m.text, 'Not available at your nearest center. Available at Center b, 8.1 km away.');
      expect(m.centerId, 'b');
    });

    test('the center that has it is closed: says so', () {
      final m = describeAvailability(
        _result([nearbyCenter('a', km: 2, have: 0), nearbyCenter('b', km: 8.1, open: false, hoursLabel: 'Opens today at 09:00')]),
        quantity: 1,
      );
      expect(m.text, endsWith('8.1 km away (opens today at 09:00).'));
    });

    test('the nearest of several that have it wins', () {
      final m = describeAvailability(_result([nearbyCenter('far', km: 9), nearbyCenter('mid', km: 5), nearbyCenter('none', km: 1, have: 0)]), quantity: 1);
      expect(m.centerId, 'mid');
    });

    test('some stock but nowhere enough: says how many, suggests fewer, cannot reserve', () {
      final m = describeAvailability(
        _result([nearbyCenter('a', km: 2, have: 3, wanted: 5), nearbyCenter('b', km: 4, have: 1, wanted: 5)]),
        quantity: 5,
      );
      expect(m.kind, AvailabilityKind.partial);
      expect(m.text, startsWith('Only 3 available at Center a, 2.0 km away; you need 5.'));
      expect(m.text, contains('smaller quantity'));
      expect(m.canReserve, isFalse);
    });

    test('nothing anywhere: out of stock', () {
      final m = describeAvailability(_result([nearbyCenter('a', have: 0), nearbyCenter('b', have: 0)]), quantity: 1);
      expect(m.kind, AvailabilityKind.outOfStock);
      expect(m.text, 'Currently out of stock at centers near you.');
      expect(m.canReserve, isFalse);
    });

    test('no centers in range at all', () {
      final m = describeAvailability(_result(const []), quantity: 1);
      expect(m.kind, AvailabilityKind.noCenters);
      expect(m.canReserve, isFalse);
    });
  });

  group('parsing the server response', () {
    test('a nearby center, exactly as the API sends it', () {
      final n = NearbyCenter.fromJson({
        'center': {'centerId': 'c1', 'name': 'Kendra', 'village': 'Shirur', 'district': 'Pune', 'latitude': 18.83, 'longitude': 74.38, 'operatorName': 'Olga', 'phone': '98220', 'rating': null},
        'distanceKm': 2.2,
        'estimatedTravelMinutes': 6,
        'travelTimeIsEstimate': true,
        'inventory': {
          'status': 'partial',
          'label': '1 of 2 items available',
          'availableItems': 1,
          'totalItems': 2,
          'items': [
            {'productId': 'p1', 'requested': 2, 'available': 5, 'isFullyAvailable': true},
            {'productId': 'p2', 'requested': 1, 'available': 0, 'isFullyAvailable': false},
          ],
        },
        'hours': {'isOpenNow': true, 'isSwitchedOn': true, 'opensAt': '09:00', 'closesAt': '18:00', 'minutesUntilOpen': 0, 'label': 'Open until 18:00'},
        'pendingPickups': 3,
        'scores': {'distance': 99.4, 'inventory': 50.0, 'operational': 90.0, 'historical': 50.0, 'total': 75.1},
        'isHomeCenter': false,
        'isRecommended': true,
        'recommendationReason': '2.2 km away, 1 of 2 items available',
      });
      expect(n.center.name, 'Kendra');
      expect(n.inventory.status, InventoryStatus.partial);
      expect(n.inventory.items.last.isFullyAvailable, isFalse);
      expect(n.hours.label, 'Open until 18:00');
      expect(n.recommendationReason, contains('1 of 2'));
    });

    test('with no cart the inventory verdict is null', () {
      final n = NearbyCenter.fromJson({
        'center': {'centerId': 'c1', 'name': 'K', 'village': 'V', 'district': '', 'latitude': 1, 'longitude': 2, 'operatorName': '', 'phone': ''},
        'distanceKm': 1,
        'estimatedTravelMinutes': 2,
        'inventory': {'status': null, 'label': null, 'availableItems': 0, 'totalItems': 0, 'items': []},
        'hours': {'isOpenNow': false, 'opensAt': '09:00', 'closesAt': '18:00', 'label': 'Closed by operator'},
        'pendingPickups': 0,
        'isHomeCenter': false,
        'isRecommended': false,
      });
      expect(n.inventory.status, isNull);
      expect(n.center.hasPhone, isFalse);
      expect(n.recommendationReason, isNull);
    });
  });

  group('where the farmer is', () {
    ProviderContainer container(FakeDeviceLocation device, FakeCentersRepository repo) {
      final c = ProviderContainer(overrides: [deviceLocationProvider.overrideWithValue(device), centersRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      return c;
    }

    const saved = FarmerLocation(latitude: 19, longitude: 75, source: LocationSource.pin);

    ProviderContainer container2(DeviceLocation device, FakeCentersRepository repo) {
      final c = ProviderContainer(overrides: [deviceLocationProvider.overrideWithValue(device), centersRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(c.dispose);
      return c;
    }

    test('GPS first, and it is remembered on the profile', () async {
      final repo = FakeCentersRepository(saved: saved);
      final loc = await container(FakeDeviceLocation(result: shirur), repo).read(farmerLocationProvider.future);
      expect(loc, shirur);
      await Future<void>.delayed(Duration.zero);
      expect(repo.savedLocations, [shirur]);
    });

    for (final failure in [const LocationUnavailable('off'), Exception('boom')]) {
      test('GPS fails (${failure.runtimeType}): falls back to the saved location', () async {
        final repo = FakeCentersRepository(saved: saved);
        expect(await container(FakeDeviceLocation(error: failure), repo).read(farmerLocationProvider.future), saved);
        expect(repo.savedLocations, isEmpty, reason: 'nothing new to remember');
      });
    }

    test('no GPS and nothing saved: unknown, so the app asks', () async {
      expect(await container(FakeDeviceLocation(error: const LocationUnavailable('off')), FakeCentersRepository()).read(farmerLocationProvider.future), isNull);
    });

    test('a failing profile lookup is also just "unknown"', () async {
      final repo = _ThrowingRepo();
      expect(await container(FakeDeviceLocation(error: const LocationUnavailable('off')), repo).read(farmerLocationProvider.future), isNull);
    });

    test('a village chosen while the GPS lookup is still running is not overwritten by its late result', () async {
      final repo = FakeCentersRepository(saved: saved);
      final slow = _SlowGps();
      final c = container2(slow, repo);
      final first = c.read(farmerLocationProvider.future); // starts the (slow) automatic lookup
      await c.read(farmerLocationProvider.notifier).chooseVillage(const Village(name: 'Paithan', district: 'Aurangabad', latitude: 19.4772, longitude: 75.3843));
      slow.finish(shirur); // the GPS answers after the farmer already chose
      expect((await first)?.label, 'Paithan');
      expect(c.read(farmerLocationProvider).value?.label, 'Paithan');
      expect(repo.savedLocations.every((l) => l.label != null || l.latitude == 19.4772), isTrue, reason: 'the late GPS fix was not saved over the choice');
    });

    test('choosing a village sets and saves the location; retrying GPS reports why it failed', () async {
      final repo = FakeCentersRepository();
      final device = FakeDeviceLocation(error: const LocationUnavailable('Location is turned off on this device.'));
      final c = container(device, repo);
      await c.read(farmerLocationProvider.future);

      await c.read(farmerLocationProvider.notifier).chooseVillage(const Village(name: 'Shirur', district: 'Pune', latitude: 18.8284, longitude: 74.376));
      final chosen = c.read(farmerLocationProvider).value!;
      expect(chosen.source, LocationSource.village);
      expect(chosen.label, 'Shirur');
      expect(repo.savedLocations.single.latitude, 18.8284);

      final message = await c.read(farmerLocationProvider.notifier).useGps();
      expect(message, 'Location is turned off on this device. Choose your village instead.');
      expect(c.read(farmerLocationProvider).value, chosen, reason: 'a failed retry keeps the current location');

      device
        ..error = null
        ..result = shirur;
      expect(await c.read(farmerLocationProvider.notifier).useGps(), isNull);
      expect(c.read(farmerLocationProvider).value, shirur);
    });
  });

  group('nearby centers screen', () {
    Future<FakeCentersRepository> pump(WidgetTester tester, {NearbyCentersArgs args = const NearbyCentersArgs(), FakeCentersRepository? repo, FarmerLocation? at = shirur, Size size = const Size(420, 1400)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fake = repo ?? FakeCentersRepository();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          centersRepositoryProvider.overrideWithValue(fake),
          deviceLocationProvider.overrideWithValue(at == null ? FakeDeviceLocation(error: const LocationUnavailable('off')) : FakeDeviceLocation(result: at)),
        ],
        child: MaterialApp(theme: AppTheme.light, home: NearbyCentersScreen(args: args)),
      ));
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('each card has what a farmer needs, and the top one is recommended with its reason', (tester) async {
      final repo = FakeCentersRepository()
        ..centers = (cart) => [
              nearbyCenter('a', km: 2.3, recommended: true, reason: 'Closest open center', cart: false, pending: 2),
              nearbyCenter('b', km: 8.1, open: false, hoursLabel: 'Opens tomorrow at 09:00', cart: false, phone: '', operatorName: ''),
            ];
      await pump(tester, repo: repo);

      expect(find.text('Recommended: Closest open center'), findsOneWidget);
      expect(find.text('Center a'), findsOneWidget);
      expect(find.text('Village a, Pune'), findsOneWidget);
      expect(find.text('2.3 km away · about 18 min'), findsOneWidget, reason: 'travel time is an estimate, worded as one');
      expect(find.textContaining('Open · Open until 18:00'), findsOneWidget);
      expect(find.text('Run by Olga'), findsOneWidget);
      expect(find.text('2 pickups waiting'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget, reason: 'only the center with a phone number offers a call');
      expect(find.text('Open in Maps'), findsNWidgets(2));
      expect(find.textContaining('Closed · Opens tomorrow at 09:00'), findsOneWidget);
      expect(find.text('Within 10 km · best match first'), findsOneWidget);
      expect(find.text('Showing centers near your current location (GPS)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with a cart, the stock verdict is shown per center', (tester) async {
      final repo = FakeCentersRepository()
        ..centers = (cart) => [nearbyCenter('a', recommended: true), nearbyCenter('b', km: 5, have: 0)];
      await pump(tester, repo: repo, args: const NearbyCentersArgs(cart: Cart([CartLine('p-neemcake', 1)])));
      expect(find.text('All items available'), findsOneWidget);
      expect(find.text('Out of stock for your order'), findsOneWidget);
      expect(repo.nearbyCalls.single.lines.single.productId, 'p-neemcake');
    });

    testWidgets('picking: only centers that can fill the whole order can be chosen', (tester) async {
      final repo = FakeCentersRepository()
        ..centers = (cart) => [nearbyCenter('a', recommended: true), nearbyCenter('b', km: 5, have: 0)];
      await pump(tester, repo: repo, args: const NearbyCentersArgs(cart: Cart([CartLine('p-neemcake', 1)]), pick: true));
      expect(find.text('Choose this center'), findsOneWidget);
      expect(find.text('This center cannot fill your whole order.'), findsOneWidget);
    });

    testWidgets('no centers in range says so', (tester) async {
      final repo = FakeCentersRepository()..centers = (_) => const [];
      await pump(tester, repo: repo);
      expect(find.text('No village centers within 10 km yet.'), findsOneWidget);
    });

    testWidgets('an unknown location asks for the village instead of failing', (tester) async {
      await pump(tester, at: null);
      expect(find.text('Tell us where you are so we can find the nearest village centers.'), findsOneWidget);
      expect(find.text('Choose village'), findsOneWidget);
      expect(find.text('Use GPS'), findsOneWidget);
    });

    testWidgets('a server error can be retried', (tester) async {
      final repo = FakeCentersRepository()..nearbyError = Exception("Couldn't reach the server");
      await pump(tester, repo: repo);
      expect(find.textContaining("Couldn't reach the server"), findsOneWidget);
      repo.nearbyError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Center a'), findsOneWidget);
    });

    testWidgets('wide screens render without overflow', (tester) async {
      await pump(tester, size: const Size(1280, 900));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('village picker: searches, and choosing one sets and saves the location', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeCentersRepository(villageList: const [
      Village(name: 'Shirur', district: 'Pune', latitude: 18.8284, longitude: 74.376),
      Village(name: 'Paithan', district: 'Aurangabad', latitude: 19.4772, longitude: 75.3843),
    ]);
    late ProviderContainer container;
    // The screen closes itself with a route pop, so it needs a router: open it from a home page.
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, _) => Scaffold(body: TextButton(onPressed: () => context.push('/pick'), child: const Text('open picker')))),
      GoRoute(path: '/pick', builder: (context, _) => const VillagePickerScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [centersRepositoryProvider.overrideWithValue(repo), deviceLocationProvider.overrideWithValue(FakeDeviceLocation(error: const LocationUnavailable('off')))],
      child: Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
      }),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();
    expect(find.text('Shirur'), findsOneWidget);
    expect(find.text('Paithan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pai');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Shirur'), findsNothing);

    await tester.tap(find.text('Paithan'));
    await tester.pumpAndSettle();
    expect(find.text('open picker'), findsOneWidget, reason: 'the picker closed itself');
    final location = container.read(farmerLocationProvider).value!;
    expect(location.label, 'Paithan');
    expect(location.source, LocationSource.village);
    expect(repo.savedLocations.single.latitude, 19.4772);
  });
}

class _ThrowingRepo extends FakeCentersRepository {
  @override
  Future<FarmerLocation?> savedLocation() async => throw Exception('offline');
}

/// A GPS that answers only when the test says so.
class _SlowGps implements DeviceLocation {
  final _done = Completer<FarmerLocation>();

  void finish(FarmerLocation l) => _done.complete(l);

  @override
  Future<FarmerLocation> current() => _done.future;
}
