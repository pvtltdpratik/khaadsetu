import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/session_profile.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/sign_out_button.dart';

/// The test APK's front door: three big buttons, one per dashboard.
///
/// Which dashboard an account may use is decided by the SERVER (an admin is
/// whoever is on `SUPER_ADMIN_EMAILS`, an operator owns a village center), so a
/// button only opens the dashboard the signed-in account really has. Tapping
/// another one says what to do to test it. Dashboards open on top of this screen,
/// so the back button returns here.
class DevRolePickerScreen extends ConsumerWidget {
  const DevRolePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(sessionProfileProvider);
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Choose a dashboard'), actions: const [SignOutButton()]),
        body: SafeArea(
          child: profile.when(
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(sessionProfileProvider)),
            data: (me) => me == null ? const AppLoadingIndicator() : _Body(me: me),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.me});

  final SessionProfile me;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final pendingOperator = me.isPendingOperator;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        ContentContainer(
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(color: Colors.deepOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.science_outlined, color: Colors.deepOrange),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('DEV BUILD: for testing only', style: text.titleSmall?.copyWith(color: Colors.deepOrange))),
                ]),
              ),
              AppSpacing.gapMd,
              Text(me.name.isEmpty ? me.email : me.name, key: const Key('dev-account'), style: text.titleMedium),
              Text('Signed in as a ${roleLabel(me)}', key: const Key('dev-role'), style: text.bodyMedium?.copyWith(color: colors.textMuted)),
              AppSpacing.gapLg,
              _RoleButton(
                keyName: 'farmer',
                icon: Icons.agriculture_rounded,
                label: 'Farmer Dashboard',
                available: me.role == AppRole.farmer && !pendingOperator,
                open: () => context.push(RoutePaths.farmerHome),
                howToTest: 'Sign in with an ordinary farmer account.',
              ),
              AppSpacing.gapMd,
              _RoleButton(
                keyName: 'center',
                icon: Icons.storefront_rounded,
                label: 'Center Dashboard',
                available: me.role == AppRole.operator || pendingOperator,
                open: () => context.push(pendingOperator ? RoutePaths.pendingOperator : RoutePaths.operatorDashboard),
                howToTest: 'Sign in with an account that owns a village center. An admin can create the center and assign it to the account.',
              ),
              AppSpacing.gapMd,
              _RoleButton(
                keyName: 'admin',
                icon: Icons.admin_panel_settings_rounded,
                label: 'Admin Dashboard',
                available: me.role == AppRole.admin,
                open: () => context.push(RoutePaths.adminOverview),
                howToTest: 'Sign in with an email listed in SUPER_ADMIN_EMAILS on the server.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({required this.keyName, required this.icon, required this.label, required this.available, required this.open, required this.howToTest});

  final String keyName;
  final IconData icon;
  final String label;
  final bool available;
  final VoidCallback open;
  final String howToTest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 96,
      child: FilledButton.icon(
        key: Key('dev-open-$keyName'),
        style: FilledButton.styleFrom(
          backgroundColor: available ? colors.primary : colors.surfaceSunken,
          foregroundColor: available ? colors.onPrimary : colors.textMuted,
          textStyle: Theme.of(context).textTheme.titleMedium,
        ),
        onPressed: available
            ? open
            : () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Not for this account'),
                    content: Text('This account cannot open the $label. $howToTest'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                  ),
                ),
        icon: Icon(available ? icon : Icons.lock_outline_rounded, size: 32),
        label: Text(label),
      ),
    );
  }
}
