import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../data/repositories/admin_api_repository.dart';
import '../../domain/entities/admin_models.dart';
import '../../domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminApiRepository(ref.watch(apiClientProvider)));

final adminOverviewProvider = FutureProvider.autoDispose<AdminOverview>((ref) => ref.watch(adminRepositoryProvider).overview());

final adminRecentActivityProvider =
    FutureProvider.autoDispose<List<AuditEntry>>((ref) => ref.watch(adminRepositoryProvider).recentActivity(limit: 8));

/// A people list's filters. Equatable so the same filters share one cached result.
class PeopleQuery extends Equatable {
  const PeopleQuery({required this.role, this.segment, this.q = ''});

  final PersonRole role;
  final PersonSegment? segment;
  final String q;

  @override
  List<Object?> get props => [role, segment, q];
}

final adminUsersProvider = FutureProvider.autoDispose.family<List<AdminUser>, PeopleQuery>(
  (ref, query) => ref.watch(adminRepositoryProvider).users(role: query.role, segment: query.segment, q: query.q),
);

final adminUserDetailProvider = FutureProvider.autoDispose.family<AdminUserDetail, String>(
  (ref, userId) => ref.watch(adminRepositoryProvider).userDetail(userId),
);

class CentersQuery extends Equatable {
  const CentersQuery({this.status, this.hasOperator, this.q = ''});

  final String? status;
  final bool? hasOperator;
  final String q;

  @override
  List<Object?> get props => [status, hasOperator, q];
}

final adminCentersProvider = FutureProvider.autoDispose.family<List<AdminCenter>, CentersQuery>(
  (ref, query) => ref.watch(adminRepositoryProvider).centers(status: query.status, hasOperator: query.hasOperator, q: query.q),
);

final adminCenterProvider = FutureProvider.autoDispose.family<AdminCenter, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).center(id),
);

final adminCenterStockProvider = FutureProvider.autoDispose.family<List<StockItem>, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).centerStock(id),
);

/// Operators who could be given a center: signed up, none assigned, in good standing.
final unassignedOperatorsProvider = FutureProvider.autoDispose<List<AdminUser>>(
  (ref) => ref.watch(adminRepositoryProvider).users(role: PersonRole.operator, segment: PersonSegment.unassigned),
);

/// Active centers with nobody running them.
final centersWithoutOperatorProvider = FutureProvider.autoDispose<List<AdminCenter>>(
  (ref) => ref.watch(adminRepositoryProvider).centers(status: 'active', hasOperator: false),
);

/// After any change, everything the panel shows may be stale.
void refreshAdminData(WidgetRef ref) {
  ref
    ..invalidate(adminOverviewProvider)
    ..invalidate(adminRecentActivityProvider)
    ..invalidate(adminUsersProvider)
    ..invalidate(adminUserDetailProvider)
    ..invalidate(adminCentersProvider)
    ..invalidate(adminCenterProvider)
    ..invalidate(adminCenterStockProvider)
    ..invalidate(unassignedOperatorsProvider)
    ..invalidate(centersWithoutOperatorProvider);
}
