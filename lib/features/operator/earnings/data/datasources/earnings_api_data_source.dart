import '../../../../../core/network/api_client.dart';

class EarningsApiDataSource {
  const EarningsApiDataSource(this._api);

  final ApiClient _api;

  Future<double> fetchCommissionRatePercent() async {
    final json = await _api.get('/v1/operator/earnings/commission-rate') as Map<String, dynamic>;
    return (json['commissionRatePercent'] as num).toDouble();
  }
}
