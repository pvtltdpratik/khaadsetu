import 'package:equatable/equatable.dart';

// Everything the app knows about home delivery, in one place: what a delivery
// costs, following one, being a delivery partner (jobs, wallet, trips), and
// carrying a load from one farm to another.

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
DateTime? _t(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();

enum VehicleType {
  bike('Bike', 5, 80),
  pickup('Pickup / small van', 100, 1500),
  tractor('Tractor', 500, 8000);

  const VehicleType(this.label, this.minKg, this.maxKg);

  final String label;
  final int minKg;
  final int maxKg;

  static VehicleType? parse(Object? raw) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

/// Where a delivery is to be brought.
class DeliveryAddress extends Equatable {
  const DeliveryAddress({required this.latitude, required this.longitude, required this.phone, this.label = '', this.note = '', this.village = ''});

  final double latitude;
  final double longitude;
  final String phone;
  final String label;
  final String note;
  final String village;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        if (label.isNotEmpty) 'label': label,
        if (note.isNotEmpty) 'note': note,
        if (village.isNotEmpty) 'village': village,
      };

  @override
  List<Object?> get props => [latitude, longitude, phone, label, note, village];
}

/// What delivering a cart would cost, before the farmer decides.
class DeliveryQuote extends Equatable {
  const DeliveryQuote({
    required this.centerId,
    required this.centerName,
    required this.available,
    required this.fee,
    required this.weightKg,
    required this.roadKm,
    required this.partnersFree,
    required this.note,
    required this.payment,
    this.suggestedVehicle,
  });

  factory DeliveryQuote.fromJson(Map<String, dynamic> j) => DeliveryQuote(
        centerId: (j['centerId'] as String?) ?? '',
        centerName: (j['centerName'] as String?) ?? '',
        available: j['available'] as bool,
        fee: j['fee'] == null ? null : _d(j['fee']),
        weightKg: _d(j['weightKg']),
        roadKm: _d(j['roadKm']),
        partnersFree: _i(j['partnersFree']),
        note: (j['note'] as String?) ?? '',
        payment: (j['payment'] as String?) ?? '',
        suggestedVehicle: VehicleType.parse(j['suggestedVehicle']),
      );

  final String centerId;
  final String centerName;

  /// False when the farm is too far from the center.
  final bool available;
  final double? fee;
  final double weightKg;
  final double roadKm;
  final int partnersFree;
  final String note;
  final String payment;
  final VehicleType? suggestedVehicle;

  @override
  List<Object?> get props => [centerId, available, fee, weightKg, roadKm, partnersFree, note];
}

enum DeliveryStatus {
  open,
  assigned,
  inTransit,
  delivered,
  cancelled,
  fallback;

  static DeliveryStatus parse(Object? raw) => switch (raw) {
        'assigned' => DeliveryStatus.assigned,
        'in_transit' => DeliveryStatus.inTransit,
        'delivered' => DeliveryStatus.delivered,
        'cancelled' => DeliveryStatus.cancelled,
        'fallback' => DeliveryStatus.fallback,
        _ => DeliveryStatus.open,
      };

  /// Someone is on it (or looking), so the codes are live.
  bool get isLive => this == open || this == assigned || this == inTransit;
}

class GeoPoint extends Equatable {
  const GeoPoint({required this.latitude, required this.longitude, this.label = ''});

  factory GeoPoint.fromJson(Map<String, dynamic> j) => GeoPoint(latitude: _d(j['latitude']), longitude: _d(j['longitude']), label: (j['label'] as String?) ?? '');

  final double latitude;
  final double longitude;
  final String label;

  @override
  List<Object?> get props => [latitude, longitude, label];
}

class PartnerInfo extends Equatable {
  const PartnerInfo({required this.name, required this.vehicleLabel, required this.vehicleNumber, required this.ratingAvg, required this.ratingCount, required this.deliveriesDone, required this.phone});

  factory PartnerInfo.fromJson(Map<String, dynamic> j) => PartnerInfo(
        name: (j['name'] as String?) ?? 'Farmer',
        vehicleLabel: (j['vehicleLabel'] as String?) ?? '',
        vehicleNumber: (j['vehicleNumber'] as String?) ?? '',
        ratingAvg: _d(j['ratingAvg']),
        ratingCount: _i(j['ratingCount']),
        deliveriesDone: _i(j['deliveriesDone']),
        phone: (j['phone'] as String?) ?? '',
      );

  final String name;
  final String vehicleLabel;
  final String vehicleNumber;
  final double ratingAvg;
  final int ratingCount;
  final int deliveriesDone;
  final String phone;

  @override
  List<Object?> get props => [name, vehicleNumber, ratingAvg, ratingCount, phone];
}

/// A delivery as the person waiting for it sees it: a buyer following an order,
/// or a sender following a farmer-to-farmer load ([isP2p]).
class DeliveryTracking extends Equatable {
  const DeliveryTracking({
    required this.jobId,
    required this.isP2p,
    required this.status,
    required this.stage,
    required this.fee,
    required this.weightKg,
    required this.distanceKm,
    required this.payableAmount,
    required this.pickup,
    required this.drop,
    required this.canSwitchToPickup,
    required this.canCancel,
    required this.rated,
    this.partner,
    this.partnerLocation,
    this.dropCode,
    this.nextStop,
    this.distanceToNextStopKm,
    this.etaMinutes,
    this.description = '',
    this.feePayer,
    this.receiverPhone = '',
    this.searchUntil,
  });

  factory DeliveryTracking.fromJson(Map<String, dynamic> j) {
    final loc = j['partnerLocation'] as Map<String, dynamic>?;
    final partner = j['partner'] as Map<String, dynamic>?;
    final isP2p = j['kind'] == 'p2p';
    return DeliveryTracking(
      jobId: j['jobId'] as String,
      isP2p: isP2p,
      status: DeliveryStatus.parse(j['status']),
      stage: (j['stage'] as String?) ?? '',
      fee: _d(j['fee']),
      weightKg: _d(j['weightKg']),
      distanceKm: _d(j['distanceKm']),
      payableAmount: _d(j['payableAmount']),
      pickup: GeoPoint.fromJson(j['pickup'] as Map<String, dynamic>),
      drop: GeoPoint.fromJson(j['drop'] as Map<String, dynamic>),
      partner: partner == null ? null : PartnerInfo.fromJson(partner),
      partnerLocation: loc == null ? null : GeoPoint.fromJson(loc),
      dropCode: j['dropCode'] as String?,
      nextStop: j['nextStop'] as String?,
      distanceToNextStopKm: j['distanceToNextStopKm'] == null ? null : _d(j['distanceToNextStopKm']),
      etaMinutes: j['etaMinutes'] == null ? null : _i(j['etaMinutes']),
      canSwitchToPickup: (j['canSwitchToPickup'] as bool?) ?? false,
      canCancel: (j['canCancel'] as bool?) ?? false,
      rated: (j['rated'] as bool?) ?? false,
      description: (j['description'] as String?) ?? '',
      feePayer: j['feePayer'] as String?,
      receiverPhone: (j['receiverPhone'] as String?) ?? '',
      searchUntil: _t(j['searchUntil']),
    );
  }

  final String jobId;
  final bool isP2p;
  final DeliveryStatus status;
  final String stage;
  final double fee;
  final double weightKg;
  final double distanceKm;

  /// Goods plus fee: what the buyer hands the partner in cash.
  final double payableAmount;
  final GeoPoint pickup;
  final GeoPoint drop;
  final PartnerInfo? partner;
  final GeoPoint? partnerLocation;

  /// The code to read out when it arrives (the receiver gives it to the partner).
  final String? dropCode;

  /// `center`/`you` for an order, `pickup`/`receiver` for a load.
  final String? nextStop;
  final double? distanceToNextStopKm;
  final int? etaMinutes;
  final bool canSwitchToPickup;
  final bool canCancel;
  final bool rated;
  final String description;

  /// `sender` or `receiver`: who hands the partner the fee, for a load.
  final String? feePayer;
  final String receiverPhone;
  final DateTime? searchUntil;

  @override
  List<Object?> get props => [jobId, status, stage, partner, partnerLocation, dropCode, etaMinutes, canSwitchToPickup, canCancel, rated];
}

// ---------------------------------------------------------------------------
// Being a delivery partner
// ---------------------------------------------------------------------------

enum PartnerStatus {
  none,
  draft,
  pending,
  approved,
  rejected,
  suspended;

  static PartnerStatus parse(Object? raw) => values.firstWhere((s) => s.name == raw, orElse: () => PartnerStatus.none);
}

class PartnerDocument extends Equatable {
  const PartnerDocument({required this.contentType, required this.sizeBytes});

  final String contentType;
  final int sizeBytes;

  @override
  List<Object?> get props => [contentType, sizeBytes];
}

/// The farmer's own delivery-partner application and switches.
class PartnerProfile extends Equatable {
  const PartnerProfile({
    required this.status,
    required this.days,
    required this.maxDistanceKm,
    required this.freeFrom,
    required this.freeUntil,
    required this.online,
    required this.missing,
    required this.canSubmit,
    this.vehicleType,
    this.vehicleNumber = '',
    this.capacityKg,
    this.phone = '',
    this.reviewCenterId,
    this.reviewCenterName,
    this.rejectionReason,
    this.licence,
    this.rc,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.deliveriesDone = 0,
  });

  factory PartnerProfile.fromJson(Map<String, dynamic> j) {
    final docs = (j['documents'] as Map<String, dynamic>?) ?? const {};
    PartnerDocument? doc(String k) {
      final d = docs[k] as Map<String, dynamic>?;
      return d == null ? null : PartnerDocument(contentType: (d['contentType'] as String?) ?? '', sizeBytes: _i(d['sizeBytes']));
    }

    return PartnerProfile(
      status: PartnerStatus.parse(j['status']),
      vehicleType: VehicleType.parse(j['vehicleType']),
      vehicleNumber: (j['vehicleNumber'] as String?) ?? '',
      capacityKg: j['capacityKg'] == null ? null : _i(j['capacityKg']),
      phone: (j['phone'] as String?) ?? '',
      days: [for (final d in (j['days'] as List? ?? const [])) _i(d)],
      maxDistanceKm: _i(j['maxDistanceKm']),
      freeFrom: (j['freeFrom'] as String?) ?? '06:00',
      freeUntil: (j['freeUntil'] as String?) ?? '20:00',
      online: (j['online'] as bool?) ?? false,
      reviewCenterId: j['reviewCenterId'] as String?,
      reviewCenterName: j['reviewCenterName'] as String?,
      rejectionReason: j['rejectionReason'] as String?,
      missing: [for (final m in (j['missing'] as List? ?? const [])) m as String],
      canSubmit: (j['canSubmit'] as bool?) ?? false,
      licence: doc('licence'),
      rc: doc('rc'),
      ratingAvg: _d(j['ratingAvg']),
      ratingCount: _i(j['ratingCount']),
      deliveriesDone: _i(j['deliveriesDone']),
    );
  }

  final PartnerStatus status;
  final VehicleType? vehicleType;
  final String vehicleNumber;
  final int? capacityKg;
  final String phone;

  /// 0 = Monday ... 6 = Sunday.
  final List<int> days;
  final int maxDistanceKm;
  final String freeFrom;
  final String freeUntil;
  final bool online;
  final String? reviewCenterId;
  final String? reviewCenterName;
  final String? rejectionReason;

  /// What is still needed before the application can be sent.
  final List<String> missing;
  final bool canSubmit;
  final PartnerDocument? licence;
  final PartnerDocument? rc;
  final double ratingAvg;
  final int ratingCount;
  final int deliveriesDone;

  bool get isApproved => status == PartnerStatus.approved;
  bool get canEdit => status == PartnerStatus.none || status == PartnerStatus.draft || status == PartnerStatus.rejected;

  @override
  List<Object?> get props => [status, vehicleType, vehicleNumber, capacityKg, phone, days, maxDistanceKm, freeFrom, freeUntil, online, reviewCenterId, rejectionReason, missing, canSubmit, licence, rc];
}

/// A job as the delivery partner sees it (an offer, or the one he is doing).
class PartnerJob extends Equatable {
  const PartnerJob({
    required this.id,
    required this.isP2p,
    required this.status,
    required this.fee,
    required this.weightKg,
    required this.distanceKm,
    required this.items,
    required this.pickup,
    required this.dropVillage,
    required this.mine,
    this.pickupPhone = '',
    this.centerName,
    this.drop,
    this.buyerName,
    this.dropPhone,
    this.dropNote,
    this.handoverCode,
    this.cashToCollect,
    this.collectFeeFrom,
    this.offerExpiresAt,
    this.tripId,
  });

  factory PartnerJob.fromJson(Map<String, dynamic> j) {
    final pickup = j['pickup'] as Map<String, dynamic>;
    final drop = j['drop'] as Map<String, dynamic>;
    final exact = drop['latitude'] != null;
    return PartnerJob(
      id: j['id'] as String,
      isP2p: j['kind'] == 'p2p',
      status: DeliveryStatus.parse(j['status']),
      fee: _d(j['fee']),
      weightKg: _d(j['weightKg']),
      distanceKm: _d(j['distanceKm']),
      items: (j['items'] as String?) ?? '',
      pickup: GeoPoint(latitude: _d(pickup['latitude']), longitude: _d(pickup['longitude']), label: (pickup['label'] as String?) ?? ''),
      pickupPhone: (pickup['phone'] as String?) ?? '',
      centerName: pickup['centerName'] as String?,
      dropVillage: (drop['village'] as String?) ?? '',
      drop: exact ? GeoPoint(latitude: _d(drop['latitude']), longitude: _d(drop['longitude']), label: (drop['label'] as String?) ?? '') : null,
      dropPhone: drop['phone'] as String?,
      dropNote: drop['note'] as String?,
      buyerName: j['buyerName'] as String?,
      mine: (j['mine'] as bool?) ?? false,
      handoverCode: j['handoverCode'] as String?,
      cashToCollect: j['cashToCollect'] == null ? null : _d(j['cashToCollect']),
      collectFeeFrom: j['collectFeeFrom'] as String?,
      offerExpiresAt: _t(j['offerExpiresAt']),
      tripId: j['tripId'] as String?,
    );
  }

  final String id;
  final bool isP2p;
  final DeliveryStatus status;
  final double fee;
  final double weightKg;
  final double distanceKm;
  final String items;
  final GeoPoint pickup;
  final String pickupPhone;
  final String? centerName;
  final String dropVillage;

  /// The exact drop, only once he has accepted.
  final GeoPoint? drop;
  final String? buyerName;
  final String? dropPhone;
  final String? dropNote;
  final bool mine;

  /// What he reads to the operator (or, for a load, to the sender) to get the goods.
  final String? handoverCode;

  /// The cash he collects: goods + fee for an order; the fee for a load.
  final double? cashToCollect;

  /// `receiver`, or for a load `sender`/`receiver`: who hands him the fee.
  final String? collectFeeFrom;
  final DateTime? offerExpiresAt;
  final String? tripId;

  @override
  List<Object?> get props => [id, status, fee, weightKg, handoverCode, offerExpiresAt, mine];
}

enum LedgerKind {
  feeEarned,
  goodsOwed,
  goodsSettled;

  static LedgerKind parse(Object? raw) => switch (raw) {
        'goods_owed' => LedgerKind.goodsOwed,
        'goods_settled' => LedgerKind.goodsSettled,
        _ => LedgerKind.feeEarned,
      };
}

class WalletEntry extends Equatable {
  const WalletEntry({required this.kind, required this.amount, required this.note, required this.createdAt});

  factory WalletEntry.fromJson(Map<String, dynamic> j) =>
      WalletEntry(kind: LedgerKind.parse(j['kind']), amount: _d(j['amount']), note: (j['note'] as String?) ?? '', createdAt: _t(j['createdAt']) ?? DateTime.now());

  final LedgerKind kind;
  final double amount;
  final String note;
  final DateTime createdAt;

  @override
  List<Object?> get props => [kind, amount, note, createdAt];
}

class OwedToCenter extends Equatable {
  const OwedToCenter({required this.centerName, required this.owed});

  final String centerName;
  final double owed;

  @override
  List<Object?> get props => [centerName, owed];
}

class Wallet extends Equatable {
  const Wallet({required this.earned, required this.owed, required this.owedByCenter, required this.entries, required this.deliveriesDone, required this.ratingAvg, required this.ratingCount, required this.cancellations});

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        earned: _d(j['earned']),
        owed: _d(j['owed']),
        owedByCenter: [for (final o in (j['owedByCenter'] as List? ?? const [])) OwedToCenter(centerName: (o as Map)['centerName'] as String, owed: _d(o['owed']))],
        entries: [for (final e in (j['entries'] as List? ?? const [])) WalletEntry.fromJson(e as Map<String, dynamic>)],
        deliveriesDone: _i(j['deliveriesDone']),
        ratingAvg: _d(j['ratingAvg']),
        ratingCount: _i(j['ratingCount']),
        cancellations: _i(j['cancellations']),
      );

  /// Fees kept so far.
  final double earned;

  /// Cash for goods he has collected and not yet handed to a center.
  final double owed;
  final List<OwedToCenter> owedByCenter;
  final List<WalletEntry> entries;
  final int deliveriesDone;
  final double ratingAvg;
  final int ratingCount;
  final int cancellations;

  @override
  List<Object?> get props => [earned, owed, owedByCenter, entries, deliveriesDone];
}

