import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/core/widgets/kit.dart';
import 'package:khaadsetu_version1/features/staff/activity_log_screen.dart';

void main() {
  test('actions read as sentences', () {
    expect(describeAction('POST /v1/operator/orders/:id/ready'), 'Changed: orders › ready');
    expect(describeAction('GET /v1/admin/users/:id/card'), 'Viewed: users › card');
    expect(describeAction('DELETE /v1/devices'), 'Removed: devices');
  });

  testWidgets('the admin log shows who did what, and asks again when a filter changes', (tester) async {
    final asked = <LogQuery>[];
    final List<Override> overrides = [
      activityLogProvider.overrideWith((ref, q) async {
        asked.add(q);
        return [
          {'id': 1, 'at': '2026-09-27T10:15:00Z', 'actorRole': 'operator', 'actorName': 'Ram', 'actorId': 'op1', 'method': 'POST', 'action': 'POST /v1/operator/orders/:id/ready', 'targetId': 'order-9', 'status': 200},
          {'id': 2, 'at': '2026-09-27T10:10:00Z', 'actorRole': 'farmer', 'actorName': 'Sita', 'actorId': 'f1', 'method': 'POST', 'action': 'POST /v1/own/listings', 'targetId': '', 'status': 403},
        ];
      }),
      activitySummaryProvider.overrideWith((ref) async => [{'role': 'operator', 'actions': 5, 'people': 2, 'failed': 0}]),
    ];
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp(theme: AppTheme.light, home: const ActivityLogScreen(scope: LogScope.everyone))));
    await tester.pumpAndSettle();
    expect(find.text('Changed: orders › ready'), findsOneWidget);
    expect(find.textContaining('operator Ram'), findsOneWidget);
    expect(find.text('403'), findsOneWidget);
    await tester.tap(find.byKey(const Key('role-farmer')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('log-failed')));
    await tester.tap(find.byKey(const Key('log-failed')));
    await tester.pumpAndSettle();
    expect(asked.last.role, 'farmer');
    expect(asked.last.failed, isTrue);
  });

  testWidgets('a person with no history sees a plain note', (tester) async {
    final List<Override> overrides = [activityLogProvider.overrideWith((ref, q) async => <Json>[])];
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp(theme: AppTheme.light, home: const ActivityLogScreen())));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('log-empty')), findsOneWidget);
  });
}
