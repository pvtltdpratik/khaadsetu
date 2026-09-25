import 'package:equatable/equatable.dart';

import '../../../../operator/surplus/domain/entities/surplus_lot.dart';

/// The village center that holds a surplus offer.
class SurplusCenter extends Equatable {
  const SurplusCenter({required this.centerId, required this.name, required this.village, required this.phone, required this.isOpen, this.district = ''});

  factory SurplusCenter.fromJson(Map<String, dynamic> json) => SurplusCenter(
        centerId: json['centerId'] as String,
        name: json['name'] as String,
        village: (json['village'] as String?) ?? '',
        district: (json['district'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        isOpen: json['isOpen'] != false,
      );

  final String centerId;
  final String name;
  final String village;
  final String district;
  final String phone;

  /// Whether the operator has the shop switched on. A closed center can still
  /// be reserved from; the farmer collects later.
  final bool isOpen;

  @override
  List<Object?> get props => [centerId, name, village, district, phone, isOpen];
}

/// A batch of discounted units a farmer can reserve for pickup: cheaper than
/// the regular price because of its [condition] (near expiry, opened, ...).
class SurplusOffer extends Equatable {
  const SurplusOffer({
    required this.lotId,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.catalogPrice,
    required this.unitPrice,
    required this.available,
    required this.condition,
    required this.center,
    required this.distanceKm,
    required this.estimatedTravelMinutes,
    this.bestBefore,
    this.note = '',
    this.isFarmerResale = false,
    this.inspected = true,
    this.verifiedPurchase = false,
  });

  factory SurplusOffer.fromJson(Map<String, dynamic> json) => SurplusOffer(
        lotId: json['id'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        unit: (json['unit'] as String?) ?? '',
        catalogPrice: (json['catalogPrice'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        available: (json['available'] as num).toInt(),
        condition: SurplusCondition.parse(json['condition'] as String?),
        bestBefore: json['bestBefore'] == null ? null : DateTime.tryParse(json['bestBefore'] as String),
        note: (json['note'] as String?) ?? '',
        center: SurplusCenter.fromJson(json['center'] as Map<String, dynamic>),
        distanceKm: (json['distanceKm'] as num).toDouble(),
        estimatedTravelMinutes: (json['estimatedTravelMinutes'] as num).toInt(),
        isFarmerResale: json['isFarmerResale'] as bool? ?? false,
        inspected: json['inspected'] as bool? ?? true,
        verifiedPurchase: json['verifiedPurchase'] as bool? ?? false,
      );

  final String lotId;
  final String productId;
  final String productName;
  final String unit;
  final double catalogPrice;
  final double unitPrice;

  /// Units left that nobody else is holding.
  final int available;
  final SurplusCondition condition;
  final DateTime? bestBefore;
  final String note;
  final SurplusCenter center;
  final double distanceKm;

  /// From distance alone (no road data), so show it as "about".
  final int estimatedTravelMinutes;

  /// Sold by another farmer (not the center's own stock).
  final bool isFarmerResale;

  /// The village center has checked the goods in person. False while a farmer's listing is live but not yet handed in.
  final bool inspected;

  /// Backed by the seller's own platform order.
  final bool verifiedPurchase;

  /// How much cheaper than the regular price, as a whole percent.
  int get discountPercent => catalogPrice <= 0 ? 0 : ((1 - unitPrice / catalogPrice) * 100).round();

  @override
  List<Object?> get props => [lotId, productId, productName, unit, catalogPrice, unitPrice, available, condition, bestBefore, note, center, distanceKm, estimatedTravelMinutes, isFarmerResale, inspected, verifiedPurchase];
}
