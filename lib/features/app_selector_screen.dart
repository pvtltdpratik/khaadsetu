import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_providers.dart';
import '../core/auth/user_role.dart';
import '../core/responsive/responsive.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_button.dart';
import 'auth/presentation/widgets/role_selector.dart';

/// One-time role chooser. New accounts pick a role at sign-up, so the router
/// only lands here for accounts created before roles existed. Saving the role
/// updates the user, which makes the router redirect into the right app.
class AppSelectorScreen extends ConsumerStatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  ConsumerState<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends ConsumerState<AppSelectorScreen> {
  UserRole? _role;
  bool _saving = false;
  String? _error;

  Future<void> _continue() async {
    final role = _role;
    if (role == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).setRole(role);
      // The router reacts to the user update and redirects into the app.
    } catch (err) {
      if (mounted) setState(() => _error = '$err');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final displayName = (user?.userMetadata?['full_name'] as String?) ?? user?.email ?? '';
    final colors = context.colors;
    return Scaffold(
      body: ResponsiveScope(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ContentContainer(
                maxWidth: 640,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.eco_rounded, size: context.responsive(mobile: 56.0, tablet: 72.0), color: colors.primary),
                    AppSpacing.gapMd,
                    Text('ShetSamrudhi', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                    AppSpacing.gapXs,
                    Text(
                      displayName.isEmpty
                          ? 'How will you use the app?'
                          : 'Welcome, $displayName. How will you use the app?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                    ),
                    AppSpacing.gapXl,
                    RoleSelector(selected: _role, enabled: !_saving, onChanged: (r) => setState(() => _role = r)),
                    if (_error != null) ...[
                      AppSpacing.gapMd,
                      Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.danger)),
                    ],
                    AppSpacing.gapLg,
                    AppButton(label: 'Continue', expand: true, isLoading: _saving, onPressed: _role == null ? null : _continue),
                    AppSpacing.gapSm,
                    TextButton.icon(
                      onPressed: _saving ? null : () => ref.read(authServiceProvider).signOut(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
