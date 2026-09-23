import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/nearby_center.dart';
import '../providers/centers_providers.dart';

/// Shows where the app thinks the farmer is, and lets them fix it: try the
/// GPS again, or choose their village.
class LocationBanner extends ConsumerWidget {
  const LocationBanner({super.key});

  static String describe(FarmerLocation l) => switch (l.source) {
        LocationSource.gps => 'your current location (GPS)',
        LocationSource.pin => 'the point you chose',
        LocationSource.village => '${l.label ?? 'your village'} (your village)',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final location = ref.watch(farmerLocationProvider);

    Future<void> retryGps() async {
      final message = await ref.read(farmerLocationProvider.notifier).useGps();
      if (message != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }

    final actions = Wrap(
      spacing: AppSpacing.xs,
      children: [
        TextButton.icon(onPressed: retryGps, icon: const Icon(Icons.my_location_rounded, size: 18), label: const Text('Use GPS')),
        TextButton.icon(
          onPressed: () => context.push(RoutePaths.farmerChooseVillage),
          icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
          label: const Text('Choose village'),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(12),
      ),
      child: location.when(
        loading: () => Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Finding your location…', style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
        error: (_, _) => _Content(icon: Icons.location_off_outlined, color: colors.warning, text: 'We could not work out where you are.', actions: actions),
        data: (l) => l == null
            ? _Content(
                icon: Icons.location_off_outlined,
                color: colors.warning,
                text: 'Tell us where you are so we can find the nearest village centers.',
                actions: actions,
              )
            : _Content(icon: Icons.place_outlined, color: colors.primary, text: 'Showing centers near ${describe(l)}', actions: actions),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.icon, required this.color, required this.text, required this.actions});

  final IconData icon;
  final Color color;
  final String text;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
        actions,
      ],
    );
  }
}
