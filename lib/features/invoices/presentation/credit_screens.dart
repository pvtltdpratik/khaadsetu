import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/price_format.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../domain/invoice_models.dart';
import 'invoice_list_screen.dart';
import 'invoice_providers.dart';

/// The WhatsApp link that opens a chat with a farmer, with a polite reminder ready to send. Phone numbers are Indian
/// unless they already carry a country code.
Uri whatsAppReminder({required String phone, required String name, required double due, String centerName = 'the village center'}) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final number = digits.length == 10 ? '91$digits' : digits;
  final message = 'Namaste $name, a gentle reminder: ${formatRupeesExact(due)} is due at $centerName. Please pay when you can. Thank you!';
  return Uri.https('wa.me', '/$number', {'text': message});
}

/// Who owes this center money (the udhaar book), largest first.
class CreditBookScreen extends ConsumerWidget {
  const CreditBookScreen({super.key, required this.onOpenFarmer});

  final void Function(BuildContext context, String farmerId) onOpenFarmer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final book = ref.watch(creditBookProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Credit book')),
      body: ResponsiveScope(
        child: book.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(creditBookProvider)),
          data: (b) => RefreshIndicator(
            onRefresh: () => ref.refresh(creditBookProvider.future),
            child: ListView(padding: context.pagePadding, children: [
              Container(
                key: const Key('credit-total'),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Column(children: [
                  Text(formatRupeesExact(b.totalOutstanding), style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text('owed to you by ${b.farmers.length} farmer${b.farmers.length == 1 ? '' : 's'}', style: text.bodyMedium),
                ]),
              ),
              AppSpacing.gapMd,
              if (b.farmers.isEmpty)
                Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('Nobody owes you anything. When you sell on credit, the amount is written here.', key: const Key('credit-empty'), textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted)))
              else
                for (final f in b.farmers)
                  Card(
                    child: ListTile(
                      key: Key('credit-${f.farmerId}'),
                      title: Text(f.name),
                      subtitle: Text([if (f.village.isNotEmpty) f.village, if (f.phone.isNotEmpty) f.phone].join('  ·  ')),
                      trailing: Text(formatRupeesExact(f.balance), style: text.titleSmall?.copyWith(color: colors.danger)),
                      onTap: () => onOpenFarmer(context, f.farmerId),
                    ),
                  ),
            ]),
          ),
        ),
      ),
    );
  }
}

class CreditAccountScreen extends ConsumerWidget {
  const CreditAccountScreen({super.key, required this.farmerId, this.centerName = 'the village center', this.launcher});

  final String farmerId;
  final String centerName;

  /// Opens a link (WhatsApp). Swappable for tests.
  final Future<bool> Function(Uri uri)? launcher;

