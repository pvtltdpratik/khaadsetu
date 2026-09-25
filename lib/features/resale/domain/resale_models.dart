import 'package:equatable/equatable.dart';

/// Condition the seller reports for the bag.
enum ResaleCondition {
  sealed('sealed', 'Sealed, unopened'),
  opened('opened', 'Opened'),
  partiallyUsed('partially_used', 'Partially used');

  const ResaleCondition(this.api, this.label);

  final String api;
  final String label;

  static ResaleCondition parse(Object? raw) => values.firstWhere((c) => c.api == raw, orElse: () => opened);
}

/// How the seller wants to be paid when it sells.
enum PayoutMode {
  wallet('wallet', 'Wallet (instant, keep 100%)', 'Instant. Use it on your next purchase.'),
  upi('upi', 'UPI / bank (24 to 48 hours)', 'Sent to your UPI within 24 to 48 hours.'),
  cash('cash', 'Cash at the center (keep 97%)', 'Collect the cash at your village center.');

  const PayoutMode(this.api, this.label, this.hint);

  final String api;
  final String label;
  final String hint;

  static PayoutMode parse(Object? raw) => values.firstWhere((m) => m.api == raw, orElse: () => wallet);
}

enum ResaleStatus {
  draft('draft', 'Draft'),
  pendingVerification('pending_verification', 'Pending verification'),
  inspectionRequired('inspection_required', 'Bring it to the center'),
  live('live', 'Live'),
  awaitingHandover('awaiting_handover', 'Buyer found: bring it in'),
  listed('listed', 'Listed at the center'),
  soldOut('sold_out', 'Sold'),
  rejected('rejected', 'Not accepted'),
  withdrawn('withdrawn', 'Withdrawn');

  const ResaleStatus(this.api, this.label);

  final String api;
  final String label;

  static ResaleStatus parse(Object? raw) => values.firstWhere((s) => s.api == raw, orElse: () => draft);

  /// Still moving toward, or on, the shelf.
  bool get isOpen => this == pendingVerification || this == inspectionRequired || this == live || this == awaitingHandover || this == listed;
}

/// A product the farmer bought and collected, and how much of it they may still resell.
class EligibleProduct extends Equatable {
  const EligibleProduct({
    required this.productId,
    required this.name,
    required this.brand,
    required this.unit,
    required this.catalogPrice,
    required this.purchased,
    required this.remaining,
    required this.listingsLeft,
  });

  factory EligibleProduct.fromJson(Map<String, dynamic> json) => EligibleProduct(
        productId: json['productId'] as String,
        name: json['name'] as String,
        brand: (json['brand'] as String?) ?? '',
        unit: (json['unit'] as String?) ?? '',
        catalogPrice: (json['catalogPrice'] as num).toDouble(),
        purchased: (json['purchased'] as num).toInt(),
        remaining: (json['remaining'] as num).toInt(),
        listingsLeft: (json['listingsLeft'] as num).toInt(),
      );

  final String productId;
  final String name;
  final String brand;
  final String unit;
  final double catalogPrice;
  final int purchased;
  final int remaining;

  /// How many more times this product may be listed this season (3 in all).
  final int listingsLeft;

  bool get canList => remaining > 0 && listingsLeft > 0;

  @override
  List<Object?> get props => [productId, name, brand, unit, catalogPrice, purchased, remaining, listingsLeft];
}

/// The suggested price for one unit, and the range the seller may choose from.
class PriceGuide extends Equatable {
  const PriceGuide({required this.catalogPrice, required this.suggested, required this.min, required this.max});

  factory PriceGuide.fromJson(Map<String, dynamic> json) => PriceGuide(
        catalogPrice: (json['catalogPrice'] as num).toDouble(),
        suggested: (json['suggested'] as num).toDouble(),
        min: (json['min'] as num).toDouble(),
        max: (json['max'] as num).toDouble(),
      );

  final double catalogPrice;
  final double suggested;
  final double min;
  final double max;

  @override
  List<Object?> get props => [catalogPrice, suggested, min, max];
}

