import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/auth/user_role.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/auth/presentation/widgets/role_selector.dart';

void main() {
  group('UserRole.fromMetadata', () {
    test('reads the stored role', () {
      expect(UserRole.fromMetadata({'role': 'farmer'}), UserRole.farmer);
      expect(UserRole.fromMetadata({'role': 'operator'}), UserRole.operator);
    });

    test('is null for accounts without a valid role', () {
      expect(UserRole.fromMetadata(null), isNull);
      expect(UserRole.fromMetadata({}), isNull);
      expect(UserRole.fromMetadata({'role': 'admin'}), isNull);
      expect(UserRole.fromMetadata({'role': 42}), isNull);
    });
  });

  group('redirectForRole', () {
    test('a farmer skips the chooser and lands in the farmer app', () {
      expect(redirectForRole(UserRole.farmer, RoutePaths.root), RoutePaths.farmerHome);
    });

    test('an operator skips the chooser and lands in the operator app', () {
      expect(redirectForRole(UserRole.operator, RoutePaths.root), RoutePaths.operatorDashboard);
    });

    test('a farmer cannot open operator screens', () {
      expect(redirectForRole(UserRole.farmer, RoutePaths.operatorDashboard), RoutePaths.farmerHome);
      expect(redirectForRole(UserRole.farmer, '/operator/orders/123'), RoutePaths.farmerHome);
      expect(redirectForRole(UserRole.farmer, RoutePaths.operatorRoot), RoutePaths.farmerHome);
    });

    test('an operator cannot open farmer screens', () {
      expect(redirectForRole(UserRole.operator, RoutePaths.farmerHome), RoutePaths.operatorDashboard);
      expect(redirectForRole(UserRole.operator, '/farmer/community/post/p1'), RoutePaths.operatorDashboard);
    });

    test("each role can use its own app's deep links", () {
      expect(redirectForRole(UserRole.farmer, '/farmer/community/post/p1'), isNull);
      expect(redirectForRole(UserRole.operator, '/operator/orders/123'), isNull);
    });

    test('an account with no role can only reach the chooser', () {
      expect(redirectForRole(null, RoutePaths.root), isNull);
      expect(redirectForRole(null, RoutePaths.farmerHome), RoutePaths.root);
      expect(redirectForRole(null, RoutePaths.operatorDashboard), RoutePaths.root);
    });
  });

  testWidgets('RoleSelector shows both roles and reports the tapped one', (tester) async {
    UserRole? picked;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: RoleSelector(selected: picked, onChanged: (r) => picked = r)),
    ));

    expect(find.text('Farmer'), findsOneWidget);
    expect(find.text('Village Center Operator'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    await tester.tap(find.text('Village Center Operator'));
    expect(picked, UserRole.operator);
  });
}
