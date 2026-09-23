import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/admin/domain/entities/admin_models.dart';
import 'package:khaadsetu_version1/features/admin/domain/repositories/admin_repository.dart';
import 'package:khaadsetu_version1/features/admin/presentation/providers/admin_providers.dart';
import 'package:khaadsetu_version1/features/admin/presentation/screens/admin_center_detail_screen.dart';
import 'package:khaadsetu_version1/features/admin/presentation/screens/admin_overview_screen.dart';
import 'package:khaadsetu_version1/features/admin/presentation/screens/admin_people_screen.dart';
import 'package:khaadsetu_version1/features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'package:khaadsetu_version1/features/admin/presentation/screens/create_center_screen.dart';

AdminUser _user(String id, String name, PersonRole role, PersonSegment segment, {String? center, String? village, String status = 'active'}) => AdminUser(
      userId: id,
      email: '$id@example.com',
      name: name,
      status: segment == PersonSegment.suspended ? 'suspended' : status,
      role: role,
      segment: segment,
      ordersCount: 3,
      centerId: center == null ? null : 'c-$id',
      centerName: center,
      village: village,
    );

AdminCenter _center(String id, String name, {bool operator = true, String status = 'active', int low = 0}) => AdminCenter(
      centerId: id,
      name: name,
      village: 'Shirur',
      district: 'Pune',
      latitude: 18.83,
      longitude: 74.37,
      operatorName: '',
      phone: '98220 00000',
      isOpen: true,
      opensAt: '09:00',
      closesAt: '18:00',
      status: status,
      productsStocked: 4,
      lowStockCount: low,
      pendingOrders: 2,
      operatorId: operator ? 'op-1' : null,
      operatorEmail: operator ? 'op-1@example.com' : null,
      operatorUserName: operator ? 'Olga Operator' : null,
      operatorStatus: operator ? 'active' : null,
    );

/// An in-memory admin API that records what the screens ask it to do.
class FakeAdminRepository implements AdminRepository {
  final peopleCalls = <String>[];
  final statusChanges = <String>[];
  final assigned = <String>[];
  final created = <Map<String, Object?>>[];
  final centerStatusChanges = <String>[];
  bool failNextCreate = false;

  final users_ = [
    _user('op-a', 'Active Operator', PersonRole.operator, PersonSegment.active, center: 'Center A'),
    _user('op-w', 'Waiting Operator', PersonRole.operator, PersonSegment.unassigned),
    _user('op-s', 'Suspended Operator', PersonRole.operator, PersonSegment.suspended, center: 'Center S'),
    _user('f-a', 'Asha Farmer', PersonRole.farmer, PersonSegment.active, village: 'Shirur'),
    _user('f-s', 'Bhau Farmer', PersonRole.farmer, PersonSegment.suspended, village: 'Paithan'),
  ];

  @override
  Future<AdminOverview> overview() async => const AdminOverview(
        operators: PeopleGroup(active: 1, suspended: 1, unassigned: 1, total: 3),
        farmers: PeopleGroup(active: 1, suspended: 1, unassigned: 0, total: 2),
        centersActive: 2,
        centersSuspended: 1,
        centersWithoutOperator: 1,
        ordersPending: 4,
        ordersReadyForPickup: 1,
        ordersToday: 5,
        restockPending: 2,
        lowStockItems: 3,
      );

  @override
  Future<List<AuditEntry>> recentActivity({int limit = 10}) async => [
        AuditEntry(id: 'a1', adminEmail: 'boss@example.com', action: 'user.suspend', targetType: 'user', targetId: 'f-s', details: const {'role': 'farmer'}, createdAt: DateTime.now()),
      ];

  @override
  Future<List<AdminUser>> users({required PersonRole role, PersonSegment? segment, String? q, int limit = 100}) async {
    peopleCalls.add('${role.name}/${segment?.name}/${q ?? ''}');
    return users_
        .where((u) => u.role == role && (segment == null || u.segment == segment))
        .where((u) => (q ?? '').isEmpty || u.name.toLowerCase().contains(q!.toLowerCase()))
        .toList();
  }

  @override
  Future<AdminUserDetail> userDetail(String userId) async => AdminUserDetail(
        user: users_.firstWhere((u) => u.userId == userId),
        scans: 2,
        ordersByStatus: const {'pending': 1, 'completed': 2},
      );

  @override
  Future<void> setUserStatus(String userId, {required bool suspended, String? reason}) async {
    statusChanges.add('$userId:${suspended ? 'suspend' : 'reactivate'}:${reason ?? ''}');
  }

  final centers_ = [
    _center('c1', 'Center A', low: 2),
    _center('c2', 'Orphan Center', operator: false),
    _center('c3', 'Closed Center', status: 'suspended'),
  ];

  @override
  Future<List<AdminCenter>> centers({String? status, bool? hasOperator, String? q, int limit = 100}) async => centers_
      .where((c) => status == null || c.status == status)
      .where((c) => hasOperator == null || c.hasOperator == hasOperator)
      .toList();

