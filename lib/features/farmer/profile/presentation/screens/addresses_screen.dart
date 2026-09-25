import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/profile_models.dart';
import '../providers/profile_providers.dart';

/// The farmer's saved addresses. With [onPick] set (choosing where to deliver) tapping one
/// returns it instead of opening it for editing.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key, this.pick = false});

  final bool pick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(pick ? 'Choose an address' : 'Saved addresses')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-address'),
        onPressed: () => context.push(RoutePaths.farmerProfileAddressNew),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add address'),
      ),
      body: ResponsiveScope(
        child: addresses.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(addressesProvider)),
          data: (list) => list.isEmpty
              ? const _Empty()
              : ListView.separated(
                  padding: context.pagePadding.copyWith(bottom: 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => AppSpacing.gapSm,
                  itemBuilder: (context, i) => FadeSlideIn(
                    index: i,
                    child: _AddressCard(
                      address: list[i],
                      onTap: pick ? () => Navigator.of(context).pop(list[i]) : null,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.location_off_outlined, size: 56, color: colors.textMuted),
          AppSpacing.gapMd,
          Text('No saved addresses yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Add your home or farm so deliveries find you.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
        ]),
      ),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.address, this.onTap});

  final SavedAddress address;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
        ref.invalidate(addressesProvider);
      } catch (err) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(border: Border.all(color: address.isDefault ? colors.primary : colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Text(address.label.toUpperCase(), style: text.labelSmall),
                ),
                if (address.isDefault) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text('DEFAULT', style: text.labelSmall?.copyWith(color: colors.primary)),
                ],
                if (address.hasPin) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.gps_fixed, size: 14, color: colors.success),
                ],
                const Spacer(),
                if (onTap == null)
                  PopupMenuButton<String>(
                    key: Key('address-menu-${address.addressId}'),
                    onSelected: (v) async {
                      switch (v) {
                        case 'edit':
                          context.push(RoutePaths.farmerProfileAddressNew, extra: address);
                        case 'default':
                          await run(() => ref.read(profileRepositoryProvider).makeDefault(address.addressId));
                        case 'delete':
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete this address?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) await run(() => ref.read(profileRepositoryProvider).deleteAddress(address.addressId));
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (!address.isDefault) const PopupMenuItem(value: 'default', child: Text('Make default')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ]),
              const SizedBox(height: AppSpacing.xs),
              Text('${address.fullName}   ${address.phone}', style: text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(address.formatted, style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
