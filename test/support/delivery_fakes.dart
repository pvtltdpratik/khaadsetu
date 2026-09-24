import 'dart:typed_data';

import 'package:khaadsetu_version1/core/network/api_client.dart';
import 'package:khaadsetu_version1/features/delivery/domain/entities/delivery_models.dart';
import 'package:khaadsetu_version1/features/delivery/management/domain/management_models.dart';
import 'package:khaadsetu_version1/features/delivery/management/domain/management_repository.dart';
import 'package:khaadsetu_version1/features/delivery/domain/repositories/delivery_repository.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/nearby_center.dart';

const _center = GeoPoint(latitude: 18.8, longitude: 74.3, label: 'Center a, Village a');
const _farm = GeoPoint(latitude: 18.83, longitude: 74.37, label: 'Near the temple');

DeliveryQuote deliveryQuote({bool available = true, double? fee = 60, int partnersFree = 1}) => DeliveryQuote(
      centerId: 'a',
      centerName: 'Center a',
      available: available,
      fee: available ? fee : null,
      weightKg: 40,
      roadKm: 6.5,
      partnersFree: partnersFree,
      note: available
          ? (partnersFree > 0 ? 'A delivery partner nearby is free right now.' : 'No delivery partner is free right now. We will keep looking.')
          : 'Home delivery is only available within 20 km of the center. You can collect it yourself instead.',
      payment: 'You pay the goods and the delivery fee in cash to the delivery partner when it arrives.',
    );

const rameshInfo = PartnerInfo(name: 'Ramesh Patil', vehicleLabel: 'Pickup / small van', vehicleNumber: 'MH12AB1234', ratingAvg: 4.6, ratingCount: 12, deliveriesDone: 30, phone: '9876500000');

DeliveryTracking aTracking({
  String jobId = 'job-1',
  DeliveryStatus status = DeliveryStatus.open,
  bool p2p = false,
  bool rated = false,
  PartnerInfo? partner,
  String? dropCode,
  int? etaMinutes,
  bool canSwitch = true,
  bool canCancel = false,
  String feePayer = 'sender',
}) {
  final withPartner = status == DeliveryStatus.assigned || status == DeliveryStatus.inTransit || status == DeliveryStatus.delivered;
  final live = status == DeliveryStatus.assigned || status == DeliveryStatus.inTransit;
  return DeliveryTracking(
    jobId: jobId,
    isP2p: p2p,
    status: status,
    stage: switch (status) {
      DeliveryStatus.open => 'Finding a delivery partner',
      DeliveryStatus.assigned => p2p ? 'Your delivery partner is coming to collect it' : 'Your delivery partner is on the way to the center',
      DeliveryStatus.inTransit => p2p ? 'On its way to the receiver' : 'Your order is on its way to you',
      DeliveryStatus.delivered => 'Delivered',
      DeliveryStatus.cancelled => 'Delivery cancelled',
      DeliveryStatus.fallback => 'No delivery partner was free: collect it at the center',
    },
    fee: 60,
    weightKg: 40,
    distanceKm: 6.5,
    payableAmount: p2p ? 60 : 1260,
    pickup: _center,
    drop: _farm,
    partner: withPartner ? (partner ?? rameshInfo) : null,
    partnerLocation: live && etaMinutes != null ? const GeoPoint(latitude: 18.81, longitude: 74.31) : null,
    dropCode: live ? (dropCode ?? '7391') : null,
    nextStop: etaMinutes == null ? null : (status == DeliveryStatus.assigned ? (p2p ? 'pickup' : 'center') : (p2p ? 'receiver' : 'you')),
    distanceToNextStopKm: etaMinutes == null ? null : 4.2,
    etaMinutes: etaMinutes,
    canSwitchToPickup: !p2p && canSwitch && (status == DeliveryStatus.open || status == DeliveryStatus.assigned),
    canCancel: canCancel,
    rated: rated,
    description: p2p ? 'Two sacks of seed potatoes' : '',
    feePayer: p2p ? feePayer : null,
    receiverPhone: p2p ? '9822054321' : '',
  );
}

