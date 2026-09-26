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
import '../delivery/presentation/providers/document_picker.dart';
import '../farmer/centers/presentation/providers/centers_providers.dart';
import 'own_api.dart';
import 'own_market_screens.dart';
import 'own_sales_screens.dart';

Tone listingTone(String s) => switch (s) { 'approved' => Tone.good, 'pending' => Tone.warn, 'rejected' || 'hidden' => Tone.bad, _ => Tone.neutral };
String listingText(String s) => switch (s) { 'draft' => 'Not sent', 'pending' => 'Being checked', 'approved' => 'On sale', 'rejected' => 'Sent back', 'hidden' => 'Hidden', 'paused' => 'Paused', 'sold_out' => 'Sold out', 'expired' => 'Expired', _ => s };

/// What I make and sell: my listings with their check, my earnings, and a way to add a new one.
class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final mine = ref.watch(myListingsProvider);
    final summary = ref.watch(ownSummaryProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Tx('My home-made products'),
        actions: [IconButton(key: const Key('open-my-sales'), tooltip: 'Orders', icon: const Icon(Icons.receipt_long_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OwnSalesScreen())))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('listing-add'),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ListingEditorScreen()));
          ref.invalidate(myListingsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Tx('Add a product'),
      ),
      body: ResponsiveScope(
        child: mine.when(
          skipLoadingOnReload: true,
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myListingsProvider)),
          data: (list) => RefreshIndicator(
            onRefresh: () => ref.refresh(myListingsProvider.future),
            child: ListView(padding: context.pagePadding.copyWith(bottom: 96), children: [
              if (summary != null)
                KitCard(
                  title: 'Your earnings',
                  icon: Icons.savings_outlined,
                  child: Column(children: [
                    KitRow('Earned so far', formatRupeesExact(summary.obj('sales').num_('earned'))),
                    KitRow('This month', formatRupeesExact(summary.obj('sales').num_('month'))),
                    if (summary.obj('sales').num_('owed') > 0) KitRow('Platform share to pay a center', formatRupeesExact(summary.obj('sales').num_('owed'))),
                  ]),
                ),
              if (list.isEmpty)
                Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('Make compost, vermicompost or jeevamrut? List it here. A village center checks it, and farmers near you can buy it.', key: const Key('listings-empty'), textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted))),
              for (final (i, l) in list.indexed)
                KitCard(
                  index: i + 1,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ListingEditorScreen(existing: l)));
                    ref.invalidate(myListingsProvider);
                  },
                  title: l.str('name'),
                  trailing: StatusPill(listingText(l.str('status')), tone: listingTone(l.str('status'))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${formatRupeesExact(l.num_('pricePerUnit'))} per ${l.str('unit')} · ${l.num_('quantityAvailable').toStringAsFixed(0)} ${l.str('unit')} left · ${l.int_('soldCount')} sold', key: Key('mine-${l.str('id')}'), style: text.bodyMedium),
                    if (l.str('rejectionReason').isNotEmpty) Text('Sent back: ${l.str('rejectionReason')}', style: text.bodySmall?.copyWith(color: colors.danger)),
                    if (l.str('hiddenReason').isNotEmpty) Text('Hidden: ${l.str('hiddenReason')}', style: text.bodySmall?.copyWith(color: colors.danger)),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Makes or changes one product, adds its photos and lab report, and sends it to a village center to be checked.
class ListingEditorScreen extends ConsumerStatefulWidget {
  const ListingEditorScreen({super.key, this.existing});

  final Json? existing;

  @override
  ConsumerState<ListingEditorScreen> createState() => _ListingEditorScreenState();
}

class _ListingEditorScreenState extends ConsumerState<ListingEditorScreen> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.str('name'));
  late final _desc = TextEditingController(text: widget.existing?.str('description'));
  late final _materials = TextEditingController(text: widget.existing?.str('materials'));
  late final _qty = TextEditingController(text: widget.existing == null ? '' : widget.existing!.num_('quantityAvailable').toStringAsFixed(0));
  late final _price = TextEditingController(text: widget.existing == null ? '' : widget.existing!.num_('pricePerUnit').toString());
  late final _min = TextEditingController(text: widget.existing == null ? '1' : widget.existing!.num_('minOrder').toString());
  late final _village = TextEditingController(text: widget.existing?.str('village'));
  late String _category = widget.existing?.str('category', 'compost') ?? 'compost';
  late String _unit = widget.existing?.str('unit', 'kg') ?? 'kg';
  late bool _organic = widget.existing?.flag('organicConfirmed') ?? false;
  String? _id;
  Json? _saved;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _id = widget.existing?.str('id');
    _saved = widget.existing;
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _materials, _qty, _price, _min, _village]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _status => _saved?.str('status', 'draft') ?? 'draft';
  bool get _locked => _status == 'pending' || _status == 'hidden';

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) snack(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    await _run(() async {
      final here = await ref.read(farmerLocationProvider.future);
      final body = <String, dynamic>{
        'category': _category, 'name': _name.text.trim(), 'description': _desc.text.trim(), 'materials': _materials.text.trim(), 'unit': _unit,
        'quantityAvailable': double.parse(_qty.text.trim()), 'pricePerUnit': double.parse(_price.text.trim()), 'minOrder': double.tryParse(_min.text.trim()) ?? 1,
        'village': _village.text.trim(), 'organicConfirmed': _organic,
        if (here != null) ...{'pickupLatitude': here.latitude, 'pickupLongitude': here.longitude, 'pickupLabel': here.label ?? _village.text.trim()},
      };
      final api = ref.read(ownApiProvider);
      _saved = _id == null ? await api.create(body) : await api.update(_id!, body);
      _id = _saved!.str('id');
      ref.invalidate(myListingsProvider);
      if (mounted) {
        setState(() {});
        snack(context, 'Saved. Now add photos, then send it for checking.');
      }
    });
  }

  Future<void> _photo(int position) => _run(() async {
        final camera = await showModalBottomSheet<bool>(
          context: context,
          builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take a photo'), onTap: () => Navigator.pop(context, true)),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(context, false)),
          ])),
        );
        if (camera == null) return;
        final doc = await ref.read(documentPickerProvider).pick(camera: camera);
        if (doc == null) return;
        await ref.read(ownApiProvider).uploadPhoto(_id!, position, doc.bytes);
        ref.invalidate(apiImageProvider('/v1/own/listings/$_id/photos/$position'));
        _saved = (await ref.read(ownApiProvider).mine()).where((x) => x.str('id') == _id).firstOrNull ?? _saved;
        if (mounted) setState(() {});
      });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final photos = _saved?.int_('photoCount') ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(_id == null ? 'Add a product' : 'My product'), actions: [if (_saved != null) Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: StatusPill(listingText(_status), tone: listingTone(_status))))]),
      body: ResponsiveScope(
        child: Form(
          key: _key,
          child: ListView(padding: context.pagePadding, children: [
            if (_status == 'rejected') KitCard(child: Text('Sent back: ${_saved!.str('rejectionReason')}. Fix it and send it again.', key: const Key('listing-rejected'), style: text.bodyMedium?.copyWith(color: colors.danger))),
            if (_status == 'approved') const KitCard(child: Text('Changing the name, kind or materials sends it back for checking.')),
            Wrap(spacing: 8, children: [for (final e in ownCategoryLabels.entries) ChoiceChip(key: Key('kind-${e.key}'), label: Text(e.value), selected: _category == e.key, onSelected: _locked ? null : (_) => setState(() => _category = e.key))]),
            AppSpacing.gapMd,
            TextFormField(key: const Key('listing-name'), controller: _name, enabled: !_locked, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v ?? '').trim().length < 2 ? 'Give it a name' : null),
            AppSpacing.gapSm,
            TextFormField(key: const Key('listing-materials'), controller: _materials, enabled: !_locked, maxLines: 2, decoration: const InputDecoration(labelText: 'What is it made from?', hintText: 'Cow dung, dry leaves, earthworms…')),
            AppSpacing.gapSm,
            TextFormField(controller: _desc, enabled: !_locked, maxLines: 3, decoration: const InputDecoration(labelText: 'About it (optional)')),
            AppSpacing.gapSm,
            Row(children: [
              Expanded(child: TextFormField(key: const Key('listing-price'), controller: _price, enabled: !_locked, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price (₹)'), validator: (v) => (double.tryParse((v ?? '').trim()) ?? 0) <= 0 ? 'Enter a price' : null)),
              AppSpacing.gapSm,
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<String>(initialValue: _unit, decoration: const InputDecoration(labelText: 'per'), items: const [DropdownMenuItem(value: 'kg', child: Text('kg')), DropdownMenuItem(value: 'litre', child: Text('litre')), DropdownMenuItem(value: 'bag', child: Text('bag'))], onChanged: _locked ? null : (v) => setState(() => _unit = v ?? 'kg')),
              ),
            ]),
            AppSpacing.gapSm,
            Row(children: [
              Expanded(child: TextFormField(key: const Key('listing-qty'), controller: _qty, enabled: !_locked, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'How much you have'), validator: (v) => double.tryParse((v ?? '').trim()) == null ? 'Enter a quantity' : null)),
              AppSpacing.gapSm,
              Expanded(child: TextFormField(controller: _min, enabled: !_locked, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Least one can buy'))),
            ]),
            AppSpacing.gapSm,
            TextFormField(controller: _village, enabled: !_locked, decoration: const InputDecoration(labelText: 'Village')),
            CheckboxListTile(key: const Key('listing-organic'), contentPadding: EdgeInsets.zero, value: _organic, onChanged: _locked ? null : (v) => setState(() => _organic = v ?? false), title: const Text('I promise it is organic: no chemical fertilizer or pesticide')),
            AppSpacing.gapSm,
            AppButton(key: const Key('listing-save'), label: 'Save', expand: true, isLoading: _busy, onPressed: _locked ? null : _save),
            if (_id != null) ...[
              AppSpacing.gapLg,
              Text('Photos ($photos of at least 2)', style: text.titleSmall),
              AppSpacing.gapSm,
              Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < (photos + 1).clamp(2, 6); i++) PhotoSlot(key: Key('lphoto-$i'), label: 'Photo ${i + 1}', done: i < photos, previewPath: '/v1/own/listings/$_id/photos/$i', busy: _busy, onPick: _locked ? null : () => _photo(i))]),
              AppSpacing.gapLg,
              if (_status == 'draft' || _status == 'rejected')
                AppButton(
                  key: const Key('listing-submit'),
                  label: 'Send for checking',
                  expand: true,
                  isLoading: _busy,
                  onPressed: () => _run(() async {
                    _saved = await ref.read(ownApiProvider).submit(_id!);
                    ref.invalidate(myListingsProvider);
                    if (context.mounted) {
                      setState(() {});
                      snack(context, 'Sent to a village center. You will be told when it is checked.');
                    }
                  }),
                ),
              if (_status == 'approved' || _status == 'paused')
                AppButton(
                  key: const Key('listing-pause'),
                  label: _status == 'paused' ? 'Put it on sale again' : 'Pause selling',
                  variant: AppButtonVariant.outlined,
                  expand: true,
                  isLoading: _busy,
                  onPressed: () => _run(() async {
                    final api = ref.read(ownApiProvider);
                    _saved = _status == 'paused' ? await api.resume(_id!) : await api.pause(_id!);
                    ref.invalidate(myListingsProvider);
                    if (mounted) setState(() {});
                  }),
                ),
              if (_status == 'draft' || _status == 'rejected')
                TextButton.icon(
                  key: const Key('listing-delete'),
                  onPressed: () => _run(() async {
                    await ref.read(ownApiProvider).remove(_id!);
                    if (context.mounted) Navigator.of(context).pop();
                  }),
                  icon: Icon(Icons.delete_outline, color: colors.danger),
                  label: Text('Delete', style: TextStyle(color: colors.danger)),
                ),
            ],
          ]),
        ),
      ),
    );
  }
}
