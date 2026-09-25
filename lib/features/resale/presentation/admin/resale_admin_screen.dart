import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/resale_models.dart';
import '../resale_providers.dart';

/// The platform's side of farmers' resale: complaints from buyers, and UPI payouts owed to sellers.
class ResaleAdminScreen extends ConsumerWidget {
  const ResaleAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputes = ref.watch(resaleDisputesProvider).value?.length ?? 0;
    final payouts = ref.watch(upiPayoutsProvider).value?.length ?? 0;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Farmer resale'),
          bottom: TabBar(tabs: [Tab(text: 'Complaints${disputes > 0 ? ' ($disputes)' : ''}'), Tab(text: 'UPI payouts${payouts > 0 ? ' ($payouts)' : ''}')]),
        ),
        body: const TabBarView(children: [_Disputes(), _Payouts()]),
      ),
    );
  }
}

class _Disputes extends ConsumerWidget {
  const _Disputes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final list = ref.watch(resaleDisputesProvider);
    return list.when(
      loading: () => const AppLoadingIndicator(),
      error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(resaleDisputesProvider)),
      data: (items) => items.isEmpty
          ? Center(child: Text('No complaints waiting.', style: text.bodyMedium?.copyWith(color: colors.textMuted)))
          : ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
              for (final d in items)
                Card(
                  key: Key('dispute-${d.disputeId}'),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${d.productName}  ·  ${formatRupees(d.gross)}', style: text.titleSmall),
                      Text('Approved by ${d.centerName} (inspection score ${d.centerQuality}/100)${d.batchNumber.isEmpty ? '' : '  ·  batch ${d.batchNumber}'}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('"${d.reason}"', style: text.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
                        OutlinedButton(key: Key('reject-${d.disputeId}'), onPressed: () => _resolve(context, ref, d, uphold: false), child: const Text('Reject')),
                        FilledButton(key: Key('uphold-${d.disputeId}'), onPressed: () => _resolve(context, ref, d, uphold: true), child: const Text('Refund the buyer')),
                      ]),
                    ]),
                  ),
                ),
            ]),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref, ResaleDispute d, {required bool uphold}) async {
    final answer = await showDialog<({int? percent, String note})>(context: context, builder: (context) => _ResolveDialog(uphold: uphold, gross: d.gross));
    if (answer == null) return;
    try {
      await ref.read(resaleRepositoryProvider).resolveDispute(d.disputeId, uphold: uphold, refundPercent: answer.percent, note: answer.note);
      ref.invalidate(resaleDisputesProvider);
    } catch (err) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }
}

class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog({required this.uphold, required this.gross});

  final bool uphold;
  final double gross;

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  int _percent = 100;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.uphold ? 'Refund the buyer' : 'Reject the complaint'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.uphold) ...[
          Text('Refund ${formatRupees(widget.gross * _percent / 100)} ($_percent%)', key: const Key('refund-label')),
          Wrap(spacing: 8, children: [for (final p in const [25, 50, 75, 100]) ChoiceChip(key: Key('percent-$p'), label: Text('$p%'), selected: _percent == p, onSelected: (_) => setState(() => _percent = p))]),
          const SizedBox(height: 8),
          const Text('The seller bears their share of it from their earnings, and the center loses inspection points.'),
        ],
        TextField(key: const Key('note'), controller: _note, maxLength: 300, decoration: const InputDecoration(labelText: 'Note to the buyer')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(key: const Key('resolve-confirm'), onPressed: () => Navigator.pop(context, (percent: widget.uphold ? _percent : null, note: _note.text.trim())), child: const Text('Confirm')),
      ],
    );
  }
}

class _Payouts extends ConsumerWidget {
  const _Payouts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final list = ref.watch(upiPayoutsProvider);
    return list.when(
      loading: () => const AppLoadingIndicator(),
      error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(upiPayoutsProvider)),
      data: (items) => items.isEmpty
          ? Center(child: Text('No UPI payouts waiting.', style: text.bodyMedium?.copyWith(color: colors.textMuted)))
          : ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
              for (final p in items)
                Card(
                  key: Key('upi-${p.saleId}'),
                  child: ListTile(
                    title: Text('${p.sellerName}  ·  ${formatRupees(p.amount)}'),
                    subtitle: SelectableText(p.upiId),
                    trailing: FilledButton(
                      key: Key('sent-${p.saleId}'),
                      onPressed: () async {
                        final reference = await showDialog<String>(context: context, builder: (context) => const _ReferenceDialog());
                        if (reference == null) return;
                        try {
                          await ref.read(resaleRepositoryProvider).markUpiPaid(p.saleId, reference: reference);
                          ref.invalidate(upiPayoutsProvider);
                        } catch (err) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
                        }
                      },
                      child: const Text('Mark sent'),
                    ),
                  ),
                ),
            ]),
    );
  }
}

class _ReferenceDialog extends StatefulWidget {
  const _ReferenceDialog();

  @override
  State<_ReferenceDialog> createState() => _ReferenceDialogState();
}

class _ReferenceDialogState extends State<_ReferenceDialog> {
  final _ref = TextEditingController();

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Payment reference'),
        content: TextField(key: const Key('utr'), controller: _ref, decoration: const InputDecoration(labelText: 'UPI reference (optional)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(key: const Key('utr-confirm'), onPressed: () => Navigator.pop(context, _ref.text.trim()), child: const Text('Confirm sent')),
        ],
      );
}
