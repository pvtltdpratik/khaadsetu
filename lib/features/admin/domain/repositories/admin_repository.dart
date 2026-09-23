import '../entities/admin_models.dart';

/// Everything the admin panel reads and changes. Lists return the first
/// [limit] rows (the server's maximum page is 200); the panel narrows with
/// search and category filters rather than paging.
abstract class AdminRepository {
  Future<AdminOverview> overview();

  Future<List<AuditEntry>> recentActivity({int limit = 10});

  Future<List<AdminUser>> users({required PersonRole role, PersonSegment? segment, String? q, int limit = 100});

  Future<AdminUserDetail> userDetail(String userId);

  Future<void> setUserStatus(String userId, {required bool suspended, String? reason});

  Future<List<AdminCenter>> centers({String? status, bool? hasOperator, String? q, int limit = 100});

  Future<AdminCenter> center(String centerId);

  Future<List<StockItem>> centerStock(String centerId);

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
  });

  Future<void> setCenterSuspended(String centerId, {required bool suspended});

  /// Pass null to remove the center's operator.
  Future<void> assignOperator(String centerId, String? userId);

  Future<List<VillageOption>> searchVillages(String query);
}
