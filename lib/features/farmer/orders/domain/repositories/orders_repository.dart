import '../../../../delivery/domain/entities/delivery_models.dart';
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

/// A surplus offer sold out (or was withdrawn) before this farmer could reserve it.
class SurplusUnavailableException implements Exception {
  const SurplusUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class OrdersRepository {
  /// Reserves [quantity] units of a discounted surplus lot for pickup at the
  /// center that listed it. Throws [SurplusUnavailableException] when it is gone.
  Future<FarmerOrder> placeSurplus({required String lotId, required int quantity, FarmerLocation? location});

  /// Reserves [items] for pickup. With [centerId] the farmer's own choice is
  /// used; without it the server assigns the best center that has everything,
  /// judged from [location]. With [delivery] the order is brought to that
  /// address by a delivery partner instead of being collected.
  /// Throws [OutOfStockException] when nothing fits.
  Future<FarmerOrder> place({required List<CartLine> items, String? centerId, FarmerLocation? location, DeliveryAddress? delivery});

  Future<List<FarmerOrder>> myOrders();

  Future<FarmerOrder> order(String id);

  Future<FarmerOrder> cancel(String id);
}
