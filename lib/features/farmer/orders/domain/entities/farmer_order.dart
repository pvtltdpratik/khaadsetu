import 'package:equatable/equatable.dart';

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

class OrderLine extends Equatable {
  const OrderLine({required this.productName, required this.quantity, required this.unitPrice});

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        productName: json['productName'] as String,
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
      );

  final String productName;
  final int quantity;
  final double unitPrice;

  @override
  List<Object?> get props => [productName, quantity, unitPrice];
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
  });

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

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [id, status, createdAt, items, totalAmount, pickupOtp, reservedUntil, center];
}
