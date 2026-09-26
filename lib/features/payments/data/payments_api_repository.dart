import '../../../core/network/api_client.dart';
import '../domain/payment_models.dart';
import '../domain/payments_repository.dart';

class PaymentsApiRepository implements PaymentsRepository {
  const PaymentsApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<PaymentConfig> config() async => PaymentConfig.fromJson(await _api.get('/v1/payments/config') as Map<String, dynamic>);

  @override
  Future<PaymentSession> start(String orderId) async => PaymentSession.fromJson(await _api.post('/v1/payments/orders', body: {'orderId': orderId}) as Map<String, dynamic>);

  @override
  Future<void> payFromWallet(String orderId) async {
    await _api.post('/v1/payments/wallet', body: {'orderId': orderId});
  }

  @override
  Future<bool> sync(String orderId) async {
    final json = await _api.post('/v1/payments/orders/${Uri.encodeComponent(orderId)}/sync') as Map<String, dynamic>;
    return json['paymentStatus'] == 'paid';
  }

  @override
  Future<void> verify({required String razorpayOrderId, required String razorpayPaymentId, required String signature}) async {
    await _api.post('/v1/payments/verify', body: {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': signature,
    });
  }
}
