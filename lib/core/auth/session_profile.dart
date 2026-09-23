import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client_provider.dart';
import '../routing/route_paths.dart';
import 'auth_providers.dart';

/// What the SERVER says this person is. It is decided from the server's own
/// records (an admin's email, a center they own), never from the role picked
/// at sign-up, which is only a request.
enum AppRole {
  admin,
  operator,
  farmer;

  static AppRole parse(Object? raw) => AppRole.values.firstWhere((r) => r.name == raw, orElse: () => AppRole.farmer);
}

class SessionCenter extends Equatable {
  const SessionCenter({required this.centerId, required this.name, required this.status});

  final String centerId;
  final String name;
  final String status;

  @override
  List<Object?> get props => [centerId, name, status];
}

/// The signed-in user as the API sees them (`GET /v1/me`).
class SessionProfile extends Equatable {
  const SessionProfile({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.requestedRole,
    required this.status,
    this.center,
  });

  factory SessionProfile.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as Map<String, dynamic>?;
    return SessionProfile(
      userId: json['userId'] as String,
      email: (json['email'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      role: AppRole.parse(json['role']),
      requestedRole: (json['requestedRole'] as String?) ?? 'farmer',
      status: (json['status'] as String?) ?? 'active',
      center: center == null
          ? null
          : SessionCenter(
              centerId: center['centerId'] as String,
              name: center['name'] as String,
              status: center['status'] as String,
            ),
    );
  }

  final String userId;
  final String email;
  final String name;
  final AppRole role;

  /// What they chose at sign-up: 'farmer' or 'operator'.
  final String requestedRole;
  final String status;
  final SessionCenter? center;

  bool get isSuspended => status == 'suspended';

  /// Signed up as an operator but no administrator has given them a center yet.
  bool get isPendingOperator => role == AppRole.farmer && requestedRole == 'operator';

  @override
  List<Object?> get props => [userId, email, name, role, requestedRole, status, center];
}

/// The signed-in user's id, or null when signed out. Changes on sign-in and
/// sign-out only (repeated token refreshes for the same user don't re-emit).
final authUserIdProvider = StreamProvider<String?>((ref) async* {
  final auth = ref.watch(authServiceProvider);
  yield auth.currentUser?.id;
  await for (final state in auth.onAuthStateChange) {
    yield state.session?.user.id;
  }
});

/// The signed-in user's server-side profile, or null when signed out. Loading
/// (or an error) keeps the router on the gate screen until it is known.
final FutureProvider<SessionProfile?> sessionProfileProvider = FutureProvider<SessionProfile?>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) return null;
  final json = await ref.watch(apiClientProvider).get('/v1/me') as Map<String, dynamic>;
  return SessionProfile.fromJson(json);
});

/// Where a signed-in user must be sent from [location], or null to leave them.
/// [me] is null while their profile is still loading (or failed): until we
/// know who they are, the only place to be is the gate screen at the root.
///
/// Pure so every rule can be unit-tested without a router.
String? redirectForSession(SessionProfile? me, String location) {
  bool within(String prefix) => location == prefix || location.startsWith('$prefix/');

  if (me == null) return location == RoutePaths.root ? null : RoutePaths.root;
  if (me.isSuspended) return location == RoutePaths.suspended ? null : RoutePaths.suspended;

  final String home;
  final bool allowed;
  switch (me.role) {
    case AppRole.admin:
      home = RoutePaths.adminOverview;
      allowed = within(RoutePaths.adminRoot);
    case AppRole.operator:
      home = RoutePaths.operatorDashboard;
      allowed = within(RoutePaths.operatorRoot);
    case AppRole.farmer when me.isPendingOperator:
      home = RoutePaths.pendingOperator;
      allowed = location == RoutePaths.pendingOperator;
    case AppRole.farmer:
      home = RoutePaths.farmerHome;
      allowed = within(RoutePaths.farmerRoot);
  }
  return allowed ? null : home;
}
