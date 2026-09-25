import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../delivery/presentation/providers/document_picker.dart';
import '../../../farmer/centers/domain/entities/nearby_center.dart';
import '../../../farmer/centers/presentation/providers/centers_providers.dart';
import '../../domain/resale_math.dart';
import '../../domain/resale_models.dart';
import '../resale_providers.dart';

String isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The form for listing leftover fertilizer: what it is, its photos, the price and where to hand it over.
class SellSurplusFormScreen extends ConsumerStatefulWidget {
  const SellSurplusFormScreen({super.key});

  @override
  ConsumerState<SellSurplusFormScreen> createState() => _SellSurplusFormScreenState();
}

class _SellSurplusFormScreenState extends ConsumerState<SellSurplusFormScreen> {
  EligibleProduct? _product;
  int _units = 1;
  ResaleCondition _condition = ResaleCondition.sealed;
  DateTime? _mfg;
  DateTime? _expiry;
  final _batch = TextEditingController();
  final _upi = TextEditingController();
  PayoutMode _payout = PayoutMode.wallet;
  String? _centerId;
  Uint8List? _front;
  Uint8List? _back;
  PriceGuide? _guide;
  double? _price;
  bool _loadingGuide = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _batch.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _refreshGuide() async {
    final product = _product;
    if (product == null) return;
    setState(() => _loadingGuide = true);
    try {
      final guide = await ref.read(resaleRepositoryProvider).suggest(productId: product.productId, condition: _condition, mfgDate: _mfg == null ? null : isoDay(_mfg!));
      if (!mounted) return;
      setState(() {
        _guide = guide;
        // Keep a price the farmer chose if it is still allowed; otherwise start from the suggestion.
        _price = (_price != null && _price! >= guide.min && _price! <= guide.max) ? _price : guide.suggested;
        _loadingGuide = false;
      });
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = '$err';
          _loadingGuide = false;
        });
      }
    }
  }

  Future<void> _pickDate({required bool expiry}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: expiry ? (_expiry ?? now.add(const Duration(days: 365))) : (_mfg ?? now.subtract(const Duration(days: 90))),
      firstDate: expiry ? now.add(const Duration(days: 1)) : DateTime(now.year - 5),
      lastDate: expiry ? DateTime(now.year + 6) : now,
      helpText: expiry ? 'Expiry date on the bag' : 'Manufacturing date on the bag',
    );
    if (picked == null) return;
    setState(() => expiry ? _expiry = picked : _mfg = picked);
    if (!expiry) _refreshGuide();
  }

  Future<void> _pickPhoto({required bool front}) async {
    final camera = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take a photo'), onTap: () => Navigator.pop(context, true)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(context, false)),
        ]),
      ),
    );
    if (camera == null) return;
    final picked = await ref.read(documentPickerProvider).pick(camera: camera);
    if (picked != null && mounted) setState(() => front ? _front = picked.bytes : _back = picked.bytes);
  }

  String? get _problem {
    if (_product == null) return 'Choose the fertilizer you want to sell';
    if (_expiry == null) return 'Enter the expiry date from the bag';
    if (_front == null || _back == null) return 'Add a photo of the front and of the back of the bag';
    if (_price == null || _guide == null) return 'Waiting for the price range';
    if (_centerId == null) return 'Choose the center where you will hand it over';
    if (_payout == PayoutMode.upi && !RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$').hasMatch(_upi.text.trim())) return 'Enter your UPI id, like name@bank';
    return null;
  }

  Future<void> _submit() async {
    final problem = _problem;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(resaleRepositoryProvider).create(
            NewListing(
              productId: _product!.productId,
              units: _units,
              condition: _condition,
              mfgDate: _mfg == null ? null : isoDay(_mfg!),
              expiryDate: isoDay(_expiry!),
              batchNumber: _batch.text.trim(),
              askingPrice: _price!,
              centerId: _centerId!,
              payoutMode: _payout,
              upiId: _upi.text.trim(),
            ),
            front: _front!,
            back: _back!,
          );
      ref
        ..invalidate(myListingsProvider)
        ..invalidate(eligibleProductsProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sent to your village center'),
          content: const Text('They will check your photos and either put it on sale or ask you to bring it in. You will get a notification.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.of(context).pop();
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
    final eligible = ref.watch(eligibleProductsProvider);
    final centers = ref.watch(nearbyCentersProvider(Cart.empty));

    return Scaffold(
      appBar: AppBar(title: const Text('List fertilizer for sale')),
      body: ResponsiveScope(
        child: eligible.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(eligibleProductsProvider)),
          data: (products) {
            if (products.isEmpty) return const _NothingToSell();
            return ListView(
              padding: context.pagePadding.copyWith(bottom: AppSpacing.xl),
              children: [
                Text('1. What are you selling?', style: text.titleMedium),
                Text('Only organic fertilizer you bought here and collected.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                AppSpacing.gapSm,
                for (final p in products) _ProductChoice(product: p, selected: _product?.productId == p.productId, onTap: p.canList ? () {
                      setState(() {
                        _product = p;
                        _units = 1;
                        _price = null;
                      });
                      _refreshGuide();
                    } : null),
                if (_product != null) ...[
                  AppSpacing.gapMd,
                  Text('2. How much, and in what condition?', style: text.titleMedium),
                  AppSpacing.gapSm,
                  Row(children: [
                    IconButton.outlined(key: const Key('units-minus'), onPressed: _units > 1 ? () => setState(() => _units--) : null, icon: const Icon(Icons.remove_rounded)),
                    SizedBox(width: 56, child: Text('$_units', key: const Key('units'), textAlign: TextAlign.center, style: text.titleLarge)),
                    IconButton.outlined(key: const Key('units-plus'), onPressed: _units < _product!.remaining ? () => setState(() => _units++) : null, icon: const Icon(Icons.add_rounded)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('× ${_product!.unit}  (up to ${_product!.remaining})', style: text.bodyMedium)),
                  ]),
                  AppSpacing.gapSm,
                  Wrap(spacing: AppSpacing.sm, children: [
                    for (final c in ResaleCondition.values)
                      ChoiceChip(
                        key: Key('condition-${c.api}'),
                        label: Text(c.label),
                        selected: _condition == c,
                        onSelected: (_) {
                          setState(() => _condition = c);
                          _refreshGuide();
                        },
                      ),
                  ]),
                  AppSpacing.gapSm,
                  Row(children: [
                    Expanded(child: _DateField(key: const Key('mfg-date'), label: 'Made on', value: _mfg, onTap: () => _pickDate(expiry: false))),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _DateField(key: const Key('expiry-date'), label: 'Expires on', value: _expiry, onTap: () => _pickDate(expiry: true))),
                  ]),
                  AppSpacing.gapSm,
                  TextField(key: const Key('batch'), controller: _batch, decoration: const InputDecoration(labelText: 'Batch number (from the bag)', prefixIcon: Icon(Icons.qr_code_2_rounded))),
                  AppSpacing.gapMd,
                  Text('3. Photos of the bag', style: text.titleMedium),
                  AppSpacing.gapSm,
                  Row(children: [
                    Expanded(child: _PhotoTile(key: const Key('photo-front'), label: 'Front', bytes: _front, onTap: () => _pickPhoto(front: true))),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _PhotoTile(key: const Key('photo-back'), label: 'Back', bytes: _back, onTap: () => _pickPhoto(front: false))),
                  ]),
                  AppSpacing.gapMd,
                  Text('4. Your price for one ${_product!.unit}', style: text.titleMedium),
                  AppSpacing.gapSm,
                  _PriceBox(guide: _guide, price: _price, loading: _loadingGuide, payout: _payout, units: _units, onChanged: (v) => setState(() => _price = v)),
                  AppSpacing.gapMd,
                  Text('5. Where will you hand it over?', style: text.titleMedium),
                  AppSpacing.gapSm,
                  centers.when(
                    loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: AppLoadingIndicator()),
                    error: (_, _) => Text('Could not load centers near you.', style: text.bodySmall?.copyWith(color: colors.danger)),
                    data: (result) => result == null || result.centers.isEmpty
                        ? Text('No village center found near you yet.', style: text.bodyMedium)
                        : RadioGroup<String>(
                            groupValue: _centerId,
                            onChanged: (v) => setState(() => _centerId = v),
                            child: Column(children: [
                              for (final c in result.centers)
                                RadioListTile<String>(
                                  key: Key('center-${c.center.centerId}'),
                                  contentPadding: EdgeInsets.zero,
                                  value: c.center.centerId,
                                  title: Text('${c.center.name}, ${c.center.village}'),
                                  subtitle: Text('${c.distanceKm.toStringAsFixed(1)} km away'),
                                ),
                            ]),
                          ),
                  ),
                  AppSpacing.gapMd,
                  Text('6. How do you want to be paid?', style: text.titleMedium),
                  RadioGroup<PayoutMode>(
                    groupValue: _payout,
                    onChanged: (v) => setState(() => _payout = v!),
                    child: Column(children: [
                      for (final m in PayoutMode.values)
                        RadioListTile<PayoutMode>(key: Key('payout-${m.api}'), contentPadding: EdgeInsets.zero, value: m, title: Text(m.label), subtitle: Text(m.hint)),
                    ]),
                  ),
                  if (_payout == PayoutMode.upi) TextField(key: const Key('upi'), controller: _upi, decoration: const InputDecoration(labelText: 'Your UPI id', hintText: 'name@bank', prefixIcon: Icon(Icons.account_balance_outlined))),
                  AppSpacing.gapMd,
                  if (_error != null) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text(_error!, key: const Key('form-error'), style: text.bodyMedium?.copyWith(color: colors.danger))),
                  AppButton(label: 'Send for verification', icon: Icons.send_rounded, expand: true, isLoading: _saving, onPressed: _submit),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NothingToSell extends StatelessWidget {
  const _NothingToSell();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: colors.textMuted),
          AppSpacing.gapMd,
          Text('Nothing to sell yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('You can resell organic fertilizer you bought on ShetSamrudhi and collected from a village center. Once you have collected an order, it appears here.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
        ]),
      ),
    );
  }
}

class _ProductChoice extends StatelessWidget {
  const _ProductChoice({required this.product, required this.selected, required this.onTap});

  final EligibleProduct product;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final why = product.listingsLeft <= 0 ? 'Already listed 3 times this season' : (product.remaining <= 0 ? 'All of it is already listed' : 'You can list up to ${product.remaining}');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          key: Key('product-${product.productId}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(border: Border.all(color: selected ? colors.primary : colors.border, width: selected ? 2 : 1), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(children: [
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: onTap == null ? colors.textMuted : colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.name, style: text.titleSmall?.copyWith(color: onTap == null ? colors.textMuted : null)),
                  Text('Bought ${product.purchased} × ${product.unit}  ·  $why', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                ]),
              ),
              Text(formatRupees(product.catalogPrice), style: text.labelMedium),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({super.key, required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_month_outlined)),
        child: Text(value == null ? 'Choose' : isoDay(value!), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: value == null ? context.colors.textMuted : null)),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({super.key, required this.label, required this.bytes, required this.onTap});

  final String label;
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: colors.border)),
        child: bytes == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: colors.primary), const SizedBox(height: 4), Text('$label of the bag')])
            : Stack(fit: StackFit.expand, children: [Image.memory(bytes!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined))), Positioned(left: 6, bottom: 6, child: Chip(label: Text(label), visualDensity: VisualDensity.compact))]),
      ),
    );
  }
}

