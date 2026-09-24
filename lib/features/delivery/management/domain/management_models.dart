import 'package:equatable/equatable.dart';

import '../../domain/entities/delivery_models.dart';

// What a village center's operator (for their own center) and the platform admin
// (for every center) see of home delivery: the deliveries, the people who apply to
// deliver, and the cash partners still hold. The two share one set of shapes.

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
DateTime? _t(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();

/// Which app is asking. The operator is limited to their own center and can act on
/// deliveries; the admin sees every center.
enum ManagementScope { operator, admin }

/// One delivery as the center sees it.
class ManagedDelivery extends Equatable {
  const ManagedDelivery({
    required this.id,
    required this.isP2p,
    required this.status,
    required this.fee,
    required this.weightKg,
    required this.distanceKm,
    required this.goodsAmount,
    required this.cashToCollect,
    required this.dropVillage,
    required this.buyerName,
    required this.needsDriver,
    required this.offersPending,
    this.orderId,
    this.centerName,
    this.partnerId,
    this.partnerName,
    this.partnerPhone,
    this.vehicleType,
    this.vehicleNumber,
    this.ratingAvg,
    this.createdAt,
    this.searchUntil,
  });

  factory ManagedDelivery.fromJson(Map<String, dynamic> j) => ManagedDelivery(
        id: j['id'] as String,
        isP2p: j['kind'] == 'p2p',
        orderId: j['orderId'] as String?,
        status: DeliveryStatus.parse(j['status']),
        fee: _d(j['fee']),
        weightKg: _d(j['weightKg']),
        distanceKm: _d(j['distanceKm']),
        goodsAmount: _d(j['goodsAmount']),
        cashToCollect: _d(j['cashToCollect']),
        dropVillage: (j['dropVillage'] as String?) ?? '',
        buyerName: (j['buyerName'] as String?) ?? 'Farmer',
        needsDriver: (j['needsDriver'] as bool?) ?? false,
        offersPending: _i(j['offersPending']),
        centerName: j['centerName'] as String?,
        partnerId: j['partnerId'] as String?,
        partnerName: j['partnerName'] as String?,
        partnerPhone: j['partnerPhone'] as String?,
        vehicleType: VehicleType.parse(j['vehicleType']),
        vehicleNumber: j['vehicleNumber'] as String?,
        ratingAvg: j['ratingAvg'] == null ? null : _d(j['ratingAvg']),
        createdAt: _t(j['createdAt']),
        searchUntil: _t(j['searchUntil']),
      );

  final String id;
  final bool isP2p;
  final String? orderId;
  final DeliveryStatus status;
  final double fee;
  final double weightKg;
  final double distanceKm;
  final double goodsAmount;

  /// Goods + fee: what the partner takes from the buyer in cash.
  final double cashToCollect;
  final String dropVillage;
  final String buyerName;

  /// Nobody has taken it for a while, so the operator can pick someone.
  final bool needsDriver;
  final int offersPending;

  /// Only on the admin's list, which spans centers.
  final String? centerName;
  final String? partnerId;
  final String? partnerName;
  final String? partnerPhone;
  final VehicleType? vehicleType;
  final String? vehicleNumber;
  final double? ratingAvg;
  final DateTime? createdAt;
  final DateTime? searchUntil;

  bool get hasPartner => partnerId != null;

  @override
  List<Object?> get props => [id, status, fee, partnerId, needsDriver, offersPending, centerName];
}

/// Someone the operator could give a job to.
class AssignCandidate extends Equatable {
  const AssignCandidate({required this.userId, required this.name, required this.phone, required this.vehicleType, required this.vehicleNumber, required this.capacityKg, required this.ratingAvg, required this.ratingCount, required this.freeNow, this.toPickupKm});

  factory AssignCandidate.fromJson(Map<String, dynamic> j) => AssignCandidate(
        userId: j['userId'] as String,
        name: (j['name'] as String?) ?? 'Farmer',
        phone: (j['phone'] as String?) ?? '',
        vehicleType: VehicleType.parse(j['vehicleType']),
        vehicleNumber: (j['vehicleNumber'] as String?) ?? '',
        capacityKg: _i(j['capacityKg']),
        ratingAvg: _d(j['ratingAvg']),
        ratingCount: _i(j['ratingCount']),
        freeNow: (j['freeNow'] as bool?) ?? false,
        toPickupKm: j['toPickupKm'] == null ? null : _d(j['toPickupKm']),
      );

  final String userId;
  final String name;
  final String phone;
  final VehicleType? vehicleType;
  final String vehicleNumber;
  final int capacityKg;
  final double ratingAvg;
  final int ratingCount;
  final bool freeNow;
  final double? toPickupKm;

  @override
  List<Object?> get props => [userId, freeNow, toPickupKm];
}

class PartnerEvent extends Equatable {
  const PartnerEvent({required this.actorRole, required this.action, required this.note, required this.createdAt});

  factory PartnerEvent.fromJson(Map<String, dynamic> j) => PartnerEvent(
        actorRole: (j['actorRole'] as String?) ?? '',
        action: (j['action'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        createdAt: _t(j['createdAt']) ?? DateTime.now(),
      );

  final String actorRole;
  final String action;
  final String note;
  final DateTime createdAt;

  @override
  List<Object?> get props => [actorRole, action, note, createdAt];
}

/// A farmer's application to deliver, as the center that checks it sees it.
class PartnerApplication extends Equatable {
  const PartnerApplication({
    required this.userId,
    required this.name,
    required this.village,
    required this.status,
    required this.vehicleNumber,
    required this.phone,
    required this.maxDistanceKm,
    required this.days,
    required this.freeFrom,
    required this.freeUntil,
    required this.online,
    required this.ratingAvg,
    required this.ratingCount,
    required this.deliveriesDone,
    this.vehicleType,
    this.capacityKg,
    this.reviewCenterName,
    this.rejectionReason,
    this.submittedAt,
    this.licence,
    this.rc,
    this.events = const [],
  });

  factory PartnerApplication.fromJson(Map<String, dynamic> j) {
    final docs = (j['documents'] as Map<String, dynamic>?) ?? const {};
    PartnerDocument? doc(String k) {
      final d = docs[k] as Map<String, dynamic>?;
      return d == null ? null : PartnerDocument(contentType: (d['contentType'] as String?) ?? '', sizeBytes: _i(d['sizeBytes']));
    }

    return PartnerApplication(
      userId: j['userId'] as String,
      name: (j['name'] as String?) ?? 'Farmer',
      village: (j['village'] as String?) ?? '',
      status: PartnerStatus.parse(j['status']),
      vehicleType: VehicleType.parse(j['vehicleType']),
      vehicleNumber: (j['vehicleNumber'] as String?) ?? '',
      capacityKg: j['capacityKg'] == null ? null : _i(j['capacityKg']),
      phone: (j['phone'] as String?) ?? '',
      maxDistanceKm: _i(j['maxDistanceKm']),
      days: [for (final d in (j['days'] as List? ?? const [])) _i(d)],
      freeFrom: (j['freeFrom'] as String?) ?? '',
      freeUntil: (j['freeUntil'] as String?) ?? '',
      online: (j['online'] as bool?) ?? false,
      reviewCenterName: j['reviewCenterName'] as String?,
      rejectionReason: j['rejectionReason'] as String?,
      ratingAvg: _d(j['ratingAvg']),
      ratingCount: _i(j['ratingCount']),
      deliveriesDone: _i(j['deliveriesDone']),
      submittedAt: _t(j['submittedAt']),
      licence: doc('licence'),
      rc: doc('rc'),
      events: [for (final e in (j['events'] as List? ?? const [])) PartnerEvent.fromJson(e as Map<String, dynamic>)],
    );
  }

  final String userId;
  final String name;
  final String village;
  final PartnerStatus status;
  final VehicleType? vehicleType;
  final String vehicleNumber;
  final int? capacityKg;
  final String phone;
  final int maxDistanceKm;
  final List<int> days;
  final String freeFrom;
  final String freeUntil;
  final bool online;
  final String? reviewCenterName;
  final String? rejectionReason;
  final double ratingAvg;
  final int ratingCount;
  final int deliveriesDone;
  final DateTime? submittedAt;
  final PartnerDocument? licence;
  final PartnerDocument? rc;
  final List<PartnerEvent> events;

  @override
  List<Object?> get props => [userId, status, vehicleNumber, capacityKg, phone, online, rejectionReason, licence, rc, events];
}

enum ReviewAction {
  approve,
  reject,
  suspend,
  reactivate;

  /// Reject and suspend need the reason to be said, since the farmer is told it.
  bool get needsReason => this == reject || this == suspend;
}

/// Cash a partner collected for goods and has not yet handed to this center.
class CashOwed extends Equatable {
  const CashOwed({required this.partnerId, required this.name, required this.phone, required this.owed});

  factory CashOwed.fromJson(Map<String, dynamic> j) => CashOwed(
        partnerId: j['partnerId'] as String,
        name: (j['name'] as String?) ?? 'Farmer',
        phone: (j['phone'] as String?) ?? '',
        owed: _d(j['owed']),
      );

  final String partnerId;
  final String name;
  final String phone;
  final double owed;

  @override
  List<Object?> get props => [partnerId, owed];
}

/// The admin overview's delivery block.
class DeliverySummary extends Equatable {
  const DeliverySummary({required this.waiting, required this.needDriver, required this.onTheRoad, required this.deliveredToday, required this.partnersPending, required this.partnersApproved, required this.partnersOnline, required this.cashOwed});

  factory DeliverySummary.fromJson(Map<String, dynamic> j) {
    final jobs = (j['jobs'] as Map<String, dynamic>?) ?? const {};
    final partners = (j['partners'] as Map<String, dynamic>?) ?? const {};
    return DeliverySummary(
      waiting: _i(jobs['waiting']),
      needDriver: _i(jobs['needDriver']),
      onTheRoad: _i(jobs['onTheRoad']),
      deliveredToday: _i(jobs['deliveredToday']),
      partnersPending: _i(partners['pending']),
      partnersApproved: _i(partners['approved']),
      partnersOnline: _i(partners['online']),
      cashOwed: _d(j['cashOwed']),
    );
  }

  final int waiting;
  final int needDriver;
  final int onTheRoad;
  final int deliveredToday;
  final int partnersPending;
  final int partnersApproved;
  final int partnersOnline;
  final double cashOwed;

  @override
  List<Object?> get props => [waiting, needDriver, onTheRoad, deliveredToday, partnersPending, partnersApproved, partnersOnline, cashOwed];
}
