import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khaadsetu_version1/features/admin/domain/entities/admin_models.dart';
import 'package:khaadsetu_version1/features/delivery/domain/entities/delivery_models.dart';
import 'package:khaadsetu_version1/features/delivery/management/domain/management_models.dart';
import 'package:khaadsetu_version1/features/farmer/notifications/domain/entities/app_notification.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/entities/farmer_order.dart';

/// The app's models against what the real backend answers. `delivery_server_samples.json`
/// was captured by running a whole delivery through the Express server (apply,
/// approve, order, accept, hand over, deliver, wallet, cash, a trip, a load, the
/// admin's views), so a renamed field or a changed shape fails here, not on a phone.
///
/// To capture it again, run the delivery flow against the backend's test server and
/// save each response under the same names.
void main() {
  final samples = jsonDecode(File('test/fixtures/delivery_server_samples.json').readAsStringSync()) as Map<String, dynamic>;
  Map<String, dynamic> obj(String k) => samples[k] as Map<String, dynamic>;
  List<Map<String, dynamic>> list(String k) => [for (final e in samples[k] as List) e as Map<String, dynamic>];

  group('applying to deliver', () {
    test('a farmer who never applied has status none and knows everything that is missing', () {
      final p = PartnerProfile.fromJson(obj('partnerNone'));
      expect(p.status, PartnerStatus.none);
      expect(p.canEdit, isTrue);
      expect(p.missing, containsAll(['vehicleType', 'vehicleNumber', 'capacityKg', 'phone', 'licence', 'rc']));
      expect(p.canSubmit, isFalse);
      expect(p.days, [0, 1, 2, 3, 4, 5, 6]);
    });

    test('a saved draft with both papers can be sent', () {
      final p = PartnerProfile.fromJson(obj('partnerDraft'));
      expect(p.status, PartnerStatus.draft);
      expect(p.vehicleType, VehicleType.pickup);
      expect(p.vehicleNumber, 'MH12AB1234');
      expect(p.capacityKg, 600);
      expect(p.licence, isNotNull);
      expect(p.rc, isNotNull);
      expect(p.missing, isEmpty);
      expect(p.canSubmit, isTrue);
      expect(p.reviewCenterName, 'Shirur Center');
      expect(p.freeFrom, '00:00');
    });

    test('pending, then approved and online', () {
      expect(PartnerProfile.fromJson(obj('partnerPending')).status, PartnerStatus.pending);
      final online = PartnerProfile.fromJson(obj('partnerOnline'));
      expect(online.isApproved, isTrue);
      expect(online.online, isTrue);
    });
  });

  group('the center checking the application', () {
    test('the queue and the detail with its history', () {
      final row = PartnerApplication.fromJson(list('opPartnersList').single);
      expect(row.userId, 'ramesh');
      expect(row.name, 'Ramesh Patil');
      expect(row.village, 'Shirur');
      expect(row.status, PartnerStatus.pending);
      expect(row.vehicleType, VehicleType.pickup);
      expect(row.submittedAt, isNotNull);

      final detail = PartnerApplication.fromJson(obj('opPartnerDetail'));
      expect(detail.licence, isNotNull);
      expect(detail.rc, isNotNull);
      expect(detail.events.map((e) => e.action), contains('submitted'));
      expect(detail.reviewCenterName, 'Shirur Center');
    });

    test('a paper comes back as an image, and approving returns the new status', () {
      expect(samples['documentContentType'], startsWith('image/'));
      expect(samples['documentBytes'] as int, greaterThan(100));
      expect(PartnerApplication.fromJson(obj('opApprove')).status, PartnerStatus.approved);
    });
  });

  group('the buyer', () {
    test('the quote', () {
      final q = DeliveryQuote.fromJson(obj('quote'));
      expect(q.available, isTrue);
      expect(q.fee, 60);
      expect(q.weightKg, 40);
      expect(q.partnersFree, 1);
      expect(q.suggestedVehicle, VehicleType.pickup);
      expect(q.payment, contains('cash'));
      expect(q.centerName, 'Shirur Center');
    });

    test('an order just placed: waiting for a partner, no code yet, no counter code either', () {
      final o = FarmerOrder.fromJson(obj('orderPlaced'));
      expect(o.isHomeDelivery, isTrue);
      expect(o.deliveryFee, 60);
      expect(o.payableAmount, o.totalAmount + 60);
      expect(o.pickupOtp, isNull);
      final d = o.delivery!;
      expect(d.status, DeliveryStatus.open);
      expect(d.stage, 'Finding a delivery partner');
      expect(d.partner, isNull);
      expect(d.dropCode, isNull);
      expect(d.canSwitchToPickup, isTrue);
      expect(d.isP2p, isFalse);
      expect(d.pickup.label, contains('Shirur Center'));
    });

    test('a partner accepted: who is coming, and the code to read out', () {
      final d = FarmerOrder.fromJson(obj('orderAssigned')).delivery!;
      expect(d.status, DeliveryStatus.assigned);
      expect(d.partner!.name, 'Ramesh Patil');
      expect(d.partner!.vehicleNumber, 'MH12AB1234');
      expect(d.partner!.vehicleLabel, 'Pickup / small van');
      expect(d.dropCode, matches(RegExp(r'^\d{4}$')));
      expect(d.canSwitchToPickup, isTrue);
    });

    test('on the road: the code, the partner\'s place and the time left', () {
      final d = FarmerOrder.fromJson(obj('orderInTransit')).delivery!;
      expect(d.status, DeliveryStatus.inTransit);
      expect(d.dropCode, isNotNull);
      expect(d.canSwitchToPickup, isFalse);
      final tracked = FarmerOrder.fromJson(obj('orderTracked')).delivery!;
      expect(tracked.partnerLocation, isNotNull);
      expect(tracked.nextStop, 'you');
      expect(tracked.distanceToNextStopKm, isNotNull);
      expect(tracked.etaMinutes, isNotNull);
    });

    test('delivered: the order is completed and no code is left to show', () {
      final o = FarmerOrder.fromJson(obj('orderDelivered'));
      expect(o.status, FarmerOrderStatus.completed);
      expect(o.delivery!.status, DeliveryStatus.delivered);
      expect(o.delivery!.dropCode, isNull);
      expect(o.delivery!.rated, isFalse);
    });

    test('switching to pickup gives a pickup code back and ends the delivery', () {
      final o = FarmerOrder.fromJson(obj('orderSwitched'));
      expect(o.isHomeDelivery, isFalse);
      expect(o.deliveryFee, 0);
      expect(o.pickupOtp, matches(RegExp(r'^\d{4}$')));
      expect(o.delivery!.status, DeliveryStatus.cancelled);
    });
  });

  group('the partner', () {
    test('an offer shows the money and the rough place, and hides the exact drop', () {
      final offer = PartnerJob.fromJson(list('partnerOffers').single);
      expect(offer.status, DeliveryStatus.open);
      expect(offer.fee, 60);
      expect(offer.weightKg, 40);
      expect(offer.items, contains('Vermicompost'));
      expect(offer.centerName, 'Shirur Center');
      expect(offer.drop, isNull);
      expect(offer.dropPhone, isNull);
      expect(offer.handoverCode, isNull);
      expect(offer.offerExpiresAt, isNotNull);
      expect(offer.mine, isFalse);
    });

    test('once accepted: the exact place, the phone, the code and the cash', () {
      final job = PartnerJob.fromJson(obj('partnerAccepted'));
      expect(job.status, DeliveryStatus.assigned);
      expect(job.mine, isTrue);
      expect(job.handoverCode, matches(RegExp(r'^\d{4}$')));
      expect(job.drop, isNotNull);
      expect(job.dropPhone, '9876543210');
      expect(job.buyerName, isNotEmpty);
      expect(job.cashToCollect, greaterThan(job.fee), reason: 'the goods money on top of his fee');
      expect(job.collectFeeFrom, 'receiver');
      expect(PartnerJob.fromJson(list('partnerActive').single).id, job.id);
    });

    test('on the road the handover code is gone; after delivery he keeps the fee', () {
      final onRoad = PartnerJob.fromJson(list('partnerInTransit').single);
      expect(onRoad.status, DeliveryStatus.inTransit);
      expect(onRoad.handoverCode, isNull);
      expect(PartnerJob.fromJson(obj('partnerDelivered')).status, DeliveryStatus.delivered);
    });

    test('the wallet: fee earned, goods owed, then some handed over', () {
      final w = Wallet.fromJson(obj('wallet'));
      expect(w.earned, 60);
      expect(w.owed, greaterThan(0));
      expect(w.deliveriesDone, 1);
      expect(w.owedByCenter.single.centerName, 'Shirur Center');
      expect(w.entries.map((e) => e.kind), containsAll([LedgerKind.feeEarned, LedgerKind.goodsOwed]));
    });
  });

  group('cash and deliveries at the center', () {
    test('the deliveries board, one delivery, and who could take a job', () {
      final taken = ManagedDelivery.fromJson(list('opDeliveries').first);
      expect(taken.status, DeliveryStatus.assigned);
      expect(taken.partnerName, 'Ramesh Patil');
      expect(taken.vehicleType, VehicleType.pickup);
      expect(taken.vehicleNumber, 'MH12AB1234');
      expect(taken.cashToCollect, taken.goodsAmount + taken.fee);
      expect(taken.buyerName, isNotEmpty);
      expect(taken.isP2p, isFalse);
      expect(taken.needsDriver, isFalse);

      expect(ManagedDelivery.fromJson(obj('opHandover')).status, DeliveryStatus.inTransit);
      final open = ManagedDelivery.fromJson(obj('opDeliveryOpen'));
      expect(open.status, DeliveryStatus.open);
      expect(open.hasPartner, isFalse);

      for (final c in list('candidates')) {
        final cand = AssignCandidate.fromJson(c);
        expect(cand.userId, isNotEmpty);
        expect(cand.capacityKg, greaterThan(0));
      }
    });

    test('the cash owed, before and after recording some', () {
      final owed = CashOwed.fromJson(list('opCash').single);
      expect(owed.partnerId, 'ramesh');
      expect(owed.name, 'Ramesh Patil');
      final after = CashOwed.fromJson(list('opCashSettled').single);
      expect(after.owed, owed.owed - 200);
    });
  });

  group('trips and loads', () {
    test('a trip, my trips, and the board', () {
      final t = Trip.fromJson(obj('trip'));
      expect(t.spareKg, 60);
      expect(t.leftKg, 60);
      expect(t.from.label, 'Shirur');
      expect(t.to.label, 'Talegaon');
      expect(t.bookings, 0);
      expect(Trip.fromJson(list('myTrips').single).id, t.id);
      final onBoard = Trip.fromJson(list('board').single);
      expect(onBoard.partnerName, 'Ramesh Patil');
      expect(onBoard.vehicleType, VehicleType.pickup);
      expect(onBoard.fromKm, isNotNull);
    });

    test('the quote for a load, and the load as its sender follows it', () {
      final q = LoadQuote.fromJson(obj('loadQuote'));
      expect(q.available, isTrue);
      expect(q.fee, greaterThanOrEqualTo(30));

      final placed = DeliveryTracking.fromJson(obj('loadPlaced'));
      expect(placed.isP2p, isTrue);
      expect(placed.description, 'Two sacks of seed potatoes');
      expect(placed.feePayer, 'sender');
      expect(placed.canCancel, isTrue);
      expect(placed.canSwitchToPickup, isFalse);
      expect(placed.receiverPhone, '9822054321');

      final assigned = DeliveryTracking.fromJson(obj('loadAssigned'));
      expect(assigned.status, DeliveryStatus.assigned);
      expect(assigned.partner!.name, 'Ramesh Patil');
      expect(assigned.dropCode, matches(RegExp(r'^\d{4}$')));

      final onRoad = DeliveryTracking.fromJson(obj('loadInTransit'));
      expect(onRoad.status, DeliveryStatus.inTransit);
      expect(onRoad.canCancel, isFalse);
      expect(list('myLoads').map(DeliveryTracking.fromJson).single.jobId, placed.jobId);
    });

    test('a load booked on a trip is an offer for its owner, with the sender\'s phone after accepting', () {
      final offer = PartnerJob.fromJson(list('partnerLoadOffers').single);
      expect(offer.isP2p, isTrue);
      expect(offer.items, 'Two sacks of seed potatoes');
      expect(offer.centerName, isNull);
      expect(offer.tripId, isNotNull);
      final accepted = PartnerJob.fromJson(obj('partnerLoadAccepted'));
      expect(accepted.pickupPhone, '9822012345');
      expect(accepted.dropPhone, '9822054321');
      expect(accepted.collectFeeFrom, 'sender');
      expect(accepted.cashToCollect, accepted.fee);
    });
  });

  group('the admin', () {
    test('every center\'s deliveries and applications', () {
      final rows = list('adminDeliveries').map(ManagedDelivery.fromJson).toList();
      expect(rows.map((d) => d.isP2p), contains(true));
      expect(rows.map((d) => d.isP2p), contains(false));
      expect(rows.where((d) => !d.isP2p).every((d) => d.centerName == 'Shirur Center'), isTrue);
      expect(PartnerApplication.fromJson(list('adminPartners').single).status, PartnerStatus.approved);
    });

    test('the overview counts', () {
      final o = AdminOverview.fromJson(obj('adminOverview'));
      final d = o.delivery!;
      expect(d.partnersApproved, 1);
      expect(d.partnersOnline, 1);
      expect(d.onTheRoad, greaterThanOrEqualTo(1));
      expect(d.deliveredToday, 1);
      expect(d.cashOwed, greaterThan(0));
    });
  });

  test('delivery notifications are their own kind, so they get their icon and their destination', () {
    final types = list('notifications').map((n) => NotificationType.parse(n['type'])).toSet();
    expect(types, contains(NotificationType.delivery));
    expect(NotificationType.parse('delivery'), NotificationType.delivery);
  });
}
