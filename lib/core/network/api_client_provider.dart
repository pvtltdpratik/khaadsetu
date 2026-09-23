import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../auth/session_profile.dart';
import '../device/device_id_provider.dart';
import 'api_client.dart';

/// Shared by every feature's data source. The device id and access token
/// resolve lazily, per request, so building the client never waits on
/// `shared_preferences` or the network.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authServiceProvider);
  return ApiClient(
    deviceId: () => ref.read(deviceIdProvider.future),
    accessToken: auth.accessToken,
    // The router's redirect sends a signed-out user to the sign-in screen.
    onUnauthorized: () => auth.signOut().catchError((_) {}),
    // Re-ask the server who this is: it now says suspended, and the router
    // sends them to the suspended screen.
    onAccountSuspended: () => ref.invalidate(sessionProfileProvider),
  );
});
