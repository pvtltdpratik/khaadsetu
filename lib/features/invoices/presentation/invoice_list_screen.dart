import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animation/fade_slide_in.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/price_format.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../domain/invoice_models.dart';
import '../pdf/invoice_output.dart';
import 'invoice_providers.dart';
import 'invoice_status_chip.dart';

/// Where a bill's own page is, for whoever is looking.
String invoiceRoute(InvoiceScope scope, String id) => switch (scope) {
      InvoiceScope.farmer => RoutePaths.farmerBill(id),
      InvoiceScope.operator => RoutePaths.operatorBill(id),
      InvoiceScope.admin => RoutePaths.adminInvoice(id),
    };

/// The bills for one role: a farmer's own, a center's, or everything (admin). Filter by payment, search by number or name.
class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key, required this.scope});

  final InvoiceScope scope;

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  late InvoiceQuery _query = InvoiceQuery(scope: widget.scope);
  final _search = TextEditingController();
  bool _exporting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final csv = await ref.read(invoiceRepositoryProvider).exportCsv(_query);
      await ref.read(invoiceOutputProvider).shareCsv(csv);
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final list = ref.watch(invoiceListProvider(_query));
    final canSearch = widget.scope != InvoiceScope.farmer;
    Widget chip(String key, String label, String? status) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(key: Key(key), label: Text(label), selected: _query.paymentStatus == status, onSelected: (_) => setState(() => _query = _query.copyWith(paymentStatus: status))),
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (widget.scope) { InvoiceScope.farmer => 'My bills', InvoiceScope.operator => 'Bills', InvoiceScope.admin => 'All invoices' }),
        actions: [
          if (widget.scope == InvoiceScope.admin)
            IconButton(key: const Key('export-invoices'), tooltip: 'Export to Excel', onPressed: _exporting ? null : _export, icon: _exporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.file_download_outlined)),
        ],
      ),
      body: ResponsiveScope(
        child: Column(children: [
          if (canSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: TextField(
                key: const Key('invoice-search'),
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Bill number or name'),
                onSubmitted: (v) => setState(() => _query = _query.copyWith(search: v)),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [chip('pay-all', 'All', null), chip('pay-unpaid', 'Unpaid', 'unpaid'), chip('pay-partial', 'Part paid', 'partial'), chip('pay-paid', 'Paid', 'paid'), chip('pay-refunded', 'Refunded', 'refunded')]),
          ),
          Expanded(
            child: list.when(
              loading: () => const AppLoadingIndicator(),
              error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(invoiceListProvider(_query))),
              data: (data) => RefreshIndicator(
                onRefresh: () => ref.refresh(invoiceListProvider(_query).future),
                child: ListView(padding: context.pagePadding, children: [
                  if (data.items.isNotEmpty)
                    Container(
                      key: const Key('invoice-summary'),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Row(children: [
                        Expanded(child: Text('${data.summary.count} bill${data.summary.count == 1 ? '' : 's'}  ·  ${formatRupeesExact(data.summary.total)}', style: text.titleSmall)),
                        if (data.summary.due > 0) Text('${formatRupeesExact(data.summary.due)} due', style: text.titleSmall?.copyWith(color: colors.danger)),
                      ]),
                    ),
                  AppSpacing.gapSm,
                  if (data.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(_query.isFiltered ? 'No bills match. Clear a filter to see more.' : 'No bills yet. Every sale, delivery and service will appear here.', key: const Key('no-invoices'), textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted)),
                    )
                  else
                    for (var i = 0; i < data.items.length; i++)
                      FadeSlideIn(index: i, child: _InvoiceTile(invoice: data.items[i], scope: widget.scope)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, required this.scope});

  final Invoice invoice;
  final InvoiceScope scope;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final date = '${invoice.issuedAt.day.toString().padLeft(2, '0')}/${invoice.issuedAt.month.toString().padLeft(2, '0')}/${invoice.issuedAt.year}';
    // A farmer sees the other side of the deal; the center and the admin see who bought.
    final who = scope == InvoiceScope.farmer && invoice.buyer.name.isNotEmpty && invoice.kind != 'delivery' ? invoice.seller.name : invoice.buyer.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md), side: BorderSide(color: colors.border)),
        child: InkWell(
          key: Key('invoice-${invoice.id}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.push(invoiceRoute(scope, invoice.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(invoice.number, style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text('$who  ·  ${invoiceKindLabels[invoice.kind] ?? invoice.kind}  ·  $date', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                ]),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatRupeesExact(invoice.grandTotal), style: text.titleSmall),
                const SizedBox(height: 4),
                InvoiceStatusChip(invoice: invoice),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
