import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/price_format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import 'own_api.dart';

Tone saleTone(String s) => switch (s) { 'completed' => Tone.good, 'cancelled' => Tone.bad, 'ready' => Tone.info, _ => Tone.warn };
String saleText(String s) => switch (s) { 'placed' => 'New', 'ready' => 'Ready', 'completed' => 'Done', _ => 'Cancelled' };

/// The orders of farmer-made products: what I sold and what I bought.
class OwnSalesScreen extends ConsumerWidget {
  const OwnSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Farmer-made orders'), bottom: const TabBar(tabs: [Tab(key: Key('tab-selling'), text: 'I sold'), Tab(key: Key('tab-buying'), text: 'I bought')])),
        body: ResponsiveScope(child: TabBarView(children: [_SalesList(role: 'seller'), _SalesList(role: 'buyer')])),
      ),
    );
  }
}

class _SalesList extends ConsumerWidget {
  const _SalesList({required this.role});

  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return ref.watch(ownSalesProvider(role)).when(
          skipLoadingOnReload: true,
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(ownSalesProvider(role))),
          data: (list) => RefreshIndicator(
            onRefresh: () => ref.refresh(ownSalesProvider(role).future),
            child: ListView(padding: context.pagePadding, children: [
              if (list.isEmpty) Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(role == 'seller' ? 'Nobody has ordered from you yet.' : 'You have not bought a farmer-made product yet.', key: Key('sales-empty-$role'), textAlign: TextAlign.center, style: text.bodyMedium)),
              for (final (i, s) in list.indexed)
                KitCard(
                  index: i,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OwnSaleScreen(saleId: s.str('id'))));
                    ref.invalidate(ownSalesProvider(role));
                  },
                  title: s.str('listingName'),
                  trailing: StatusPill(saleText(s.str('status')), tone: saleTone(s.str('status'))),
                  child: Text('${s.num_('quantity').toStringAsFixed(0)} ${s.str('unit')} · ${formatRupeesExact(s.num_('total'))} · ${role == 'seller' ? s.str('buyerName') : s.str('sellerName')}', key: Key('sale-${s.str('id')}'), style: text.bodyMedium),
                ),
            ]),
          ),
        );
  }
}

/// One order, from both sides. The buyer reads out the pickup code; the seller types it in and says how he was paid.
class OwnSaleScreen extends ConsumerStatefulWidget {
  const OwnSaleScreen({super.key, required this.saleId});

  final String saleId;

  @override
  ConsumerState<OwnSaleScreen> createState() => _OwnSaleScreenState();
}

