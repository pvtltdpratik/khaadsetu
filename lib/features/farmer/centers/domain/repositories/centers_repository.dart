import '../entities/nearby_center.dart';

abstract class CentersRepository {
  /// The centers this farmer could use from [location], best first. [cart] is
  /// what they want (empty when just browsing).
  Future<NearbyResult> nearby({required FarmerLocation location, Cart cart = Cart.empty, int limit = 5});

  Future<List<Village>> villages(String query);

  /// The location saved on the farmer's profile, or failing that the village
  /// they registered with. Null when neither is known.
  Future<FarmerLocation?> savedLocation();

  Future<void> saveLocation(FarmerLocation location);
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
