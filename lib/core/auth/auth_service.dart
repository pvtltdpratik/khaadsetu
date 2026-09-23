import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_role.dart';

/// Thrown for any failed auth call, with a message worded for the UI.
class AuthFailure implements Exception {
  AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Result of [AuthService.signUp]. Supabase can be configured to require
/// email confirmation first, in which case no session exists yet.
enum SignUpResult { signedIn, confirmEmail }

/// Thin wrapper over Supabase Auth so screens never touch the SDK directly
/// and every failure arrives as a readable [AuthFailure].
class AuthService {
  const AuthService(this._auth);

  final GoTrueClient _auth;

  Session? get currentSession => _auth.currentSession;
  User? get currentUser => _auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// The signed-in user's role, or null for a signed-out user or an account
  /// created before roles existed.
  UserRole? get currentRole => UserRole.fromMetadata(_auth.currentUser?.userMetadata);

  /// Saves the role on the account (used by the one-time chooser). The SDK
  /// emits a user-updated event, which re-runs the router's redirect.
  Future<void> setRole(UserRole role) {
    return _guard(() => _auth.updateUser(UserAttributes(data: {UserRole.metadataKey: role.name})));
  }

  Future<void> signIn({required String email, required String password}) {
    return _guard(() => _auth.signInWithPassword(email: email.trim(), password: password));
  }

  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final response = await _guard(() => _auth.signUp(
          email: email.trim(),
          password: password,
          data: {'full_name': name.trim(), UserRole.metadataKey: role.name},
        ));
    // An address that is already registered comes back as a user with no
    // identities (Supabase hides it to avoid revealing who has an account).
    if (response.user?.identities?.isEmpty ?? false) {
      throw AuthFailure('An account with this email already exists. Try signing in instead.');
    }
    return response.session != null ? SignUpResult.signedIn : SignUpResult.confirmEmail;
  }

  Future<void> signOut() => _guard(() => _auth.signOut());

  /// A valid access token for the API, or null when signed out. The SDK
  /// refreshes tokens in the background; this covers the gap when the app
  /// resumes with an already-expired one.
  Future<String?> accessToken() async {
    var session = _auth.currentSession;
    if (session == null) return null;
    if (session.isExpired) {
      try {
        session = (await _auth.refreshSession()).session;
      } catch (_) {
        return null;
      }
    }
    return session?.accessToken;
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AuthException catch (e) {
      throw AuthFailure(_friendly(e));
    } catch (_) {
      throw AuthFailure("Couldn't reach the sign-in service. Check your internet connection and try again.");
    }
  }

  String _friendly(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) return 'Incorrect email or password.';
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email first. Check your inbox for the confirmation link.';
    }
    if (message.contains('already registered')) return 'An account with this email already exists. Try signing in instead.';
    if (message.contains('rate limit') || e.statusCode == '429') {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (message.contains('password')) return e.message;
    return e.message;
  }
}
