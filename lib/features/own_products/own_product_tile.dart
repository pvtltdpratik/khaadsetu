import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/price_format.dart';
import '../../core/widgets/kit.dart';

/// One farmer-made product, styled like a shop product card (see `ProductCard`) so the two look like one catalogue —
/// except every tile here carries the green "Farmer-made" ribbon, so it is never mistaken for a center's own stock.
class OwnProductTile extends StatelessWidget {
  const OwnProductTile({super.key, required this.item, required this.onTap, this.compact = false});

  final Json item;
  final VoidCallback onTap;

  /// A smaller card for a horizontal preview strip: name only, no seller line.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final l = item;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: Key('own-tile-${l.str('id')}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: colors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: Stack(children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md - 1)),
                    child: ApiImage('/v1/own/listings/${l.str('id')}/photos/0', zoomable: false, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 8,
                  child: Container(
                    key: const Key('farmer-made-ribbon'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: colors.success, borderRadius: const BorderRadius.horizontal(right: Radius.circular(6))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.eco_rounded, size: 12, color: colors.onSuccess),
                      const SizedBox(width: 3),
                      Text('Farmer-made', style: text.labelSmall?.copyWith(color: colors.onSuccess, fontSize: 10, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(l.str('name'), style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${l.str('sellerName')}${l.str('village').isEmpty ? '' : ', ${l.str('village')}'}${l['distanceKm'] == null ? '' : ' · ${l.num_('distanceKm').toStringAsFixed(1)} km'}',
                    style: text.labelSmall?.copyWith(color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                if (l.int_('ratingCount') > 0)
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: colors.success, borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(l.num_('ratingAvg').toStringAsFixed(1), style: text.labelSmall?.copyWith(color: colors.onSuccess, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 2),
                        Icon(Icons.star_rounded, size: 11, color: colors.onSuccess),
                      ]),
                    ),
                    const SizedBox(width: 6),
                    Text('(${l.int_('ratingCount')})', style: text.labelSmall?.copyWith(color: colors.textMuted)),
                  ]),
                const SizedBox(height: 2),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatRupeesExact(l.num_('pricePerUnit')), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Expanded(child: Text('/ ${l.str('unit')}', style: text.labelSmall?.copyWith(color: colors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
