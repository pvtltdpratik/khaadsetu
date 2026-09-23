import 'package:equatable/equatable.dart';

/// One product on THIS center's shelf.
///
/// [currentStock] is what is physically there; [reserved] is promised to app
/// orders waiting for pickup; [available] (the difference) is what can still
/// be sold. "Low" is judged on [available], because reserved stock is spoken for.
class InventoryItem extends Equatable {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.currentStock,
    required this.lowStockThreshold,
    this.reserved = 0,
    this.incoming = 0,
    this.maxCapacity,
    this.lastRestockedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        currentStock: (json['currentStock'] as num).toInt(),
        lowStockThreshold: (json['lowStockThreshold'] as num).toInt(),
        reserved: ((json['reserved'] as num?) ?? 0).toInt(),
        incoming: ((json['incoming'] as num?) ?? 0).toInt(),
        maxCapacity: (json['maxCapacity'] as num?)?.toInt(),
        lastRestockedAt: json['lastRestockedAt'] == null ? null : DateTime.parse(json['lastRestockedAt'] as String).toLocal(),
      );

  /// The product's id in the catalog.
  final String id;
  final String name;

  /// e.g. "bag", "bottle".
  final String unit;
  final double unitPrice;
  final int currentStock;
  final int lowStockThreshold;
  final int reserved;

  /// Approved by the platform but not yet received.
  final int incoming;

  /// How much this center can physically store; null when unlimited.
  final int? maxCapacity;
  final DateTime? lastRestockedAt;

  int get available => currentStock - reserved;

  bool get isLowStock => available <= lowStockThreshold;

  @override
  List<Object?> get props =>
      [id, name, unit, unitPrice, currentStock, lowStockThreshold, reserved, incoming, maxCapacity, lastRestockedAt];
}

/// The operator said a delivery did not match what was expected.
class DiscrepancyReport extends Equatable {
  const DiscrepancyReport({required this.expected, required this.received});

  final int expected;
  final int received;

  @override
  List<Object?> get props => [expected, received];
}

class ReceiveResult extends Equatable {
  const ReceiveResult({required this.item, this.discrepancy});

  final InventoryItem item;
  final DiscrepancyReport? discrepancy;

  @override
  List<Object?> get props => [item, discrepancy];
}
