import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/location/place_namer.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../centers/domain/entities/nearby_center.dart';
import '../../../centers/presentation/providers/centers_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/farmer_profile.dart';

/// "Namaste, {name}" + where the farmer is right now (from the phone's GPS), with a
/// notification bell showing an unread badge. Custom rather than a Material [AppBar] so the greeting can carry
/// more warmth than an app bar title allows.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.profile, required this.onNotificationsTap});

  final FarmerProfile profile;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Namaste, ${profile.name.split(' ').first}',
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              const CurrentLocationLine(),
            ],
          ),
        ),
        AppSpacing.gapMd,
        _NotificationBell(count: profile.unreadNotificationCount, onTap: onNotificationsTap),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceSunken,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined, color: colors.textPrimary),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: colors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onDanger,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the farmer is now, read from the phone's GPS and named ("Shirur, Pune"). Tap to read
/// the GPS again. With no GPS it asks the farmer to set their location rather than guessing one.
class CurrentLocationLine extends ConsumerWidget {
  const CurrentLocationLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted);
    final place = ref.watch(currentPlaceProvider);
    final location = ref.watch(farmerLocationProvider);

    Future<void> refresh() async {
      final message = await ref.read(farmerLocationProvider.notifier).useGps();
      ref.invalidate(currentPlaceProvider);
      if (message != null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }

    late final IconData icon;
    late final String label;
    late final VoidCallback? onTap;
    if (place.isLoading || location.isLoading) {
      icon = Icons.location_searching;
      label = 'Finding your location…';
      onTap = null;
    } else if (location.value == null) {
      icon = Icons.location_off_outlined;
      label = 'Set your location';
      onTap = () => context.push(RoutePaths.farmerChooseVillage);
    } else {
      final loc = location.value!;
      final name = place.value?.short ?? '';
      icon = loc.source == LocationSource.gps ? Icons.my_location : Icons.location_on_outlined;
      label = name.isNotEmpty ? name : (loc.source == LocationSource.gps ? 'Your current location' : (loc.label ?? 'Your location'));
      onTap = refresh;
    }
    return InkWell(
      key: const Key('current-location'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.textMuted),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: style)),
          ],
        ),
      ),
    );
  }
}
