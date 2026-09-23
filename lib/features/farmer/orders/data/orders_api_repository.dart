import '../../../../core/network/api_client.dart';
import '../../centers/domain/entities/nearby_center.dart';
import '../domain/entities/farmer_order.dart';
import '../domain/repositories/orders_repository.dart';

class OrdersApiRepository implements OrdersRepository {
  const OrdersApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<FarmerOrder> place({required List<CartLine> items, String? centerId, FarmerLocation? location}) async {
    try {
      final json = await _api.post('/v1/orders', body: {
        'items': [for (final l in items) {'productId': l.productId, 'quantity': l.quantity}],
        'centerId': ?centerId,
        if (location != null) ...{
          'latitude': location.latitude,
          'longitude': location.longitude,
          'locationSource': location.source == LocationSource.gps ? 'gps' : 'pin',
        },
      });
      return FarmerOrder.fromJson(json as Map<String, dynamic>);
    } on ApiException catch (err) {
      if (err.code == 'out_of_stock') {
        final raw = (err.details?['alternatives'] as List?) ?? const [];
        throw OutOfStockException(
          err.message,
          [for (final a in raw) CenterAlternative.fromJson(a as Map<String, dynamic>)],
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<FarmerOrder>> myOrders() async {
    final list = await _api.get('/v1/orders') as List;
    return list.map((e) => FarmerOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<FarmerOrder> order(String id) async =>
      FarmerOrder.fromJson(await _api.get('/v1/orders/${Uri.encodeComponent(id)}') as Map<String, dynamic>);

  @override
  Future<FarmerOrder> cancel(String id) async =>
      FarmerOrder.fromJson(await _api.post('/v1/orders/${Uri.encodeComponent(id)}/cancel') as Map<String, dynamic>);
}
