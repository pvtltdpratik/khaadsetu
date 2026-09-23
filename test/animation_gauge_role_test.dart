import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/auth/user_role.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/core/widgets/soil_health_gauge.dart';
import 'package:khaadsetu_version1/features/auth/presentation/widgets/role_selector.dart';

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
      theme: AppTheme.light,
      builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduce), child: w!),
      home: Scaffold(body: Center(child: child)),
    );

/// The ring's current sweep (0-1), read from the painter.
double _sweep(WidgetTester tester) {
  final paint = tester.widgetList<CustomPaint>(find.descendant(of: find.byType(SoilHealthGauge), matching: find.byType(CustomPaint))).first;
  return (paint.painter! as dynamic).progress as double;
}

void main() {
  group('soil health gauge', () {
    testWidgets('the ring sweeps round to the score, and the number is right from the start', (tester) async {
      await tester.pumpWidget(_host(const SoilHealthGauge(size: 120, score: 80)));
      expect(_sweep(tester), 0, reason: 'starts empty');
      expect(find.text('80'), findsOneWidget, reason: 'the score itself is never animated away');

      await tester.pump(const Duration(milliseconds: 300));
      final mid = _sweep(tester);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(0.8));

      await tester.pumpAndSettle();
      expect(_sweep(tester), closeTo(0.8, 0.001));
    });

    testWidgets('a new score glides from where the ring was', (tester) async {
      await tester.pumpWidget(_host(const SoilHealthGauge(size: 120, score: 40)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_host(const SoilHealthGauge(size: 120, score: 90)));
      await tester.pump(const Duration(milliseconds: 50));
      final now = _sweep(tester);
      expect(now, greaterThanOrEqualTo(0.4));
      expect(now, lessThan(0.9));
      await tester.pumpAndSettle();
      expect(_sweep(tester), closeTo(0.9, 0.001));
    });

    testWidgets('no scan yet: an empty ring, nothing to sweep', (tester) async {
      await tester.pumpWidget(_host(const SoilHealthGauge(size: 120)));
      await tester.pumpAndSettle();
      expect(_sweep(tester), 0);
      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('with reduced motion the ring is at the score at once', (tester) async {
      await tester.pumpWidget(_host(const SoilHealthGauge(size: 120, score: 80), reduce: true));
      await tester.pump();
      expect(_sweep(tester), closeTo(0.8, 0.001));
    });
  });

  group('role selector', () {
    Widget selector(UserRole? selected, {ValueChanged<UserRole>? onChanged}) => _host(SizedBox(width: 380, child: RoleSelector(selected: selected, onChanged: onChanged ?? (_) {})));

    testWidgets('choosing a role eases its card into the selected look and ticks it', (tester) async {
      UserRole? picked;
      await tester.pumpWidget(selector(null, onChanged: (r) => picked = r));
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      await tester.tap(find.text(UserRole.operator.label));
      await tester.pump();
      expect(picked, UserRole.operator, reason: 'the tap still works through the animated card');

      await tester.pumpWidget(selector(UserRole.operator));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget, reason: 'the tick is on its way in');
      expect(tester.widgetList<ScaleTransition>(find.ancestor(of: find.byIcon(Icons.check_circle_rounded), matching: find.byType(ScaleTransition))).any((s) => s.scale.value < 1), isTrue, reason: 'still scaling up');

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('switching roles moves the tick, and only one is ever ticked', (tester) async {
      await tester.pumpWidget(selector(UserRole.farmer));
      await tester.pumpAndSettle();
      await tester.pumpWidget(selector(UserRole.operator));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      final tick = tester.getCenter(find.byIcon(Icons.check_circle_rounded)).dy;
      final operatorRow = tester.getCenter(find.text(UserRole.operator.label)).dy;
      final farmerRow = tester.getCenter(find.text(UserRole.farmer.label)).dy;
      expect((tick - operatorRow).abs(), lessThan((tick - farmerRow).abs()), reason: 'the tick is on the operator card');
    });

    testWidgets('with reduced motion the tick is simply there', (tester) async {
      await tester.pumpWidget(_host(SizedBox(width: 380, child: RoleSelector(selected: UserRole.farmer, onChanged: (_) {})), reduce: true));
      await tester.pump();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
