import 'package:equatable/equatable.dart';

/// Why a batch is being sold cheaper. The [api] value is what the server stores.
enum SurplusCondition {
  nearExpiry('near_expiry', 'Near expiry'),
  opened('opened', 'Opened pack'),
  returned('returned', 'Returned'),
  damagedPackaging('damaged_packaging', 'Damaged packaging'),
  other('other', 'Other'),

  /// Only farmers' resale lots have these two; a center does not choose them.
  sealed('sealed', 'Sealed, unopened'),
  partiallyUsed('partially_used', 'Partially used');

  const SurplusCondition(this.api, this.label);

  final String api;
  final String label;

  static SurplusCondition parse(String? raw) => values.firstWhere((c) => c.api == raw, orElse: () => other);

  /// What an operator can pick when marking their own stock down.
  static const forCenters = [nearExpiry, opened, returned, damagedPackaging, other];
}

/// Where a lot stands. Only [active] lots can be bought.
enum SurplusStatus {
  active,
  soldOut,
  expired,
  withdrawn;

  static SurplusStatus parse(String? raw) => values.firstWhere((s) => s.name == raw, orElse: () => active);
}

/// A batch of units at this center sold below the catalog price, apart from the
/// regular shelf. [available] is what is left to sell: [quantity] minus the
/// [reserved] units that app orders are holding.
class SurplusLot extends Equatable {
  const SurplusLot({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.catalogPrice,
    required this.unitPrice,
    required this.quantity,
    required this.reserved,
    required this.condition,
    required this.status,
    this.bestBefore,
    this.note = '',
    this.fromShelf = false,
  });

  factory SurplusLot.fromJson(Map<String, dynamic> json) => SurplusLot(
        id: json['id'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        unit: (json['unit'] as String?) ?? '',
        catalogPrice: (json['catalogPrice'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantity: (json['quantity'] as num).toInt(),
        reserved: (json['reserved'] as num).toInt(),
        condition: SurplusCondition.parse(json['condition'] as String?),
        status: SurplusStatus.parse(json['status'] as String?),
        bestBefore: json['bestBefore'] == null ? null : DateTime.tryParse(json['bestBefore'] as String),
        note: (json['note'] as String?) ?? '',
        fromShelf: json['fromShelf'] == true,
      );

  final String id;
  final String productId;
  final String productName;
  final String unit;

  /// The regular price; the surplus price is always below it.
  final double catalogPrice;
  final double unitPrice;

  /// Units still in the lot, including those held by orders.
  final int quantity;
  final int reserved;
  final SurplusCondition condition;
  final SurplusStatus status;

  /// The last day the goods are good for, if the operator gave one.
  final DateTime? bestBefore;
  final String note;

  /// Marked down from the shelf (rather than arriving from outside).
  final bool fromShelf;

  int get available => quantity - reserved;

  bool get isOnSale => status == SurplusStatus.active;

  /// How much cheaper than the regular price, as a whole percent.
  int get discountPercent => catalogPrice <= 0 ? 0 : ((1 - unitPrice / catalogPrice) * 100).round();

  @override
  List<Object?> get props => [id, productId, productName, unit, catalogPrice, unitPrice, quantity, reserved, condition, status, bestBefore, note, fromShelf];
}