  @override
  Future<AdminCenter> center(String centerId) async => centers_.firstWhere((c) => c.centerId == centerId);

  @override
  Future<List<StockItem>> centerStock(String centerId) async => const [
        StockItem(name: 'Neem Cake', unit: 'bag', onHand: 10, reserved: 3, available: 7, reorderLevel: 8, incoming: 0, isLow: true),
      ];

  @override
  Future<AdminCenter> createCenter({
    required String name,
    required String village,
    required String district,
    required double latitude,
    required double longitude,
    String? phone,
    String? operatorName,
    String? operatorId,
    String? opensAt,
    String? closesAt,
  }) async {
    if (failNextCreate) {
      failNextCreate = false;
      throw Exception('That user already operates another village center');
    }
    created.add({'name': name, 'village': village, 'district': district, 'lat': latitude, 'lng': longitude, 'opens': opensAt, 'closes': closesAt});
    return _center('new', name);
  }

  @override
  Future<void> setCenterSuspended(String centerId, {required bool suspended}) async {
    centerStatusChanges.add('$centerId:${suspended ? 'suspend' : 'reactivate'}');
  }

  @override
  Future<void> assignOperator(String centerId, String? userId) async {
    assigned.add('$centerId:${userId ?? 'none'}');
  }

  @override
  Future<List<VillageOption>> searchVillages(String query) async =>
      query.toLowerCase().startsWith('shir') ? const [VillageOption(name: 'Shirur', district: 'Pune', latitude: 18.8284, longitude: 74.376)] : const [];
}