PartnerProfile partnerProfile({
  PartnerStatus status = PartnerStatus.none,
  VehicleType? vehicle,
  String number = '',
  int? capacity,
  String phone = '',
  bool online = false,
  bool licence = false,
  bool rc = false,
  List<String>? missing,
  bool? canSubmit,
  String? rejection,
  String? centerId,
}) {
  final gaps = missing ??
      [
        if (vehicle == null) 'vehicleType',
        if (number.isEmpty) 'vehicleNumber',
        if (capacity == null) 'capacityKg',
        if (phone.isEmpty) 'phone',
        if (!licence) 'licence',
        if (!rc) 'rc',
      ];
  return PartnerProfile(
    status: status,
    vehicleType: vehicle,
    vehicleNumber: number,
    capacityKg: capacity,
    phone: phone,
    days: const [0, 1, 2, 3, 4, 5, 6],
    maxDistanceKm: 10,
    freeFrom: '06:00',
    freeUntil: '20:00',
    online: online,
    reviewCenterId: centerId,
    reviewCenterName: centerId == null ? null : 'Center $centerId',
    rejectionReason: rejection,
    missing: gaps,
    canSubmit: canSubmit ?? gaps.isEmpty,
    licence: licence ? const PartnerDocument(contentType: 'image/jpeg', sizeBytes: 1000) : null,
    rc: rc ? const PartnerDocument(contentType: 'image/jpeg', sizeBytes: 1000) : null,
    ratingAvg: 4.5,
    ratingCount: 4,
    deliveriesDone: 9,
  );
}

PartnerJob partnerJob(
  String id, {
  DeliveryStatus status = DeliveryStatus.open,
  bool mine = false,
  bool p2p = false,
  double fee = 60,
  double weight = 40,
  String? handover,
  String items = '1 x Vermicompost',
}) {
  final own = mine && (status == DeliveryStatus.assigned || status == DeliveryStatus.inTransit);
  return PartnerJob(
    id: id,
    isP2p: p2p,
    status: status,
    fee: fee,
    weightKg: weight,
    distanceKm: 6.5,
    items: items,
    pickup: _center,
    pickupPhone: own && p2p ? '9822012345' : '',
    centerName: p2p ? null : 'Center a',
    dropVillage: 'Shirur',
    drop: own ? _farm : null,
    buyerName: own ? 'Suresh' : null,
    dropPhone: own ? '9822054321' : null,
    dropNote: own ? 'Blue gate' : null,
    mine: mine,
    handoverCode: own && status == DeliveryStatus.assigned ? (handover ?? '4821') : null,
    cashToCollect: own ? (p2p ? fee : 1260) : null,
    collectFeeFrom: own ? (p2p ? 'sender' : 'receiver') : null,
    offerExpiresAt: status == DeliveryStatus.open && !mine ? DateTime.now().add(const Duration(minutes: 4)) : null,
  );
}

Wallet aWallet({double earned = 240, double owed = 1200, List<WalletEntry>? entries}) => Wallet(
      earned: earned,
      owed: owed,
      owedByCenter: owed > 0 ? [OwedToCenter(centerName: 'Center a', owed: owed)] : const [],
      entries: entries ?? [WalletEntry(kind: LedgerKind.feeEarned, amount: 60, note: 'Delivery fee', createdAt: DateTime(2026, 9, 24, 10))],
      deliveriesDone: 9,
      ratingAvg: 4.5,
      ratingCount: 4,
      cancellations: 0,
    );

Trip trip(String id, {int spare = 60, int left = 60, DateTime? date, String? partner}) => Trip(
      id: id,
      from: const GeoPoint(latitude: 18.81, longitude: 74.3, label: 'Shirur'),
      to: const GeoPoint(latitude: 18.86, longitude: 74.3, label: 'Talegaon'),
      date: date ?? DateTime(2026, 9, 25),
      spareKg: spare,
      leftKg: left,
      bookings: spare - left > 0 ? 1 : 0,
      note: 'Going to the market',
      partnerName: partner,
      vehicleType: partner == null ? null : VehicleType.pickup,
      ratingAvg: partner == null ? null : 4.4,
      fromKm: partner == null ? null : 1.2,
    );

class FakeDeliveryRepository implements DeliveryRepository {
  FakeDeliveryRepository();

  Object? error; // thrown by the next mutating call
  final calls = <String>[];

  T _guard<T>(String call, T Function() run) {
    calls.add(call);
    if (error != null) {
      final e = error!;
      error = null;
      throw e;
    }
    return run();
  }

  // ---- buying ----
  DeliveryQuote quoteAnswer = deliveryQuote();
  final quotes = <({List<CartLine> items, String? centerId})>[];
  DeliveryTracking trackingAnswer = aTracking();

  @override
  Future<DeliveryQuote> quote({required List<CartLine> items, required FarmerLocation location, String? centerId}) async {
    quotes.add((items: items, centerId: centerId));
    return quoteAnswer;
  }

  @override
  Future<DeliveryTracking> tracking(String orderId) async => trackingAnswer;

