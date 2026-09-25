// ignore_for_file: prefer_initializing_formals (a private field with a public named parameter)
import 'package:equatable/equatable.dart';

import '../../../../delivery/domain/entities/delivery_models.dart';

enum FarmerOrderStatus {
  pending,
  readyForPickup,
  completed,
  cancelled;

  static FarmerOrderStatus parse(Object? raw) => values.firstWhere((s) => s.name == raw, orElse: () => FarmerOrderStatus.pending);

  String get label => switch (this) {
        FarmerOrderStatus.pending => 'Reserved',
        FarmerOrderStatus.readyForPickup => 'Ready for pickup',
        FarmerOrderStatus.completed => 'Collected',
        FarmerOrderStatus.cancelled => 'Cancelled',
      };

  /// Still holding stock for the farmer, so it can be cancelled and the code is live.
  bool get isActive => this == FarmerOrderStatus.pending || this == FarmerOrderStatus.readyForPickup;
}

/// Whether the goods were paid online (Razorpay). Delivery fees are always paid in cash.
enum PaymentStatus {
  unpaid,
  paid,

  /// Paid, then the order was cancelled or expired and the money is on its way back.
  refunded;

  static PaymentStatus parse(Object? raw) => values.firstWhere((s) => s.name == raw, orElse: () => PaymentStatus.unpaid);
}

class OrderLine extends Equatable {
  const OrderLine({required this.productName, required this.quantity, required this.unitPrice, this.surplusLotId});

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        productName: json['productName'] as String,
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        surplusLotId: json['surplusLotId'] as String?,
      );

  final String productName;
  final int quantity;
  final double unitPrice;

  /// Set when this line was bought from a discounted surplus lot.
  final String? surplusLotId;

  bool get isSurplus => surplusLotId != null;

  @override
  List<Object?> get props => [productName, quantity, unitPrice, surplusLotId];
}

/// Where an order is to be collected.
class OrderCenter extends Equatable {
  const OrderCenter({required this.centerId, required this.name, required this.village, required this.phone});

  factory OrderCenter.fromJson(Map<String, dynamic> json) => OrderCenter(
        centerId: json['centerId'] as String,
        name: json['name'] as String,
        village: json['village'] as String,
        phone: (json['phone'] as String?) ?? '',
      );

  final String centerId;
  final String name;
  final String village;
  final String phone;

  @override
  List<Object?> get props => [centerId, name, village, phone];
}

class FarmerOrder extends Equatable {
  const FarmerOrder({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.totalAmount,
    this.pickupOtp,
    this.reservedUntil,
    this.center,
    this.deliveryFee = 0,
    this.delivery,
    this.paymentStatus = PaymentStatus.unpaid,
    double? payableAmount,
  }) : _payableAmount = payableAmount;

  factory FarmerOrder.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as Map<String, dynamic>?;
    return FarmerOrder(
      id: json['id'] as String,
      status: FarmerOrderStatus.parse(json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      items: (json['items'] as List).map((e) => OrderLine.fromJson(e as Map<String, dynamic>)).toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      pickupOtp: json['pickupOtp'] as String?,
      reservedUntil: json['reservedUntil'] == null ? null : DateTime.parse(json['reservedUntil'] as String).toLocal(),
      center: center == null ? null : OrderCenter.fromJson(center),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      delivery: json['delivery'] == null ? null : DeliveryTracking.fromJson(json['delivery'] as Map<String, dynamic>),
      paymentStatus: PaymentStatus.parse(json['paymentStatus']),
      payableAmount: (json['payableAmount'] as num?)?.toDouble(),
    );
  }

  final String id;
  final FarmerOrderStatus status;
  final DateTime createdAt;
  final List<OrderLine> items;
  final double totalAmount;

  /// The 4-digit code to read out at the counter. Only present while active.
  final String? pickupOtp;

  /// The pickup deadline: after this the reservation lapses.
  final DateTime? reservedUntil;
  final OrderCenter? center;

  /// What bringing it home costs (0 for a pickup).
  final double deliveryFee;

  /// Who is bringing it and where they are, for an order that has a delivery
  /// (also kept after it fell back to pickup, so the story can be told).
  final DeliveryTracking? delivery;

  /// Being brought home: the pickup code is not used and the delivery card takes over.
  bool get isHomeDelivery => delivery != null && delivery!.status != DeliveryStatus.fallback && delivery!.status != DeliveryStatus.cancelled;

  final PaymentStatus paymentStatus;
  final double? _payableAmount;

  bool get isPaidOnline => paymentStatus == PaymentStatus.paid;

  /// Still to pay in cash: the goods unless they were paid online, plus the delivery fee.
  /// The server works this out; the fallback is the same sum.
  double get payableAmount => _payableAmount ?? ((isPaidOnline ? 0 : totalAmount) + deliveryFee);

  /// Whether "Pay online" can still be offered: the order is open, unpaid and not already on its way.
  bool get canPayOnline => status.isActive && paymentStatus == PaymentStatus.unpaid && totalAmount > 0 && delivery?.status != DeliveryStatus.inTransit;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [id, status, createdAt, items, totalAmount, pickupOtp, reservedUntil, center, deliveryFee, delivery, paymentStatus, _payableAmount];
}
