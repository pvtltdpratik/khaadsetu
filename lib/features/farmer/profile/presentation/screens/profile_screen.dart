import 'package:flutter/material.dart';
import '../../../../own_products/my_listings_screen.dart';
import '../../../../../core/auth/farmer_mode.dart';
import '../../../../../core/l10n/app_locale.dart';
import '../../../../staff/activity_log_screen.dart';
import '../../../../own_products/own_market_screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/animation/motion.dart';
import '../../../../../core/animation/pressable.dart';
import '../../../../../core/auth/auth_providers.dart';
import '../../../../../core/auth/session_profile.dart';
import '../../../../../core/location/place_namer.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/update/update_controller.dart';
import '../../../../delivery/presentation/providers/document_picker.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/profile_providers.dart';

/// The account page, laid out like a shopping app's: who you are at the top, the
/// things you reach for most as tiles, then settings and the rest as a list.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(farmerProfileProvider).value;
    final contact = ref.watch(contactProvider).value;
    final place = ref.watch(currentPlaceProvider).value;
    final name = (profile?.name.isNotEmpty ?? false) ? profile!.name : 'Farmer';

    return ResponsiveScope(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            name: name,
            subtitle: [
              if (contact != null && contact.phone.isNotEmpty) contact.phone,
              if (contact != null && (contact.email.isNotEmpty || contact.loginEmail.isNotEmpty)) contact.email.isNotEmpty ? contact.email : contact.loginEmail,
            ].join('  ·  '),
            place: place?.short,
            onEdit: () => context.push(RoutePaths.farmerProfileContact),
          ),
          Padding(
            padding: context.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  index: 1,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 2.6,
                    children: [
                      _Tile(icon: Icons.receipt_long_outlined, label: 'My Orders', onTap: () => context.push(RoutePaths.farmerOrders)),
                      _Tile(icon: Icons.location_on_outlined, label: 'Addresses', onTap: () => context.push(RoutePaths.farmerProfileAddresses)),
                      _Tile(icon: Icons.forum_outlined, label: 'My Posts', onTap: () => context.push(RoutePaths.farmerProfileActivity)),
                      _Tile(icon: Icons.account_balance_outlined, label: 'Schemes', onTap: () => context.push(RoutePaths.farmerSchemes)),
                    ],
                  ),
                ),
                AppSpacing.gapMd,
                FadeSlideIn(
                  index: 2,
                  child: _Section(title: 'Account settings', children: [
                    _Row(icon: Icons.person_outline, title: 'Edit profile', subtitle: 'Name, mobile number and email', onTap: () => context.push(RoutePaths.farmerProfileContact)),
                    _Row(icon: Icons.home_work_outlined, title: 'Saved addresses', subtitle: 'Home, farm and other places', onTap: () => context.push(RoutePaths.farmerProfileAddresses)),
                    _Row(icon: Icons.agriculture_outlined, title: 'Farm & scheme details', subtitle: 'Answer once, use for every scheme', onTap: () => context.push(RoutePaths.farmerProfileFarm)),
                    _Row(icon: Icons.my_location_outlined, title: 'My location', subtitle: place?.short ?? 'Use GPS or choose a village', onTap: () => context.push(RoutePaths.farmerChooseVillage)),
                  ]),
                ),
                AppSpacing.gapMd,
                FadeSlideIn(
                  index: 3,
                  child: _Section(title: 'Sell, earn and grow', children: [
                    const LanguageTile(),
                    if (ref.watch(farmerModeProvider))
                      _Row(icon: Icons.storefront_outlined, title: 'Back to center mode', subtitle: 'Return to your village center dashboard', onTap: () {
                        ref.read(farmerModeProvider.notifier).set(false);
                        context.go(RoutePaths.operatorDashboard);
                      }),
                    _Row(icon: Icons.history, title: 'My activity', subtitle: 'What you did in the app, and when', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ActivityLogScreen()))),
                    _Row(icon: Icons.eco_outlined, title: 'Sell what I make', subtitle: 'Compost, vermicompost, jeevamrut: checked by a village center', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MyListingsScreen()))),
                    _Row(icon: Icons.storefront_outlined, title: 'Farmer-made products', subtitle: 'Buy organic products from farmers near you', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OwnMarketScreen()))),
                    _Row(icon: Icons.recycling_outlined, title: 'Sell surplus fertilizer', subtitle: 'Get money back for what you did not use', onTap: () => context.push(RoutePaths.farmerSellSurplus)),
                    _Row(icon: Icons.account_balance_wallet_outlined, title: 'My wallet', subtitle: 'Earnings and refunds', onTap: () => context.push(RoutePaths.farmerWallet)),
                    _Row(icon: Icons.fact_check_outlined, title: 'My fertilizer log', subtitle: 'Log results, earn coins, coupons and badges', onTap: () => context.push(RoutePaths.farmerLog)),
                    _Row(icon: Icons.receipt_long_outlined, title: 'My bills', subtitle: 'Bills for what you bought, sold and delivered', onTap: () => context.push(RoutePaths.farmerBills)),
                    _Row(icon: Icons.notifications_active_outlined, title: 'Notification settings', subtitle: 'Choose what buzzes your phone, and quiet hours', onTap: () => context.push(RoutePaths.farmerNotificationSettings)),
                    _Row(icon: Icons.eco_outlined, title: 'Organic certification', subtitle: 'PGS-India: steps, rules and your progress', onTap: () => context.push(RoutePaths.farmerOrganic)),
                    _Row(icon: Icons.calculate_outlined, title: 'Profit calculator', subtitle: 'Will a fertilizer pay for itself?', onTap: () => context.push(RoutePaths.farmerCalculator)),
                    _Row(icon: Icons.local_shipping_outlined, title: 'Deliver & Earn', subtitle: 'Carry loads for other farmers', onTap: () => context.push(RoutePaths.farmerDeliver)),
                    _Row(icon: Icons.inventory_2_outlined, title: 'Send a Load', subtitle: 'Have something carried for you', onTap: () => context.push(RoutePaths.farmerLoads)),
                  ]),
                ),
                AppSpacing.gapMd,
                FadeSlideIn(
                  index: 4,
                  child: _Section(title: 'More', children: [
                    _Row(icon: Icons.smart_toy_outlined, title: 'Farming assistant', subtitle: 'Ask in Marathi, Hindi or English', onTap: () => context.push(RoutePaths.farmerAssistant)),
                    _Row(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () => context.push(RoutePaths.farmerNotifications)),
                    _Row(icon: Icons.history_outlined, title: 'Soil scan history', onTap: () => context.push(RoutePaths.farmerSoilScanHistory)),
                    _Row(
                      key: const Key('profile-check-for-updates'),
                      icon: Icons.system_update_alt_rounded,
                      title: 'Check for updates',
                      subtitle: 'See if a newer version is ready to install',
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(updateControllerProvider.notifier).check(force: true);
                        if (ref.read(updateControllerProvider).phase == UpdatePhase.idle) {
                          messenger.showSnackBar(const SnackBar(content: Text("You're already on the latest version")));
                        }
                      },
                    ),
                  ]),
                ),
                AppSpacing.gapMd,
                OutlinedButton.icon(
                  key: const Key('profile-sign-out'),
                  style: OutlinedButton.styleFrom(foregroundColor: colors.danger, minimumSize: const Size.fromHeight(AppTouchTarget.min)),
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    ref.invalidate(sessionProfileProvider);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
                AppSpacing.gapLg,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.subtitle, required this.place, required this.onEdit});

  final String name;
  final String subtitle;
  final String? place;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.primary.withValues(alpha: 0.82)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _ProfilePhoto(name: name),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, key: const Key('profile-name'), style: text.titleLarge?.copyWith(color: colors.onPrimary), overflow: TextOverflow.ellipsis),
                  if (subtitle.isNotEmpty) Text(subtitle, style: text.bodySmall?.copyWith(color: colors.onPrimary.withValues(alpha: 0.9)), overflow: TextOverflow.ellipsis),
                  if (place != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.location_on, size: 14, color: colors.onPrimary.withValues(alpha: 0.9)),
                        const SizedBox(width: 2),
                        Flexible(child: Text(place!, style: text.bodySmall?.copyWith(color: colors.onPrimary.withValues(alpha: 0.9)), overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                ],
              ),
            ),
            IconButton(onPressed: onEdit, icon: Icon(Icons.edit_outlined, color: colors.onPrimary), tooltip: 'Edit profile'),
          ],
        ),
      ),
    );
  }
}