Future<FakeAdminRepository> _pump(WidgetTester tester, Widget screen, {Size size = const Size(400, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeAdminRepository();
  await tester.pumpWidget(ProviderScope(
    overrides: [adminRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: screen)),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('overview: what needs attention, and the counts by category', (tester) async {
    await _pump(tester, const AdminOverviewScreen());
    expect(find.text('1 operator waiting for a center'), findsOneWidget);
    expect(find.text('1 center without an operator'), findsOneWidget);
    expect(find.text('2 restock requests pending approval'), findsOneWidget);
    expect(find.text('3 products running low across centers'), findsOneWidget);
    expect(find.text('Operators'), findsOneWidget);
    expect(find.text('Farmers'), findsOneWidget);
    expect(find.text('Awaiting center'), findsOneWidget);
    expect(find.text('Suspended a farmer'), findsOneWidget, reason: 'recent admin activity');
    expect(tester.takeException(), isNull);
  });

  testWidgets('operators are sorted into categories with counts, and each filter narrows the list', (tester) async {
    final repo = await _pump(tester, const AdminPeopleScreen(role: PersonRole.operator));
    expect(find.text('Active Operator'), findsOneWidget);
    expect(find.text('Waiting Operator'), findsOneWidget);
    expect(find.text('Suspended Operator'), findsOneWidget);
    expect(find.text('Awaiting center (1)'), findsOneWidget);
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('No center assigned'), findsOneWidget);

    await tester.tap(find.text('Awaiting center (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting Operator'), findsOneWidget);
    expect(find.text('Active Operator'), findsNothing);
    expect(repo.peopleCalls.last, 'operator/unassigned/');

    await tester.tap(find.text('Suspended (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Suspended Operator'), findsOneWidget);
    expect(find.text('Waiting Operator'), findsNothing);
  });

  testWidgets('farmers have no "awaiting center" category, and search waits for a pause', (tester) async {
    final repo = await _pump(tester, const AdminPeopleScreen(role: PersonRole.farmer));
    expect(find.textContaining('Awaiting center'), findsNothing);
    expect(find.text('Asha Farmer'), findsOneWidget);
    expect(find.text('Bhau Farmer'), findsOneWidget);
    expect(find.text('Shirur · 3 orders'), findsOneWidget);

    final callsBefore = repo.peopleCalls.length;
    await tester.enterText(find.byType(TextField), 'asha');
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.peopleCalls.length, callsBefore, reason: 'not searched on every keystroke');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(repo.peopleCalls.last, 'farmer/null/asha');
    expect(find.text('Asha Farmer'), findsOneWidget);
    expect(find.text('Bhau Farmer'), findsNothing);
  });

  testWidgets('an empty result says why', (tester) async {
    await _pump(tester, const AdminPeopleScreen(role: PersonRole.farmer));
    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('No one matches these filters'), findsOneWidget);
  });

  testWidgets('the panel can open pre-filtered (a link from the overview)', (tester) async {
    await _pump(tester, const AdminPeopleScreen(role: PersonRole.operator, initialSegment: PersonSegment.unassigned));
    expect(find.text('Waiting Operator'), findsOneWidget);
    expect(find.text('Active Operator'), findsNothing);
  });

  testWidgets('suspending a person asks first, records the reason, and is not done if cancelled', (tester) async {
    final repo = await _pump(tester, const AdminUserDetailScreen(userId: 'f-a'));
    expect(find.text('Asha Farmer'), findsWidgets);
    expect(find.text('Soil scans'), findsOneWidget);

    await tester.tap(find.text('Suspend'));
    await tester.pumpAndSettle();
    expect(find.text('Suspend Asha Farmer?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.statusChanges, isEmpty);

    await tester.tap(find.text('Suspend'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Spam');
    await tester.tap(find.widgetWithText(FilledButton, 'Suspend').last);
    await tester.pumpAndSettle();
    expect(repo.statusChanges, ['f-a:suspend:Spam']);
    expect(find.text('Asha Farmer suspended'), findsOneWidget);
  });

  testWidgets('a suspended person offers Reactivate instead', (tester) async {
    final repo = await _pump(tester, const AdminUserDetailScreen(userId: 'f-s'));
    expect(find.text('Reactivate'), findsOneWidget);
    expect(find.text('Suspend'), findsNothing);
    await tester.tap(find.text('Reactivate'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reactivate').last);
    await tester.pumpAndSettle();
    expect(repo.statusChanges, ['f-s:reactivate:']);
  });

  testWidgets('an operator with no center can be assigned one, chosen from centers that need an operator', (tester) async {
    final repo = await _pump(tester, const AdminUserDetailScreen(userId: 'op-w'));
    expect(find.text('Assign a center'), findsOneWidget);
    await tester.tap(find.text('Assign a center'));
    await tester.pumpAndSettle();
    expect(find.text('Orphan Center'), findsOneWidget);
    expect(find.text('Center A'), findsNothing, reason: 'that one already has an operator');
    await tester.tap(find.text('Orphan Center'));
    await tester.pumpAndSettle();
    expect(repo.assigned, ['c2:op-w']);
  });

  testWidgets('an operator who runs a center can be removed from it, after confirming', (tester) async {
    final repo = await _pump(tester, const AdminUserDetailScreen(userId: 'op-a'));
    expect(find.text('Assign a center'), findsNothing);
    await tester.tap(find.text('Remove from center'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(repo.assigned, ['c-op-a:none']);
  });

  testWidgets('center detail shows operator, hours and stock health, with suspend and assign controls', (tester) async {
    final repo = await _pump(tester, const AdminCenterDetailScreen(centerId: 'c2'));
    expect(find.text('Orphan Center'), findsOneWidget);
    expect(find.text('No operator'), findsOneWidget);
    expect(find.text('09:00 – 18:00'), findsOneWidget);
    expect(find.text('Neem Cake'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('7 bag'), findsOneWidget);
    expect(find.text('Assign operator'), findsOneWidget);
    expect(find.text('Remove operator'), findsNothing);

    await tester.tap(find.text('Suspend center'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
    await tester.pumpAndSettle();
    expect(repo.centerStatusChanges, ['c2:suspend']);
  });

  testWidgets('create center: validates, fills coordinates from a village suggestion, and submits', (tester) async {
    final repo = await _pump(tester, const CreateCenterScreen(), size: const Size(500, 1200));

    await tester.tap(find.text('Create center'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a village'), findsOneWidget);
    expect(find.text('Enter the Latitude as a number'), findsOneWidget);
    expect(repo.created, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Center name'), 'Shirur Kendra');
    await tester.enterText(find.widgetWithText(TextFormField, 'Village'), 'shir');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pune').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create center'));
    await tester.pumpAndSettle();

    expect(repo.created.single, {'name': 'Shirur Kendra', 'village': 'Shirur', 'district': 'Pune', 'lat': 18.8284, 'lng': 74.376, 'opens': '09:00', 'closes': '18:00'});
  });

  testWidgets('create center: out-of-range coordinates are rejected, and a server error keeps the form', (tester) async {
    final repo = await _pump(tester, const CreateCenterScreen(), size: const Size(500, 1200));
    await tester.enterText(find.widgetWithText(TextFormField, 'Center name'), 'X Kendra');
    await tester.enterText(find.widgetWithText(TextFormField, 'Village'), 'Somewhere');
    await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '95');
    await tester.enterText(find.widgetWithText(TextFormField, 'Longitude'), '74');
    await tester.tap(find.text('Create center'));
    await tester.pumpAndSettle();
    expect(find.text('Latitude must be between -90.0 and 90.0'), findsOneWidget);
    expect(repo.created, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Latitude'), '18.5');
    repo.failNextCreate = true;
    await tester.tap(find.text('Create center'));
    await tester.pumpAndSettle();
    expect(find.textContaining('already operates'), findsOneWidget);
    expect(find.text('X Kendra'), findsOneWidget, reason: 'the typed input is still there');
  });

  testWidgets('wide layouts render without overflow', (tester) async {
    await _pump(tester, const AdminOverviewScreen(), size: const Size(1280, 900));
    expect(tester.takeException(), isNull);
    await _pump(tester, const AdminPeopleScreen(role: PersonRole.operator), size: const Size(1280, 900));
    expect(tester.takeException(), isNull);
  });
}
