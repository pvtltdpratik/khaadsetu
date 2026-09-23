import '../entities/nearby_center.dart';
import '../entities/surplus_offer.dart';

abstract class CentersRepository {
  /// The centers this farmer could use from [location], best first. [cart] is
  /// what they want (empty when just browsing).
  Future<NearbyResult> nearby({required FarmerLocation location, Cart cart = Cart.empty, int limit = 5});

  /// Discounted surplus units near [location], nearest first. [productId]
  /// narrows it to one product.
  Future<List<SurplusOffer>> surplusNearby({required FarmerLocation location, String? productId});

  Future<List<Village>> villages(String query);

  /// The location saved on the farmer's profile, or failing that the village
  /// they registered with. Null when neither is known.
  Future<FarmerLocation?> savedLocation();

  Future<void> saveLocation(FarmerLocation location);

  /// Whether this farmer has asked to be told when [productId] is available near them.
  Future<bool> isNotifyMeOn(String productId);

  /// Asks to be told, once, when any center near [location] receives the product.
  Future<void> turnNotifyMeOn(String productId, FarmerLocation location);

  Future<void> turnNotifyMeOff(String productId);
}

/// Why the device's position could not be read, worded for the farmer.
class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The phone's own position (GPS).
abstract class DeviceLocation {
  Future<FarmerLocation> current();
}
