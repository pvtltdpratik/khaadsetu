import '../../../../../core/network/api_client.dart';
import '../../domain/entities/order.dart';

/// Operator-side orders. The pickup OTP is checked by the server: operator
/// endpoints never return it (`pickupOtp` is always null), the operator just
/// types what the farmer reads out.
class OrdersApiDataSource {
  const OrdersApiDataSource(this._api);

  final ApiClient _api;

  Future<List<Order>> fetchOrders() async {
    final list = await _api.get('/v1/operator/orders') as List;
    return list.map((e) => _parse(e as Map<String, dynamic>)).toList();
  }

  Future<Order> fetchOrderById(String id) async {
    return _parse(await _api.get('/v1/operator/orders/$id') as Map<String, dynamic>);
  }

  Future<Order> markReadyForPickup(String orderId) async {
    return _parse(await _api.post('/v1/operator/orders/$orderId/ready') as Map<String, dynamic>);
  }

  Future<Order> verifyOtpAndComplete(String orderId, String enteredOtp) async {
    final json = await _api.post(
      '/v1/operator/orders/$orderId/verify-otp',
      body: {'otp': enteredOtp},
    ) as Map<String, dynamic>;
    return _parse(json);
  }

  Future<Order> createWalkInOrder({
    required String customerName,
    required List<OrderLineItem> items,
  }) async {
    final json = await _api.post('/v1/operator/orders/walk-in', body: {
      'customerName': customerName,
      'items': [
        for (final i in items)
          {'productId': ?i.productId, 'productName': i.productName, 'quantity': i.quantity, 'unitPrice': i.unitPrice},
      ],
    }) as Map<String, dynamic>;
    return _parse(json);
  }

  Order _parse(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      type: OrderType.values.byName(json['type'] as String),
      status: OrderStatus.values.byName(json['status'] as String),
      items: (json['items'] as List)
          .map((e) => e as Map<String, dynamic>)
          .map((m) => OrderLineItem(
                productName: m['productName'] as String,
                quantity: (m['quantity'] as num).toInt(),
                unitPrice: (m['unitPrice'] as num).toDouble(),
              ))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      pickupOtp: json['pickupOtp'] as String?,
    );
  }
}
