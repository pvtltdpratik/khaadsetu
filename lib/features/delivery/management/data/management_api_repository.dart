import 'dart:typed_data';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/delivery_models.dart';
import '../domain/management_models.dart';
import '../domain/management_repository.dart';

String _id(String id) => Uri.encodeComponent(id);

String _statusParam(DeliveryStatus s) => switch (s) {
      DeliveryStatus.inTransit => 'in_transit',
      _ => s.name,
    };

class ManagementApiRepository implements DeliveryManagementRepository {
  const ManagementApiRepository(this._api, this.scope);

  final ApiClient _api;
  final ManagementScope scope;

  String get _base => scope == ManagementScope.operator ? '/v1/operator' : '/v1/admin';

  void _operatorOnly() {
    if (scope != ManagementScope.operator) throw UnsupportedError('Only a village center operator can do this');
  }

  @override
  Future<List<ManagedDelivery>> deliveries({DeliveryStatus? status}) async => [
        for (final j in await _api.get('$_base/deliveries', query: {'status': status == null ? null : _statusParam(status), 'limit': '100'}) as List)
          ManagedDelivery.fromJson(j as Map<String, dynamic>),
      ];

  @override
  Future<List<PartnerApplication>> partners({PartnerStatus? status, String? query}) async => [
        for (final j in await _api.get('$_base/delivery-partners', query: {'status': status?.name, 'q': query, 'limit': '100'}) as List)
          PartnerApplication.fromJson(j as Map<String, dynamic>),
      ];

  @override
  Future<PartnerApplication> partner(String userId) async =>
      PartnerApplication.fromJson(await _api.get('$_base/delivery-partners/${_id(userId)}') as Map<String, dynamic>);

  @override
  Future<Uint8List> document(String userId, String kind) => _api.getBytes('$_base/delivery-partners/${_id(userId)}/documents/$kind');

  @override
  Future<PartnerApplication> review(String userId, ReviewAction action, {String? note}) async {
    final json = await _api.post('$_base/delivery-partners/${_id(userId)}/${action.name}', body: {if (note != null && note.isNotEmpty) 'note': note});
    return PartnerApplication.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<AssignCandidate>> candidates(String jobId) async {
    _operatorOnly();
    return [for (final j in await _api.get('$_base/deliveries/${_id(jobId)}/candidates') as List) AssignCandidate.fromJson(j as Map<String, dynamic>)];
  }

  @override
  Future<ManagedDelivery> assign(String jobId, String partnerId) async {
    _operatorOnly();
    return ManagedDelivery.fromJson(await _api.post('$_base/deliveries/${_id(jobId)}/assign', body: {'partnerId': partnerId}) as Map<String, dynamic>);
  }

  @override
  Future<ManagedDelivery> handover(String jobId, String otp) async {
    _operatorOnly();
    return ManagedDelivery.fromJson(await _api.post('$_base/deliveries/${_id(jobId)}/handover', body: {'otp': otp}) as Map<String, dynamic>);
  }

  @override
  Future<List<CashOwed>> cashOwed() async {
    _operatorOnly();
    return [for (final j in await _api.get('$_base/delivery-cash') as List) CashOwed.fromJson(j as Map<String, dynamic>)];
  }

  @override
  Future<List<CashOwed>> settleCash(String partnerId, double amount, {String note = ''}) async {
    _operatorOnly();
    final json = await _api.post('$_base/delivery-cash/${_id(partnerId)}/settle', body: {'amount': amount, if (note.isNotEmpty) 'note': note});
    return [for (final j in json as List) CashOwed.fromJson(j as Map<String, dynamic>)];
  }
}
