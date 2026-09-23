import '../routing/route_paths.dart';

/// Which app an account uses. Chosen at sign-up and stored in the Supabase
/// user's metadata under [metadataKey].
enum UserRole {
  farmer,
  operator;

  static const metadataKey = 'role';

  String get label => switch (this) {
        UserRole.farmer => 'Farmer',
        UserRole.operator => 'Village Center Operator',
      };

  String get homePath => switch (this) {
        UserRole.farmer => RoutePaths.farmerHome,
        UserRole.operator => RoutePaths.operatorDashboard,
      };

  /// The role in a user's metadata, or null when absent or unrecognised
  /// (accounts created before roles existed have none).
  static UserRole? fromMetadata(Map<String, dynamic>? metadata) {
    final raw = metadata?[metadataKey];
    for (final role in values) {
      if (role.name == raw) return role;
    }
    return null;
  }
}

/// Where a signed-in user with [role] must be sent from [location], or null
/// to leave them where they are. Kept pure so it can be unit-tested without
/// a router.
///
/// - No role yet: only the root (role chooser) is reachable.
/// - Has a role: the root is skipped, and the other role's app is off limits.
String? redirectForRole(UserRole? role, String location) {
  final inFarmerApp = location == RoutePaths.farmerRoot || location.startsWith('${RoutePaths.farmerRoot}/');
  final inOperatorApp = location == RoutePaths.operatorRoot || location.startsWith('${RoutePaths.operatorRoot}/');

  if (role == null) {
    return location == RoutePaths.root ? null : RoutePaths.root;
  }
  if (location == RoutePaths.root) return role.homePath;
  if (role == UserRole.farmer && inOperatorApp) return role.homePath;
  if (role == UserRole.operator && inFarmerApp) return role.homePath;
  return null;
}
