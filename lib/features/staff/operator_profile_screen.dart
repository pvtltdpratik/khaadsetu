import 'package:flutter/material.dart';
import '../../core/l10n/app_locale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/auth/farmer_mode.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/routing/route_paths.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import '../delivery/board/board_screen.dart';
import '../delivery/presentation/screens/delivery_hub_screen.dart';
import '../farmer/profile/presentation/screens/farm_details_screen.dart';
import '../vehicles/vehicles_screen.dart';

final operatorMeProvider = FutureProvider.autoDispose<Json>((ref) async => asJson(await ref.watch(apiClientProvider).get('/v1/operator/me')));

/// The operator's own profile: the payout account, storage, languages, and (because the same login is also a farmer) the
/// farm, vehicles and deliveries he can use as a farmer, kept apart from the center's own money and stock.
class OperatorProfileScreen extends ConsumerStatefulWidget {
  const OperatorProfileScreen({super.key});

  @override
  ConsumerState<OperatorProfileScreen> createState() => _OperatorProfileScreenState();
}

class _OperatorProfileScreenState extends ConsumerState<OperatorProfileScreen> {
  final _holder = TextEditingController();
  final _account = TextEditingController();
  final _ifsc = TextEditingController();
  final _upi = TextEditingController();
  final _storage = TextEditingController();
  final _about = TextEditingController();
  final _languages = <String>{};
  bool _loaded = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_holder, _account, _ifsc, _upi, _storage, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Json p) {
    if (_loaded) return;
    _loaded = true;
    _holder.text = p.str('bankHolder');
    _ifsc.text = p.str('bankIfsc');
    _upi.text = p.str('upiId');
    _storage.text = p.num_('storageCapacityKg') > 0 ? p.num_('storageCapacityKg').toStringAsFixed(0) : '';
    _about.text = p.str('about');
    _languages
      ..clear()
      ..addAll([for (final l in (p['languages'] as List? ?? const [])) '$l']);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).put('/v1/operator/profile', body: {
        'bankHolder': _holder.text.trim(),
        // Sent only when he types a new number: the saved one is never shown back in full.
        if (_account.text.trim().isNotEmpty) 'bankAccount': _account.text.trim(),
        'bankIfsc': _ifsc.text.trim(),
        'upiId': _upi.text.trim(),
        'storageCapacityKg': double.tryParse(_storage.text.trim()) ?? 0,
        'languages': _languages.toList(),
        'about': _about.text.trim(),
      });
      _account.clear();
      _loaded = false;
      ref.invalidate(operatorMeProvider);
      if (mounted) snack(context, 'Saved');
    } catch (e) {
      if (mounted) snack(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final me = ref.watch(operatorMeProvider);
    void open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    return Scaffold(
      appBar: AppBar(title: const Tx('My profile')),
      body: ResponsiveScope(
        child: me.when(
          skipLoadingOnReload: true,
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(operatorMeProvider)),
          data: (m) {
            final profile = m.obj('profile');
            _fill(profile);
            final center = m.obj('center');
            final kyc = profile.str('kycStatus');
            return ListView(padding: context.pagePadding, children: [
              KitCard(
                title: center.str('name'),
                icon: Icons.storefront_outlined,
                trailing: StatusPill(center.flag('isOpen') ? 'Open' : 'Closed', tone: center.flag('isOpen') ? Tone.good : Tone.neutral),
                child: KitRow('Village', center.str('village')),
              ),
              const KitCard(child: LanguageTile()),
              KitCard(
                index: 1,
                title: 'Payout account',
                icon: Icons.account_balance_outlined,
                trailing: StatusPill(kyc == 'verified' ? 'KYC verified' : (kyc == 'submitted' ? 'KYC being checked' : 'KYC not done'), tone: kyc == 'verified' ? Tone.good : (kyc == 'submitted' ? Tone.warn : Tone.neutral)),
                child: Column(children: [
                  TextField(key: const Key('op-holder'), controller: _holder, decoration: const InputDecoration(labelText: 'Account holder')),
                  AppSpacing.gapSm,
                  TextField(
                    key: const Key('op-account'),
                    controller: _account,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Account number', helperText: profile.str('bankAccountMasked').isEmpty ? null : 'Saved: ${profile.str('bankAccountMasked')} (type a new one to change it)'),
                  ),
                  AppSpacing.gapSm,
                  TextField(key: const Key('op-ifsc'), controller: _ifsc, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'IFSC code')),
                  AppSpacing.gapSm,
                  TextField(key: const Key('op-upi'), controller: _upi, decoration: const InputDecoration(labelText: 'UPI id', hintText: 'name@bank')),
                ]),
              ),
              KitCard(
                index: 2,
                title: 'The center',
                icon: Icons.warehouse_outlined,
                child: Column(children: [
                  TextField(controller: _storage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Storage room (kg)')),
                  AppSpacing.gapSm,
                  Align(alignment: Alignment.centerLeft, child: Text('Languages you speak', style: text.labelLarge)),
                  Wrap(spacing: 8, children: [
                    for (final l in const [('mr', 'मराठी'), ('hi', 'हिन्दी'), ('en', 'English')])
                      FilterChip(key: Key('lang-${l.$1}'), label: Text(l.$2), selected: _languages.contains(l.$1), onSelected: (on) => setState(() => on ? _languages.add(l.$1) : _languages.remove(l.$1))),
                  ]),
                  AppSpacing.gapSm,
                  TextField(controller: _about, maxLength: 500, maxLines: 3, decoration: const InputDecoration(labelText: 'About you (farmers can read this)')),
                ]),
              ),
              AppButton(key: const Key('op-save'), label: 'Save', expand: true, isLoading: _busy, onPressed: _save),
              AppSpacing.gapLg,
              KitCard(
                index: 3,
                title: 'Me as a farmer',
                icon: Icons.agriculture_outlined,
                child: Column(children: [
                  Text('You farm too. These use your own account as a farmer, and stay apart from the center\'s stock, sales and money. You cannot check your own vehicles or products; they go to another center.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                  AppButton(key: const Key('switch-farmer-mode'), label: 'Switch to farmer mode', icon: Icons.agriculture_outlined, expand: true, onPressed: () {
                    ref.read(farmerModeProvider.notifier).set(true);
                    GoRouter.of(context).go(RoutePaths.farmerHome);
                  }),
                  ListTile(key: const Key('op-farm'), contentPadding: EdgeInsets.zero, leading: const Icon(Icons.landscape_outlined), title: const Text('My farm'), trailing: const Icon(Icons.chevron_right), onTap: () => open(const FarmDetailsScreen())),
                  ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.local_shipping_outlined), title: const Tx('My vehicles'), trailing: const Icon(Icons.chevron_right), onTap: () => open(const VehiclesScreen())),
                  ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.route_outlined), title: const Tx('Deliver & Earn'), trailing: const Icon(Icons.chevron_right), onTap: () => open(const DeliveryBoardScreen())),
                  ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.delivery_dining_outlined), title: const Text('Deliver for others (partner)'), trailing: const Icon(Icons.chevron_right), onTap: () => open(const DeliveryHubScreen())),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
