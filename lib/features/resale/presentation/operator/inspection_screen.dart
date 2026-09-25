import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../farmer/marketplace/domain/entities/product.dart';
import '../../../farmer/marketplace/presentation/providers/marketplace_providers.dart';
import '../../domain/resale_models.dart';
import '../farmer/sell_surplus_form_screen.dart' show isoDay;
import '../resale_providers.dart';

const sealChoices = {
  'sealed': 'Sealed, unopened',
  'opened_resealed': 'Opened, resealed',
  'loose': 'Loose',
  'damaged_packaging': 'Damaged packaging',
};

const solidVisuals = {'free_flowing': 'Free flowing', 'clumped': 'Clumped', 'wet': 'Wet'};
const liquidVisuals = {'clear': 'Clear', 'cloudy': 'Cloudy', 'separated': 'Separated'};

/// The reasons the goods cannot be accepted, for what the operator has entered so far. The server enforces the same rules.
List<String> inspectionBlocks({required bool productMatches, required String seal, required String visual, required String batch, required DateTime? expiry, DateTime? now}) {
  final today = now ?? DateTime.now();
  final blocks = <String>[];
  if (!productMatches) blocks.add('The bag cannot be matched to a product sold on the platform');
  if (expiry != null && !expiry.isAfter(DateTime(today.year, today.month, today.day))) blocks.add('The product has expired');
  if (seal == 'damaged_packaging') blocks.add('The packaging is severely damaged');
  if (visual == 'wet') blocks.add('The product is wet or spoiled');
  if (batch.trim().length < 2) blocks.add('The batch number is missing or unreadable');
  return blocks;
}

/// The physical check at the counter. Given a [listingId] it inspects that farmer's listing; without one it takes in
/// goods from someone at the counter (a "walk-in"), asking who is selling and what.
class InspectionScreen extends ConsumerWidget {
  const InspectionScreen({super.key, this.listingId});

  final String? listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (listingId == null) return const _Form();
    final listing = ref.watch(resaleQueueProvider(resaleEveryStatus));
    return listing.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Inspect goods')), body: const AppLoadingIndicator()),
      error: (err, _) => Scaffold(appBar: AppBar(title: const Text('Inspect goods')), body: AppErrorView(message: '$err')),
      data: (all) => _Form(listing: all.firstWhere((l) => l.id == listingId)),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({this.listing});

  final ResaleListing? listing;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  bool _matches = true;
  String _seal = 'sealed';
  String _visual = 'free_flowing';
  late int _units = widget.listing?.units ?? 1;
  DateTime? _mfg;
  DateTime? _expiry;
  late final _batch = TextEditingController(text: widget.listing?.batchNumber ?? '');
  final _upi = TextEditingController();
  final _sellerSearch = TextEditingController();
  final _newName = TextEditingController();
  final _newPhone = TextEditingController();
  bool _proof = false;
  double? _price;
  PriceGuide? _guide;
  Product? _product;
  SellerMatch? _seller;
  bool _noAccount = false;
  PayoutMode _payout = PayoutMode.wallet;
  List<SellerMatch> _matches0 = const [];
  Timer? _debounce;
  bool _saving = false;
  String? _error;

  ResaleListing? get _listing => widget.listing;
  String get _productId => _listing?.productId ?? _product?.id ?? '';
  bool get _isLiquid => (_listing?.unit ?? _product?.unitLabel ?? '').contains(RegExp(r'\bL\b|litre|liter', caseSensitive: false)) && !(_listing?.unit ?? _product?.unitLabel ?? '').contains('kg');