/// The farmer's own photo if they set one, else their initial. Tapping it offers to take or choose one,
/// or remove it: entirely optional, so there is never a wrong state here.
class _ProfilePhoto extends ConsumerWidget {
  const _ProfilePhoto({required this.name});

  final String name;

  Future<void> _change(BuildContext context, WidgetRef ref, bool hasPhoto) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: Tx('Take a photo'), onTap: () => Navigator.pop(context, 'camera')),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: Tx('Choose from gallery'), onTap: () => Navigator.pop(context, 'gallery')),
        if (hasPhoto) ListTile(leading: const Icon(Icons.delete_outline), title: Tx('Remove photo'), onTap: () => Navigator.pop(context, 'remove')),
      ])),
    );
    if (choice == null) return;
    try {
      if (choice == 'remove') {
        await ref.read(profileRepositoryProvider).removePhoto();
      } else {
        final doc = await ref.read(documentPickerProvider).pick(camera: choice == 'camera');
        if (doc == null) return;
        await ref.read(profileRepositoryProvider).uploadPhoto(doc.bytes);
      }
      ref.invalidate(farmerPhotoProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final photo = ref.watch(farmerPhotoProvider).value;
    return GestureDetector(
      key: const Key('profile-photo'),
      onTap: () => _change(context, ref, photo != null),
      child: Pressable(
        child: Stack(children: [
          AnimatedSwitcher(
            duration: Motion.medium,
            switchInCurve: Motion.pop,
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
            child: CircleAvatar(
              key: ValueKey(photo?.lengthInBytes ?? 0),
              radius: 32,
              backgroundColor: colors.onPrimary.withValues(alpha: 0.2),
              backgroundImage: photo == null ? null : MemoryImage(photo),
              child: photo == null ? Text(name.characters.first.toUpperCase(), style: text.headlineMedium?.copyWith(color: colors.onPrimary)) : null,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: CircleAvatar(radius: 12, backgroundColor: colors.onPrimary, child: Icon(Icons.camera_alt, size: 14, color: colors.primary)),
          ),
        ]),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.textMuted)),
        ),
        Container(
          decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.divider),
              children[i],
            ],
          ]),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({super.key, required this.icon, required this.title, required this.onTap, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: Icon(icon, color: context.colors.primary),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
