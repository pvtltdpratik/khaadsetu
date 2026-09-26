import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/price_format.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../domain/invoice_models.dart';
import '../pdf/invoice_output.dart';
import '../pdf/invoice_pdf.dart';
import 'invoice_providers.dart';
import 'invoice_status_chip.dart';

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _qty(double q) => q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);

/// One bill, laid out like the paper one, with what can be done to it: share it as a PDF, print it on a sheet or a
/// receipt roll, and (for the center) take a payment, take goods back, or cancel it.
class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.scope, required this.id});

  final InvoiceScope scope;
  final String id;

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref
        ..invalidate(invoiceProvider((scope: scope, id: id)))
        ..invalidate(invoiceListProvider)
        ..invalidate(creditBookProvider)
        ..invalidate(dailyClosingProvider);
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (err) {
      messenger.showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(invoiceProvider((scope: scope, id: id)));
    return Scaffold(
      appBar: AppBar(title: Text(invoice.value?.isCreditNote == true ? 'Credit note' : 'Bill')),
      body: ResponsiveScope(
        child: invoice.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(invoiceProvider((scope: scope, id: id)))),
          data: (inv) => _Body(scope: scope, invoice: inv, run: (action, {String? done}) => _run(context, ref, action, done: done)),
        ),
      ),
    );
  }
}

typedef _Runner = Future<void> Function(Future<void> Function() action, {String? done});

class _Body extends ConsumerWidget {
  const _Body({required this.scope, required this.invoice, required this.run});

  final InvoiceScope scope;
  final Invoice invoice;
  final _Runner run;

