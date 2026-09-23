import 'package:equatable/equatable.dart';

/// Where a farmer's position came from, in order of preference.
enum LocationSource {
  gps,
  pin,
  village;

  static LocationSource parse(Object? raw) => LocationSource.values.firstWhere((s) => s.name == raw, orElse: () => LocationSource.gps);
}

class FarmerLocation extends Equatable {
  const FarmerLocation({required this.latitude, required this.longitude, required this.source, this.label});

  final double latitude;
  final double longitude;
  final LocationSource source;

  /// A name to show for it, e.g. the village ("Shirur"). Null for a raw GPS fix.
  final String? label;

  @override
  List<Object?> get props => [latitude, longitude, source, label];
}

/// A place from the server's village list (the fallback when GPS is off).
class Village extends Equatable {
  const Village({required this.name, required this.district, required this.latitude, required this.longitude});

  factory Village.fromJson(Map<String, dynamic> json) => Village(
        name: json['name'] as String,
        district: json['district'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  final String name;
  final String district;
  final double latitude;
  final double longitude;

  String get display => '$name, $district';

  @override
  List<Object?> get props => [name, district, latitude, longitude];
}

/// One line of what the farmer wants: a product and how many.
class CartLine extends Equatable {
  const CartLine(this.productId, this.quantity);

  final String productId;
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

/// The cart, as one value with deep equality, so identical carts share one
/// cached lookup.
class Cart extends Equatable {
  const Cart(this.lines);

  static const empty = Cart([]);

  final List<CartLine> lines;

  @override
  List<Object?> get props => [lines];
}

enum InventoryStatus {
  all,
  partial,
  none;

  static InventoryStatus? parse(Object? raw) {
    for (final s in values) {
      if (s.name == raw) return s;
    }
    return null;
  }
}

class InventoryLine extends Equatable {
  const InventoryLine({required this.productId, required this.requested, required this.available, required this.isFullyAvailable});

  factory InventoryLine.fromJson(Map<String, dynamic> json) => InventoryLine(
        productId: json['productId'] as String,
        requested: (json['requested'] as num).toInt(),
        available: (json['available'] as num).toInt(),
        isFullyAvailable: json['isFullyAvailable'] as bool,
      );

  final String productId;
  final int requested;
  final int available;
  final bool isFullyAvailable;

  @override
  List<Object?> get props => [productId, requested, available, isFullyAvailable];
}

/// How well a center covers the cart. [status] is null when no cart was sent.
class CenterInventory extends Equatable {
  const CenterInventory({required this.status, required this.label, required this.availableItems, required this.totalItems, required this.items});

  factory CenterInventory.fromJson(Map<String, dynamic> json) => CenterInventory(
        status: InventoryStatus.parse(json['status']),
        label: json['label'] as String?,
        availableItems: (json['availableItems'] as num).toInt(),
        totalItems: (json['totalItems'] as num).toInt(),
        items: (json['items'] as List).map((e) => InventoryLine.fromJson(e as Map<String, dynamic>)).toList(),
      );

  final InventoryStatus? status;
  final String? label;
  final int availableItems;
  final int totalItems;
  final List<InventoryLine> items;

  @override
  List<Object?> get props => [status, label, availableItems, totalItems, items];
}

class CenterHours extends Equatable {
  const CenterHours({required this.isOpenNow, required this.opensAt, required this.closesAt, required this.label});

  factory CenterHours.fromJson(Map<String, dynamic> json) => CenterHours(
        isOpenNow: json['isOpenNow'] as bool,
        opensAt: json['opensAt'] as String,
        closesAt: json['closesAt'] as String,
        label: json['label'] as String,
      );

  final bool isOpenNow;
  final String opensAt;
  final String closesAt;

  /// "Open until 18:00", "Opens tomorrow at 09:00", "Closed by operator".
  final String label;

  @override
  List<Object?> get props => [isOpenNow, opensAt, closesAt, label];
}

class CenterInfo extends Equatable {
  const CenterInfo({
    required this.centerId,
    required this.name,
    required this.village,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.operatorName,
    required this.phone,
  });

  factory CenterInfo.fromJson(Map<String, dynamic> json) => CenterInfo(
        centerId: json['centerId'] as String,
        name: json['name'] as String,
        village: json['village'] as String,
        district: (json['district'] as String?) ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        operatorName: (json['operatorName'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
      );

  final String centerId;
  final String name;
  final String village;
  final String district;
  final double latitude;
  final double longitude;
  final String operatorName;
  final String phone;

  bool get hasPhone => phone.trim().isNotEmpty;

  @override
  List<Object?> get props => [centerId, name, village, district, latitude, longitude, operatorName, phone];
}

/// A center as offered to this farmer: how far, what it has, whether it is open.
class NearbyCenter extends Equatable {
  const NearbyCenter({
    required this.center,
    required this.distanceKm,
    required this.estimatedTravelMinutes,
    required this.inventory,
    required this.hours,
    required this.pendingPickups,
    required this.isHomeCenter,
    required this.isRecommended,
    this.recommendationReason,
  });

  factory NearbyCenter.fromJson(Map<String, dynamic> json) => NearbyCenter(
        center: CenterInfo.fromJson(json['center'] as Map<String, dynamic>),
        distanceKm: (json['distanceKm'] as num).toDouble(),
        estimatedTravelMinutes: (json['estimatedTravelMinutes'] as num).toInt(),
        inventory: CenterInventory.fromJson(json['inventory'] as Map<String, dynamic>),
        hours: CenterHours.fromJson(json['hours'] as Map<String, dynamic>),
        pendingPickups: (json['pendingPickups'] as num).toInt(),
        isHomeCenter: json['isHomeCenter'] as bool,
        isRecommended: json['isRecommended'] as bool,
        recommendationReason: json['recommendationReason'] as String?,
      );

  final CenterInfo center;
  final double distanceKm;

  /// An estimate from distance (no road data yet); show it with a "~".
  final int estimatedTravelMinutes;
  final CenterInventory inventory;
  final CenterHours hours;
  final int pendingPickups;
  final bool isHomeCenter;
  final bool isRecommended;
  final String? recommendationReason;

  @override
  List<Object?> get props => [center, distanceKm, estimatedTravelMinutes, inventory, hours, pendingPickups, isHomeCenter, isRecommended, recommendationReason];
}

class NearbyResult extends Equatable {
  const NearbyResult({required this.location, required this.radiusKm, required this.centers});

  final FarmerLocation location;
  final int radiusKm;

  /// Best first. The first one is the recommended center.
  final List<NearbyCenter> centers;

  @override
  List<Object?> get props => [location, radiusKm, centers];
}

/// Another center the farmer can try after their choice sold out.
class CenterAlternative extends Equatable {
  const CenterAlternative({required this.centerId, required this.name, required this.village, required this.distanceKm, required this.inventoryStatus, this.inventoryLabel});

  factory CenterAlternative.fromJson(Map<String, dynamic> json) => CenterAlternative(
        centerId: json['centerId'] as String,
        name: json['name'] as String,
        village: json['village'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        inventoryStatus: InventoryStatus.parse(json['inventoryStatus']),
        inventoryLabel: json['inventoryLabel'] as String?,
      );

  final String centerId;
  final String name;
  final String village;
  final double distanceKm;
  final InventoryStatus? inventoryStatus;
  final String? inventoryLabel;

  @override
  List<Object?> get props => [centerId, name, village, distanceKm, inventoryStatus, inventoryLabel];
}