class _OwnSaleScreenState extends ConsumerState<OwnSaleScreen> {
  final _otp = TextEditingController();
  String _mode = 'cash';
  bool _busy = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(OwnApi api) job, {String? done}) async {
    setState(() => _busy = true);
    try {
      await job(ref.read(ownApiProvider));
      ref.invalidate(ownSaleProvider(widget.saleId));
      if (done != null && mounted) snack(context, done);
    } catch (e) {
      if (mounted) snack(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rate() async {
    var stars = 5;
    final comment = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, set) => AlertDialog(
          title: const Text('How was it?'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 1; i <= 5; i++) IconButton(key: Key('star-$i'), onPressed: () => set(() => stars = i), icon: Icon(i <= stars ? Icons.star : Icons.star_border, color: Colors.amber))]),
            TextField(controller: comment, maxLength: 300, decoration: const InputDecoration(hintText: 'A word about the product (optional)')),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')), FilledButton(key: const Key('star-send'), onPressed: () => Navigator.pop(context, true), child: const Text('Send'))],
        ),
      ),
    );
    final text = comment.text.trim();
    comment.dispose();
    if (ok == true) await _run((api) => api.review(widget.saleId, stars: stars, comment: text), done: 'Thank you');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final sale = ref.watch(ownSaleProvider(widget.saleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: ResponsiveScope(
        child: sale.when(
          skipLoadingOnReload: true,
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(ownSaleProvider(widget.saleId))),
          data: (s) {
            final seller = s.str('role') == 'seller';
            final status = s.str('status');
            final open = status == 'placed' || status == 'ready';
            final pickup = s.str('fulfilment') == 'farm_pickup';
            return ListView(padding: context.pagePadding, children: [
              KitCard(
                title: s.str('listingName'),
                icon: Icons.eco_outlined,
                trailing: StatusPill(saleText(status), tone: saleTone(status)),
                child: Column(children: [
                  KitRow('Quantity', '${s.num_('quantity').toStringAsFixed(0)} ${s.str('unit')} × ${formatRupeesExact(s.num_('unitPrice'))}'),
                  KitRow('Total', formatRupeesExact(s.num_('total')), bold: true),
                  KitRow(seller ? 'Buyer' : 'Seller', seller ? s.str('buyerName') : s.str('sellerName')),
                  KitRow('Phone', seller ? s.str('buyerPhone', '-') : s.str('sellerPhone', '-')),
                  KitRow('How', pickup ? 'Pick up at the farm' : 'Delivery to the buyer'),
                  if (seller) ...[
                    KitRow('Platform share (${s.num_('commissionPercent').toStringAsFixed(1)}%)', formatRupeesExact(s.num_('commissionAmount'))),
                    KitRow('You receive', formatRupeesExact(s.num_('sellerNet')), bold: true),
                  ] else if (pickup) ...[
                    KitRow('Where', [s.str('pickupLabel'), s.str('pickupVillage')].where((x) => x.isNotEmpty).join(', ')),
                  ],
                  if (s.str('cancelledReason').isNotEmpty) KitRow('Cancelled', s.str('cancelledReason')),
                ]),
              ),
              if (!seller && s['pickupCode'] != null)
                KitCard(
                  index: 1,
                  title: 'Your pickup code',
                  icon: Icons.pin_outlined,
                  child: Column(children: [
                    Text(s.str('pickupCode'), key: const Key('pickup-code'), style: text.displayMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 8, color: colors.primary)),
                    Text('Tell this code to the seller when you receive the product. Pay him in cash or UPI.', textAlign: TextAlign.center, style: text.bodyMedium),
                  ]),
                ),
              if (seller && open)
                KitCard(
                  index: 1,
                  title: 'Your part',
                  icon: Icons.handshake_outlined,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (status == 'placed') AppButton(key: const Key('sale-ready'), label: 'Mark ready', expand: true, isLoading: _busy, onPressed: () => _run((api) => api.ready(widget.saleId), done: 'The buyer is told')),
                    if (pickup) ...[
                      AppSpacing.gapSm,
                      TextField(key: const Key('sale-otp'), controller: _otp, maxLength: 4, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Code the buyer tells you')),
                      Wrap(spacing: 8, children: [
                        ChoiceChip(key: const Key('pay-cash'), label: const Text('Paid in cash'), selected: _mode == 'cash', onSelected: (_) => setState(() => _mode = 'cash')),
                        ChoiceChip(key: const Key('pay-upi'), label: const Text('Paid by UPI'), selected: _mode == 'upi', onSelected: (_) => setState(() => _mode = 'upi')),
                      ]),
                      AppSpacing.gapSm,
                      AppButton(key: const Key('sale-complete'), label: 'Handed over, paid', expand: true, isLoading: _busy, onPressed: () => _run((api) => api.complete(widget.saleId, otp: _otp.text.trim(), mode: _mode), done: 'Done. A bill was made.')),
                    ] else if (s['deliveryJobId'] == null)
                      AppButton(key: const Key('sale-delivery'), label: 'Ask a partner to deliver', expand: true, isLoading: _busy, onPressed: () => _run((api) => api.requestDelivery(widget.saleId, weightKg: s.num_('quantity')), done: 'Delivery partners near you are asked')),
                    if (s['deliveryJobId'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('A delivery partner is arranged. The buyer pays him on delivery.', style: text.bodyMedium)),
                  ]),
                ),
              if (open)
                TextButton.icon(
                  key: const Key('sale-cancel'),
                  onPressed: _busy ? null : () => _run((api) => api.cancel(widget.saleId, reason: seller ? 'Cancelled by the seller' : 'Cancelled by the buyer')),
                  icon: Icon(Icons.close, color: colors.danger),
                  label: Text('Cancel this order', style: TextStyle(color: colors.danger)),
                ),
              if (!seller && status == 'completed' && !s.flag('reviewed'))
                AppButton(key: const Key('sale-rate'), label: 'Rate the seller', expand: true, onPressed: _rate),
            ]);
          },
        ),
      ),
    );
  }
}
