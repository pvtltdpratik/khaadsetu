import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/staff/vehicle_limits_screen.dart';

void main() {
  testWidgets('the admin sees each kind of vehicle with its distances and cost', (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        vehicleCategoriesProvider.overrideWith((ref) async => [
              {'id': 'bike', 'label': 'Bike', 'normalDistanceKm': 15, 'maxDistanceKm': null, 'runningCostPerKm': 4},
              {'id': 'truck_heavy', 'label': 'Heavy truck', 'normalDistanceKm': 100, 'maxDistanceKm': 1000, 'runningCostPerKm': 35},
            ]),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const VehicleLimitsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Bike'), findsOneWidget);
    expect(find.text('Same as normal'), findsOneWidget);
    expect(find.text('1000 km'), findsOneWidget);
    expect(find.text('₹35 per km'), findsOneWidget);
    await tester.tap(find.text('Bike'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('limit-normal')), findsOneWidget);
  });
}
