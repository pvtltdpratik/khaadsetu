import 'dart:typed_data';

import 'package:khaadsetu_version1/features/resale/domain/resale_models.dart';
import 'package:khaadsetu_version1/features/resale/domain/resale_repository.dart';

ResaleListing aListing(
  String id, {
  ResaleStatus status = ResaleStatus.pendingVerification,
  int units = 2,
  double askingPrice = 380,
  double? finalPrice,
  bool verified = true,
  int reserved = 0,
  int sold = 0,
  String seller = 'Sunita Jadhav',
  PayoutMode payout = PayoutMode.wallet,
  DateTime? due,
  List<ResaleSale> sales = const [],
  String rejectReason = '',
  String unit = '40 kg bag',
  int photos = 2,
}) =>
    ResaleListing(
      id: id,
      productId: 'p-vermicompost',
      productName: 'Vermicompost',
      unit: unit,
      catalogPrice: 450,
      units: units,
      condition: ResaleCondition.sealed,
      expiryDate: '2027-12-31',
      askingPrice: askingPrice,
      status: status,
      payoutMode: payout,
      centerId: 'c1',
      centerName: 'Shirur Center',
      verifiedPurchase: verified,
      photoCount: photos,
      unitsAvailable: units - reserved - sold,
      unitsReserved: reserved,
      unitsSold: sold,
      channel: 'digital',
      sellerDisplayName: seller,
      sellerContact: '9822011111',
      batchNumber: 'B-2201',
      finalPrice: finalPrice,
      handoverDue: due,
      rejectReason: rejectReason,
      suggestedPrice: 383,
      sales: sales,
      youReceivePerUnit: 338.2,
    );

const vermicompost = EligibleProduct(productId: 'p-vermicompost', name: 'Vermicompost', brand: 'HaritBhoomi', unit: '40 kg bag', catalogPrice: 450, purchased: 5, remaining: 5, listingsLeft: 3);
const usedUp = EligibleProduct(productId: 'p-neemcake', name: 'Neem Cake', brand: 'GreenGrow', unit: '25 kg bag', catalogPrice: 600, purchased: 2, remaining: 0, listingsLeft: 3);
const tooOften = EligibleProduct(productId: 'p-other', name: 'Bone Meal', brand: 'EarthWorks', unit: '10 kg bag', catalogPrice: 900, purchased: 4, remaining: 4, listingsLeft: 0);

class FakeResaleRepository implements ResaleRepository {
  FakeResaleRepository({
    this.eligibleProducts = const [vermicompost],
    List<ResaleListing>? listings,
    this.walletState = const WalletState(balance: 0, entries: []),
    this.guide = const PriceGuide(catalogPrice: 450, suggested: 383, min: 180, max: 405),
  }) : listings = listings ?? [];

  List<EligibleProduct> eligibleProducts;
  final List<ResaleListing> listings;
  WalletState walletState;
  PriceGuide guide;
  Object? createError;
  Object? inspectError;

  final created = <({NewListing listing, Uint8List front, Uint8List back})>[];
  final suggested = <({String productId, ResaleCondition condition, String? mfg})>[];
  final calls = <String>[];
  final inspections = <({String id, InspectionChecklist checklist})>[];
  final walkIns = <({String? sellerId, String? sellerName, String? sellerPhone, String productId, PayoutMode mode, InspectionChecklist checklist})>[];
  final disputesRaised = <({String orderId, String reason})>[];
  List<SellerMatch> sellers = const [];
  List<PayoutDue> cash = [];
  List<PayoutDue> upi = [];
  List<ResaleDispute> openDisputes = [];
  final resolved = <({String id, bool uphold, int? percent, String note})>[];

  @override
  Future<List<EligibleProduct>> eligible() async => eligibleProducts;

  @override
  Future<PriceGuide> suggest({required String productId, required ResaleCondition condition, String? mfgDate}) async {
    suggested.add((productId: productId, condition: condition, mfg: mfgDate));
    return guide;
  }