/// What the seller is asking, and the details of the bag, for a new listing.
class NewListing extends Equatable {
  const NewListing({
    required this.productId,
    required this.units,
    required this.condition,
    required this.expiryDate,
    required this.askingPrice,
    required this.centerId,
    required this.payoutMode,
    this.mfgDate,
    this.batchNumber = '',
    this.upiId = '',
  });

  final String productId;
  final int units;
  final ResaleCondition condition;
  final String? mfgDate;
  final String expiryDate;
  final String batchNumber;
  final double askingPrice;
  final String centerId;
  final PayoutMode payoutMode;
  final String upiId;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'units': units,
        'condition': condition.api,
        if (mfgDate != null) 'mfgDate': mfgDate,
        'expiryDate': expiryDate,
        if (batchNumber.isNotEmpty) 'batchNumber': batchNumber,
        'askingPrice': askingPrice,
        'centerId': centerId,
        'payoutMode': payoutMode.api,
        if (upiId.isNotEmpty) 'upiId': upiId,
      };

  @override
  List<Object?> get props => [productId, units, condition, mfgDate, expiryDate, batchNumber, askingPrice, centerId, payoutMode, upiId];
}

class ResaleSale extends Equatable {
  const ResaleSale({required this.saleId, required this.units, required this.gross, required this.sellerNet, required this.verified, required this.payoutStatus, required this.createdAt});

  factory ResaleSale.fromJson(Map<String, dynamic> json) => ResaleSale(
        saleId: json['saleId'] as String,
        units: (json['units'] as num).toInt(),
        gross: (json['gross'] as num).toDouble(),
        sellerNet: (json['sellerNet'] as num).toDouble(),
        verified: json['verified'] as bool? ?? false,
        payoutStatus: json['payoutStatus'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );

  final String saleId;
  final int units;
  final double gross;
  final double sellerNet;
  final bool verified;

  /// 'paid', 'pending' (UPI on its way), 'cash_due' or 'cash_paid'.
  final String payoutStatus;
  final DateTime createdAt;

  String get payoutLabel => switch (payoutStatus) {
        'paid' => 'Paid',
        'pending' => 'On its way (UPI)',
        'cash_due' => 'Collect cash at the center',
        'cash_paid' => 'Cash received',
        _ => payoutStatus,
      };

  @override
  List<Object?> get props => [saleId, units, gross, sellerNet, verified, payoutStatus, createdAt];
}

class ResaleListing extends Equatable {
  const ResaleListing({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.catalogPrice,
    required this.units,
    required this.condition,
    required this.expiryDate,
    required this.askingPrice,
    required this.status,
    required this.payoutMode,
    required this.centerId,
    required this.centerName,
    required this.verifiedPurchase,
    required this.photoCount,
    required this.unitsAvailable,
    required this.unitsReserved,
    required this.unitsSold,
    required this.channel,
    this.sellerName = '',
    this.sellerPhone = '',
    this.sellerDisplayName = '',
    this.sellerContact = '',
    this.mfgDate,
    this.batchNumber = '',
    this.finalPrice,
    this.rejectReason = '',
    this.handoverDue,
    this.createdAt,
    this.suggestedPrice = 0,
    this.sales = const [],
    this.youReceivePerUnit,
  });

