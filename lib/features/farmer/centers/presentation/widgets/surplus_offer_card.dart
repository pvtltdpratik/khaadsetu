import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/pop_in.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_format.dart';
import '../../../orders/domain/repositories/orders_repository.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../domain/entities/surplus_offer.dart';
import '../providers/centers_providers.dart';

const _maxQuantity = 99;

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _travel(int minutes) => minutes < 60 ? '$minutes min' : '${minutes ~/ 60} h ${minutes % 60} min';

/// Opens the reserve dialog and, if the farmer reserves, takes them to the order
/// (which shows the pickup code).
Future<void> reserveSurplusOffer(BuildContext context, WidgetRef ref, SurplusOffer offer) async {
  final orderId = await showDialog<String>(context: context, builder: (context) => ReserveSurplusDialog(offer: offer));
  if (orderId != null && context.mounted) context.push(RoutePaths.farmerOrder(orderId));
}

/// One discounted lot: the price against the regular price, why it is cheaper,
/// what is left, and where to collect it.
class SurplusOfferCard extends ConsumerWidget {
  const SurplusOfferCard({super.key, required this.offer});

  final SurplusOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final o = offer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(o.productName, style: text.titleSmall)),
              // The discount is the reason to look: it pops in after the card lands.
              PopIn(
                delay: const Duration(milliseconds: 220),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text('${o.discountPercent}% off', style: text.labelSmall?.copyWith(color: colors.success, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(formatRupees(o.unitPrice), style: text.titleMedium?.copyWith(color: colors.primary)),
              const SizedBox(width: AppSpacing.sm),
              Text(formatRupees(o.catalogPrice), style: text.bodySmall?.copyWith(color: colors.textMuted, decoration: TextDecoration.lineThrough)),
              if (o.unit.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(o.unit, style: text.bodySmall?.copyWith(color: colors.textMuted)),
              ],
            ],
          ),
          AppSpacing.gapXs,
          Text(
            '${o.condition.label}${o.bestBefore == null ? '' : ' · best before ${_date(o.bestBefore!)}'} · ${o.available} available',
            style: text.bodyMedium,
          ),
          if (o.note.isNotEmpty) Text(o.note, style: text.bodySmall?.copyWith(color: colors.textMuted)),
          AppSpacing.gapXs,
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: 16, color: colors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${o.center.name}, ${o.center.village} · ${o.distanceKm.toStringAsFixed(1)} km · about ${_travel(o.estimatedTravelMinutes)}',
                  style: text.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => reserveSurplusOffer(context, ref, o),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: Text(o.center.isOpen ? 'Reserve' : 'Reserve, collect later'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks how many, then reserves them. Pops the new order's id on success.
class ReserveSurplusDialog extends ConsumerStatefulWidget {
  const ReserveSurplusDialog({super.key, required this.offer});

  final SurplusOffer offer;

  @override
  ConsumerState<ReserveSurplusDialog> createState() => _ReserveSurplusDialogState();
}

class _ReserveSurplusDialogState extends ConsumerState<ReserveSurplusDialog> {
  int _quantity = 1;
  bool _busy = false;
  String? _error;
  bool _gone = false;

  int get _max => widget.offer.available.clamp(1, _maxQuantity);

  Future<void> _reserve() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await ref.read(ordersRepositoryProvider).placeSurplus(
            lotId: widget.offer.lotId,
            quantity: _quantity,
            location: ref.read(farmerLocationProvider).value,
          );
      ref
        ..invalidate(myOrdersProvider)
        ..invalidate(surplusNearbyProvider)
        ..invalidate(nearbyCentersProvider);
      if (mounted) Navigator.of(context).pop(order.id);
    } on SurplusUnavailableException catch (err) {
      // Someone else got there first: refresh the list behind this dialog.
      ref.invalidate(surplusNearbyProvider);
      if (mounted) {
        setState(() {
          _error = err.message;
          _gone = true;
        });
      }
    } catch (err) {
      if (mounted) setState(() => _error = '$err');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final o = widget.offer;
    return AlertDialog(
      title: const Text('Reserve surplus'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(o.productName, style: text.titleSmall),
          Text('${o.center.name}, ${o.center.village}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          AppSpacing.gapMd,
          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Fewer',
                onPressed: _quantity > 1 && !_busy && !_gone ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(width: 48, child: Text('$_quantity', textAlign: TextAlign.center, style: text.titleLarge)),
              IconButton.outlined(
                tooltip: 'More',
                onPressed: _quantity < _max && !_busy && !_gone ? () => setState(() => _quantity++) : null,
                icon: const Icon(Icons.add_rounded),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(formatRupees(o.unitPrice * _quantity), style: text.titleMedium, textAlign: TextAlign.end)),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            'Held for you for 5 days. You pay at the center when you collect. Only ${o.available} ${o.available == 1 ? 'unit is' : 'units are'} left at this price.',
            style: text.bodySmall?.copyWith(color: colors.textMuted),
          ),
          if (_error != null) ...[
            AppSpacing.gapSm,
            Text(_error!, style: text.bodySmall?.copyWith(color: colors.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(_gone ? 'Close' : 'Cancel')),
        if (!_gone)
          FilledButton(
            onPressed: _busy ? null : _reserve,
            child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Reserve for pickup'),
          ),
      ],
    );
  }
}
