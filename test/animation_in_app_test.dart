import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/animation/motion.dart';
import 'package:khaadsetu_version1/core/animation/pop_in.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/core/widgets/app_button.dart';
import 'package:khaadsetu_version1/core/widgets/app_loading_indicator.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/surplus_offer.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/providers/centers_providers.dart';
import 'package:khaadsetu_version1/features/farmer/centers/presentation/screens/surplus_nearby_screen.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/providers/orders_providers.dart';
import 'package:khaadsetu_version1/features/farmer/orders/presentation/widgets/order_card.dart';
import 'package:khaadsetu_version1/features/operator/surplus/domain/entities/surplus_lot.dart';

import 'support/farmer_fakes.dart';

Widget _host(Widget child, {List<dynamic> overrides = const [], bool reduce = false}) => ProviderScope(
      // ignore: argument_type_not_assignable
      overrides: [...overrides.cast()],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduce), child: w!),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

/// The opacity a widget currently shows: the product of every Opacity above it.
double _shown(WidgetTester tester, Finder of) {
  var o = 1.0;
  for (final w in tester.widgetList<Opacity>(find.ancestor(of: of, matching: find.byType(Opacity)))) {
    o *= w.opacity;
  }
  return o;
}

SurplusOffer _offer(String id) => SurplusOffer(
      lotId: id,
      productId: 'p-neemcake',
      productName: 'Product $id',
      unit: 'bag',
      catalogPrice: 600,
      unitPrice: 450,
      available: 3,
      condition: SurplusCondition.nearExpiry,
      center: const SurplusCenter(centerId: 'c', name: 'Kendra', village: 'Shirur', phone: '', isOpen: true),
      distanceKm: 2,
      estimatedTravelMinutes: 10,
    );

void main() {
  group('PopIn', () {
    testWidgets('starts small and see-through, overshoots into place, and leaves no layers once done', (tester) async {
      await tester.pumpWidget(_host(const PopIn(child: Text('badge'))));
      expect(_shown(tester, find.text('badge')), 0);
      final small = tester.getSize(find.text('badge')).width;

      await tester.pump(Motion.slow ~/ 2);
      expect(_shown(tester, find.text('badge')), greaterThan(0));
      expect(tester.getSize(find.text('badge')).width, greaterThanOrEqualTo(small));

      await tester.pumpAndSettle();
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('badge'), findsOneWidget);
    });

    testWidgets('waits for its delay, and with reduced motion is simply shown', (tester) async {
      await tester.pumpWidget(_host(const PopIn(delay: Duration(milliseconds: 400), child: Text('late'))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_shown(tester, find.text('late')), 0, reason: 'still waiting');
      await tester.pumpAndSettle();

      await tester.pumpWidget(_host(const PopIn(delay: Duration(milliseconds: 400), child: Text('now')), reduce: true));
      expect(find.byType(Opacity), findsNothing);
    });
  });

  group('AppButton', () {
    testWidgets('the label and the spinner cross-fade, then only the spinner remains', (tester) async {
      Widget button(bool loading) => _host(AppButton(label: 'Save', isLoading: loading, onPressed: () {}));
      await tester.pumpWidget(button(false));
      expect(find.text('Save'), findsOneWidget);

      await tester.pumpWidget(button(true));
      await tester.pump(Motion.fast ~/ 2);
      expect(find.text('Save'), findsOneWidget, reason: 'fading out');
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'fading in');

      await tester.pump(Motion.fast * 2);
      expect(find.text('Save'), findsNothing);

      await tester.pumpWidget(button(false));
      await tester.pump(Motion.fast * 2);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('it dips when pressed, but a disabled or loading button does not react', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(AppButton(label: 'Go', onPressed: () => taps++)));
      final g = await tester.startGesture(tester.getCenter(find.text('Go')));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, lessThan(1));
      await g.up();
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.pumpWidget(_host(const AppButton(label: 'Go')));
      final down = await tester.startGesture(tester.getCenter(find.text('Go')));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1, reason: 'nothing to press');
      await down.up();
    });

    testWidgets('with reduced motion the label is swapped without a fade', (tester) async {
      await tester.pumpWidget(_host(AppButton(label: 'Save', onPressed: () {}), reduce: true));
      expect(find.byType(AnimatedSwitcher), findsNothing);
      expect(find.byType(AnimatedScale), findsNothing);
    });
  });

  group('AppLoadingIndicator', () {
    testWidgets('a quick load never flashes a spinner: it only fades in after a beat', (tester) async {
      await tester.pumpWidget(_host(const AppLoadingIndicator(message: 'Loading')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_shown(tester, find.byType(CircularProgressIndicator)), 0);
      await tester.pump(const Duration(milliseconds: 600));
      expect(_shown(tester, find.byType(CircularProgressIndicator)), 1);
      expect(find.text('Loading'), findsOneWidget);
      // Remove it while the spinner's own animation runs, so the test can end.
      await tester.pumpWidget(_host(const SizedBox()));
    });
  });

  group('screens use the motion', () {
    testWidgets('the pickup code pops in on an order', (tester) async {
      await tester.pumpWidget(_host(OrderCard(order: farmerOrder('o1')), overrides: [ordersRepositoryProvider.overrideWithValue(FakeOrdersRepository())]));
      expect(find.text('4821'), findsOneWidget);
      expect(_shown(tester, find.text('4821')), 0, reason: 'not there yet');
      await tester.pumpAndSettle();
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('surplus deals arrive one after another, and the discount badge pops after its card', (tester) async {
      final centers = FakeCentersRepository()..surplus = [_offer('a'), _offer('b'), _offer('c')];
      tester.view.physicalSize = const Size(420, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [centersRepositoryProvider.overrideWithValue(centers), deviceLocationProvider.overrideWithValue(FakeDeviceLocation(result: shirur))],
        child: MaterialApp(theme: AppTheme.light, home: const SurplusNearbyScreen()),
      ));
      // Let the data arrive, then look at the first frames of the entrance.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 90));
      final first = _shown(tester, find.text('Product a'));
      final third = _shown(tester, find.text('Product c'));
      expect(first, greaterThan(0));
      expect(third, lessThan(first), reason: 'the third card is still waiting for its turn');

      await tester.pumpAndSettle();
      for (final n in ['a', 'b', 'c']) {
        expect(find.text('Product $n'), findsOneWidget);
      }
      expect(find.byType(Opacity), findsNothing, reason: 'all done, nothing left half-drawn');
    });

    testWidgets('with reduced motion the deals are all there from the first frame', (tester) async {
      final centers = FakeCentersRepository()..surplus = [_offer('a'), _offer('b')];
      tester.view.physicalSize = const Size(420, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [centersRepositoryProvider.overrideWithValue(centers), deviceLocationProvider.overrideWithValue(FakeDeviceLocation(result: shirur))],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, w) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: w!),
          home: const SurplusNearbyScreen(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 10));
      expect(_shown(tester, find.text('Product a')), 1);
      expect(_shown(tester, find.text('Product b')), 1);
    });
  });
}
