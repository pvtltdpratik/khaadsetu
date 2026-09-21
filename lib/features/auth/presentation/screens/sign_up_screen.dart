import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/auth_scaffold.dart';

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
  bool _isSubmitting = false;
  String? _error;

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
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final result = await ref.read(authServiceProvider).signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
      if (!mounted) return;
      if (result == SignUpResult.confirmEmail) {
        // No session yet: the account exists but the email must be confirmed.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created. Check your email to confirm it, then sign in.'),
        ));
        context.go(RoutePaths.signIn);
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
      title: 'Create your account',
      subtitle: 'Join ShetSamrudhi in a minute',
      form: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              AppSpacing.gapMd,
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
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
              AppButton(label: 'Create account', expand: true, isLoading: _isSubmitting, onPressed: _submit),
            ],
          ),
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Already have an account?', style: Theme.of(context).textTheme.bodyMedium),
          TextButton(onPressed: () => context.go(RoutePaths.signIn), child: const Text('Sign in')),
        ],
      ),
    );
  }
}