  @override
  void initState() {
    super.initState();
    final l = _listing;
    if (l != null) {
      _expiry = DateTime.tryParse(l.expiryDate);
      _mfg = l.mfgDate == null ? null : DateTime.tryParse(l.mfgDate!);
      _price = l.price;
      _seal = switch (l.condition) { ResaleCondition.sealed => 'sealed', ResaleCondition.opened => 'opened_resealed', ResaleCondition.partiallyUsed => 'loose' };
      _visual = _isLiquid ? 'clear' : 'free_flowing';
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshGuide());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_batch, _upi, _sellerSearch, _newName, _newPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  ResaleCondition get _condition => switch (_seal) { 'sealed' => ResaleCondition.sealed, 'opened_resealed' => ResaleCondition.opened, _ => ResaleCondition.partiallyUsed };

  Future<void> _refreshGuide() async {
    if (_productId.isEmpty) return;
    try {
      final g = await ref.read(resaleRepositoryProvider).suggestAtCounter(productId: _productId, condition: _condition, visual: _visual, mfgDate: _mfg == null ? null : isoDay(_mfg!));
      if (!mounted) return;
      setState(() {
        _guide = g;
        final current = _listing?.price;
        // At the counter a listing's price can only be lowered: start from the lower of the asking and suggested price.
        _price = current != null ? (g.suggested < current ? g.suggested : current) : g.suggested;
      });
    } catch (_) {}
  }

  void _searchSellers(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().length < 2) {
        setState(() => _matches0 = const []);
        return;
      }
      try {
        final found = await ref.read(resaleRepositoryProvider).findSellers(q.trim());
        if (mounted) setState(() => _matches0 = found);
      } catch (_) {}
    });
  }

  Future<void> _pickDate({required bool expiry}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: expiry ? (_expiry ?? now.add(const Duration(days: 365))) : (_mfg ?? now.subtract(const Duration(days: 90))),
      firstDate: expiry ? now.subtract(const Duration(days: 365)) : DateTime(now.year - 5),
      lastDate: expiry ? DateTime(now.year + 6) : now,
      helpText: expiry ? 'Expiry date on the bag' : 'Manufacturing date on the bag',
    );
    if (picked == null) return;
    setState(() => expiry ? _expiry = picked : _mfg = picked);
    if (!expiry) _refreshGuide();
  }

  List<String> get _blocks => inspectionBlocks(productMatches: _matches, seal: _seal, visual: _visual, batch: _batch.text, expiry: _expiry);

  String? get _missing {
    if (_listing == null) {
      if (_product == null) return 'Choose the product';
      if (!_noAccount && _seller == null) return 'Choose the seller, or mark them as having no account';
      if (_noAccount && (_newName.text.trim().isEmpty || _newPhone.text.trim().length < 8)) return 'Enter the seller\'s name and phone number';
    }
    if (_expiry == null) return 'Enter the expiry date from the bag';
    if (_price == null) return 'Waiting for the price range';
    if (_payout == PayoutMode.upi && _listing == null && !_noAccount && !RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$').hasMatch(_upi.text.trim())) return 'Enter the UPI id, like name@bank';
    return null;
  }

  Future<void> _submit() async {
    final missing = _missing;
    if (missing != null) {
      setState(() => _error = missing);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final checklist = InspectionChecklist(
      productMatches: _matches,
      seal: _seal,
      units: _units,
      mfgDate: _mfg == null ? null : isoDay(_mfg!),
      expiryDate: isoDay(_expiry!),
      batchNumber: _batch.text.trim(),
      visual: _visual,
      purchaseProofSeen: _proof,
      unitPrice: _price,
      upiId: _upi.text.trim(),
    );
    final repo = ref.read(resaleRepositoryProvider);
    try {
      if (_listing != null) {
        await repo.inspect(_listing!.id, checklist);
      } else {
        await repo.walkIn(
          sellerId: _noAccount ? null : _seller!.sellerId,
          sellerName: _noAccount ? _newName.text.trim() : null,
          sellerPhone: _noAccount ? _newPhone.text.trim() : null,
          productId: _product!.id,
          payoutMode: _noAccount ? PayoutMode.cash : _payout,
          checklist: checklist,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_listing != null ? 'Accepted. It is listed at the center.' : 'Taken in and listed for sale.')));
      setState(() => _saving = false);
      Navigator.of(context).maybePop();
    } catch (err) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$err';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final walkIn = _listing == null;
    final blocks = _blocks;
    final visuals = _isLiquid ? liquidVisuals : solidVisuals;
    final products = walkIn ? ref.watch(productsProvider).value?.where((p) => p.category == ProductCategory.organic).toList() ?? const <Product>[] : const <Product>[];

    return Scaffold(
      appBar: AppBar(title: Text(walkIn ? 'Take in goods' : 'Inspect goods')),
      body: ResponsiveScope(
        child: ListView(
          padding: context.pagePadding.copyWith(bottom: AppSpacing.xl),
          children: [
            if (!walkIn) ...[
              Text('${_listing!.units} × ${_listing!.productName}', style: text.titleLarge),
              Text('${_listing!.sellerDisplayName}  ·  listed at ${formatRupees(_listing!.askingPrice)} each', style: text.bodySmall?.copyWith(color: colors.textMuted)),
              AppSpacing.gapMd,
            ],
            if (walkIn) ...[
              Text('Who is selling?', style: text.titleMedium),
              SwitchListTile(key: const Key('no-account'), contentPadding: EdgeInsets.zero, value: _noAccount, onChanged: (v) => setState(() => _noAccount = v), title: const Text('The seller has no account'), subtitle: const Text('They are paid in cash, and it does not count as a verified purchase.')),
              if (!_noAccount) ...[
                TextField(key: const Key('seller-search'), controller: _sellerSearch, onChanged: _searchSellers, decoration: const InputDecoration(labelText: 'Search a registered farmer by name, phone or village', prefixIcon: Icon(Icons.search_rounded))),
                for (final m in _matches0)
                  ListTile(key: Key('seller-${m.sellerId}'), contentPadding: EdgeInsets.zero, leading: Icon(_seller?.sellerId == m.sellerId ? Icons.check_circle_rounded : Icons.person_outline, color: colors.primary), title: Text(m.name), subtitle: Text('${m.village}${m.phone.isEmpty ? '' : '  ·  ${m.phone}'}'), onTap: () => setState(() => _seller = m)),
                if (_seller != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('Selling: ${_seller!.name}', key: const Key('chosen-seller'), style: text.titleSmall)),
              ] else ...[
                TextField(key: const Key('new-name'), controller: _newName, onChanged: (_) => setState(() {}), textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Seller\'s name')),
                AppSpacing.gapSm,
                TextField(key: const Key('new-phone'), controller: _newPhone, onChanged: (_) => setState(() {}), keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Seller\'s phone number')),
              ],
              AppSpacing.gapMd,
              Text('Which product?', style: text.titleMedium),
              AppSpacing.gapSm,
              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
                for (final p in products)
                  ChoiceChip(
                    key: Key('walkin-product-${p.id}'),
                    label: Text(p.name),
                    selected: _product?.id == p.id,
                    onSelected: (_) {
                      setState(() {
                        _product = p;
                        _units = 1;
                        _visual = _isLiquid ? 'clear' : 'free_flowing';
                      });
                      _refreshGuide();
                    },
                  ),
              ]),
              AppSpacing.gapMd,
            ],
            Text('Inspection checklist', style: text.titleMedium),
            SwitchListTile(key: const Key('matches'), contentPadding: EdgeInsets.zero, value: _matches, onChanged: (v) => setState(() => _matches = v), title: const Text('The bag matches a product we sell'), subtitle: const Text('Product identity')),
            Text('Seal and packaging', style: text.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              for (final e in sealChoices.entries)
                ChoiceChip(key: Key('seal-${e.key}'), label: Text(e.value), selected: _seal == e.key, onSelected: (_) { setState(() => _seal = e.key); _refreshGuide(); }),
            ]),
            AppSpacing.gapSm,
            Text(_isLiquid ? 'Look of the liquid' : 'Look of the granules', style: text.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, children: [
              for (final e in visuals.entries)
                ChoiceChip(key: Key('visual-${e.key}'), label: Text(e.value), selected: _visual == e.key, onSelected: (_) { setState(() => _visual = e.key); _refreshGuide(); }),
            ]),
            AppSpacing.gapSm,
            Row(children: [
              IconButton.outlined(key: const Key('units-minus'), onPressed: _units > 1 ? () => setState(() => _units--) : null, icon: const Icon(Icons.remove_rounded)),
              SizedBox(width: 56, child: Text('$_units', key: const Key('units'), textAlign: TextAlign.center, style: text.titleLarge)),
              IconButton.outlined(key: const Key('units-plus'), onPressed: (_listing == null || _units < _listing!.units) ? () => setState(() => _units++) : null, icon: const Icon(Icons.add_rounded)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('units counted or weighed${_listing != null ? ' (listed: ${_listing!.units})' : ''}', style: text.bodyMedium)),
            ]),
            AppSpacing.gapSm,
            Row(children: [
              Expanded(child: _DateBox(key: const Key('mfg'), label: 'Made on', value: _mfg, onTap: () => _pickDate(expiry: false))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _DateBox(key: const Key('expiry'), label: 'Expires on', value: _expiry, onTap: () => _pickDate(expiry: true))),
            ]),
            AppSpacing.gapSm,
            TextField(key: const Key('batch'), controller: _batch, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Batch number (from the bag)', prefixIcon: Icon(Icons.qr_code_2_rounded))),
            if (walkIn || !(_listing?.verifiedPurchase ?? false))
              SwitchListTile(key: const Key('proof'), contentPadding: EdgeInsets.zero, value: _proof, onChanged: (v) => setState(() => _proof = v), title: const Text('The farmer showed their platform order or receipt'), subtitle: const Text('Adds a "verified purchase" badge: buyers trust it more, and the seller keeps 89% instead of 86%.'))
            else
              Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [Icon(Icons.verified_rounded, color: colors.success, size: 18), const SizedBox(width: AppSpacing.xs), Expanded(child: Text('Verified: bought on the platform', style: text.bodyMedium))])),
            AppSpacing.gapSm,
            if (_guide != null && _price != null) _PriceBox(guide: _guide!, price: _price!.clamp(_guide!.min, _guide!.max).toDouble(), ceiling: _listing?.price, onChanged: (v) => setState(() => _price = v)),
            if (walkIn && !_noAccount) ...[
              AppSpacing.gapMd,
              Text('Payout', style: text.titleMedium),
              RadioGroup<PayoutMode>(
                groupValue: _payout,
                onChanged: (v) => setState(() => _payout = v!),
                child: Column(children: [for (final m in PayoutMode.values) RadioListTile<PayoutMode>(key: Key('payout-${m.api}'), contentPadding: EdgeInsets.zero, value: m, title: Text(m.label))]),
              ),
              if (_payout == PayoutMode.upi) TextField(key: const Key('upi'), controller: _upi, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Seller\'s UPI id', hintText: 'name@bank')),
            ],
            AppSpacing.gapMd,
            if (blocks.isNotEmpty)
              Container(
                key: const Key('blocks'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: colors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cannot be accepted', style: text.titleSmall?.copyWith(color: colors.danger)),
                  for (final b in blocks) Text('• $b', style: text.bodySmall?.copyWith(color: colors.danger)),
                ]),
              ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(_error!, key: const Key('form-error'), style: text.bodyMedium?.copyWith(color: colors.danger))),
            AppSpacing.gapMd,
            AppButton(label: walkIn ? 'Accept and list for sale' : 'Accept the goods', icon: Icons.check_rounded, expand: true, isLoading: _saving, onPressed: blocks.isEmpty ? _submit : null),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({super.key, required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: InputDecorator(decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_month_outlined)), child: Text(value == null ? 'Choose' : isoDay(value!))),
      );
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.guide, required this.price, required this.ceiling, required this.onChanged});

  final PriceGuide guide;
  final double price;

  /// A listing's own price: at the counter it can only be lowered.
  final double? ceiling;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final max = ceiling == null ? guide.max : (ceiling! < guide.max ? ceiling! : guide.max);
    final hi = max < guide.min ? guide.min : max;
    final p = price.clamp(guide.min, hi).toDouble();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Price per unit: ${formatRupees(p)}', key: const Key('counter-price'), style: text.titleMedium),
        Text('Suggested for what you see: ${formatRupees(guide.suggested)}  ·  range ${formatRupees(guide.min)} to ${formatRupees(guide.max)}${ceiling == null ? '' : '  ·  it can only be lowered from ${formatRupees(ceiling!)}'}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
        if (hi > guide.min) Slider(key: const Key('counter-slider'), value: p, min: guide.min, max: hi, divisions: (hi - guide.min).round().clamp(1, 400), onChanged: onChanged),
      ]),
    );
  }
}
