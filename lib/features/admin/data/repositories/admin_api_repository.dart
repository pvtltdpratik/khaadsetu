import '../../../../core/network/api_client.dart';
import '../../domain/entities/admin_models.dart';
import '../../domain/repositories/admin_repository.dart';

/// The admin panel against the real API (`/v1/admin/...`).
class AdminApiRepository implements AdminRepository {
  const AdminApiRepository(this._api);

  final ApiClient _api;

  List<Map<String, dynamic>> _rows(Object? list) => (list as List).cast<Map<String, dynamic>>();

  @override
  Future<AdminOverview> overview() async =>
      AdminOverview.fromJson(await _api.get('/v1/admin/overview') as Map<String, dynamic>);

  @override
  Future<List<AuditEntry>> recentActivity({int limit = 10}) async =>
      _rows(await _api.get('/v1/admin/audit', query: {'limit': '$limit'})).map(AuditEntry.fromJson).toList();

  @override
  Future<List<AdminUser>> users({required PersonRole role, PersonSegment? segment, String? q, int limit = 100}) async {
    final list = await _api.get('/v1/admin/users', query: {
      'role': role.name,
      'segment': segment?.name,
      'q': q?.trim(),
      'limit': '$limit',
    });
    return _rows(list).map(AdminUser.fromJson).toList();
  }

  @override
  Future<AdminUserDetail> userDetail(String userId) async => AdminUserDetail.fromJson(
      await _api.get('/v1/admin/users/${Uri.encodeComponent(userId)}') as Map<String, dynamic>);

  @override
  Future<void> setUserStatus(String userId, {required bool suspended, String? reason}) async {
    await _api.patch('/v1/admin/users/${Uri.encodeComponent(userId)}', body: {
      'status': suspended ? 'suspended' : 'active',
      if (suspended && reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  @override
  Future<List<AdminCenter>> centers({String? status, bool? hasOperator, String? q, int limit = 100}) async {
    final list = await _api.get('/v1/admin/centers', query: {
      'status': status,
      'hasOperator': hasOperator?.toString(),
      'q': q?.trim(),
      'limit': '$limit',
    });
    return _rows(list).map(AdminCenter.fromJson).toList();
  }

  @override
  Future<AdminCenter> center(String centerId) async =>
      AdminCenter.fromJson(await _api.get('/v1/admin/centers/${Uri.encodeComponent(centerId)}') as Map<String, dynamic>);

  @override
  Future<List<StockItem>> centerStock(String centerId) async =>
      _rows(await _api.get('/v1/admin/centers/${Uri.encodeComponent(centerId)}/inventory', query: {'limit': '200'}))
          .map(StockItem.fromJson)
          .toList();

  @override
  Future<AdminCenter> createCenter({
    required String name,
    required String village,
    required String district,
    required double latitude,
    required double longitude,
    String? phone,
    String? operatorName,
    String? operatorId,
    String? opensAt,
    String? closesAt,
  }) async {
    String? blankToNull(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    final created = await _api.post('/v1/admin/centers', body: {
      'name': name.trim(),
      'village': village.trim(),
      if (district.trim().isNotEmpty) 'district': district.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'phone': ?blankToNull(phone),
      'operatorName': ?blankToNull(operatorName),
      'operatorId': ?operatorId,
      'opensAt': ?opensAt,
      'closesAt': ?closesAt,
    });
    return AdminCenter.fromJson(created as Map<String, dynamic>);
  }

  @override
  Future<void> setCenterSuspended(String centerId, {required bool suspended}) async {
    await _api.patch('/v1/admin/centers/${Uri.encodeComponent(centerId)}', body: {'status': suspended ? 'suspended' : 'active'});
  }

  @override
  Future<void> assignOperator(String centerId, String? userId) async {
    await _api.put('/v1/admin/centers/${Uri.encodeComponent(centerId)}/operator', body: {'userId': userId});
  }

  @override
  Future<List<VillageOption>> searchVillages(String query) async =>
      _rows(await _api.get('/v1/centers/villages', query: {'q': query})).map(VillageOption.fromJson).toList();
}
