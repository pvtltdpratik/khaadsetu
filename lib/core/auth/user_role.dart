/// What a person asks to be at sign-up (farmer or operator), stored in their
/// Supabase metadata under [metadataKey]. It is only a REQUEST: the server
/// decides the real role (see `AppRole`), because metadata is user-editable.
enum UserRole {
  farmer,
  operator;

  static const metadataKey = 'role';

  String get label => switch (this) {
        UserRole.farmer => 'Farmer',
        UserRole.operator => 'Village Center Operator',
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
