import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/nearby_center.dart';
import '../providers/centers_providers.dart';
import '../widgets/center_card.dart';
import '../widgets/location_banner.dart';

/// How this screen is being used: just browsing, or choosing where to collect
/// a particular order (then it returns the chosen center's id).
class NearbyCentersArgs {
  const NearbyCentersArgs({this.cart = Cart.empty, this.pick = false});

  final Cart cart;
  final bool pick;
}

class NearbyCentersScreen extends ConsumerWidget {
  const NearbyCentersScreen({super.key, this.args = const NearbyCentersArgs()});

  final NearbyCentersArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final nearby = ref.watch(nearbyCentersProvider(args.cart));

    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: Text(args.pick ? 'Choose a center' : 'Village centers near you')),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(nearbyCentersProvider(args.cart));
              await ref.read(nearbyCentersProvider(args.cart).future);
            },
            child: ListView(
              children: [
                ContentContainer(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LocationBanner(),
                      AppSpacing.gapMd,
                      if (args.cart.lines.isNotEmpty) ...[
                        Text(
                          args.pick ? 'Pick where you will collect your order.' : 'Stock shown is for the item you are looking at.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                        ),
                        AppSpacing.gapSm,
                      ],
                      nearby.when(
                        loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: AppLoadingIndicator()),
                        error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(nearbyCentersProvider(args.cart))),
                        data: (result) => _Results(result: result, args: args),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result, required this.args});

  final NearbyResult? result;
  final NearbyCentersArgs args;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (result == null) return const SizedBox.shrink();
    if (result!.centers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.location_off_outlined, size: 40, color: colors.textMuted),
            AppSpacing.gapSm,
            Text(
              'No village centers within ${result!.radiusKm} km yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Within ${result!.radiusKm} km · best match first', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.textMuted)),
        AppSpacing.gapSm,
        for (final (i, n) in result!.centers.indexed) ...[
          FadeSlideIn(
            key: ValueKey(n.center.centerId),
            index: i,
            child: CenterCard(
              nearby: n,
              onChoose: !args.pick || (args.cart.lines.isNotEmpty && n.inventory.status != InventoryStatus.all)
                  ? null
                  : () => context.pop(n.center.centerId),
            ),
          ),
          if (args.pick && args.cart.lines.isNotEmpty && n.inventory.status != InventoryStatus.all)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('This center cannot fill your whole order.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
            ),
          AppSpacing.gapMd,
        ],
      ],
    );
  }
}
