import 'package:equatable/equatable.dart';

enum OrderType { appOrder, walkIn }

/// pending -> readyForPickup -> completed for app orders (OTP verified at
/// handover); walk-in sales are created directly as completed since there's
/// no separate pickup step.
enum OrderStatus { pending, readyForPickup, completed, cancelled }

class OrderLineItem extends Equatable {
  const OrderLineItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productName;
  final int quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;

  @override
  List<Object?> get props => [productName, quantity, unitPrice];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.customerName,
    required this.type,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.pickupOtp,
  });

  final String id;
  final String customerName;
  final OrderType type;
  final OrderStatus status;
  final List<OrderLineItem> items;
  final DateTime createdAt;

  /// Only meaningful for an [OrderType.appOrder] awaiting pickup — null once
  /// completed, and never set for walk-in sales.
  final String? pickupOtp;

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({OrderStatus? status, String? pickupOtp}) {
    return Order(
      id: id,
      customerName: customerName,
      type: type,
      status: status ?? this.status,
      items: items,
      createdAt: createdAt,
      pickupOtp: pickupOtp ?? this.pickupOtp,
    );
  }

  @override
  List<Object?> get props =>
      [id, customerName, type, status, items, createdAt, pickupOtp];
}
