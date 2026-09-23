import '../entities/surplus_lot.dart';

/// The operator's surplus / second-hand stock: units sold below the catalog
/// price, kept apart from the regular shelf.
abstract class SurplusRepository {
  /// Every lot at this center, newest first (on sale, sold out, expired, withdrawn).
  Future<List<SurplusLot>> lots();

  /// With [fromShelf] the units are taken off the regular shelf (only what is
  /// not already reserved); otherwise they are new units from outside.
  Future<SurplusLot> create({
    required String productId,
    required int quantity,
    required double unitPrice,
    required SurplusCondition condition,
    DateTime? bestBefore,
    String? note,
    bool fromShelf = false,
  });

  Future<SurplusLot> update(String id, {double? unitPrice, String? note});

  /// Takes the lot off sale. Unsold units return to the shelf if they came from it.
  Future<SurplusLot> withdraw(String id);
}