  Future<void> _collect(BuildContext context, WidgetRef ref, CreditAccount account) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<({double amount, String mode, String reference})>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _CollectSheet(balance: account.balance));
    if (result == null) return;
    try {
      await ref.read(invoiceRepositoryProvider).collectCredit(farmerId, amount: result.amount, mode: result.mode, reference: result.reference);
      ref
        ..invalidate(creditAccountProvider(farmerId))
        ..invalidate(creditBookProvider)
        ..invalidate(invoiceListProvider)
        ..invalidate(dailyClosingProvider);
      messenger.showSnackBar(SnackBar(content: Text('${formatRupeesExact(result.amount)} received.')));
    } catch (err) {
      messenger.showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final account = ref.watch(creditAccountProvider(farmerId));
    return Scaffold(
      appBar: AppBar(title: Text(account.value?.farmer.name ?? 'Credit account')),
      body: ResponsiveScope(
        child: account.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(creditAccountProvider(farmerId))),
          data: (a) => ListView(padding: context.pagePadding, children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: a.balance > 0 ? colors.danger.withValues(alpha: 0.1) : colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(children: [
                Text(formatRupeesExact(a.balance), key: const Key('account-balance'), style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text(a.balance > 0 ? 'still to pay' : 'nothing owed', style: text.bodyMedium),
              ]),
            ),
            AppSpacing.gapMd,
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
              if (a.balance > 0) FilledButton.icon(key: const Key('collect'), onPressed: () => _collect(context, ref, a), icon: const Icon(Icons.payments_outlined), label: const Text('Collect payment')),
              if (a.balance > 0 && a.farmer.phone.isNotEmpty)
                OutlinedButton.icon(
                  key: const Key('remind'),
                  onPressed: () => (launcher ?? (u) => launchUrl(u, mode: LaunchMode.externalApplication))(whatsAppReminder(phone: a.farmer.phone, name: a.farmer.name, due: a.balance, centerName: centerName)),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Remind on WhatsApp'),
                ),
            ]),
            if (a.dueInvoices.isNotEmpty) ...[
              AppSpacing.gapLg,
              Text('Unpaid bills', style: text.titleMedium),
              for (final inv in a.dueInvoices)
                ListTile(
                  key: Key('due-${inv.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(inv.number),
                  subtitle: Text(inv.dueDate == null ? 'No due date' : 'Due ${inv.dueDate!.day}/${inv.dueDate!.month}/${inv.dueDate!.year}'),
                  trailing: Text(formatRupeesExact(inv.balanceDue), style: text.titleSmall),
                  onTap: () => context.push(invoiceRoute(InvoiceScope.operator, inv.id)),
                ),
            ],
            AppSpacing.gapLg,
            Text('History', style: text.titleMedium),
            for (final e in a.entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(e.note.isEmpty ? e.kind : e.note),
                subtitle: Text('${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}'),
                trailing: Text('${e.amount > 0 ? '+' : '-'}${formatRupeesExact(e.amount.abs())}', style: text.titleSmall?.copyWith(color: e.amount > 0 ? colors.danger : colors.success)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _CollectSheet extends StatefulWidget {
  const _CollectSheet({required this.balance});

  final double balance;

  @override
  State<_CollectSheet> createState() => _CollectSheetState();
}

class _CollectSheetState extends State<_CollectSheet> {
  late final _amount = TextEditingController(text: widget.balance.toStringAsFixed(widget.balance == widget.balance.roundToDouble() ? 0 : 2));
  final _reference = TextEditingController();
  String _mode = 'cash';
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Collect payment', style: Theme.of(context).textTheme.titleMedium),
          Text('Settles the oldest bills first. ${formatRupeesExact(widget.balance)} is owed.', style: Theme.of(context).textTheme.bodySmall),
          AppSpacing.gapMd,
          TextField(key: const Key('collect-amount'), controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount received')),
          AppSpacing.gapSm,
          Wrap(spacing: AppSpacing.sm, children: [for (final m in payModes) ChoiceChip(key: Key('collect-mode-$m'), label: Text(paymentModeLabels[m]!), selected: _mode == m, onSelected: (_) => setState(() => _mode = m))]),
          if (_mode != 'cash') ...[AppSpacing.gapSm, TextField(key: const Key('collect-reference'), controller: _reference, decoration: const InputDecoration(labelText: 'Transaction id (UTR), optional'))],
          if (_error != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(_error!, key: const Key('collect-error'), style: TextStyle(color: context.colors.danger))),
          AppSpacing.gapMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('collect-save'),
              onPressed: () {
                final amount = double.tryParse(_amount.text.trim());
                if (amount == null || amount <= 0) return setState(() => _error = 'Enter the amount received');
                if (amount > widget.balance + 0.001) return setState(() => _error = 'That is more than the ${formatRupeesExact(widget.balance)} owed');
                Navigator.pop(context, (amount: amount, mode: _mode, reference: _reference.text.trim()));
              },
              child: const Text('Save'),
            ),
          ),
        ]),
      );
}