  @override
  Future<void> switchToPickup(String orderId) async => _guard('switchToPickup:$orderId', () {});

  final orderRatings = <({String orderId, int stars, String comment})>[];

  @override
  Future<void> rateDelivery({required String orderId, required int stars, String comment = ''}) async =>
      _guard('rateDelivery', () => orderRatings.add((orderId: orderId, stars: stars, comment: comment)));

  // ---- partner ----
  PartnerProfile profile = partnerProfile();
  final saved = <Map<String, dynamic>>[];
  final uploads = <String>[];

  @override
  Future<PartnerProfile> partner() async => profile;

  @override
  Future<PartnerProfile> savePartner(Map<String, dynamic> changes) async => _guard('savePartner', () {
        saved.add(changes);
        profile = partnerProfile(
          status: profile.status == PartnerStatus.none ? PartnerStatus.draft : profile.status,
          vehicle: changes['vehicleType'] == null ? profile.vehicleType : VehicleType.parse(changes['vehicleType']),
          number: (changes['vehicleNumber'] as String?) ?? profile.vehicleNumber,
          capacity: (changes['capacityKg'] as int?) ?? profile.capacityKg,
          phone: (changes['phone'] as String?) ?? profile.phone,
          licence: profile.licence != null,
          rc: profile.rc != null,
          online: profile.online,
          centerId: (changes['reviewCenterId'] as String?) ?? profile.reviewCenterId,
        );
        return profile;
      });

  @override
  Future<PartnerProfile> uploadDocument({required String kind, required Uint8List bytes, required String filename}) async => _guard('upload:$kind', () {
        uploads.add(kind);
        profile = partnerProfile(
          status: profile.status == PartnerStatus.none ? PartnerStatus.draft : profile.status,
          vehicle: profile.vehicleType,
          number: profile.vehicleNumber,
          capacity: profile.capacityKg,
          phone: profile.phone,
          licence: kind == 'licence' || profile.licence != null,
          rc: kind == 'rc' || profile.rc != null,
          centerId: profile.reviewCenterId,
        );
        return profile;
      });

  @override
  Future<PartnerProfile> submitApplication() async => _guard('submit', () {
        profile = partnerProfile(
            status: PartnerStatus.pending, vehicle: profile.vehicleType, number: profile.vehicleNumber, capacity: profile.capacityKg, phone: profile.phone, licence: true, rc: true, centerId: profile.reviewCenterId);
        return profile;
      });

  @override
  Future<PartnerProfile> setOnline(bool online) async => _guard('online:$online', () {
        profile = partnerProfile(
            status: PartnerStatus.approved, vehicle: profile.vehicleType, number: profile.vehicleNumber, capacity: profile.capacityKg, phone: profile.phone, licence: true, rc: true, online: online, centerId: profile.reviewCenterId);
        return profile;
      });

  @override
  Future<void> withdraw() async => _guard('withdraw', () => profile = partnerProfile());

  final locations = <({double latitude, double longitude})>[];

  @override
  Future<void> shareLocation({required double latitude, required double longitude}) async => locations.add((latitude: latitude, longitude: longitude));

  List<PartnerJob> offerList = [];
  List<PartnerJob> activeList = [];

  @override
  Future<List<PartnerJob>> offers() async => offerList;

  @override
  Future<List<PartnerJob>> activeJobs() async => activeList;

  @override
  Future<PartnerJob> accept(String jobId) async => _guard('accept:$jobId', () {
        final job = partnerJob(jobId, status: DeliveryStatus.assigned, mine: true);
        offerList = offerList.where((o) => o.id != jobId).toList();
        activeList = [...activeList, job];
        return job;
      });

  @override
  Future<void> decline(String jobId) async => _guard('decline:$jobId', () => offerList = offerList.where((o) => o.id != jobId).toList());

  final delivered = <({String jobId, String otp})>[];

  @override
  Future<PartnerJob> deliver({required String jobId, required String otp}) async => _guard('deliver:$jobId', () {
        delivered.add((jobId: jobId, otp: otp));
        activeList = activeList.where((a) => a.id != jobId).toList();
        return partnerJob(jobId, status: DeliveryStatus.delivered, mine: true);
      });

  final buyerRatings = <({String jobId, int stars})>[];

  @override
  Future<void> rateBuyer({required String jobId, required int stars, String comment = ''}) async =>
      _guard('rateBuyer', () => buyerRatings.add((jobId: jobId, stars: stars)));

  Wallet walletAnswer = aWallet();

