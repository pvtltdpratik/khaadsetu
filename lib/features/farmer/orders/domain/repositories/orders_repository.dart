import '../../../centers/domain/entities/nearby_center.dart';
import '../entities/farmer_order.dart';

/// The chosen center (or every center in range) ran out of an item while the
/// farmer was ordering. [alternatives] are other centers worth trying.
class OutOfStockException implements Exception {
  const OutOfStockException(this.message, this.alternatives);

  final String message;
  final List<CenterAlternative> alternatives;

  @override
  String toString() => message;
}

abstract class OrdersRepository {
  /// Reserves [items] for pickup. With [centerId] the farmer's own choice is
  /// used; without it the server assigns the best center that has everything,
  /// judged from [location]. Throws [OutOfStockException] when nothing fits.
  Future<FarmerOrder> place({required List<CartLine> items, String? centerId, FarmerLocation? location});

  Future<List<FarmerOrder>> myOrders();

  Future<FarmerOrder> order(String id);

  Future<FarmerOrder> cancel(String id);
}
