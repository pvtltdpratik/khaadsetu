import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/responsive/responsive_layout.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/surplus_lot.dart';
import '../providers/surplus_providers.dart';
import '../widgets/create_surplus_sheet.dart';
import '../widgets/edit_surplus_sheet.dart';

String _money(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// The operator's surplus offers: units sold cheaper than the catalog price.
class SurplusScreen extends ConsumerStatefulWidget {
  const SurplusScreen({super.key});

  @override
  ConsumerState<SurplusScreen> createState() => _SurplusScreenState();
}

class _SurplusScreenState extends ConsumerState<SurplusScreen> {
  bool _showEnded = false;

  @override
  Widget build(BuildContext context) {
    final lots = ref.watch(surplusLotsProvider);
    return ResponsiveScope(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            refreshSurplus(ref);
            await ref.read(surplusLotsProvider.future);
          },
          child: ListView(
            padding: context.pagePadding,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back to inventory',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.operatorInventory),
                  ),
                  Expanded(child: Text('Surplus stock', style: Theme.of(context).textTheme.headlineSmall)),
                  FilledButton.icon(
                    onPressed: () => showAdaptiveModal<SurplusLot>(context: context, builder: (context) => const CreateSurplusSheet()),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('List surplus'),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              lots.when(
                data: (all) {
                  final onSale = all.where((l) => l.isOnSale).toList();
                  final ended = all.where((l) => !l.isOnSale).toList();
                  final shown = _showEnded ? ended : onSale;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          ChoiceChip(label: Text('On sale (${onSale.length})'), selected: !_showEnded, onSelected: (_) => setState(() => _showEnded = false)),
                          ChoiceChip(label: Text('Ended (${ended.length})'), selected: _showEnded, onSelected: (_) => setState(() => _showEnded = true)),
                        ],
                      ),
                      AppSpacing.gapMd,
                      if (shown.isEmpty)
                        _Empty(showEnded: _showEnded, anyLots: all.isNotEmpty)
                      else
                        for (final (i, lot) in shown.indexed) ...[
                          FadeSlideIn(key: ValueKey(lot.id), index: i, child: _LotCard(lot: lot)),
                          AppSpacing.gapSm,
                        ],
                    ],
                  );
                },
                loading: () => const SizedBox(height: 200, child: AppLoadingIndicator()),
                error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(surplusLotsProvider)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.showEnded, required this.anyLots});

  final bool showEnded;
  final bool anyLots;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.sell_outlined, size: 48, color: colors.textMuted),
          AppSpacing.gapMd,
          Text(showEnded ? 'Nothing has ended yet' : 'No surplus on sale', style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.gapXs,
          Text(
            showEnded
                ? 'Sold-out, expired and withdrawn offers show up here.'
                : anyLots
                    ? 'Your offers have all ended. List new units to sell them cheaper to nearby farmers.'
                    : 'Sell near-expiry, opened or returned units at a lower price. Nearby farmers will see them marked down.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LotCard extends ConsumerStatefulWidget {
  const _LotCard({required this.lot});

  final SurplusLot lot;

  @override
  ConsumerState<_LotCard> createState() => _LotCardState();
}

class _LotCardState extends ConsumerState<_LotCard> {
  bool _busy = false;

  Future<void> _withdraw() async {
    final lot = widget.lot;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw this offer?'),
        content: Text(
          '${lot.productName} will no longer be shown to farmers.'
          '${lot.reserved > 0 ? ' ${lot.reserved} unit${lot.reserved == 1 ? ' is' : 's are'} held by orders and stay with those orders.' : ''}'
          '${lot.fromShelf ? ' Unsold units go back on your shelf.' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(surplusRepositoryProvider).withdraw(lot.id);
      refreshSurplus(ref);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer withdrawn')));
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final lot = widget.lot;
    final (statusLabel, statusColor) = switch (lot.status) {
      SurplusStatus.active => ('On sale', colors.success),
      SurplusStatus.soldOut => ('Sold out', colors.textMuted),
      SurplusStatus.expired => ('Expired', colors.danger),
      SurplusStatus.withdrawn => ('Withdrawn', colors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(lot.productName, style: text.titleSmall)),
              _Pill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Rs ${_money(lot.unitPrice)}', style: text.titleMedium?.copyWith(color: colors.primary)),
              const SizedBox(width: AppSpacing.sm),
              Text('Rs ${_money(lot.catalogPrice)}', style: text.bodySmall?.copyWith(color: colors.textMuted, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: AppSpacing.sm),
              _Pill(label: '${lot.discountPercent}% off', color: colors.success),
            ],
          ),
          AppSpacing.gapXs,
          Text(
            '${lot.available} available${lot.reserved > 0 ? ', ${lot.reserved} held by orders' : ''}${lot.unit.isEmpty ? '' : ' · ${lot.unit}'}',
            style: text.bodyMedium,
          ),
          Text(
            '${lot.condition.label}${lot.bestBefore == null ? '' : ' · best before ${_date(lot.bestBefore!)}'}${lot.fromShelf ? ' · from your shelf' : ''}',
            style: text.bodySmall?.copyWith(color: colors.textMuted),
          ),
          if (lot.note.isNotEmpty) Text(lot.note, style: text.bodySmall?.copyWith(color: colors.textMuted)),
          if (lot.isOnSale) ...[
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  onPressed: _busy ? null : () => showAdaptiveModal<SurplusLot>(context: context, builder: (context) => EditSurplusSheet(lot: lot)),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.remove_shopping_cart_outlined, size: 18),
                  label: const Text('Withdraw'),
                  onPressed: _busy ? null : _withdraw,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