  @override
  Future<ResaleListing> create(NewListing listing, {required Uint8List front, required Uint8List back}) async {
    if (createError != null) throw createError!;
    created.add((listing: listing, front: front, back: back));
    final made = aListing('new-${created.length}', units: listing.units, askingPrice: listing.askingPrice, payout: listing.payoutMode);
    listings.insert(0, made);
    return made;
  }

  @override
  Future<List<ResaleListing>> mine() async => [...listings];

  @override
  Future<ResaleListing> listing(String id) async => listings.firstWhere((l) => l.id == id);

  @override
  Future<ResaleListing> withdraw(String id) async {
    calls.add('withdraw $id');
    final i = listings.indexWhere((l) => l.id == id);
    listings[i] = aListing(id, status: ResaleStatus.withdrawn);
    return listings[i];
  }

  @override
  Future<WalletState> wallet() async => walletState;

  @override
  Future<void> raiseDispute({required String orderId, required String reason}) async => disputesRaised.add((orderId: orderId, reason: reason));

  @override
  Future<List<ResaleListing>> queue({List<ResaleStatus>? statuses}) async => listings.where((l) => statuses == null || statuses.contains(l.status)).toList();

  @override
  Future<Uint8List> photo(String id, String kind) async => Uint8List.fromList(const [0x89, 0x50, 0x4e, 0x47]);

  ResaleListing _set(String id, ResaleStatus status) {
    final i = listings.indexWhere((l) => l.id == id);
    listings[i] = aListing(id, status: status, seller: listings[i].sellerDisplayName, units: listings[i].units);
    return listings[i];
  }

  @override
  Future<ResaleListing> preapprove(String id) async {
    calls.add('preapprove $id');
    return _set(id, ResaleStatus.live);
  }

  @override
  Future<ResaleListing> requestInspection(String id, {String note = ''}) async {
    calls.add('request $id "$note"');
    return _set(id, ResaleStatus.inspectionRequired);
  }

  @override
  Future<ResaleListing> reject(String id, String reason) async {
    calls.add('reject $id "$reason"');
    return _set(id, ResaleStatus.rejected);
  }

  @override
  Future<ResaleListing> inspect(String id, InspectionChecklist checklist) async {
    if (inspectError != null) throw inspectError!;
    inspections.add((id: id, checklist: checklist));
    return _set(id, ResaleStatus.listed);
  }

  @override
  Future<PriceGuide> suggestAtCounter({required String productId, required ResaleCondition condition, String? visual, String? mfgDate}) async => guide;

  @override
  Future<List<SellerMatch>> findSellers(String query) async => sellers.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();

  @override
  Future<ResaleListing> walkIn({String? sellerId, String? sellerName, String? sellerPhone, required String productId, required PayoutMode payoutMode, required InspectionChecklist checklist}) async {
    if (inspectError != null) throw inspectError!;
    walkIns.add((sellerId: sellerId, sellerName: sellerName, sellerPhone: sellerPhone, productId: productId, mode: payoutMode, checklist: checklist));
    return aListing('walk-${walkIns.length}', status: ResaleStatus.listed);
  }

  @override
  Future<List<PayoutDue>> cashDue() async => [...cash];

  @override
  Future<void> markCashPaid(String saleId) async {
    calls.add('cash-paid $saleId');
    cash.removeWhere((p) => p.saleId == saleId);
  }

  @override
  Future<List<ResaleDispute>> disputes({String? status}) async => [...openDisputes];

  @override
  Future<void> resolveDispute(String id, {required bool uphold, int? refundPercent, String note = ''}) async {
    resolved.add((id: id, uphold: uphold, percent: refundPercent, note: note));
    openDisputes.removeWhere((d) => d.disputeId == id);
  }

  @override
  Future<List<PayoutDue>> upiPayouts() async => [...upi];

  @override
  Future<void> markUpiPaid(String saleId, {String reference = ''}) async {
    calls.add('upi-paid $saleId "$reference"');
    upi.removeWhere((p) => p.saleId == saleId);
  }
}
