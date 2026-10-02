import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/auth/user_role.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../delivery/presentation/providers/document_picker.dart';
import '../../../farmer/profile/presentation/providers/profile_providers.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/role_selector.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole? _role;
  Uint8List? _photo;
  bool _isSubmitting = false;
  String? _error;

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: Tx('Take a photo'), onTap: () => Navigator.pop(context, 'camera')),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: Tx('Choose from gallery'), onTap: () => Navigator.pop(context, 'gallery')),
        if (_photo != null) ListTile(leading: const Icon(Icons.delete_outline), title: Tx('Remove photo'), onTap: () => Navigator.pop(context, 'remove')),
      ])),
    );
    if (choice == null) return;
    if (choice == 'remove') {
      setState(() => _photo = null);
      return;
    }
    final doc = await ref.read(documentPickerProvider).pick(camera: choice == 'camera');
    if (doc != null) setState(() => _photo = doc.bytes);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null) {
      setState(() => _error = 'Choose whether you are a farmer or an operator.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final result = await ref.read(authServiceProvider).signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            role: _role!,
          );
      if (!mounted) return;
      if (result == SignUpResult.confirmEmail) {
        // No session yet: the account exists but the email must be confirmed.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created. Check your email to confirm it, then sign in.'),
        ));
        context.go(RoutePaths.signIn);
      } else if (_photo != null) {
        // A session exists now: send the photo they chose, but never let a failure here undo the account that was just made.
        try {
          await ref.read(profileRepositoryProvider).uploadPhoto(_photo!);
        } catch (_) {
          // They can add it later from their profile.
        }
      }
      // Otherwise a session exists and the router's redirect takes over.
    } catch (err) {
      if (mounted) setState(() => _error = '$err');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AuthScaffold(
      title: context.t('Create your account'),
      subtitle: context.t('Join ShetSamrudhi in a minute'),
      form: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  key: const Key('signup-photo'),
                  onTap: _isSubmitting ? null : _pickPhoto,
                  child: Stack(children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: colors.surfaceSunken,
                      backgroundImage: _photo == null ? null : MemoryImage(_photo!),
                      child: _photo == null ? Icon(Icons.person_outline, size: 36, color: colors.textMuted) : null,
                    ),
                    Positioned(right: -2, bottom: -2, child: CircleAvatar(radius: 12, backgroundColor: colors.primary, child: const Icon(Icons.camera_alt, size: 14, color: Colors.white))),
                  ]),
                ),
              ),
              Center(child: Tx('Add a photo (optional)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted))),
              AppSpacing.gapMd,
              Tx('I am a', style: Theme.of(context).textTheme.labelLarge),
              AppSpacing.gapSm,
              RoleSelector(
                selected: _role,
                enabled: !_isSubmitting,
                onChanged: (r) => setState(() {
                  _role = r;
                  _error = null;
                }),
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                decoration: InputDecoration(
                  labelText: context.t('Full name'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
                decoration: InputDecoration(
                  labelText: context.t('Email'),
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
              ),
              AppSpacing.gapMd,
              PasswordField(
                controller: _password,
                label: 'Password (min 8 characters)',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
              ),
              AppSpacing.gapMd,
              PasswordField(
                controller: _confirm,
                label: 'Confirm password',
                onSubmitted: _submit,
                validator: (v) => v != _password.text ? 'Passwords do not match' : null,
              ),
              if (_error != null) ...[
                AppSpacing.gapMd,
                Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.danger)),
              ],
              AppSpacing.gapLg,
              AppButton(label: context.t('Create account'), expand: true, isLoading: _isSubmitting, onPressed: _submit),
            ],
          ),
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(context.t('Already have an account?'), style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
          TextButton(onPressed: () => context.go(RoutePaths.signIn), child: Text(context.t('Sign in'))),
        ],
      ),
    );
  }
}
