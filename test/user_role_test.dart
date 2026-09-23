import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/auth/session_profile.dart';
import 'package:khaadsetu_version1/core/auth/user_role.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/auth/presentation/widgets/role_selector.dart';

SessionProfile _me(AppRole role, {String requested = 'farmer', String status = 'active'}) => SessionProfile(
      userId: 'u1',
      email: 'u@example.com',
      name: 'U',
      role: role,
      requestedRole: requested,
      status: status,
    );

void main() {
  group('UserRole.fromMetadata (the sign-up request)', () {
    test('reads the stored role', () {
      expect(UserRole.fromMetadata({'role': 'farmer'}), UserRole.farmer);
      expect(UserRole.fromMetadata({'role': 'operator'}), UserRole.operator);
    });

    test('is null for accounts without a valid role', () {
      expect(UserRole.fromMetadata(null), isNull);
      expect(UserRole.fromMetadata({}), isNull);
      expect(UserRole.fromMetadata({'role': 'admin'}), isNull, reason: 'nobody can request to be an admin');
      expect(UserRole.fromMetadata({'role': 42}), isNull);
    });
  });

  group('SessionProfile', () {
    test('parses what /v1/me returns', () {
      final p = SessionProfile.fromJson({
        'userId': 'abc',
        'email': 'a@b.c',
        'name': 'Asha',
        'requestedRole': 'operator',
        'status': 'active',
        'role': 'operator',
        'center': {'centerId': 'c1', 'name': 'Kendra', 'status': 'active'},
      });
      expect(p.role, AppRole.operator);
      expect(p.center?.name, 'Kendra');
      expect(p.isPendingOperator, isFalse);
    });

    test('an unknown role is treated as a farmer, never as something with more power', () {
      expect(SessionProfile.fromJson({'userId': 'x', 'role': 'root'}).role, AppRole.farmer);
      expect(AppRole.parse(null), AppRole.farmer);
    });

    test('an operator with no center yet is pending, and a suspended account is flagged', () {
      final pending = SessionProfile.fromJson({'userId': 'x', 'role': 'farmer', 'requestedRole': 'operator', 'center': null});
      expect(pending.isPendingOperator, isTrue);
      expect(_me(AppRole.farmer, status: 'suspended').isSuspended, isTrue);
    });
  });

  group('redirectForSession', () {
    test('until the server has answered, the only place to be is the gate', () {
      expect(redirectForSession(null, RoutePaths.root), isNull);
      expect(redirectForSession(null, RoutePaths.farmerHome), RoutePaths.root);
      expect(redirectForSession(null, RoutePaths.adminOverview), RoutePaths.root);
      expect(redirectForSession(null, RoutePaths.signIn), RoutePaths.root);
    });

    test('each role goes straight to its own home, past the gate and the auth screens', () {
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.root), RoutePaths.farmerHome);
      expect(redirectForSession(_me(AppRole.operator), RoutePaths.root), RoutePaths.operatorDashboard);
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.root), RoutePaths.adminOverview);
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.signIn), RoutePaths.adminOverview);
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.signUp), RoutePaths.farmerHome);
    });

    test('nobody can open another role\'s area', () {
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.operatorDashboard), RoutePaths.farmerHome);
      expect(redirectForSession(_me(AppRole.farmer), '/operator/orders/1'), RoutePaths.farmerHome);
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.adminOverview), RoutePaths.farmerHome);
      expect(redirectForSession(_me(AppRole.operator), RoutePaths.farmerHome), RoutePaths.operatorDashboard);
      expect(redirectForSession(_me(AppRole.operator), '/admin/users'), RoutePaths.operatorDashboard);
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.farmerHome), RoutePaths.adminOverview);
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.operatorDashboard), RoutePaths.adminOverview);
    });

    test('a lookalike prefix is not the same area', () {
      expect(redirectForSession(_me(AppRole.farmer), '/farmers-market'), RoutePaths.farmerHome);
      expect(redirectForSession(_me(AppRole.admin), '/administrator'), RoutePaths.adminOverview);
    });

    test('deep links inside your own area are left alone', () {
      expect(redirectForSession(_me(AppRole.farmer), '/farmer/community/post/p1'), isNull);
      expect(redirectForSession(_me(AppRole.operator), '/operator/orders/123'), isNull);
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.adminOperator('abc')), isNull);
      expect(redirectForSession(_me(AppRole.admin), RoutePaths.adminCenterNew), isNull);
    });

    test('an operator still waiting for a center sees only the waiting screen', () {
      final pending = _me(AppRole.farmer, requested: 'operator');
      expect(redirectForSession(pending, RoutePaths.pendingOperator), isNull);
      expect(redirectForSession(pending, RoutePaths.root), RoutePaths.pendingOperator);
      expect(redirectForSession(pending, RoutePaths.farmerHome), RoutePaths.pendingOperator);
      expect(redirectForSession(pending, RoutePaths.operatorDashboard), RoutePaths.pendingOperator);
      // A plain farmer has no business on that screen.
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.pendingOperator), RoutePaths.farmerHome);
    });

    test('a suspended account can only see the suspended screen, whatever its role', () {
      for (final role in AppRole.values) {
        final suspended = _me(role, status: 'suspended');
        expect(redirectForSession(suspended, RoutePaths.suspended), isNull, reason: role.name);
        expect(redirectForSession(suspended, RoutePaths.root), RoutePaths.suspended, reason: role.name);
        expect(redirectForSession(suspended, '/${role.name}/anything'), RoutePaths.suspended, reason: role.name);
      }
    });

    test('once reactivated, the suspended screen leads back home', () {
      expect(redirectForSession(_me(AppRole.farmer), RoutePaths.suspended), RoutePaths.farmerHome);
      expect(redirectForSession(_me(AppRole.operator), RoutePaths.suspended), RoutePaths.operatorDashboard);
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
    expect(find.text('Admin'), findsNothing, reason: 'admin is never a sign-up option');

    await tester.tap(find.text('Village Center Operator'));
    expect(picked, UserRole.operator);
  });
}
