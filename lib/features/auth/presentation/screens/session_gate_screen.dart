import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/session_profile.dart';
import '../../../../core/flavor/app_flavor.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';

/// Shown right after sign-in while the app asks the server who this person is.
/// Once the answer arrives the router moves them to the right place, so this
/// screen is only ever seen while loading, or if the lookup failed.
class SessionGateScreen extends ConsumerWidget {
  const SessionGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(sessionProfileProvider);
    return Scaffold(
      body: SafeArea(
        child: profile.when(
          data: (_) => const AppLoadingIndicator(),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => Column(
            children: [
              Expanded(child: AppErrorView(message: '$err', onRetry: () => ref.invalidate(sessionProfileProvider))),
              TextButton.icon(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
              AppSpacing.gapMd,
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-page message with a sign-out, for account states the person can't
/// act on themselves.
class _AccountStateScreen extends ConsumerWidget {
  const _AccountStateScreen({required this.icon, required this.iconColor, required this.title, required this.message, this.onRefresh});

  final IconData icon;
  final Color Function(AppColorTokens) iconColor;
  final String title;
  final String message;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ContentContainer(
              maxWidth: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 64, color: iconColor(colors)),
                  AppSpacing.gapMd,
                  Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  AppSpacing.gapSm,
                  Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
                  AppSpacing.gapLg,
                  if (onRefresh != null) ...[
                    AppButton(label: 'Check again', icon: Icons.refresh_rounded, expand: true, onPressed: onRefresh),
                    AppSpacing.gapSm,
                  ],
                  TextButton.icon(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The account was suspended by an administrator.
class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => _AccountStateScreen(
        icon: Icons.block_rounded,
        iconColor: (c) => c.danger,
        title: 'Account suspended',
        message: 'An administrator has suspended this account, so you can\'t use the app right now. '
            'Please contact the platform administrator.',
        onRefresh: () => ref.invalidate(sessionProfileProvider),
      ),
    );
  }
}

/// Signed in with a kind of account this APK is not for.
class WrongAppScreen extends StatelessWidget {
  const WrongAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final me = ref.watch(sessionProfileProvider).value;
        final flavor = ref.watch(appFlavorProvider);
        final theirs = me == null ? 'a different kind of account' : 'a ${roleLabel(me)} account';
        final use = switch (me?.role) {
          AppRole.admin => 'the Admin app',
          AppRole.operator => 'the Center app',
          _ => me?.isPendingOperator == true ? 'the Center app' : 'the Farmer app',
        };
        return _AccountStateScreen(
          icon: Icons.phonelink_lock_rounded,
          iconColor: (c) => c.warning,
          title: 'This is the wrong app for this account',
          message: 'You are signed in with $theirs, but this is ${flavor.title}. Please use $use, or sign out and sign in with a different account.',
        );
      },
    );
  }
}

/// Signed up as an operator, but no village center has been assigned yet.
class PendingOperatorScreen extends StatelessWidget {
  const PendingOperatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => _AccountStateScreen(
        icon: Icons.hourglass_top_rounded,
        iconColor: (c) => c.warning,
        title: 'Waiting for a village center',
        message: 'Your operator account is ready. The platform administrator needs to assign you a village center '
            'before you can start. You\'ll be taken in automatically once that happens; tap "Check again" to see now.',
        onRefresh: () => ref.invalidate(sessionProfileProvider),
      ),
    );
  }
}