  factory ResaleListing.fromJson(Map<String, dynamic> json) {
    final receive = json['youReceive'] as Map<String, dynamic>?;
    return ResaleListing(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      unit: (json['unit'] as String?) ?? '',
      catalogPrice: (json['catalogPrice'] as num).toDouble(),
      units: (json['units'] as num).toInt(),
      condition: ResaleCondition.parse(json['condition']),
      expiryDate: json['expiryDate'] as String,
      askingPrice: (json['askingPrice'] as num).toDouble(),
      status: ResaleStatus.parse(json['status']),
      payoutMode: PayoutMode.parse(json['payoutMode']),
      centerId: json['centerId'] as String,
      centerName: (json['centerName'] as String?) ?? '',
      verifiedPurchase: json['verifiedPurchase'] as bool? ?? false,
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      unitsAvailable: (json['unitsAvailable'] as num?)?.toInt() ?? 0,
      unitsReserved: (json['unitsReserved'] as num?)?.toInt() ?? 0,
      unitsSold: (json['unitsSold'] as num?)?.toInt() ?? 0,
      channel: (json['channel'] as String?) ?? 'digital',
      sellerName: (json['sellerName'] as String?) ?? '',
      sellerPhone: (json['sellerPhone'] as String?) ?? '',
      sellerDisplayName: (json['sellerDisplayName'] as String?) ?? '',
      sellerContact: (json['sellerContact'] as String?) ?? '',
      mfgDate: json['mfgDate'] as String?,
      batchNumber: (json['batchNumber'] as String?) ?? '',
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      rejectReason: (json['rejectReason'] as String?) ?? '',
      handoverDue: json['handoverDue'] == null ? null : DateTime.parse(json['handoverDue'] as String).toLocal(),
      createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String).toLocal(),
      suggestedPrice: (json['suggestedPrice'] as num?)?.toDouble() ?? 0,
      sales: ((json['sales'] as List?) ?? const []).map((e) => ResaleSale.fromJson(e as Map<String, dynamic>)).toList(),
      youReceivePerUnit: (receive?['perUnit'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String productId;
  final String productName;
  final String unit;
  final double catalogPrice;
  final int units;
  final ResaleCondition condition;
  final String expiryDate;
  final double askingPrice;
  final ResaleStatus status;
  final PayoutMode payoutMode;
  final String centerId;
  final String centerName;
  final bool verifiedPurchase;
  final int photoCount;
  final int unitsAvailable;
  final int unitsReserved;
  final int unitsSold;

  /// 'digital' (listed from the app) or 'walk_in' (taken in at the counter).
  final String channel;
  final String sellerName;
  final String sellerPhone;

  /// Who to call them: the name they gave, or their profile name.
  final String sellerDisplayName;
  final String sellerContact;
  final String? mfgDate;
  final String batchNumber;
  final double? finalPrice;
  final String rejectReason;

  /// When a seller who has a buyer must have brought the goods in.
  final DateTime? handoverDue;
  final DateTime? createdAt;
  final double suggestedPrice;
  final List<ResaleSale> sales;
  final double? youReceivePerUnit;

  double get price => finalPrice ?? askingPrice;
  double get earned => sales.fold(0.0, (sum, s) => sum + s.sellerNet);

  @override
  List<Object?> get props => [id, status, units, askingPrice, finalPrice, unitsAvailable, unitsReserved, unitsSold, photoCount, sales, handoverDue, rejectReason, batchNumber, sellerDisplayName];
}

class WalletEntry extends Equatable {
  const WalletEntry({required this.amount, required this.kind, required this.note, required this.createdAt});

  factory WalletEntry.fromJson(Map<String, dynamic> json) => WalletEntry(
        amount: (json['amount'] as num).toDouble(),
        kind: json['kind'] as String,
        note: (json['note'] as String?) ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );

  final double amount;
  final String kind;
  final String note;
  final DateTime createdAt;

  String get title => switch (kind) {
        'resale_earning' => 'Fertilizer sold',
        'order_payment' => 'Paid for an order',
        'order_refund' => 'Order refund',
        'dispute_refund' => 'Complaint refund',
        'dispute_debit' => 'Sale refunded to buyer',
        _ => 'Adjustment',
      };

  @override
  List<Object?> get props => [amount, kind, note, createdAt];
}

class WalletState extends Equatable {
  const WalletState({required this.balance, required this.entries});

  factory WalletState.fromJson(Map<String, dynamic> json) => WalletState(
        balance: (json['balance'] as num).toDouble(),
        entries: ((json['entries'] as List?) ?? const []).map((e) => WalletEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );

  final double balance;
  final List<WalletEntry> entries;

  @override
  List<Object?> get props => [balance, entries];
}

/// What the operator records with the goods in front of them.
class InspectionChecklist extends Equatable {
  const InspectionChecklist({
    required this.productMatches,
    required this.seal,
    required this.units,
    required this.expiryDate,
    required this.batchNumber,
    required this.visual,
    this.mfgDate,
    this.purchaseProofSeen = false,
    this.unitPrice,
    this.upiId = '',
  });

  final bool productMatches;

  /// 'sealed', 'opened_resealed', 'loose' or 'damaged_packaging'.
  final String seal;
  final int units;
  final String? mfgDate;
  final String expiryDate;
  final String batchNumber;

  /// 'free_flowing', 'clumped', 'wet' (solids) or 'clear', 'cloudy', 'separated' (liquids).
  final String visual;
  final bool purchaseProofSeen;
  final double? unitPrice;
  final String upiId;

  Map<String, dynamic> toJson() => {
        'productMatches': productMatches,
        'seal': seal,
        'units': units,
        if (mfgDate != null) 'mfgDate': mfgDate,
        'expiryDate': expiryDate,
        'batchNumber': batchNumber,
        'visual': visual,
        'purchaseProofSeen': purchaseProofSeen,
        if (unitPrice != null) 'unitPrice': unitPrice,
        if (upiId.isNotEmpty) 'upiId': upiId,
      };

  @override
  List<Object?> get props => [productMatches, seal, units, mfgDate, expiryDate, batchNumber, visual, purchaseProofSeen, unitPrice, upiId];
}

class SellerMatch extends Equatable {
  const SellerMatch({required this.sellerId, required this.name, required this.village, required this.phone});

  factory SellerMatch.fromJson(Map<String, dynamic> json) =>
      SellerMatch(sellerId: json['sellerId'] as String, name: json['name'] as String, village: (json['village'] as String?) ?? '', phone: (json['phone'] as String?) ?? '');

  final String sellerId;
  final String name;
  final String village;
  final String phone;

  @override
  List<Object?> get props => [sellerId, name, village, phone];
}

/// A payout still to be made: cash at the center, or a UPI transfer.
class PayoutDue extends Equatable {
  const PayoutDue({required this.saleId, required this.amount, required this.sellerName, required this.productName, this.upiId = '', this.sellerPhone = ''});

  factory PayoutDue.fromJson(Map<String, dynamic> json) => PayoutDue(
        saleId: json['saleId'] as String,
        amount: (json['amount'] as num).toDouble(),
        sellerName: (json['sellerName'] as String?) ?? 'Farmer',
        productName: (json['productName'] as String?) ?? '',
        upiId: (json['upiId'] as String?) ?? '',
        sellerPhone: (json['sellerPhone'] as String?) ?? '',
      );

  final String saleId;
  final double amount;
  final String sellerName;
  final String productName;
  final String upiId;
  final String sellerPhone;

  @override
  List<Object?> get props => [saleId, amount, sellerName, productName, upiId, sellerPhone];
}

/// A buyer's complaint about surplus goods, for an admin to settle.
class ResaleDispute extends Equatable {
  const ResaleDispute({required this.disputeId, required this.reason, required this.status, required this.productName, required this.centerName, required this.gross, this.batchNumber = '', this.centerQuality = 100, this.refundAmount});

  factory ResaleDispute.fromJson(Map<String, dynamic> json) => ResaleDispute(
        disputeId: json['disputeId'] as String,
        reason: json['reason'] as String,
        status: json['status'] as String,
        productName: (json['productName'] as String?) ?? '',
        centerName: (json['centerName'] as String?) ?? '',
        gross: (json['gross'] as num).toDouble(),
        batchNumber: ((json['inspection'] as Map<String, dynamic>?)?['batchNumber'] as String?) ?? '',
        centerQuality: (json['centerQuality'] as num?)?.toInt() ?? 100,
        refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      );

  final String disputeId;
  final String reason;

  /// 'open', 'upheld' or 'rejected'.
  final String status;
  final String productName;
  final String centerName;
  final double gross;
  final String batchNumber;
  final int centerQuality;
  final double? refundAmount;

  @override
  List<Object?> get props => [disputeId, reason, status, productName, centerName, gross, batchNumber, centerQuality, refundAmount];
}
