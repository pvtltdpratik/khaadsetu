import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/core/widgets/kit.dart';
import 'package:khaadsetu_version1/features/delivery/board/board_api.dart';
import 'package:khaadsetu_version1/features/delivery/board/board_screen.dart';
import 'package:khaadsetu_version1/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/nearby_center.dart';
import 'package:khaadsetu_version1/features/vehicles/vehicle_api.dart';
import 'package:khaadsetu_version1/features/vehicles/vehicles_screen.dart';

class FakeVehicles implements VehicleApi {
  FakeVehicles(this.list);

  List<Json> list;
  final activeCalls = <(String, bool)>[];
  final submitted = <String>[];

  @override
  Future<List<Json>> mine() async => list;
  @override
  Future<Json> setActive(String id, bool active) async {
    activeCalls.add((id, active));
    return {};
  }

  @override
  Future<Json> submit(String id, {String? centerId}) async {
    submitted.add(id);
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBoard implements BoardApi {
  FakeBoard(this.answer);

  Json answer;
  final asked = <Map<String, String>>[];
  final taken = <String>[];

  @override
  Future<Json> savedBoard() async => answer;
  @override
  Future<Json> board(Map<String, String> filters) async {
    asked.add(filters);
    return answer;
  }

  @override
  Future<void> savePrefs(Map<String, String> filters) async {}
  @override
  Future<Json> job(String id) async => {
        'id': id, 'fee': 900, 'distanceKm': 120, 'weightKg': 800, 'needsApproval': true, 'approved': true,
        'pickup': {'centerName': 'Shirur Kendra'}, 'drop': {'village': 'Nashik'},
        'suggestedVehicle': {'id': 'veh-1'},
        'vehicleOptions': [{'vehicleId': 'veh-1', 'label': 'Pickup', 'registrationNumber': 'MH12AB1234', 'fits': true, 'best': true, 'reasons': []}],
        'lines': [{'name': 'Vermicompost', 'quantity': 20}],
      };
  @override
  Future<Json> take(String id, {String? vehicleId, String note = ''}) async {
    taken.add('$id/$vehicleId');
    return {'kind': 'requested'};
  }

  @override
  Future<List<Json>> requests() async => [
        {'id': 'req-1', 'status': 'pending', 'pickupLabel': 'Shirur', 'dropVillage': 'Nashik', 'distanceKm': 120, 'fee': 900},
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pump(WidgetTester tester, Widget home, List<Override> overrides) async {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp(theme: AppTheme.light, home: home)));
  await tester.pumpAndSettle();
}

final noCenters = reviewCentersProvider.overrideWith((ref) async => const <NearbyCenter>[]);

void main() {
  testWidgets('no vehicles: the list explains what to do', (tester) async {
    await pump(tester, const VehiclesScreen(), [vehicleApiProvider.overrideWithValue(FakeVehicles([])), noCenters]);
    expect(find.byKey(const Key('vehicles-empty')), findsOneWidget);
    expect(find.byKey(const Key('vehicle-add')), findsOneWidget);
  });

  testWidgets('vehicles show their check and an approved one can be switched off', (tester) async {
    final fake = FakeVehicles([
      {'id': 'veh-1', 'registrationNumber': 'MH12AB1234', 'categoryLabel': 'Pickup', 'capacityKg': 800, 'status': 'approved', 'isActive': true, 'usable': true},
      {'id': 'veh-2', 'registrationNumber': 'MH14XY9999', 'categoryLabel': 'Tractor', 'capacityKg': 3000, 'status': 'pending'},
      {'id': 'veh-3', 'registrationNumber': 'MH15ZZ0001', 'categoryLabel': 'Bike', 'capacityKg': 40, 'status': 'rejected'},
    ]);
    await pump(tester, const VehiclesScreen(), [vehicleApiProvider.overrideWithValue(fake), noCenters]);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Being checked'), findsOneWidget);
    expect(find.text('Sent back'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vehicle-active-veh-1')));
    await tester.pumpAndSettle();
    expect(fake.activeCalls, [('veh-1', false)]);
  });

  final boardAnswer = <String, dynamic>{
    'total': 2, 'activeJobs': 1, 'maxActiveJobs': 3, 'canTakeMore': true, 'hint': '', 'filters': {'distanceMax': 20},
    'items': [
      {'id': 'job-a', 'fee': 120, 'distanceKm': 6.5, 'weightKg': 40, 'toPickupKm': 2.0, 'longDistance': false, 'fits': true, 'pickup': {'centerName': 'Shirur Kendra'}, 'drop': {'village': 'Kasar'}},
      {'id': 'job-b', 'fee': 900, 'distanceKm': 120, 'weightKg': 800, 'longDistance': true, 'needsApproval': true, 'fits': true, 'pickup': {'centerName': 'Shirur Kendra'}, 'drop': {'village': 'Nashik'}},
    ],
  };

  testWidgets('the board lists jobs, marks the long one, and applies a distance filter', (tester) async {
    final fake = FakeBoard(boardAnswer);
    await pump(tester, const DeliveryBoardScreen(), [boardApiProvider.overrideWithValue(fake), vehicleApiProvider.overrideWithValue(FakeVehicles([])), noCenters]);
    expect(find.text('2 jobs for you'), findsOneWidget);
    expect(find.text('Long distance'), findsOneWidget);
    expect(find.text('₹900'), findsOneWidget);

    await tester.tap(find.byKey(const Key('board-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('band-4')));
    await tester.tap(find.byKey(const Key('sort-earning')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('filter-apply')));
    await tester.pumpAndSettle();
    expect(fake.asked.last['distanceMin'], '100');
    expect(fake.asked.last['sort'], 'earning');
    expect(fake.asked.last.containsKey('distanceMax'), isFalse);
  });

  testWidgets('a long job is asked for, not taken', (tester) async {
    final fake = FakeBoard(boardAnswer);
    await pump(tester, const DeliveryBoardScreen(), [boardApiProvider.overrideWithValue(fake), vehicleApiProvider.overrideWithValue(FakeVehicles([])), noCenters]);
    await tester.tap(find.byKey(const Key('job-fee-job-b')));
    await tester.pumpAndSettle();
    expect(find.text('Long distance: the center must approve'), findsOneWidget);
    expect(find.text('Ask the village center'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('job-take')));
    await tester.tap(find.byKey(const Key('job-take')));
    await tester.pumpAndSettle();
    expect(fake.taken, ['job-b/veh-1']);
    expect(find.textContaining('Asked the village center'), findsOneWidget);
  });

  testWidgets('my requests show the state and can be withdrawn', (tester) async {
    await pump(tester, const MyRequestsScreen(), [boardApiProvider.overrideWithValue(FakeBoard(boardAnswer))]);
    expect(find.text('Waiting for the center'), findsOneWidget);
    expect(find.byKey(const Key('withdraw-req-1')), findsOneWidget);
  });
}
