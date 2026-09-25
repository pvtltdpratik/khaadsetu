import 'package:khaadsetu_version1/features/delivery/domain/entities/delivery_models.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/nearby_center.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/entities/surplus_offer.dart';
import 'package:khaadsetu_version1/features/farmer/centers/domain/repositories/centers_repository.dart';
import 'package:khaadsetu_version1/features/farmer/marketplace/domain/entities/product.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/entities/farmer_order.dart';
import 'package:khaadsetu_version1/features/farmer/orders/domain/repositories/orders_repository.dart';

const shirur = FarmerLocation(latitude: 18.83, longitude: 74.37, source: LocationSource.gps);

const neemCake = Product(
  id: 'p-neemcake',
  name: 'Neem Cake',
  brand: 'GreenGrow',
  category: ProductCategory.organic,
  priceInRupees: 600,
  unitLabel: '5 kg bag',
  rating: 4.5,
  reviewCount: 0,
  description: 'Organic fertilizer.',
  nutrientFocus: [],
  npkPercentages: {},
);

/// A nearby-center answer entry. [have] is how many of the (single) requested
/// product this center has available; [wanted] is how many were asked for.
NearbyCenter nearbyCenter(
  String id, {
  double km = 3,
  int have = 5,
  int wanted = 1,
  bool open = true,
  String hoursLabel = 'Open until 18:00',
  bool recommended = false,
  String? reason,
  String phone = '98220 00000',
  String operatorName = 'Olga',
  int pending = 0,
  bool cart = true,
}) {
  final status = !cart
      ? null
      : have >= wanted
          ? InventoryStatus.all
          : have > 0
              ? InventoryStatus.partial
              : InventoryStatus.none;
  return NearbyCenter(
    center: CenterInfo(centerId: id, name: 'Center $id', village: 'Village $id', district: 'Pune', latitude: 18.8, longitude: 74.3, operatorName: operatorName, phone: phone),
    distanceKm: km,
    estimatedTravelMinutes: (km * 8).round(),
    inventory: CenterInventory(
      status: status,
      label: switch (status) {
        InventoryStatus.all => 'All items available',
        InventoryStatus.partial => '0 of 1 items available',
        InventoryStatus.none => 'Out of stock for your order',
        null => null,
      },
      availableItems: status == InventoryStatus.all ? 1 : 0,
      totalItems: cart ? 1 : 0,
      items: cart ? [InventoryLine(productId: 'p-neemcake', requested: wanted, available: have, isFullyAvailable: have >= wanted)] : const [],
    ),
    hours: CenterHours(isOpenNow: open, opensAt: '09:00', closesAt: '18:00', label: hoursLabel),
    pendingPickups: pending,
    isHomeCenter: false,
    isRecommended: recommended,
    recommendationReason: reason,
  );
}

class FakeDeviceLocation implements DeviceLocation {
  FakeDeviceLocation({this.result, this.error});

  FarmerLocation? result;
  Object? error;
  int calls = 0;

  @override
  Future<FarmerLocation> current() async {
    calls++;
    if (error != null) throw error!;
    return result!;
  }
}

/// Answers `nearby` from a builder so tests can vary stock with the quantity asked for.
class FakeCentersRepository implements CentersRepository {
  FakeCentersRepository({this.saved, this.villageList = const []});

  FarmerLocation? saved;
  List<Village> villageList;
  final nearbyCalls = <Cart>[];
  final savedLocations = <FarmerLocation>[];
  Object? nearbyError;

  /// Builds the answer for a cart.
  List<NearbyCenter> Function(Cart cart) centers = (cart) => [nearbyCenter('a', recommended: true)];

  @override
  Future<NearbyResult> nearby({required FarmerLocation location, Cart cart = Cart.empty, int limit = 5}) async {
    nearbyCalls.add(cart);
    if (nearbyError != null) throw nearbyError!;
    return NearbyResult(location: location, radiusKm: 10, centers: centers(cart));
  }

  /// What `surplusNearby` answers, and the products it was asked about.
  List<SurplusOffer> surplus = [];
  final surplusCalls = <String?>[];
  Object? surplusError;