// ---------------------------------------------------------------------------
// Trips and farmer-to-farmer loads
// ---------------------------------------------------------------------------

class Trip extends Equatable {
  const Trip({required this.id, required this.from, required this.to, required this.date, required this.spareKg, required this.leftKg, required this.bookings, this.note = '', this.partnerName, this.vehicleType, this.ratingAvg, this.fromKm});

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'] as String,
        from: GeoPoint(latitude: _d(j['fromLatitude']), longitude: _d(j['fromLongitude']), label: (j['fromLabel'] as String?) ?? ''),
        to: GeoPoint(latitude: _d(j['toLatitude']), longitude: _d(j['toLongitude']), label: (j['toLabel'] as String?) ?? ''),
        date: DateTime.parse(j['date'] as String),
        spareKg: _i(j['spareKg']),
        leftKg: _i(j['leftKg']),
        bookings: _i(j['bookings']),
        note: (j['note'] as String?) ?? '',
        partnerName: j['partnerName'] as String?,
        vehicleType: VehicleType.parse(j['vehicleType']),
        ratingAvg: j['ratingAvg'] == null ? null : _d(j['ratingAvg']),
        fromKm: j['fromKm'] == null ? null : _d(j['fromKm']),
      );

  final String id;
  final GeoPoint from;
  final GeoPoint to;
  final DateTime date;
  final int spareKg;
  final int leftKg;
  final int bookings;
  final String note;

  /// Only on the public board.
  final String? partnerName;
  final VehicleType? vehicleType;
  final double? ratingAvg;
  final double? fromKm;

  @override
  List<Object?> get props => [id, from, to, date, spareKg, leftKg, bookings, note];
}