  Future<void> _takePayment(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({double amount, String mode, String reference})>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _PaymentSheet(due: invoice.balanceDue));
    if (result == null) return;
    await run(() async {
      await ref.read(invoiceRepositoryProvider).recordPayment(invoice.id, amount: result.amount, mode: result.mode, reference: result.reference);
    }, done: 'Payment recorded.');
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(context: context, builder: (_) => const _ReasonDialog(title: 'Cancel this bill?', hint: 'Why is it being cancelled?', action: 'Cancel bill', body: 'It stays on record, marked cancelled, with a credit note. Any money taken is given back.'));
    if (reason == null) return;
    await run(() async {
      await ref.read(invoiceRepositoryProvider).cancel(scope, invoice.id, reason: reason);
    }, done: 'The bill was cancelled.');
  }

  Future<void> _return(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({List<(int, double)> items, String reason})>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _ReturnSheet(invoice: invoice));
    if (result == null) return;
    await run(() async {
      await ref.read(invoiceRepositoryProvider).returnItems(invoice.id, items: result.items, reason: result.reason);
    }, done: 'A credit note was made and the money is back.');
  }

  Future<void> _out(BuildContext context, WidgetRef ref, Future<void> Function(InvoiceOutput out) action) async {
    try {
      await action(ref.read(invoiceOutputProvider));
    } catch (err) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final inv = invoice;
    Widget card(List<Widget> children, {Key? key}) => Container(
          key: key,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        );
    Widget row(String k, String v, {bool bold = false, Color? color, Key? key}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(k, style: bold ? text.titleSmall : text.bodyMedium)),
            Text(v, key: key, style: (bold ? text.titleSmall : text.bodyMedium)?.copyWith(color: color)),
          ]),
        );
    final isOperator = scope == InvoiceScope.operator;
    final canCorrect = inv.canBeCorrected && (isOperator || scope == InvoiceScope.admin);
    return ListView(padding: context.pagePadding.copyWith(bottom: AppSpacing.xl), children: [
      if (inv.isCancelled)
        Container(
          key: const Key('cancelled-banner'),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Text('Cancelled${inv.cancelReason.isEmpty ? '' : ': ${inv.cancelReason}'}', style: text.titleSmall?.copyWith(color: colors.danger)),
        ),
      card(key: const Key('invoice-header'), [
        Row(children: [
          Expanded(child: Text(inv.number, key: const Key('invoice-number'), style: text.titleMedium)),
          InvoiceStatusChip(invoice: inv),
        ]),
        const SizedBox(height: 2),
        Text('${invoiceKindLabels[inv.kind] ?? inv.kind}  ·  ${_date(inv.issuedAt)}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
      ]),
      card([
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _Party(title: 'From', party: inv.seller)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _Party(title: 'To', party: inv.buyer)),
        ]),
      ]),
      card(key: const Key('invoice-items'), [
        for (final l in inv.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.name, style: text.titleSmall),
                  Text('${'${_qty(l.qty)} ${l.unit}'.trim()} x ${formatRupeesExact(l.rate)}${l.discount > 0 ? '  (- ${formatRupeesExact(l.discount)})' : ''}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                  if (l.taxPercent > 0) Text('GST ${l.taxPercent.toStringAsFixed(l.taxPercent == l.taxPercent.roundToDouble() ? 0 : 1)}% (${formatRupeesExact(l.tax)} included)${l.hsn.isEmpty ? '' : '  ·  HSN ${l.hsn}'}', style: text.labelSmall?.copyWith(color: colors.textMuted)),
                ]),
              ),
              Text(formatRupeesExact(l.amount), style: text.titleSmall),
            ]),
          ),
      ]),
      card(key: const Key('invoice-totals'), [
        row('Subtotal', formatRupeesExact(inv.subtotal)),
        if (inv.discountTotal > 0) row('Discount', '- ${formatRupeesExact(inv.discountTotal)}'),
        if (inv.deliveryCharge > 0) row('Delivery', formatRupeesExact(inv.deliveryCharge)),
        if (inv.platformFee > 0) row('Service fee', formatRupeesExact(inv.platformFee)),
        if (inv.hasTax) row('Tax included', formatRupeesExact(inv.taxTotal)),
        if (inv.roundOff != 0) row('Round off', formatRupeesExact(inv.roundOff)),
        const Divider(),
        row('Grand total', formatRupeesExact(inv.grandTotal), bold: true, key: const Key('grand-total')),
        const SizedBox(height: AppSpacing.xs),
        Text(inv.amountInWords, key: const Key('amount-in-words'), style: text.bodySmall?.copyWith(color: colors.textMuted)),
      ]),
      card(key: const Key('invoice-payment'), [
        row('Payment', '${paymentStatusLabels[inv.paymentStatus] ?? inv.paymentStatus}${inv.paymentMode.isEmpty ? '' : '  ·  ${paymentModeLabels[inv.paymentMode] ?? inv.paymentMode}'}'),
        row('Paid', formatRupeesExact(inv.paidAmount)),
        if (inv.creditNotesTotal > 0) row('Credit notes', formatRupeesExact(inv.creditNotesTotal)),
        if (inv.balanceDue > 0) row('Balance due', formatRupeesExact(inv.balanceDue), bold: true, color: colors.danger, key: const Key('balance-due')),
        if (inv.dueDate != null && inv.balanceDue > 0) row('Due by', _date(inv.dueDate!)),
        if (inv.payments.isNotEmpty) ...[
          const Divider(),
          for (final p in inv.payments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${_date(p.paidAt)}  ·  ${p.isRefund ? 'Refund' : 'Paid'} ${formatRupeesExact(p.amount)}  ·  ${paymentModeLabels[p.mode] ?? p.mode}${p.reference.isEmpty ? '' : '  ·  ${p.reference}'}', style: text.bodySmall),
            ),
        ],
        if (inv.upiUri != null) ...[
          const Divider(),
          Center(child: Column(children: [
            QrImageView(key: const Key('upi-qr'), data: inv.upiUri!, size: 160, backgroundColor: Colors.white),
            Text('Scan to pay ${formatRupeesExact(inv.balanceDue)} by UPI', style: text.bodySmall),
          ])),
        ],
      ]),
      if (inv.notes.isNotEmpty) card([Text(inv.notes, style: text.bodySmall)]),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        FilledButton.icon(key: const Key('share-pdf'), onPressed: () => _out(context, ref, (o) => o.sharePdf(inv, InvoicePaper.a4)), icon: const Icon(Icons.share_rounded), label: const Text('Share PDF')),
        PopupMenuButton<InvoicePaper>(
          key: const Key('print-menu'),
          onSelected: (paper) => _out(context, ref, (o) => o.print(inv, paper)),
          itemBuilder: (_) => [for (final p in InvoicePaper.values) PopupMenuItem(key: Key('print-${p.name}'), value: p, child: Text(p.label))],
          child: IgnorePointer(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.print_outlined), label: const Text('Print'))),
        ),
        if (isOperator && inv.canTakePayment) FilledButton.tonalIcon(key: const Key('record-payment'), onPressed: () => _takePayment(context, ref), icon: const Icon(Icons.payments_outlined), label: const Text('Record payment')),
        if (isOperator && canCorrect && !inv.isCreditNote) OutlinedButton.icon(key: const Key('return-items'), onPressed: () => _return(context, ref), icon: const Icon(Icons.assignment_return_outlined), label: const Text('Goods returned')),
        if (canCorrect) OutlinedButton.icon(key: const Key('cancel-invoice'), style: OutlinedButton.styleFrom(foregroundColor: colors.danger), onPressed: () => _cancel(context, ref), icon: const Icon(Icons.block_rounded), label: const Text('Cancel bill')),
      ]),
    ]);
  }
}