  @override
  Future<List<SurplusOffer>> surplusNearby({required FarmerLocation location, String? productId}) async {
    surplusCalls.add(productId);
    if (surplusError != null) throw surplusError!;
    return surplus.where((o) => productId == null || o.productId == productId).toList();
  }

  @override
  Future<List<Village>> villages(String query) async =>
      villageList.where((v) => query.isEmpty || v.name.toLowerCase().contains(query.toLowerCase())).toList();

  @override
  Future<FarmerLocation?> savedLocation() async => saved;

  @override
  Future<void> saveLocation(FarmerLocation location) async => savedLocations.add(location);

  /// Products the farmer has asked to be told about, and where they asked from.
  final notifyMe = <String, FarmerLocation>{};
  Object? notifyMeError;

  @override
  Future<bool> isNotifyMeOn(String productId) async => notifyMe.containsKey(productId);

  @override
  Future<void> turnNotifyMeOn(String productId, FarmerLocation location) async {
    if (notifyMeError != null) throw notifyMeError!;
    notifyMe[productId] = location;
  }

  @override
  Future<void> turnNotifyMeOff(String productId) async => notifyMe.remove(productId);
}

FarmerOrder farmerOrder(
  String id, {
  FarmerOrderStatus status = FarmerOrderStatus.pending,
  String? otp = '4821',
  String centerName = 'Center a',
  String phone = '98220 00000',
  DeliveryTracking? delivery,
  double deliveryFee = 0,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
}) =>
    FarmerOrder(
      id: id,
      status: status,
      createdAt: DateTime(2026, 9, 24),
      items: const [OrderLine(productName: 'Neem Cake', quantity: 2, unitPrice: 600)],
      totalAmount: 1200,
      pickupOtp: status.isActive ? otp : null,
      reservedUntil: DateTime(2026, 9, 29),
      center: OrderCenter(centerId: 'a', name: centerName, village: 'Village a', phone: phone),
      deliveryFee: deliveryFee,
      delivery: delivery,
      paymentStatus: paymentStatus,
    );

class FakeOrdersRepository implements OrdersRepository {
  final surplusPlaced = <({String lotId, int quantity})>[];

  /// Throw a [SurplusUnavailableException] to simulate someone else getting there first.
  Object? surplusError;

  @override
  Future<FarmerOrder> placeSurplus({required String lotId, required int quantity, FarmerLocation? location}) async {
    if (surplusError != null) throw surplusError!;
    surplusPlaced.add((lotId: lotId, quantity: quantity));
    final order = FarmerOrder(
      id: 'order-surplus-${surplusPlaced.length}',
      status: FarmerOrderStatus.pending,
      createdAt: DateTime(2026, 9, 24),
      items: [OrderLine(productName: 'Neem Cake', quantity: quantity, unitPrice: 450, surplusLotId: lotId)],
      totalAmount: 450.0 * quantity,
      pickupOtp: '4821',
      reservedUntil: DateTime(2026, 9, 29),
      center: const OrderCenter(centerId: 'a', name: 'Center a', village: 'Village a', phone: '98220 00000'),
    );
    orders = [order, ...orders];
    return order;
  }

  final placed = <({List<CartLine> items, String? centerId, FarmerLocation? location, DeliveryAddress? delivery})>[];
  final cancelled = <String>[];

  /// Called for each placement; throw an [OutOfStockException] to simulate a lost race.
  FarmerOrder Function(int attempt, String? centerId) onPlace = (attempt, centerId) => farmerOrder('order-1');
  List<FarmerOrder> orders = [];

  @override
  Future<FarmerOrder> place({required List<CartLine> items, String? centerId, FarmerLocation? location, DeliveryAddress? delivery}) async {
    placed.add((items: items, centerId: centerId, location: location, delivery: delivery));
    final order = onPlace(placed.length, centerId);
    orders = [order, ...orders]; // it now exists, so the detail page can load it
    return order;
  }

  @override
  Future<List<FarmerOrder>> myOrders() async => orders;

  @override
  Future<FarmerOrder> order(String id) async => orders.firstWhere((o) => o.id == id, orElse: () => farmerOrder(id));

  @override
  Future<FarmerOrder> cancel(String id) async {
    cancelled.add(id);
    final o = await order(id);
    return farmerOrder(id, status: FarmerOrderStatus.cancelled, centerName: o.center?.name ?? 'Center a');
  }
}