  @override
  Future<Wallet> wallet() async => walletAnswer;

  // ---- trips ----
  List<Trip> trips = [];
  List<Trip> board = [];
  final posted = <({GeoPoint from, GeoPoint to, DateTime date, int spareKg, String note})>[];

  @override
  Future<List<Trip>> myTrips() async => trips;

  @override
  Future<Trip> postTrip({required GeoPoint from, required GeoPoint to, required DateTime date, required int spareKg, String note = ''}) async =>
      _guard('postTrip', () {
        posted.add((from: from, to: to, date: date, spareKg: spareKg, note: note));
        final t = Trip(id: 'trip-${posted.length}', from: from, to: to, date: date, spareKg: spareKg, leftKg: spareKg, bookings: 0, note: note);
        trips = [...trips, t];
        return t;
      });

  @override
  Future<void> cancelTrip(String id) async => _guard('cancelTrip:$id', () => trips = trips.where((t) => t.id != id).toList());

  @override
  Future<List<Trip>> tripBoard({required FarmerLocation location, double weightKg = 0}) async => board;

  // ---- loads ----
  LoadQuote loadQuoteAnswer = const LoadQuote(available: true, fee: 45, roadKm: 5.2, partnersFree: 1, note: 'A delivery partner nearby is free right now.');
  List<DeliveryTracking> loads = [];
  final sent = <LoadRequest>[];

  @override
  Future<LoadQuote> loadQuote(LoadRequest request) async => loadQuoteAnswer;

  @override
  Future<DeliveryTracking> sendLoad(LoadRequest request) async => _guard('sendLoad', () {
        sent.add(request);
        final t = aTracking(jobId: 'load-${sent.length}', p2p: true, canCancel: true);
        loads = [t, ...loads];
        return t;
      });

  @override
  Future<List<DeliveryTracking>> myLoads() async => loads;

  @override
  Future<DeliveryTracking> load(String jobId) async => loads.firstWhere((l) => l.jobId == jobId, orElse: () => throw ApiException('Request not found', statusCode: 404));

  @override
  Future<DeliveryTracking> cancelLoad(String jobId) async => _guard('cancelLoad:$jobId', () => aTracking(jobId: jobId, status: DeliveryStatus.cancelled, p2p: true));

  final handedOver = <({String jobId, String otp})>[];

  @override
  Future<DeliveryTracking> handOverLoad({required String jobId, required String otp}) async => _guard('handOver:$jobId', () {
        handedOver.add((jobId: jobId, otp: otp));
        final t = aTracking(jobId: jobId, status: DeliveryStatus.inTransit, p2p: true);
        loads = [for (final l in loads) if (l.jobId == jobId) t else l];
        return t;
      });

  @override
  Future<void> rateLoad({required String jobId, required int stars, String comment = ''}) async => _guard('rateLoad', () {});
}

/// An [ApiException] worded like the server's, for wrong-code tests.
ApiException wrongCodeError(int left) => ApiException('That code is wrong. $left ${left == 1 ? 'try' : 'tries'} left.', statusCode: 400);

// ---------------------------------------------------------------------------
// The operator's and admin's side
// ---------------------------------------------------------------------------

ManagedDelivery managedDelivery(
  String id, {
  DeliveryStatus status = DeliveryStatus.open,
  bool needsDriver = false,
  String? partner,
  String? center,
  int offers = 0,
  bool p2p = false,
}) =>
    ManagedDelivery(
      id: id,
      isP2p: p2p,
      status: status,
      fee: 60,
      weightKg: 40,
      distanceKm: 6.5,
      goodsAmount: p2p ? 0 : 1200,
      cashToCollect: p2p ? 60 : 1260,
      dropVillage: 'Shirur',
      buyerName: 'Suresh',
      needsDriver: needsDriver,
      offersPending: offers,
      centerName: center,
      partnerId: partner == null ? null : 'p-$partner',
      partnerName: partner,
      partnerPhone: partner == null ? null : '9876500000',
      vehicleType: partner == null ? null : VehicleType.pickup,
      vehicleNumber: partner == null ? null : 'MH12AB1234',
      ratingAvg: partner == null ? null : 4.6,
    );

