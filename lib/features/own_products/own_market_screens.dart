import 'package:flutter/material.dart';
import '../../core/l10n/app_locale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/price_format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import '../farmer/centers/presentation/providers/centers_providers.dart';
import 'own_api.dart';
import 'own_sales_screens.dart';

const ownCategoryLabels = {'compost': 'Compost', 'vermicompost': 'Vermicompost', 'liquid': 'Liquid', 'bio_fertilizer': 'Bio-fertilizer', 'other': 'Other'};

/// Organic products other farmers make, with a "Farmer-made" badge, sorted by distance by default.
class OwnMarketScreen extends ConsumerStatefulWidget {
  const OwnMarketScreen({super.key});

  @override
  ConsumerState<OwnMarketScreen> createState() => _OwnMarketScreenState();
}

class _OwnMarketScreenState extends ConsumerState<OwnMarketScreen> {
  String _category = '';
  String _sort = 'nearest';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final key = '$_category|$_sort|$_search';
    final market = ref.watch(ownMarketProvider(key));
    return Scaffold(
      appBar: AppBar(
        title: const Tx('Farmer-made products'),
        actions: [IconButton(key: const Key('open-my-orders'), tooltip: 'My orders', icon: const Icon(Icons.receipt_long_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OwnSalesScreen())))],
      ),
      body: ResponsiveScope(
        child: ListView(padding: context.pagePadding, children: [
          TextField(key: const Key('market-search'), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search compost, vermicompost, village…'), onSubmitted: (v) => setState(() => _search = v.trim().replaceAll('|', ' '))),
          AppSpacing.gapSm,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              ChoiceChip(key: const Key('cat-all'), label: const Tx('All'), selected: _category.isEmpty, onSelected: (_) => setState(() => _category = '')),
              for (final e in ownCategoryLabels.entries) Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(key: Key('cat-${e.key}'), label: Text(e.value), selected: _category == e.key, onSelected: (_) => setState(() => _category = e.key))),
            ]),
          ),
          AppSpacing.gapSm,
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            Tx('Sort', style: text.labelLarge),
            AppSpacing.gapSm,
            for (final s in const [('nearest', 'Nearest'), ('cheapest', 'Cheapest'), ('rating', 'Best rated'), ('newest', 'Newest')])
              Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(key: Key('sort-${s.$1}'), label: Text(s.$2), selected: _sort == s.$1, onSelected: (_) => setState(() => _sort = s.$1))),
          ])),
          AppSpacing.gapMd,
          market.when(
            skipLoadingOnReload: true,
            loading: () => const SizedBox(height: 200, child: AppLoadingIndicator()),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(ownMarketProvider(key))),
            data: (items) => items.isEmpty
                ? Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('Nothing here yet. Farmers near you will list what they make.', key: const Key('market-empty'), textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted)))
                : Column(children: [
                    for (final (i, l) in items.indexed)
                      KitCard(
                        index: i,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OwnDetailScreen(listingId: l.str('id')))),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ApiImage('/v1/own/listings/${l.str('id')}/photos/0', height: 84, width: 84, zoomable: false),
                          AppSpacing.gapMd,
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(l.str('name'), key: Key('listing-${l.str('id')}'), style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800))), const StatusPill('Farmer-made', tone: Tone.good)]),
                              Text('${formatRupeesExact(l.num_('pricePerUnit'))} per ${l.str('unit')}  ·  ${l.num_('quantityAvailable').toStringAsFixed(0)} ${l.str('unit')} left', style: text.bodyMedium),
                              Text('${l.str('sellerName')}, ${l.str('village')}${l['distanceKm'] == null ? '' : '  ·  ${l.num_('distanceKm').toStringAsFixed(1)} km'}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                              if (l.int_('ratingCount') > 0) Text('★ ${l.num_('ratingAvg').toStringAsFixed(1)} (${l.int_('ratingCount')})', style: text.bodySmall),
                            ]),
                          ),
                        ]),
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }
}

/// One product: photos, who made it, what it is made of, the lab values if any, reviews, and ordering.
class OwnDetailScreen extends ConsumerStatefulWidget {
  const OwnDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<OwnDetailScreen> createState() => _OwnDetailScreenState();
}

class _OwnDetailScreenState extends ConsumerState<OwnDetailScreen> {
  final _qty = TextEditingController(text: '1');
  final _phone = TextEditingController();
  String _fulfilment = 'farm_pickup';
  bool _busy = false;

