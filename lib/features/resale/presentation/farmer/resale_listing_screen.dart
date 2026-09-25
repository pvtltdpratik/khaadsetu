import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/resale_models.dart';
import '../resale_providers.dart';
import 'sell_surplus_hub_screen.dart';

/// One of my listings: where it stands, what happens next, what it sold for and how I am paid.
class ResaleListingScreen extends ConsumerWidget {
  const ResaleListingScreen({super.key, required this.listingId});

  final String listingId;

  static String nextStep(ResaleListing l) => switch (l.status) {
        ResaleStatus.draft => 'Not sent yet.',
        ResaleStatus.pendingVerification => 'Your village center is checking your photos.',
        ResaleStatus.inspectionRequired => 'Bring the bags to ${l.centerName} so they can be checked before they go on sale.',
        ResaleStatus.live => 'It is on the marketplace. When a buyer orders it, you will have 48 hours to bring it to ${l.centerName}.',
        ResaleStatus.awaitingHandover => 'A buyer is waiting. Bring it to ${l.centerName} before the time below, or the order is cancelled and your listing ends.',
        ResaleStatus.listed => 'Checked and at ${l.centerName}. Buyers can reserve it now.',
        ResaleStatus.soldOut => 'Everything sold.',
        ResaleStatus.rejected => l.rejectReason.isEmpty ? 'This listing was not accepted.' : 'Not accepted: ${l.rejectReason}',
        ResaleStatus.withdrawn => 'You took this listing back.',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(myListingProvider(listingId));
    return Scaffold(
      appBar: AppBar(title: const Text('Your listing')),
      body: ResponsiveScope(
        child: listing.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myListingProvider(listingId))),
          data: (l) => _Body(listing: l),
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.listing});

  final ResaleListing listing;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  Future<void> _withdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Take this listing back?'),
        content: const Text('It comes off the marketplace. If you already brought it to the center, they will hand it back to you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it listed')),
          FilledButton(key: const Key('confirm-withdraw'), onPressed: () => Navigator.pop(context, true), child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(resaleRepositoryProvider).withdraw(widget.listing.id);
      ref
        ..invalidate(myListingProvider(widget.listing.id))
        ..invalidate(myListingsProvider);
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
    final l = widget.listing;
    final color = statusColor(l.status, colors);
    final canWithdraw = l.status.isOpen && l.unitsReserved == 0;
    return ListView(
      padding: context.pagePadding,
      children: [
        Text(l.productName, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Container(
            key: const Key('status-chip'),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(l.status.label, style: text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
          Text('${l.units} × ${l.unit}', style: text.bodyMedium),
        ]),
        AppSpacing.gapMd,
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('What happens next', style: text.labelMedium),
            const SizedBox(height: 2),
            Text(ResaleListingScreen.nextStep(l), key: const Key('next-step'), style: text.bodyMedium),
            if (l.status == ResaleStatus.awaitingHandover && l.handoverDue != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text('Bring it by ${l.handoverDue!.day}/${l.handoverDue!.month} at ${l.handoverDue!.hour.toString().padLeft(2, '0')}:${l.handoverDue!.minute.toString().padLeft(2, '0')}', key: const Key('due'), style: text.titleSmall?.copyWith(color: colors.warning)),
              ),
          ]),
        ),
        AppSpacing.gapMd,
        _Row('Your price', '${formatRupees(l.price)} each${l.finalPrice != null && l.finalPrice! < l.askingPrice ? ' (lowered from ${formatRupees(l.askingPrice)})' : ''}'),
        _Row('You receive', l.youReceivePerUnit == null ? '—' : '${formatRupees(l.youReceivePerUnit!)} for each'),
        _Row('Condition', l.condition.label),
        _Row('Expires', l.expiryDate),
        if (l.batchNumber.isNotEmpty) _Row('Batch', l.batchNumber),
        _Row('Hand-over center', l.centerName),
        _Row('Paid by', l.payoutMode.label),
        _Row('Purchase', l.verifiedPurchase ? 'Verified platform order' : 'Not verified'),
        if (l.unitsSold > 0 || l.unitsReserved > 0) ...[
          AppSpacing.gapMd,
          Text('Sales', style: text.titleMedium),
          _Row('Sold', '${l.unitsSold}'),
          if (l.unitsReserved > 0) _Row('Reserved by buyers', '${l.unitsReserved}'),
          for (final s in l.sales)
            ListTile(
              key: Key('sale-${s.saleId}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('${s.units} sold for ${formatRupees(s.gross)}  →  you earn ${formatRupees(s.sellerNet)}'),
              subtitle: Text(s.payoutLabel),
            ),
        ],
        if (canWithdraw) ...[
          AppSpacing.gapLg,
          OutlinedButton.icon(
            key: const Key('withdraw'),
            style: OutlinedButton.styleFrom(foregroundColor: colors.danger),
            onPressed: _busy ? null : _withdraw,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Withdraw this listing'),
          ),
        ],
        AppSpacing.gapLg,
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: text.bodySmall?.copyWith(color: context.colors.textMuted))),
        Expanded(child: Text(value, style: text.bodyMedium)),
      ]),
    );
  }
}
