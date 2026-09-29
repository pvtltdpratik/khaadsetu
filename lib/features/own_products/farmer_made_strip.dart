import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/kit.dart';
import 'own_api.dart';
import 'own_market_screens.dart';
import 'own_product_tile.dart';

/// A preview of what farmers near this one are selling, shown right in the shop marketplace so it is never mistaken
/// for a separate, hidden feature. Collapses to nothing while it is still loading or if there is nothing to show —
/// this is a bonus, and must never make the shop itself feel broken or slow.
class FarmerMadeStrip extends ConsumerWidget {
  const FarmerMadeStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // category empty, sorted nearest, no search: the same default the full market screen opens with.
    final items = ref.watch(ownMarketProvider('|nearest|'));
    return items.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final shown = list.take(10).toList();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(children: [
                Expanded(child: Text('Farmer-made, near you', style: Theme.of(context).textTheme.titleMedium)),
                TextButton(
                  key: const Key('farmer-made-see-all'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OwnMarketScreen())),
                  child: const Text('See all'),
                ),
              ]),
            ),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: shown.length,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (context, i) {
                  final l = shown[i];
                  return SizedBox(
                    width: 150,
                    child: OwnProductTile(
                      key: Key('strip-${l.str('id')}'),
                      item: l,
                      compact: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OwnDetailScreen(listingId: l.str('id')))),
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
