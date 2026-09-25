import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/profile/domain/profile_models.dart';
import 'package:khaadsetu_version1/features/farmer/profile/presentation/providers/profile_providers.dart';
import 'package:khaadsetu_version1/features/organic/organic_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpOrganic(WidgetTester tester, Map<String, dynamic> answers) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(430, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [farmDetailsProvider.overrideWith((ref) async => FarmDetails(answers))],
    child: MaterialApp(theme: AppTheme.light, home: const OrganicCertificationScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an organic farmer in a group is told they can apply', (tester) async {
    await pumpOrganic(tester, {'practisesOrganic': true, 'inFarmerGroup': true});
    expect(find.text('You are ready to apply'), findsOneWidget);
  });

  testWidgets('without a group it says a group of 5 is needed', (tester) async {
    await pumpOrganic(tester, {'practisesOrganic': true, 'inFarmerGroup': false});
    expect(find.text('Check what you need'), findsOneWidget);
    expect(find.textContaining('at least 5 farmers'), findsOneWidget);
  });

  testWidgets('a non-organic farmer is told to start with a small plot', (tester) async {
    await pumpOrganic(tester, {'practisesOrganic': false});
    expect(find.text('Start with a small plot'), findsOneWidget);
  });

  testWidgets('unanswered questions point to the farm details', (tester) async {
    await pumpOrganic(tester, {});
    expect(find.textContaining('farm details'), findsOneWidget);
  });

  testWidgets('ticked steps are counted and remembered', (tester) async {
    await pumpOrganic(tester, {});
    expect(find.text('Your steps (0 of 7 done)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('step-group')));
    await tester.pumpAndSettle();
    expect(find.text('Your steps (1 of 7 done)'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getStringList('pgs_steps_done'), ['group']);
    await tester.tap(find.byKey(const Key('step-group')));
    await tester.pumpAndSettle();
    expect(find.text('Your steps (0 of 7 done)'), findsOneWidget);
  });
}