  @override
  void dispose() {
    _qty.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _order(Json l) async {
    final qty = double.tryParse(_qty.text.trim()) ?? 0;
    if (qty <= 0) {
      snack(context, 'Say how much you want');
      return;
    }
    setState(() => _busy = true);
    try {
      Json? address;
      if (_fulfilment == 'delivery') {
        final here = await ref.read(farmerLocationProvider.future);
        if (here == null) throw 'Set your village first, so we know where to bring it.';
        address = {'latitude': here.latitude, 'longitude': here.longitude, 'label': here.label ?? '', 'village': here.label ?? '', 'phone': _phone.text.trim()};
      }
      final sale = await ref.read(ownApiProvider).order(widget.listingId, quantity: qty, fulfilment: _fulfilment, address: address);
      ref.invalidate(ownDetailProvider(widget.listingId));
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => OwnSaleScreen(saleId: sale.str('id'))));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final detail = ref.watch(ownDetailProvider(widget.listingId));
    return Scaffold(
      appBar: AppBar(title: const Tx('Product')),
      body: ResponsiveScope(
        child: detail.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(ownDetailProvider(widget.listingId))),
          data: (l) {
            final lab = l.obj('labValues');
            final total = (double.tryParse(_qty.text.trim()) ?? 0) * l.num_('pricePerUnit');
            return ListView(padding: context.pagePadding, children: [
              SizedBox(
                height: 180,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (var i = 0; i < l.int_('photoCount'); i++) Padding(padding: const EdgeInsets.only(right: 8), child: ApiImage('/v1/own/listings/${l.str('id')}/photos/$i', height: 180, width: 240)),
                ]),
              ),
              AppSpacing.gapMd,
              Row(children: [Expanded(child: Text(l.str('name'), style: text.headlineSmall)), const StatusPill('Farmer-made', tone: Tone.good)]),
              Text('${formatRupeesExact(l.num_('pricePerUnit'))} per ${l.str('unit')}', key: const Key('detail-price'), style: text.titleMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
              AppSpacing.gapSm,
              KitCard(
                title: 'About',
                child: Column(children: [
                  KitRow('Made by', '${l.str('sellerName')}, ${l.str('village')}'),
                  if (l.int_('sellerReviews') > 0) KitRow('Seller rating', '★ ${l.num_('sellerRating').toStringAsFixed(1)} (${l.int_('sellerReviews')} reviews)'),
                  KitRow('Made from', l.str('materials', '-')),
                  KitRow('Available', '${l.num_('quantityAvailable').toStringAsFixed(0)} ${l.str('unit')} (least ${l.num_('minOrder').toStringAsFixed(0)})'),
                  if (lab.isNotEmpty) KitRow('Lab N-P-K', '${lab.str('n', '-')} - ${lab.str('p', '-')} - ${lab.str('k', '-')} %'),
                  if (l.str('description').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(l.str('description'), style: text.bodyMedium)),
                  Padding(padding: const EdgeInsets.only(top: 6), child: Text('Checked by a village center before it was listed.', style: text.bodySmall?.copyWith(color: colors.textMuted))),
                ]),
              ),
              if (l.flag('canBuy'))
                KitCard(
                  index: 1,
                  title: 'Order',
                  icon: Icons.shopping_basket_outlined,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    TextField(key: const Key('order-qty'), controller: _qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: 'How much (${l.str('unit')})')),
                    AppSpacing.gapSm,
                    Wrap(spacing: 8, children: [
                      ChoiceChip(key: const Key('ful-pickup'), label: const Text('I pick it up at the farm'), selected: _fulfilment == 'farm_pickup', onSelected: (_) => setState(() => _fulfilment = 'farm_pickup')),
                      ChoiceChip(key: const Key('ful-delivery'), label: const Text('Bring it to me'), selected: _fulfilment == 'delivery', onSelected: (_) => setState(() => _fulfilment = 'delivery')),
                    ]),
                    if (_fulfilment == 'delivery') ...[
                      AppSpacing.gapSm,
                      TextField(key: const Key('order-phone'), controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Your phone (for the delivery partner)')),
                    ],
                    AppSpacing.gapMd,
                    Text('Total ${formatRupeesExact(total)}', style: text.titleMedium),
                    AppSpacing.gapSm,
                    AppButton(key: const Key('order-place'), label: 'Place order', expand: true, isLoading: _busy, onPressed: () => _order(l)),
                    Text('You pay the seller directly, in cash or UPI, when you receive it.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                  ]),
                )
              else
                KitCard(index: 1, child: Text('This product cannot be ordered right now.', style: text.bodyMedium)),
              KitCard(
                index: 2,
                title: 'Reviews',
                icon: Icons.star_outline,
                child: l.list('reviews').isEmpty
                    ? Text('No reviews yet.', style: text.bodyMedium)
                    : Column(children: [for (final r in l.list('reviews')) KitRow('${r.str('buyerName')}  ${'★' * r.int_('stars')}', r.str('comment', '-'))]),
              ),
              TextButton.icon(
                key: const Key('report-listing'),
                onPressed: () async {
                  final reason = await showDialog<String>(context: context, builder: (_) => const _ReasonDialog());
                  if (reason == null || !context.mounted) return;
                  try {
                    await ref.read(ownApiProvider).report(widget.listingId, reason);
                    if (context.mounted) snack(context, 'Thank you. The village center will look at it.');
                  } catch (e) {
                    if (context.mounted) snack(context, '$e');
                  }
                },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report a problem with this product'),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('What is wrong?'),
        content: TextField(controller: _c, maxLength: 200, autofocus: true),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Tx('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, _c.text.trim().isEmpty ? null : _c.text.trim()), child: const Tx('Send'))],
      );
}
