import '../../../../core/network/api_client.dart';
import '../domain/entities/operator_center.dart';
import '../domain/repositories/operator_center_repository.dart';

class OperatorCenterApiRepository implements OperatorCenterRepository {
  const OperatorCenterApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<OperatorCenter> center() async => OperatorCenter.fromJson(await _api.get('/v1/operator/center') as Map<String, dynamic>);

  @override
  Future<OperatorCenter> update({bool? isOpen, String? opensAt, String? closesAt, String? phone, String? operatorName}) async {
    final json = await _api.patch('/v1/operator/center', body: {
      'isOpen': ?isOpen,
      'opensAt': ?opensAt,
      'closesAt': ?closesAt,
      'phone': ?phone,
      'operatorName': ?operatorName,
    });
    return OperatorCenter.fromJson(json as Map<String, dynamic>);
  }
}
