import 'package:equatable/equatable.dart';

/// Minimal stock ledger entry — just enough for the Phase 6 dashboard's
/// low-stock card and the walk-in POS's sellable list. Phase 7 extends this
/// with restock requests and the full inventory screen.
class InventoryItem extends Equatable {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.currentStock,
    required this.lowStockThreshold,
  });

  final String id;
  final String name;

  /// e.g. "bag", "bottle".
  final String unit;
  final double unitPrice;
  final int currentStock;
  final int lowStockThreshold;

  bool get isLowStock => currentStock <= lowStockThreshold;

  @override
  List<Object?> get props =>
      [id, name, unit, unitPrice, currentStock, lowStockThreshold];
}