PartnerApplication application(
  String id, {
  PartnerStatus status = PartnerStatus.pending,
  String name = 'Ramesh Patil',
  bool licence = true,
  bool rc = true,
  String? rejection,
  List<PartnerEvent> events = const [],
}) =>
    PartnerApplication(
      userId: id,
      name: name,
      village: 'Shirur',
      status: status,
      vehicleType: VehicleType.pickup,
      vehicleNumber: 'MH12AB1234',
      capacityKg: 600,
      phone: '9876500000',
      maxDistanceKm: 10,
      days: const [0, 1, 2, 3, 4, 5],
      freeFrom: '06:00',
      freeUntil: '20:00',
      online: false,
      reviewCenterName: 'Center a',
      rejectionReason: rejection,
      ratingAvg: 0,
      ratingCount: 0,
      deliveriesDone: 0,
      submittedAt: DateTime(2026, 9, 24),
      licence: licence ? const PartnerDocument(contentType: 'image/png', sizeBytes: 100) : null,
      rc: rc ? const PartnerDocument(contentType: 'image/png', sizeBytes: 100) : null,
      events: events,
    );

/// The smallest valid PNG, standing in for a photographed licence.
final tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, 0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
  0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class FakeManagementRepository implements DeliveryManagementRepository {
  FakeManagementRepository({this.scope = ManagementScope.operator});

  final ManagementScope scope;
  Object? error;
  final calls = <String>[];

  T _guard<T>(String call, T Function() run) {
    calls.add(call);
    if (error != null) {
      final e = error!;
      error = null;
      throw e;
    }
    return run();
  }

  List<ManagedDelivery> deliveryList = [];
  final deliveryFilters = <DeliveryStatus?>[];

  @override
  Future<List<ManagedDelivery>> deliveries({DeliveryStatus? status}) async {
    deliveryFilters.add(status);
    return deliveryList.where((d) => status == null || d.status == status).toList();
  }

  List<PartnerApplication> applications = [];
  final partnerFilters = <PartnerStatus?>[];

  @override
  Future<List<PartnerApplication>> partners({PartnerStatus? status, String? query}) async {
    partnerFilters.add(status);
    return applications.where((a) => (status == null || a.status == status) && (query == null || a.name.toLowerCase().contains(query.toLowerCase()))).toList();
  }

  @override
  Future<PartnerApplication> partner(String userId) async => applications.firstWhere((a) => a.userId == userId);

  @override
  Future<Uint8List> document(String userId, String kind) async => tinyPng;

  final reviews = <({String userId, ReviewAction action, String? note})>[];

  @override
  Future<PartnerApplication> review(String userId, ReviewAction action, {String? note}) async => _guard('review:${action.name}', () {
        reviews.add((userId: userId, action: action, note: note));
        final now = switch (action) {
          ReviewAction.approve || ReviewAction.reactivate => PartnerStatus.approved,
          ReviewAction.reject => PartnerStatus.rejected,
          ReviewAction.suspend => PartnerStatus.suspended,
        };
        final old = applications.firstWhere((a) => a.userId == userId);
        final updated = application(userId, status: now, name: old.name, rejection: action == ReviewAction.reject ? note : null);
        applications = [for (final a in applications) if (a.userId == userId) updated else a];
        return updated;
      });

  List<AssignCandidate> candidateList = [];

  @override
  Future<List<AssignCandidate>> candidates(String jobId) async => candidateList;

  final assigned = <({String jobId, String partnerId})>[];

  @override
  Future<ManagedDelivery> assign(String jobId, String partnerId) async => _guard('assign', () {
        assigned.add((jobId: jobId, partnerId: partnerId));
        final updated = managedDelivery(jobId, status: DeliveryStatus.assigned, partner: 'Ganesh');
        deliveryList = [for (final d in deliveryList) if (d.id == jobId) updated else d];
        return updated;
      });

  final handovers = <({String jobId, String otp})>[];

  @override
  Future<ManagedDelivery> handover(String jobId, String otp) async => _guard('handover', () {
        handovers.add((jobId: jobId, otp: otp));
        final updated = managedDelivery(jobId, status: DeliveryStatus.inTransit, partner: 'Ganesh');
        deliveryList = [for (final d in deliveryList) if (d.id == jobId) updated else d];
        return updated;
      });

  List<CashOwed> cash = [];
  final settled = <({String partnerId, double amount})>[];

  @override
  Future<List<CashOwed>> cashOwed() async => cash;

  @override
  Future<List<CashOwed>> settleCash(String partnerId, double amount, {String note = ''}) async => _guard('settle', () {
        settled.add((partnerId: partnerId, amount: amount));
        cash = [
          for (final c in cash)
            if (c.partnerId == partnerId)
              if (c.owed - amount > 0) CashOwed(partnerId: c.partnerId, name: c.name, phone: c.phone, owed: c.owed - amount) else ...const <CashOwed>[]
            else
              c,
        ];
        return cash;
      });
}