/// A load to be carried from one farm to another.
class LoadRequest extends Equatable {
  const LoadRequest({
    required this.from,
    required this.fromPhone,
    required this.to,
    required this.toPhone,
    required this.weightKg,
    required this.description,
    required this.feePayer,
    this.toVillage = '',
    this.toNote = '',
    this.tripId,
  });

  final GeoPoint from;
  final String fromPhone;
  final GeoPoint to;
  final String toPhone;
  final double weightKg;
  final String description;

  /// `sender` or `receiver`.
  final String feePayer;
  final String toVillage;
  final String toNote;
  final String? tripId;

  Map<String, dynamic> quoteJson() => {
        'from': {'latitude': from.latitude, 'longitude': from.longitude},
        'to': {'latitude': to.latitude, 'longitude': to.longitude},
        'weightKg': weightKg,
      };

  Map<String, dynamic> toJson() => {
        'from': {'latitude': from.latitude, 'longitude': from.longitude, 'label': from.label, 'phone': fromPhone},
        'to': {'latitude': to.latitude, 'longitude': to.longitude, 'label': to.label, 'phone': toPhone, 'village': toVillage, 'note': toNote},
        'weightKg': weightKg,
        'description': description,
        'feePayer': feePayer,
        'tripId': ?tripId,
      };

  @override
  List<Object?> get props => [from, to, weightKg, description, feePayer, tripId];
}

class LoadQuote extends Equatable {
  const LoadQuote({required this.available, required this.fee, required this.roadKm, required this.partnersFree, required this.note});

  factory LoadQuote.fromJson(Map<String, dynamic> j) => LoadQuote(
        available: j['available'] as bool,
        fee: j['fee'] == null ? null : _d(j['fee']),
        roadKm: _d(j['roadKm']),
        partnersFree: _i(j['partnersFree']),
        note: (j['note'] as String?) ?? '',
      );

  final bool available;
  final double? fee;
  final double roadKm;
  final int partnersFree;
  final String note;

  @override
  List<Object?> get props => [available, fee, roadKm, partnersFree, note];
}
