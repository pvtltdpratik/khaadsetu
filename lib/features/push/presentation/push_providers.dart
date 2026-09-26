import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_profile.dart';
import '../../../core/flavor/app_flavor.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/push/push_config.dart';
import '../../../core/push/push_service.dart';
import '../data/push_api_repository.dart';
import '../domain/push_models.dart';
import '../domain/push_repository.dart';

final pushRepositoryProvider = Provider<PushRepository>((ref) => PushApiRepository(ref.watch(apiClientProvider)));

/// The real Firebase service when this build has the Firebase values, otherwise one that does nothing.
final pushServiceProvider = Provider<PushService>((ref) {
  final options = PushConfig.optionsFor(ref.watch(appFlavorProvider));
  return options == null ? const NoopPushService() : FirebasePushService(options);
});

final notificationSettingsProvider = FutureProvider.autoDispose<NotificationSettings>((ref) => ref.watch(pushRepositoryProvider).settings());

/// Keeps this phone registered with the server while somebody is signed in: hands over the token, refreshes it when
/// Firebase changes it, and takes it back on sign-out so the next person on this phone does not get the last one's alerts.
class PushRegistration {
  PushRegistration(this._ref);

  final Ref _ref;
  String? _token;
  bool _running = false;

  Future<void> start({required PushOpened onOpened}) async {
    if (_running) return;
    _running = true;
    final flavor = _ref.read(appFlavorProvider);
    await _ref.read(pushServiceProvider).start(
      onOpened: onOpened,
      onToken: (token) async {
        _token = token;
        try {
          await _ref.read(pushRepositoryProvider).registerDevice(token: token, app: PushConfig.appNameFor(flavor));
        } catch (_) {
          // The server can be unreachable for a moment: the token is registered again the next time the app starts.
        }
      },
    );
  }

  /// Called before signing out, while the session still works.
  Future<void> forget() async {
    final token = _token;
    _running = false;
    _token = null;
    if (token != null) {
      try {
        await _ref.read(pushRepositoryProvider).unregisterDevice(token);
      } catch (_) {}
    }
    await _ref.read(pushServiceProvider).stop();
  }
}

final pushRegistrationProvider = Provider<PushRegistration>((ref) => PushRegistration(ref));

/// Wraps the app: starts push once somebody is signed in. [onOpened] is where a tapped notification should lead.
class PushRegistrar extends ConsumerStatefulWidget {
  const PushRegistrar({super.key, required this.child, required this.onOpened});

  final Widget child;
  final PushOpened onOpened;

  @override
  ConsumerState<PushRegistrar> createState() => _PushRegistrarState();
}

class _PushRegistrarState extends ConsumerState<PushRegistrar> {
  void _maybeStart(AsyncValue<SessionProfile?> session) {
    if (session.value != null) unawaited(ref.read(pushRegistrationProvider).start(onOpened: widget.onOpened));
  }

  @override
  void initState() {
    super.initState();
    // Already signed in when the app opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeStart(ref.read(sessionProfileProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Signing in while the app is open.
    ref.listen<AsyncValue<SessionProfile?>>(sessionProfileProvider, (previous, next) => _maybeStart(next));
    return widget.child;
  }
}
