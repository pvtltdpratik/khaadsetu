import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/animation/motion.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/domain/entities/app_notification.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/presentation/providers/notifications_providers.dart';
import 'package:khaadsetu_version1/features/operator/inventory/presentation/widgets/stock_level_indicator.dart';
import 'package:khaadsetu_version1/features/operator/presentation/widgets/operator_notification_bell.dart';

import 'support/operator_fakes.dart';

Widget _host(Widget child, {List<dynamic> overrides = const [], bool reduce = false}) => ProviderScope(
      // ignore: argument_type_not_assignable
      overrides: [...overrides.cast()],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduce), child: w!),
        home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))),
      ),
    );

/// The width of the coloured part of the stock bar (the second 8px-high box).
double _fillWidth(WidgetTester tester) {
  final boxes = find.descendant(of: find.byType(StockLevelIndicator), matching: find.byType(Container)).evaluate().map((e) => e.widget as Container);
  final bars = tester.widgetList<Container>(find.descendant(of: find.byType(StockLevelIndicator), matching: find.byType(Container))).where((c) => c.constraints?.maxHeight == 8).toList();
  expect(boxes, isNotEmpty);
  // The last bar is the coloured fill; its width is on its constraints.
  return bars.last.constraints!.maxWidth;
}

double _bellAngle(WidgetTester tester) {
  final rotations = tester.widgetList<Transform>(find.descendant(of: find.byType(OperatorNotificationBell), matching: find.byType(Transform)));
  // Transform.rotate builds a rotation matrix; entry (0,1) is -sin(angle).
  return rotations.map((t) => t.transform.entry(0, 1).abs()).fold<double>(0, (a, b) => a > b ? a : b);
}

void main() {
  group('stock bar', () {
    testWidgets('grows from empty to its level, and glides when the level changes', (tester) async {
      Widget bar(int onHand) => _host(StockLevelIndicator(item: shelfItem('p', onHand: onHand, reorder: 10)));
      await tester.pumpWidget(bar(20)); // ratio 1.0 of 300px
      expect(_fillWidth(tester), 0, reason: 'starts empty');

      await tester.pump(Motion.slow ~/ 2);
      final mid = _fillWidth(tester);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(300));

      await tester.pumpAndSettle();
      expect(_fillWidth(tester), closeTo(300, 0.5));

      await tester.pumpWidget(bar(5)); // ratio 0.25
      await tester.pump(const Duration(milliseconds: 60));
      final gliding = _fillWidth(tester);
      expect(gliding, lessThan(300));
      expect(gliding, greaterThan(75), reason: 'it glides down, it does not restart from empty');
      await tester.pumpAndSettle();
      expect(_fillWidth(tester), closeTo(75, 0.5));
    });

    testWidgets('with reduced motion it is at its level straight away', (tester) async {
      await tester.pumpWidget(_host(StockLevelIndicator(item: shelfItem('p', onHand: 20, reorder: 10)), reduce: true));
      await tester.pump();
      expect(_fillWidth(tester), closeTo(300, 0.5));
    });
  });

  group('notification bell', () {
    Future<void> pumpBell(WidgetTester tester, List<AppNotification> items, {bool reduce = false}) async {
      await tester.pumpWidget(_host(const OperatorNotificationBell(), overrides: [notificationsRepositoryProvider.overrideWithValue(FakeNotificationsRepository(items))], reduce: reduce));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
    }

    testWidgets('shakes when there is something unread, then settles', (tester) async {
      await pumpBell(tester, [note('1', NotificationType.order)]);
      expect(_bellAngle(tester), greaterThan(0), reason: 'shaking');
      await tester.pumpAndSettle();
      expect(_bellAngle(tester), lessThan(0.001), reason: 'back at rest');
      expect(find.byTooltip('1 unread notifications'), findsOneWidget);
    });

    testWidgets('stays still when everything has been read', (tester) async {
      await pumpBell(tester, [note('1', NotificationType.order, read: true)]);
      expect(_bellAngle(tester), 0);
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('stays still with reduced motion', (tester) async {
      await pumpBell(tester, [note('1', NotificationType.order)], reduce: true);
      expect(_bellAngle(tester), 0);
      expect(find.byTooltip('1 unread notifications'), findsOneWidget);
    });
  });
}
