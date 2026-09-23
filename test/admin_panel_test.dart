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
import 'package:khaadsetu_version1/features/admin/presentation/screens/admin_supply_screen.dart';
import 'package:khaadsetu_version1/features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'package:khaadsetu_version1/features/admin/presentation/screens/create_center_screen.dart';
import 'package:khaadsetu_version1/features/operator/surplus/domain/entities/surplus_lot.dart';

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
        surplusActiveLots: 4,
        surplusUnits: 17,
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

  final restocks_ = [
    const RestockRequest(id: 'r1', centerId: 'c1', centerName: 'Center A', productName: 'Neem Cake', quantity: 20, status: RestockStatus.pending),
    const RestockRequest(id: 'r2', centerId: 'c1', centerName: 'Center A', productName: 'Urea', quantity: 5, status: RestockStatus.approved),
  ];
  final reports_ = [
    const StockDiscrepancy(id: 'd1', centerId: 'c1', centerName: 'Center A', productName: 'Neem Cake', expected: 20, received: 17, note: 'Three bags torn', resolved: false, resolutionNote: ''),
    const StockDiscrepancy(id: 'd2', centerId: 'c1', centerName: 'Center A', productName: 'Urea', expected: 5, received: 5, note: '', resolved: true, resolutionNote: 'Recount done'),
  ];
  final restockMoves = <String>[];
  final surplus_ = [
    AdminSurplusLot(
      lot: SurplusLot(
        id: 's1',
        productId: 'p-neemcake',
        productName: 'Neem Cake',
        unit: 'bag',
        catalogPrice: 600,
        unitPrice: 450,
        quantity: 5,
        reserved: 2,
        condition: SurplusCondition.nearExpiry,
        status: SurplusStatus.active,
        bestBefore: DateTime(2026, 11, 30),
        note: 'Torn bags',
      ),
      centerId: 'c1',
      centerName: 'Center A',
      village: 'Shirur',
    ),
    const AdminSurplusLot(
      lot: SurplusLot(
        id: 's2',
        productId: 'p-verm',
        productName: 'Vermicompost',
        unit: 'bag',
        catalogPrice: 450,
        unitPrice: 300,
        quantity: 0,
        reserved: 0,
        condition: SurplusCondition.other,
        status: SurplusStatus.soldOut,
      ),
      centerId: 'c2',
      centerName: 'Orphan Center',
      village: 'Paithan',
    ),
  ];
  final surplusWithdrawals = <String>[];
  bool failNextWithdraw = false;

  @override
  Future<List<AdminSurplusLot>> surplusLots({int limit = 100}) async => [...surplus_];

  @override
  Future<void> withdrawSurplus(String id, {String? reason}) async {
    if (failNextWithdraw) {
      failNextWithdraw = false;
      throw Exception('That lot is already withdrawn');
    }
    surplusWithdrawals.add('$id:${reason ?? ''}');
    final i = surplus_.indexWhere((l) => l.lot.id == id);
    final l = surplus_[i].lot;
    surplus_[i] = AdminSurplusLot(
      lot: SurplusLot(
        id: l.id,
        productId: l.productId,
        productName: l.productName,
        unit: l.unit,
        catalogPrice: l.catalogPrice,
        unitPrice: l.unitPrice,
        quantity: l.reserved,
        reserved: l.reserved,
        condition: l.condition,
        status: SurplusStatus.withdrawn,
      ),
      centerId: surplus_[i].centerId,
      centerName: surplus_[i].centerName,
      village: surplus_[i].village,
    );
  }
  bool failNextAdvance = false;
  final resolvedReports = <String>[];

  @override
  Future<List<RestockRequest>> restockRequests({RestockStatus? status, int limit = 100}) async =>
      restocks_.where((r) => status == null || r.status == status).toList();

  @override
  Future<void> advanceRestock(String id, RestockStatus to) async {
    if (failNextAdvance) {
      failNextAdvance = false;
      throw Exception('That request is already approved');
    }
    restockMoves.add('$id:${to.name}');
    final i = restocks_.indexWhere((r) => r.id == id);
    final r = restocks_[i];
    restocks_[i] = RestockRequest(id: r.id, centerId: r.centerId, centerName: r.centerName, productName: r.productName, quantity: r.quantity, status: to);
  }

  @override
  Future<List<StockDiscrepancy>> discrepancies({required bool resolved, int limit = 100}) async =>
      reports_.where((d) => d.resolved == resolved).toList();

  @override
  Future<void> resolveDiscrepancy(String id, {String? note}) async {
    resolvedReports.add('$id:${note ?? ''}');
    final i = reports_.indexWhere((d) => d.id == id);
    final d = reports_[i];
    reports_[i] = StockDiscrepancy(id: d.id, centerId: d.centerId, centerName: d.centerName, productName: d.productName, expected: d.expected, received: d.received, note: d.note, resolved: true, resolutionNote: note ?? '');
  }
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

  testWidgets('supply: pending restock requests come first, and approving asks before it moves them on', (tester) async {
    final repo = await _pump(tester, const AdminSupplyScreen());
    expect(find.text('20 × Neem Cake'), findsOneWidget);
    expect(find.text('5 × Urea'), findsNothing, reason: 'approved requests are under another filter');

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.text('Approve this restock?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.restockMoves, isEmpty);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
    await tester.pumpAndSettle();
    expect(repo.restockMoves, ['r1:approved']);
    expect(find.text('Restock approved'), findsOneWidget);
    expect(find.text('20 × Neem Cake'), findsNothing, reason: 'it left the pending queue');
    expect(find.text('No restock requests are waiting.'), findsOneWidget);
  });

  testWidgets('supply: an approved request can be marked delivered, a delivered one has no action', (tester) async {
    final repo = await _pump(tester, const AdminSupplyScreen());
    await tester.tap(find.text('On its way'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark delivered'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mark delivered').last);
    await tester.pumpAndSettle();
    expect(repo.restockMoves, ['r2:fulfilled']);

    await tester.tap(find.text('Delivered'));
    await tester.pumpAndSettle();
    expect(find.text('5 × Urea'), findsOneWidget);
    expect(find.text('Mark delivered'), findsNothing);
  });

  testWidgets('supply: a delivery report shows the shortfall and is reviewed with a note to the operator', (tester) async {
    final repo = await _pump(tester, const AdminSupplyScreen(initialTab: SupplyTab.discrepancies));
    expect(find.text('3 short'), findsOneWidget);
    expect(find.text('Expected 20, received 17'), findsOneWidget);
    expect(find.text('Operator: Three bags torn'), findsOneWidget);

    await tester.tap(find.text('Mark reviewed'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Replacement sent');
    await tester.tap(find.widgetWithText(FilledButton, 'Mark reviewed').last);
    await tester.pumpAndSettle();
    expect(repo.resolvedReports, ['d1:Replacement sent']);
    expect(find.text('No delivery reports to review.'), findsOneWidget);

    await tester.tap(find.text('Reviewed'));
    await tester.pumpAndSettle();
    expect(find.text('Your note: Replacement sent'), findsOneWidget);
  });

  testWidgets('supply: when the server refuses, the reason is shown and the request stays put', (tester) async {
    final repo = await _pump(tester, const AdminSupplyScreen());
    repo.failNextAdvance = true;
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('already approved'), findsOneWidget);
    expect(find.text('20 × Neem Cake'), findsOneWidget);
    expect(repo.restockMoves, isEmpty);
  });

  test('the overview parses surplus, and an older server that does not send it reads as none', () {
    Map<String, dynamic> base() => {
          'people': {
            'operators': {'active': 1, 'suspended': 0, 'unassigned': 0, 'total': 1},
            'farmers': {'active': 1, 'suspended': 0, 'total': 1},
          },
          'centers': {'active': 1, 'suspended': 0, 'withoutOperator': 0},
          'orders': {'pending': 0, 'readyForPickup': 0, 'today': 0},
          'restockRequests': {'pending': 0},
          'lowStockItems': 0,
        };
    final withSurplus = AdminOverview.fromJson({...base(), 'surplus': {'activeLots': 3, 'units': 12}});
    expect((withSurplus.surplusActiveLots, withSurplus.surplusUnits), (3, 12));
    final without = AdminOverview.fromJson(base());
    expect((without.surplusActiveLots, without.surplusUnits), (0, 0));
  });

  testWidgets('overview: a Surplus card counts offers on sale and the units left', (tester) async {
    await _pump(tester, const AdminOverviewScreen());
    expect(find.text('Surplus on sale'), findsOneWidget);
    expect(find.text(' offers'), findsOneWidget);
    expect(find.text('Units left'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supply: surplus offers from every center, with price, what is held, and why; ended ones are kept apart', (tester) async {
    await _pump(tester, const AdminSupplyScreen(initialTab: SupplyTab.surplus));
    expect(find.text('On sale (1)'), findsOneWidget);
    expect(find.text('Ended (1)'), findsOneWidget);
    expect(find.text('Neem Cake'), findsOneWidget);
    expect(find.text('Center A, Shirur'), findsOneWidget);
    expect(find.text('Rs 450 (regular Rs 600, 25% off)'), findsOneWidget);
    expect(find.text('3 available, 2 held · Near expiry · best before 30/11/2026'), findsOneWidget);
    expect(find.text('Torn bags'), findsOneWidget);
    expect(find.text('Vermicompost'), findsNothing);

    await tester.tap(find.text('Ended (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Vermicompost'), findsOneWidget);
    expect(find.text('Sold out'), findsOneWidget);
    expect(find.text('Withdraw'), findsNothing, reason: 'nothing to take off sale');
  });

  testWidgets('supply: withdrawing asks first, sends the reason to the operator, and moves the offer to Ended', (tester) async {
    final repo = await _pump(tester, const AdminSupplyScreen(initialTab: SupplyTab.surplus));
    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw this offer?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.surplusWithdrawals, isEmpty);

    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Past its date');
    await tester.tap(find.widgetWithText(FilledButton, 'Withdraw'));
    await tester.pumpAndSettle();
    expect(repo.surplusWithdrawals, ['s1:Past its date']);
    expect(find.text('Offer withdrawn'), findsOneWidget);
    expect(find.text('On sale (0)'), findsOneWidget);
    expect(find.text('Ended (2)'), findsOneWidget);
  });

  testWidgets('supply: a refused withdrawal shows why and leaves the offer on the list', (tester) async {
    final repo = await _pump(tester, const AdminSupplyScreen(initialTab: SupplyTab.surplus));
    repo.failNextWithdraw = true;
    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Withdraw'));
    await tester.pumpAndSettle();
    expect(find.textContaining('already withdrawn'), findsOneWidget);
    expect(find.text('Neem Cake'), findsOneWidget);
  });

  test('a surplus link opens the Surplus view; unknown ones fall back to restocks', () {
    expect(supplyTabFromQuery('surplus'), SupplyTab.surplus);
    expect(supplyTabFromQuery('discrepancies'), SupplyTab.discrepancies);
    expect(supplyTabFromQuery('nonsense'), SupplyTab.restock);
    expect(supplyTabFromQuery(null), SupplyTab.restock);
  });

  test('the activity list words a surplus withdrawal', () {
    final e = AuditEntry(id: 'a', adminEmail: 'x', action: 'surplus.withdraw', targetType: 'surplus', targetId: 's1', details: const {}, createdAt: DateTime(2026));
    expect(e.summary, 'Withdrew a surplus offer');
  });

  testWidgets('supply: the wide layout renders without overflow', (tester) async {
    await _pump(tester, const AdminSupplyScreen(), size: const Size(1280, 900));
    expect(tester.takeException(), isNull);
  });
}