class _Party extends StatelessWidget {
  const _Party({required this.title, required this.party});

  final String title;
  final InvoiceParty party;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: context.colors.textMuted);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: text.labelSmall?.copyWith(color: context.colors.textMuted)),
      Text(party.name, style: text.titleSmall),
      if (party.place.isNotEmpty) Text(party.place, style: muted),
      if (party.phone.isNotEmpty) Text(party.phone, style: muted),
      if (party.gstin.isNotEmpty) Text('GSTIN ${party.gstin}', style: muted),
    ]);
  }
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.due});

  final double due;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late final _amount = TextEditingController(text: widget.due.toStringAsFixed(widget.due == widget.due.roundToDouble() ? 0 : 2));
  final _reference = TextEditingController();
  String _mode = 'cash';
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return setState(() => _error = 'Enter the amount received');
    if (amount > widget.due + 0.001) return setState(() => _error = 'Only ${formatRupeesExact(widget.due)} is due');
    Navigator.pop(context, (amount: amount, mode: _mode, reference: _reference.text.trim()));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Record a payment', style: Theme.of(context).textTheme.titleMedium),
          Text('${formatRupeesExact(widget.due)} is due', style: Theme.of(context).textTheme.bodySmall),
          AppSpacing.gapMd,
          TextField(key: const Key('pay-amount'), controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount received')),
          AppSpacing.gapSm,
          Wrap(spacing: AppSpacing.sm, children: [for (final m in payModes) ChoiceChip(key: Key('mode-$m'), label: Text(paymentModeLabels[m]!), selected: _mode == m, onSelected: (_) => setState(() => _mode = m))]),
          if (_mode != 'cash') ...[AppSpacing.gapSm, TextField(key: const Key('pay-reference'), controller: _reference, decoration: const InputDecoration(labelText: 'Transaction id (UTR), optional'))],
          if (_error != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(_error!, key: const Key('pay-error'), style: TextStyle(color: context.colors.danger))),
          AppSpacing.gapMd,
          SizedBox(width: double.infinity, child: FilledButton(key: const Key('pay-save'), onPressed: _save, child: const Text('Save payment'))),
        ]),
      );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.hint, required this.action, required this.body});

  final String title;
  final String hint;
  final String action;
  final String body;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.body),
          AppSpacing.gapSm,
          TextField(key: const Key('reason'), controller: _reason, autofocus: true, decoration: InputDecoration(labelText: widget.hint), onChanged: (_) => setState(() {})),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep it')),
          FilledButton(key: const Key('reason-confirm'), onPressed: _reason.text.trim().isEmpty ? null : () => Navigator.pop(context, _reason.text.trim()), child: Text(widget.action)),
        ],
      );
}

class _ReturnSheet extends StatefulWidget {
  const _ReturnSheet({required this.invoice});

  final Invoice invoice;

  @override
  State<_ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends State<_ReturnSheet> {
  late final List<double> _back = List.filled(widget.invoice.items.length, 0);
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _ready => _back.any((q) => q > 0) && _reason.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final items = widget.invoice.items;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Goods returned', style: text.titleMedium),
          Text('Choose how many of each came back. A credit note is made and the money goes back.', style: text.bodySmall),
          AppSpacing.gapSm,
          for (var i = 0; i < items.length; i++)
            Row(children: [
              Expanded(child: Text('${items[i].name}  (sold ${_qty(items[i].qty)})', style: text.bodyMedium)),
              IconButton(key: Key('less-$i'), onPressed: _back[i] > 0 ? () => setState(() => _back[i] -= 1) : null, icon: const Icon(Icons.remove_circle_outline)),
              Text(_qty(_back[i]), key: Key('back-$i'), style: text.titleSmall),
              IconButton(key: Key('more-$i'), onPressed: _back[i] < items[i].qty ? () => setState(() => _back[i] += 1) : null, icon: const Icon(Icons.add_circle_outline)),
            ]),
          TextField(key: const Key('return-reason'), controller: _reason, decoration: const InputDecoration(labelText: 'Why are they coming back?'), onChanged: (_) => setState(() {})),
          AppSpacing.gapMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('return-save'),
              onPressed: _ready ? () => Navigator.pop(context, (items: [for (var i = 0; i < items.length; i++) if (_back[i] > 0) (i, _back[i])], reason: _reason.text.trim())) : null,
              child: const Text('Make credit note'),
            ),
          ),
        ]),
      ),
    );
  }
}
