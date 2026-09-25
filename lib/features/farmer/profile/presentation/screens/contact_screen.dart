import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/profile_providers.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
final _phonePattern = RegExp(r'^\+?[0-9][0-9 -]{7,14}[0-9]$');

/// Name, mobile number and email. The login email is shown but fixed; the email here is
/// only where the platform writes to.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(contactProvider);
    final profile = ref.watch(farmerProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ResponsiveScope(
        child: contact.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(contactProvider)),
          data: (info) => _ContactForm(
            initialName: profile.value?.name == 'Farmer' ? '' : (profile.value?.name ?? ''),
            initialEmail: info.email,
            initialPhone: info.phone,
            loginEmail: info.loginEmail,
          ),
        ),
      ),
    );
  }
}

class _ContactForm extends ConsumerStatefulWidget {
  const _ContactForm({required this.initialName, required this.initialEmail, required this.initialPhone, required this.loginEmail});

  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String loginEmail;

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _email = TextEditingController(text: widget.initialEmail);
  late final _phone = TextEditingController(text: widget.initialPhone);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);
    try {
      if (_name.text.trim().isNotEmpty) await repo.saveName(_name.text.trim());
      await repo.saveContact(email: _email.text.trim(), phone: _phone.text.trim());
      ref.invalidate(contactProvider);
      ref.invalidate(farmerProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
      setState(() => _saving = false);
      Navigator.of(context).maybePop();
    } catch (err) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Form(
      key: _form,
      child: ListView(
        padding: context.pagePadding,
        children: [
          TextFormField(
            key: const Key('contact-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => (v ?? '').length > 80 ? 'Keep it under 80 characters' : null,
          ),
          AppSpacing.gapMd,
          TextFormField(
            key: const Key('contact-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined), helperText: 'Centers and delivery partners call this number'),
            validator: (v) => (v ?? '').trim().isEmpty || _phonePattern.hasMatch(v!.trim()) ? null : 'Enter a valid mobile number',
          ),
          AppSpacing.gapMd,
          TextFormField(
            key: const Key('contact-email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline), helperText: 'For receipts and updates'),
            validator: (v) => (v ?? '').trim().isEmpty || _emailPattern.hasMatch(v!.trim()) ? null : 'Enter a valid email address',
          ),
          if (widget.loginEmail.isNotEmpty) ...[
            AppSpacing.gapMd,
            Row(children: [
              Icon(Icons.lock_outline, size: 16, color: colors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('You sign in with ${widget.loginEmail}. That does not change.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted))),
            ]),
          ],
          AppSpacing.gapLg,
          AppButton(label: 'Save', expand: true, isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