/// The price slider with the suggestion, the saving against the platform price, and what the seller keeps.
class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.guide, required this.price, required this.loading, required this.payout, required this.units, required this.onChanged});

  final PriceGuide? guide;
  final double? price;
  final bool loading;
  final PayoutMode payout;
  final int units;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    if (guide == null || price == null) return Padding(padding: const EdgeInsets.all(AppSpacing.md), child: loading ? const AppLoadingIndicator() : Text('Choose a product to see the price range.', style: text.bodySmall));
    final g = guide!;
    final p = price!.clamp(g.min, g.max).toDouble();
    // A listing from the app is tied to a platform order, so it counts as a verified purchase.
    final split = ResaleMath.split(verified: true);
    final perUnit = ResaleMath.sellerNet(gross: p, verified: true, mode: payout);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: AppSpacing.sm, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.end, children: [
          Text(formatRupees(p), key: const Key('price'), style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colors.primary)),
          Text('New: ${formatRupees(g.catalogPrice)}', style: text.bodySmall?.copyWith(color: colors.textMuted, decoration: TextDecoration.lineThrough)),
          Text('Buyers save ${ResaleMath.savingPercent(catalogPrice: g.catalogPrice, price: p)}%', style: text.labelSmall?.copyWith(color: colors.success)),
        ]),
        Slider(key: const Key('price-slider'), value: p, min: g.min, max: g.max, divisions: (g.max - g.min).round().clamp(1, 400), onChanged: onChanged),
        Row(children: [
          Text('Lowest ${formatRupees(g.min)}', style: text.labelSmall?.copyWith(color: colors.textMuted)),
          const Spacer(),
          Text('Highest ${formatRupees(g.max)}', style: text.labelSmall?.copyWith(color: colors.textMuted)),
        ]),
        Align(alignment: Alignment.centerLeft, child: TextButton(key: const Key('use-suggested'), onPressed: () => onChanged(g.suggested), child: Text('Use suggested ${formatRupees(g.suggested)}'))),
        const Divider(),
        Text('You receive ${formatRupees(perUnit)} for each ($units = ${formatRupees(perUnit * units)})', key: const Key('you-receive'), style: text.titleSmall),
        Text('Platform ${split.platformPct.round()}% + village center ${split.centerPct.round()}% are taken from the sale.${payout == PayoutMode.cash ? ' Cash payout keeps 97% of your share.' : ''}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
      ]),
    );
  }
}
