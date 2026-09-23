import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/animation/animated_count.dart';
import 'package:khaadsetu_version1/core/animation/fade_slide_in.dart';
import 'package:khaadsetu_version1/core/animation/motion.dart';
import 'package:khaadsetu_version1/core/animation/page_transitions.dart';
import 'package:khaadsetu_version1/core/animation/pressable.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
      theme: AppTheme.light,
      builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion), child: w!),
      home: Scaffold(body: Center(child: child)),
    );

double _opacityOf(WidgetTester tester, Finder of) {
  final o = tester.widgetList<Opacity>(find.ancestor(of: of, matching: find.byType(Opacity)));
  return o.isEmpty ? 1 : o.first.opacity;
}

void main() {
  group('Motion', () {
    test('items are staggered, but only the first few', () {
      expect(Motion.delayFor(0), Duration.zero);
      expect(Motion.delayFor(3), Motion.stagger * 3);
      expect(Motion.delayFor(50), Motion.stagger * Motion.maxStaggered, reason: 'a long list must not make the last row wait');
      expect(Motion.delayFor(-2), Duration.zero);
    });
  });

  group('FadeSlideIn', () {
    testWidgets('starts invisible and offset, then arrives fully', (tester) async {
      await tester.pumpWidget(_app(const FadeSlideIn(child: Text('hello'))));
      expect(_opacityOf(tester, find.text('hello')), 0);
      final start = tester.getTopLeft(find.text('hello')).dy;

      await tester.pump(Motion.medium ~/ 2);
      final mid = _opacityOf(tester, find.text('hello'));
      expect(mid, greaterThan(0));
      expect(mid, lessThan(1));
      expect(tester.getTopLeft(find.text('hello')).dy, lessThan(start), reason: 'it rises into place');

      await tester.pumpAndSettle();
      expect(find.byType(Opacity), findsNothing, reason: 'once done it leaves no effect layers behind');
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('a later item waits for its turn', (tester) async {
      await tester.pumpWidget(_app(const Column(mainAxisSize: MainAxisSize.min, children: [FadeSlideIn(index: 0, child: Text('first')), FadeSlideIn(index: 4, child: Text('fifth'))])));
      await tester.pump(Motion.medium ~/ 2);
      expect(_opacityOf(tester, find.text('first')), greaterThan(0));
      expect(_opacityOf(tester, find.text('fifth')), 0, reason: 'still waiting');
      await tester.pumpAndSettle();
      expect(find.text('fifth'), findsOneWidget);
    });

    testWidgets('leaves no timers behind when removed mid-animation', (tester) async {
      await tester.pumpWidget(_app(const FadeSlideIn(index: 5, child: Text('gone'))));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('rebuilding with new content does not replay it', (tester) async {
      await tester.pumpWidget(_app(const FadeSlideIn(child: Text('one'))));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(const FadeSlideIn(child: Text('two'))));
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('with reduced motion the child is simply there', (tester) async {
      await tester.pumpWidget(_app(const FadeSlideIn(index: 5, child: Text('still')), reduceMotion: true));
      expect(find.byType(Opacity), findsNothing);
      expect(find.descendant(of: find.byType(FadeSlideIn), matching: find.byType(Transform)), findsNothing, reason: 'not even offset');
      expect(find.text('still'), findsOneWidget);
    });
  });

  group('Pressable', () {
    testWidgets('dips while pressed, returns when released, and never blocks the button inside', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(Pressable(child: ElevatedButton(onPressed: () => taps++, child: const Text('Go')))));
      double scale() => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
      expect(scale(), 1);

      final gesture = await tester.startGesture(tester.getCenter(find.text('Go')));
      await tester.pump();
      expect(scale(), lessThan(1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(scale(), 1);
      expect(taps, 1, reason: 'the tap still reached the button');
    });

    testWidgets('a drag away (cancelled press) also lets go', (tester) async {
      await tester.pumpWidget(_app(Pressable(child: ElevatedButton(onPressed: () {}, child: const Text('Go')))));
      final gesture = await tester.startGesture(tester.getCenter(find.text('Go')));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('with reduced motion it adds nothing at all', (tester) async {
      await tester.pumpWidget(_app(const Pressable(child: Text('x')), reduceMotion: true));
      expect(find.byType(AnimatedScale), findsNothing);
    });

    testWidgets('a disabled one does not dip, and does not change shape (so what is inside keeps its state)', (tester) async {
      await tester.pumpWidget(_app(const Pressable(enabled: false, child: Text('x'))));
      final g = await tester.startGesture(tester.getCenter(find.text('x')));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await g.up();
    });
  });

  group('AnimatedCount', () {
    testWidgets('counts up from zero to the value', (tester) async {
      await tester.pumpWidget(_app(const AnimatedCount(value: 100)));
      expect(find.text('0'), findsOneWidget);
      await tester.pump(Motion.slow ~/ 2);
      final mid = int.parse(tester.widget<Text>(find.byType(Text)).data!);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(100));
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('glides to a new value instead of restarting from zero', (tester) async {
      await tester.pumpWidget(_app(const AnimatedCount(value: 100)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(const AnimatedCount(value: 120)));
      await tester.pump(const Duration(milliseconds: 10));
      final now = int.parse(tester.widget<Text>(find.byType(Text)).data!);
      expect(now, greaterThanOrEqualTo(100), reason: 'it does not fall back to 0');
      await tester.pumpAndSettle();
      expect(find.text('120'), findsOneWidget);
    });

    testWidgets('uses the given format', (tester) async {
      await tester.pumpWidget(_app(AnimatedCount(value: 1500, format: (v) => '₹${v.round()}')));
      await tester.pumpAndSettle();
      expect(find.text('₹1500'), findsOneWidget);
    });

    testWidgets('with reduced motion it shows the value at once', (tester) async {
      await tester.pumpWidget(_app(const AnimatedCount(value: 42), reduceMotion: true));
      expect(find.text('42'), findsOneWidget);
    });
  });

  group('page transitions', () {
    Widget appWithTwoPages({bool reduce = false}) => MaterialApp(
          theme: AppTheme.light,
          builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduce), child: w!),
          home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('second')))), child: const Text('open')))),
        );

    testWidgets('the theme applies the same transition on every platform', (tester) async {
      final builders = AppTheme.light.pageTransitionsTheme.builders;
      for (final p in TargetPlatform.values) {
        expect(builders[p], isA<AppPageTransitionsBuilder>(), reason: '$p');
      }
      expect(appPageTransitions.builders.length, TargetPlatform.values.length);
    });

    testWidgets('a pushed page fades in, then is fully shown', (tester) async {
      await tester.pumpWidget(appWithTwoPages());
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final fades = tester.widgetList<FadeTransition>(find.ancestor(of: find.text('second'), matching: find.byType(FadeTransition)));
      expect(fades.any((f) => f.opacity.value > 0 && f.opacity.value < 1), isTrue, reason: 'mid-transition');
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      final settled = tester.widgetList<FadeTransition>(find.ancestor(of: find.text('second'), matching: find.byType(FadeTransition)));
      expect(settled.every((f) => f.opacity.value == 1), isTrue);
    });

    testWidgets('with reduced motion the page is not wrapped in any transition of ours', (tester) async {
      await tester.pumpWidget(appWithTwoPages(reduce: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(find.descendant(of: find.byType(Scaffold).last, matching: find.byType(SlideTransition)), findsNothing);
    });
  });
}
