import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khaadsetu_version1/core/routing/route_paths.dart';
import 'package:khaadsetu_version1/core/theme/app_theme.dart';
import 'package:khaadsetu_version1/features/admin/domain/entities/admin_models.dart';
import 'package:khaadsetu_version1/features/delivery/domain/entities/delivery_models.dart';
import 'package:khaadsetu_version1/features/delivery/management/domain/management_models.dart';
import 'package:khaadsetu_version1/features/delivery/management/presentation/delivery_management_screen.dart';
import 'package:khaadsetu_version1/features/delivery/management/presentation/management_providers.dart';
import 'package:khaadsetu_version1/features/delivery/management/presentation/operator_deliveries_tile.dart';

import 'support/delivery_fakes.dart';

Future<void> _pump(WidgetTester tester, FakeManagementRepository repo, {ManagementScope scope = ManagementScope.operator, Widget? home}) async {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [managementRepositoryProvider(scope).overrideWithValue(repo)],
    child: MaterialApp(theme: AppTheme.light, home: home ?? DeliveryManagementScreen(scope: scope)),
  ));
  await tester.pumpAndSettle();
}

/// The screens refresh on a timer; leaving the tree ends it.
Future<void> _end(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  group('the deliveries board', () {
    testWidgets('lists what is going out, with who is carrying it', (tester) async {
      final repo = FakeManagementRepository()
        ..deliveryList = [
          managedDelivery('j1', status: DeliveryStatus.inTransit, partner: 'Ganesh'),
          managedDelivery('j2', offers: 2),
          managedDelivery('j3', status: DeliveryStatus.delivered, partner: 'Mahesh'),
        ];
      await _pump(tester, repo);
      expect(find.byKey(const Key('delivery-j1')), findsOneWidget);
      expect(find.text('On the road'), findsWidgets);
      expect(find.textContaining('Ganesh · Pickup / small van MH12AB1234 · ★ 4.6'), findsOneWidget);
      expect(find.text('Suresh · Shirur'), findsWidgets);
      expect(find.text('40 kg · 6.5 km · fee ₹60 · goods ₹1,200'), findsWidgets);
      expect(find.text('Offered to 2 partners now.'), findsOneWidget);
      expect(find.text('Delivered'), findsWidgets);
      await _end(tester);
    });

    testWidgets('a filter asks the server for that state only', (tester) async {
      final repo = FakeManagementRepository()..deliveryList = [managedDelivery('j1'), managedDelivery('j2', status: DeliveryStatus.delivered, partner: 'Ganesh')];
      await _pump(tester, repo);
      await tester.ensureVisible(find.byKey(const Key('filter-Delivered')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-Delivered')));
      await tester.pumpAndSettle();
      expect(repo.deliveryFilters, [null, DeliveryStatus.delivered]);
      expect(find.byKey(const Key('delivery-j2')), findsOneWidget);
      expect(find.byKey(const Key('delivery-j1')), findsNothing);
      await _end(tester);
    });

    testWidgets('an empty board says so', (tester) async {
      await _pump(tester, FakeManagementRepository());
      expect(find.byKey(const Key('no-deliveries')), findsOneWidget);
      await _end(tester);
    });

    testWidgets('nobody took it: the operator is told, picks a driver from the list, and it is assigned', (tester) async {
      final repo = FakeManagementRepository()
        ..deliveryList = [managedDelivery('j1', needsDriver: true)]
        ..candidateList = [
          const AssignCandidate(userId: 'p-far', name: 'Far Farmer', phone: '9', vehicleType: VehicleType.tractor, vehicleNumber: 'MH12ZZ1', capacityKg: 2000, ratingAvg: 4, ratingCount: 3, freeNow: false, toPickupKm: 9.5),
          const AssignCandidate(userId: 'p-near', name: 'Near Farmer', phone: '9', vehicleType: VehicleType.pickup, vehicleNumber: 'MH12ZZ2', capacityKg: 600, ratingAvg: 4.8, ratingCount: 10, freeNow: true, toPickupKm: 1.2),
        ];
      await _pump(tester, repo);
      expect(find.text('Nobody has taken this yet. You can pick someone yourself.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('driver-j1')));
      await tester.pumpAndSettle();
      expect(find.text('Who can carry 40 kg?'), findsOneWidget);
      expect(find.text('Near Farmer'), findsOneWidget);
      expect(find.textContaining('1.2 km away · free now'), findsOneWidget);
      expect(find.textContaining('9.5 km away · not on duty'), findsOneWidget);

      await tester.tap(find.byKey(const Key('assign-p-near')));
      await tester.pumpAndSettle();
      expect(repo.assigned.single, (jobId: 'j1', partnerId: 'p-near'));
      expect(find.textContaining('Assigned. The partner and the farmer have been told.'), findsOneWidget);
      // The list follows: it now has a partner and a handover button.
      expect(find.byKey(const Key('handover-j1')), findsOneWidget);
      await _end(tester);
    });

    testWidgets('no partner fits: the sheet says so', (tester) async {
      final repo = FakeManagementRepository()..deliveryList = [managedDelivery('j1', needsDriver: true)];
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('driver-j1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('no-candidates')), findsOneWidget);
      await _end(tester);
    });

    testWidgets('handing over the goods needs the partner\'s code; a wrong one is reported', (tester) async {
      final repo = FakeManagementRepository()..deliveryList = [managedDelivery('j1', status: DeliveryStatus.assigned, partner: 'Ganesh')];
      await _pump(tester, repo);

      await tester.tap(find.byKey(const Key('handover-j1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('code-field')), '0000');
      await tester.pump();
      repo.error = ApiExceptionLike('That code is wrong. 4 tries left.');
      await tester.tap(find.byKey(const Key('code-submit')));
      await tester.pumpAndSettle();
      expect(find.text('That code is wrong. 4 tries left.'), findsOneWidget);
      expect(find.byKey(const Key('handover-j1')), findsOneWidget, reason: 'still waiting to be handed over');

      await tester.tap(find.byKey(const Key('handover-j1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('code-field')), '4821');
      await tester.pump();
      await tester.tap(find.byKey(const Key('code-submit')));
      await tester.pumpAndSettle();
      expect(repo.handovers.single, (jobId: 'j1', otp: '4821'));
      expect(find.byKey(const Key('handover-j1')), findsNothing, reason: 'it is on the road now');
      expect(find.text('On the road'), findsWidgets);
      await _end(tester);
    });

    testWidgets('the admin sees every center\'s deliveries but has no buttons to act', (tester) async {
      final repo = FakeManagementRepository(scope: ManagementScope.admin)
        ..deliveryList = [managedDelivery('j1', needsDriver: true, center: 'Shirur Center'), managedDelivery('j2', status: DeliveryStatus.assigned, partner: 'Ganesh', center: 'Pune Center')];
      await _pump(tester, repo, scope: ManagementScope.admin);
      expect(find.text('Shirur Center'), findsOneWidget);
      expect(find.text('Pune Center'), findsOneWidget);
      expect(find.byKey(const Key('driver-j1')), findsNothing);
      expect(find.byKey(const Key('handover-j2')), findsNothing);
      expect(find.byKey(const Key('tab-cash')), findsNothing, reason: 'cash is the operator\'s to record');
      await _end(tester);
    });
  });

  group('checking partners', () {
    testWidgets('waiting applications come first and open the review page', (tester) async {
      final repo = FakeManagementRepository()
        ..applications = [
          application('u1'),
          application('u2', status: PartnerStatus.approved, name: 'Already Approved'),
        ];
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('tab-partners')));
      await tester.pumpAndSettle();
      expect(repo.partnerFilters.last, PartnerStatus.pending, reason: 'opens on the ones waiting');
      expect(find.text('Ramesh Patil'), findsOneWidget);
      expect(find.text('Already Approved'), findsNothing);

      await tester.tap(find.byKey(const Key('pfilter-All')));
      await tester.pumpAndSettle();
      expect(find.text('Already Approved'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('an empty queue is said plainly', (tester) async {
      await _pump(tester, FakeManagementRepository());
      await tester.tap(find.byKey(const Key('tab-partners')));
      await tester.pumpAndSettle();
      expect(find.text('Nobody is waiting to be checked.'), findsOneWidget);
      await _end(tester);
    });

    Future<FakeManagementRepository> openReview(WidgetTester tester, PartnerApplication app, {ManagementScope scope = ManagementScope.operator}) async {
      final repo = FakeManagementRepository(scope: scope)..applications = [app];
      await _pump(tester, repo, scope: scope);
      await tester.tap(find.byKey(const Key('tab-partners')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pfilter-All')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('partner-${app.userId}')));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('the review page shows the vehicle and both papers, and approving asks first', (tester) async {
      final repo = await openReview(tester, application('u1'));
      expect(find.text('Waiting for your decision'), findsOneWidget);
      expect(find.text('Pickup / small van · MH12AB1234'), findsOneWidget);
      expect(find.text('Carries up to 600 kg'), findsOneWidget);
      expect(find.textContaining('Goes up to 10 km · Mon, Tue, Wed, Thu, Fri, Sat · 06:00 to 20:00'), findsOneWidget);
      expect(find.byKey(const Key('doc-image-licence')), findsOneWidget);
      expect(find.byKey(const Key('doc-image-rc')), findsOneWidget);

      await tester.tap(find.byKey(const Key('approve')));
      await tester.pumpAndSettle();
      expect(find.text('Approve this partner?'), findsOneWidget);
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(repo.reviews, isEmpty);

      await tester.tap(find.byKey(const Key('approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-approve')));
      await tester.pumpAndSettle();
      expect(repo.reviews.single.action, ReviewAction.approve);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.byKey(const Key('approve')), findsNothing);
      expect(find.byKey(const Key('suspend')), findsOneWidget, reason: 'now the way to pause them shows');
      await _end(tester);
    });

    testWidgets('turning someone down needs a reason, which they are told', (tester) async {
      final repo = await openReview(tester, application('u1'));
      await tester.tap(find.byKey(const Key('reject')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('reason-submit'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('reason-field')), 'The RC photo is blurred');
      await tester.pump();
      await tester.tap(find.byKey(const Key('reason-submit')));
      await tester.pumpAndSettle();
      expect(repo.reviews.single.action, ReviewAction.reject);
      expect(repo.reviews.single.note, 'The RC photo is blurred');
      expect(find.text('Turned down: The RC photo is blurred'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('an approved partner can be paused with a reason, and let back in', (tester) async {
      final repo = await openReview(tester, application('u1', status: PartnerStatus.approved));
      expect(find.byKey(const Key('approve')), findsNothing);
      await tester.tap(find.byKey(const Key('suspend')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('reason-field')), 'Rude to a farmer');
      await tester.pump();
      await tester.tap(find.byKey(const Key('reason-submit')));
      await tester.pumpAndSettle();
      expect(repo.reviews.single.action, ReviewAction.suspend);
      expect(find.text('Paused'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reactivate')));
      await tester.pumpAndSettle();
      expect(repo.reviews.last.action, ReviewAction.reactivate);
      expect(repo.reviews.last.note, isNull, reason: 'no reason needed to let them back in');
      expect(find.textContaining('Approved'), findsWidgets);
      await _end(tester);
    });

    testWidgets('a missing paper is shown as missing, and the history is listed', (tester) async {
      await openReview(tester, application('u1', rc: false, events: [PartnerEvent(actorRole: 'partner', action: 'submitted', note: '', createdAt: DateTime(2026, 9, 24))]));
      expect(find.byKey(const Key('missing-rc')), findsOneWidget);
      expect(find.byKey(const Key('doc-image-licence')), findsOneWidget);
      expect(find.text('Sent for checking'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('a refused decision shows the server\'s message', (tester) async {
      final repo = await openReview(tester, application('u1'));
      repo.error = ApiExceptionLike('This application is not waiting for a decision');
      await tester.tap(find.byKey(const Key('approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-approve')));
      await tester.pumpAndSettle();
      expect(find.text('This application is not waiting for a decision'), findsOneWidget);
      await _end(tester);
    });
  });

  group('cash', () {
    testWidgets('what partners still owe, and recording what they hand over', (tester) async {
      final repo = FakeManagementRepository()
        ..cash = [
          const CashOwed(partnerId: 'p1', name: 'Ganesh', phone: '9876500000', owed: 2400),
          const CashOwed(partnerId: 'p2', name: 'Mahesh', phone: '', owed: 600),
        ];
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('tab-cash')));
      await tester.pumpAndSettle();
      expect(find.text('Owes ₹2,400'), findsOneWidget);

      await tester.tap(find.byKey(const Key('record-p1')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const Key('cash-amount'))).controller!.text, '2400', reason: 'starts at everything owed');
      await tester.enterText(find.byKey(const Key('cash-amount')), '1000');
      await tester.tap(find.byKey(const Key('cash-record')));
      await tester.pumpAndSettle();
      expect(repo.settled.single, (partnerId: 'p1', amount: 1000.0));
      expect(find.text('Owes ₹1,400'), findsOneWidget);

      // Paying it all off clears the row.
      await tester.tap(find.byKey(const Key('record-p2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cash-record')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cash-p2')), findsNothing);
      await _end(tester);
    });

    testWidgets('nobody owing anything is a plain note', (tester) async {
      await _pump(tester, FakeManagementRepository());
      await tester.tap(find.byKey(const Key('tab-cash')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('no-cash')), findsOneWidget);
      await _end(tester);
    });

    testWidgets('claiming more than is owed shows the server\'s message', (tester) async {
      final repo = FakeManagementRepository()..cash = [const CashOwed(partnerId: 'p1', name: 'Ganesh', phone: '', owed: 500)];
      await _pump(tester, repo);
      await tester.tap(find.byKey(const Key('tab-cash')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('record-p1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('cash-amount')), '900');
      repo.error = ApiExceptionLike('That partner only owes Rs 500');
      await tester.tap(find.byKey(const Key('cash-record')));
      await tester.pumpAndSettle();
      expect(find.text('That partner only owes Rs 500'), findsOneWidget);
      await _end(tester);
    });
  });

  group('the operator\'s dashboard tile', () {
    Future<void> pumpTile(WidgetTester tester, FakeManagementRepository repo) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, _) => const Scaffold(body: Padding(padding: EdgeInsets.all(16), child: OperatorDeliveriesTile()))),
        GoRoute(path: RoutePaths.operatorDeliveries, builder: (context, _) => const Text('deliveries screen')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [managementRepositoryProvider(ManagementScope.operator).overrideWithValue(repo)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('says what needs the operator, and opens the board', (tester) async {
      final repo = FakeManagementRepository()
        ..deliveryList = [managedDelivery('j1', needsDriver: true), managedDelivery('j2', needsDriver: true), managedDelivery('j3')]
        ..applications = [application('u1')];
      await pumpTile(tester, repo);
      expect(find.text('2 need a driver · 1 application to check'), findsOneWidget);
      expect(find.text('3'), findsOneWidget, reason: 'the badge adds them up');
      await tester.tap(find.byKey(const Key('open-deliveries')));
      await tester.pumpAndSettle();
      expect(find.text('deliveries screen'), findsOneWidget);
    });

    testWidgets('with nothing to do it just explains itself', (tester) async {
      await pumpTile(tester, FakeManagementRepository());
      expect(find.textContaining('Orders going out with delivery partners'), findsOneWidget);
    });
  });

  group('the admin overview', () {
    test('carries the delivery counts', () {
      final o = AdminOverview.fromJson({
        'people': {
          'operators': {'active': 1, 'suspended': 0, 'unassigned': 0, 'total': 1},
          'farmers': {'active': 2, 'suspended': 0, 'unassigned': 0, 'total': 2},
        },
        'centers': {'active': 1, 'suspended': 0, 'withoutOperator': 0, 'total': 1},
        'orders': {'pending': 0, 'readyForPickup': 0, 'today': 0},
        'restockRequests': {'pending': 0},
        'lowStockItems': 0,
        'delivery': {
          'jobs': {'waiting': 3, 'needDriver': 1, 'onTheRoad': 2, 'deliveredToday': 5},
          'partners': {'pending': 4, 'approved': 6, 'online': 2},
          'cashOwed': 1800.5,
        },
      });
      expect(o.delivery!.needDriver, 1);
      expect(o.delivery!.onTheRoad, 2);
      expect(o.delivery!.deliveredToday, 5);
      expect(o.delivery!.partnersPending, 4);
      expect(o.delivery!.partnersApproved, 6);
      expect(o.delivery!.cashOwed, 1800.5);
    });

    test('an older server without them still parses', () {
      final o = AdminOverview.fromJson({
        'people': {
          'operators': {'active': 1, 'suspended': 0, 'unassigned': 0, 'total': 1},
          'farmers': {'active': 2, 'suspended': 0, 'unassigned': 0, 'total': 2},
        },
        'centers': {'active': 1, 'suspended': 0, 'withoutOperator': 0, 'total': 1},
        'orders': {'pending': 0, 'readyForPickup': 0, 'today': 0},
        'restockRequests': {'pending': 0},
        'lowStockItems': 0,
      });
      expect(o.delivery, isNull);
    });
  });
}

/// An error worded like the server's, without pulling in the HTTP client.
class ApiExceptionLike implements Exception {
  ApiExceptionLike(this.message);

  final String message;

  @override
  String toString() => message;
}
