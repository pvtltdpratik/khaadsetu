import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/auth/session_profile.dart';
import 'package:khaadsetu_version1/core/flavor/app_flavor.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/auth/presentation/screens/dev_role_picker_screen.dart';
import 'package:khaadsetu_version1/features/auth/presentation/screens/session_gate_screen.dart';

SessionProfile _me(AppRole role, {String requested = 'farmer', String status = 'active'}) =>
    SessionProfile(userId: 'u', email: 'u@example.com', name: 'Asha', role: role, requestedRole: requested, status: status);

void main() {
  group('which accounts each APK lets in', () {
    test('a farmer APK opens for farmers and turns everyone else away', () {
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.root, flavor: AppFlavor.farmer), RoutePaths.farmerHome);
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.farmerHome, flavor: AppFlavor.farmer), isNull);
      expect(redirectForSession(_me(AppRole.operator), RoutePaths.root, flavor: AppFlavor.farmer), RoutePaths.wrongApp);
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.farmerHome, flavor: AppFlavor.farmer), RoutePaths.wrongApp);
      // Someone waiting to become an operator belongs in the center app.
      expect(redirectForSession(_me(AppRole.farmer, requested: 'operator'), RoutePaths.root, flavor: AppFlavor.farmer), RoutePaths.wrongApp);
    });

    test('a center APK is for operators, including one still waiting for a center', () {
      expect(redirectForSession(_me(AppRole.operator), RoutePaths.root, flavor: AppFlavor.center), RoutePaths.operatorDashboard);
      expect(redirectForSession(_me(AppRole.farmer, requested: 'operator'), RoutePaths.root, flavor: AppFlavor.center), RoutePaths.pendingOperator);
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.root, flavor: AppFlavor.center), RoutePaths.wrongApp);
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.root, flavor: AppFlavor.center), RoutePaths.wrongApp);
    });

    test('an admin APK is for admins only', () {
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.root, flavor: AppFlavor.admin), RoutePaths.adminOverview);
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.root, flavor: AppFlavor.admin), RoutePaths.wrongApp);
      expect(redirectForSession(_me(AppRole.operator), RoutePaths.operatorDashboard, flavor: AppFlavor.admin), RoutePaths.wrongApp);
    });

    test('the wrong-app page stays put, and a right account is sent away from it', () {
      expect(redirectForSession(_me(AppRole.operator), RoutePaths.wrongApp, flavor: AppFlavor.farmer), isNull);
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.wrongApp, flavor: AppFlavor.farmer), RoutePaths.farmerHome);
    });

    test('a suspended account is told so before anything about the app', () {
      expect(redirectForSession(_me(AppRole.operator, status: 'suspended'), RoutePaths.root, flavor: AppFlavor.farmer), RoutePaths.suspended);
    });

    test('signed-out and still-loading behave the same in every flavor', () {
      for (final f in AppFlavor.values) {
        expect(redirectForSession(null, RoutePaths.farmerHome, flavor: f), RoutePaths.root);
        expect(redirectForSession(null, RoutePaths.root, flavor: f), isNull);
      }
    });

    test('without a flavor nothing changes: each role goes to its own home', () {
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.root), RoutePaths.farmerHome);
      expect(redirectForSession(_me(AppRole.operator), RoutePaths.root), RoutePaths.operatorDashboard);
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.root), RoutePaths.adminOverview);
    });
  });

  group('the test APK', () {
    test('starts on the picker for every kind of account, and lets them open their dashboard from there', () {
      for (final role in AppRole.values) {
        expect(redirectForSession(_me(role), RoutePaths.root, flavor: AppFlavor.dev), RoutePaths.devPicker);
        expect(redirectForSession(_me(role), RoutePaths.signIn, flavor: AppFlavor.dev), RoutePaths.devPicker);
        expect(redirectForSession(_me(role), RoutePaths.devPicker, flavor: AppFlavor.dev), isNull);
      }
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.adminOverview, flavor: AppFlavor.dev), isNull);
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.farmerHome, flavor: AppFlavor.dev), isNull);
    });

    test('the picker is only for the test build', () {
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.devPicker, flavor: AppFlavor.farmer), RoutePaths.farmerHome);
      expect(AppFlavor.dev.isDev, isTrue);
      expect(AppFlavor.values.where((f) => f.isDev), [AppFlavor.dev]);
    });

    test('every flavor has a name to show', () {
      expect(AppFlavor.farmer.title, 'ShetSamrudhi');
      expect(AppFlavor.center.title, contains('Center'));
      expect(AppFlavor.admin.title, contains('Admin'));
      expect(AppFlavor.dev.title, contains('DEV'));
    });
  });

  group('the screens', () {
    Future<void> pump(WidgetTester tester, Widget screen, SessionProfile me, {AppFlavor flavor = AppFlavor.dev}) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, _) => screen),
        GoRoute(path: RoutePaths.farmerHome, builder: (context, _) => const Text('farmer dashboard')),
        GoRoute(path: RoutePaths.operatorDashboard, builder: (context, _) => const Text('center dashboard')),
        GoRoute(path: RoutePaths.pendingOperator, builder: (context, _) => const Text('waiting for a center')),
        GoRoute(path: RoutePaths.adminOverview, builder: (context, _) => const Text('admin dashboard')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [sessionProfileProvider.overrideWith((ref) async => me), appFlavorProvider.overrideWithValue(flavor)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('the picker shows who is signed in and opens the dashboard they really have', (tester) async {
      await pump(tester, const DevRolePickerScreen(), _me(AppRole.farmer));
      expect(find.text('DEV BUILD: for testing only'), findsOneWidget);
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Signed in as a farmer'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dev-open-farmer')));
      await tester.pumpAndSettle();
      expect(find.text('farmer dashboard'), findsOneWidget);
    });

    testWidgets('a dashboard the account does not have explains how to test it, and opens nothing', (tester) async {
      await pump(tester, const DevRolePickerScreen(), _me(AppRole.farmer));
      await tester.tap(find.byKey(const Key('dev-open-admin')));
      await tester.pumpAndSettle();
      expect(find.text('Not for this account'), findsOneWidget);
      expect(find.textContaining('SUPER_ADMIN_EMAILS'), findsOneWidget);
      expect(find.text('admin dashboard'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dev-open-center')));
      await tester.pumpAndSettle();
      expect(find.textContaining('owns a village center'), findsOneWidget);
    });

    testWidgets('an operator opens the center dashboard', (tester) async {
      await pump(tester, const DevRolePickerScreen(), _me(AppRole.operator));
      await tester.tap(find.byKey(const Key('dev-open-center')));
      await tester.pumpAndSettle();
      expect(find.text('center dashboard'), findsOneWidget);
    });

    testWidgets('an admin opens the admin dashboard', (tester) async {
      await pump(tester, const DevRolePickerScreen(), _me(AppRole.admin));
      await tester.tap(find.byKey(const Key('dev-open-admin')));
      await tester.pumpAndSettle();
      expect(find.text('admin dashboard'), findsOneWidget);
    });

    testWidgets('an operator with no center yet is sent to their waiting screen', (tester) async {
      await pump(tester, const DevRolePickerScreen(), _me(AppRole.farmer, requested: 'operator'));
      expect(find.text('Signed in as a village center operator (waiting for a center)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dev-open-center')));
      await tester.pumpAndSettle();
      expect(find.text('waiting for a center'), findsOneWidget);
    });

    testWidgets('the wrong-app screen names the account and the app to use instead', (tester) async {
      await pump(tester, const WrongAppScreen(), _me(AppRole.operator), flavor: AppFlavor.farmer);
      expect(find.text('This is the wrong app for this account'), findsOneWidget);
      expect(find.textContaining('village center operator account'), findsOneWidget);
      expect(find.textContaining('Please use the Center app'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
