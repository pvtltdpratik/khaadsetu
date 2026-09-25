import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animation/animated_count.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/price_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../farmer/marketplace/domain/entities/product.dart';
import '../../farmer/marketplace/presentation/providers/marketplace_providers.dart';
import '../domain/profit_math.dart';
import '../domain/review_models.dart';
import 'review_providers.dart';

/// "If you apply this to your 2-acre soybean farm, we expect 15% to 22% more yield": from harvests of farmers like you
/// when there are enough, else an early estimate from how the product works.
class YieldPredictionScreen extends ConsumerStatefulWidget {
  const YieldPredictionScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<YieldPredictionScreen> createState() => _YieldPredictionScreenState();
}

class _YieldPredictionScreenState extends ConsumerState<YieldPredictionScreen> {
  String? _crop;
  late final _acres = TextEditingController();
  YieldPrediction? _result;
  bool _loading = false;
  bool _seeded = false;
  String? _error;

  @override
  void dispose() {
    _acres.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    final acres = double.tryParse(_acres.text.trim());
    if (_crop == null) return setState(() => _error = 'Choose your crop');
    if (acres == null || acres <= 0) return setState(() => _error = 'Enter the acres you would treat');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(reviewRepositoryProvider).predict(productId: widget.productId, acres: acres, crop: _crop!);
      if (mounted) setState(() => _result = r);
    } catch (err) {
      if (mounted) setState(() => _error = '$err');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final prefill = ref.watch(prefillProvider(widget.productId)).value;
    if (prefill != null && !_seeded) {
      _seeded = true;
      if (prefill.acres != null) _acres.text = prefill.acres.toString();
      if (prefill.crops.length == 1 && prefill.cropNames.contains(prefill.crops.first)) _crop = prefill.crops.first;
    }
    final names = prefill?.cropNames ?? ref.watch(cropsProvider).value?.map((c) => c.name).toList() ?? const <String>[];
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Predict my yield')),
      body: ResponsiveScope(
        child: ListView(
          padding: context.pagePadding,
          children: [
            Text('Uses your soil scan, soil type and what farmers like you have harvested.', style: text.bodyMedium?.copyWith(color: colors.textMuted)),
            AppSpacing.gapMd,
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [for (final c in names) ChoiceChip(key: Key('crop-$c'), label: Text(c), selected: _crop == c, onSelected: (_) => setState(() => _crop = c))]),
            AppSpacing.gapSm,
            TextField(key: const Key('acres'), controller: _acres, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Acres you would treat')),
            AppSpacing.gapMd,
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text(_error!, key: const Key('form-error'), style: text.bodyMedium?.copyWith(color: colors.danger))),
            AppButton(label: 'Predict', icon: Icons.trending_up_rounded, expand: true, isLoading: _loading, onPressed: _predict),
            if (r != null) ...[
              AppSpacing.gapLg,
              Container(
                key: const Key('prediction'),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.end, children: [
                    AnimatedCount(key: const Key('low'), value: r.lowPct, format: (v) => '${v.round()}%', style: text.displaySmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
                    Text(' to ', style: text.titleMedium),
                    AnimatedCount(key: const Key('high'), value: r.highPct, format: (v) => '${v.round()}%', style: text.displaySmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
                    Text(' more yield', style: text.titleMedium),
                  ]),
                  const SizedBox(height: AppSpacing.xs),
                  Text(r.message, key: const Key('prediction-message'), style: text.bodyLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text('About ${r.extraLow.toStringAsFixed(1)} to ${r.extraHigh.toStringAsFixed(1)} extra quintals on your farm.', key: const Key('extra')),
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [Icon(r.fromFarmers ? Icons.groups_rounded : Icons.science_outlined, size: 16, color: colors.textMuted), const SizedBox(width: 6), Expanded(child: Text(r.disclaimer, key: const Key('disclaimer'), style: text.bodySmall?.copyWith(color: colors.textMuted)))]),
                ]),
              ),
              AppSpacing.gapSm,
              OutlinedButton.icon(key: const Key('to-calculator'), onPressed: () => context.push(RoutePaths.farmerCalculatorFor(widget.productId)), icon: const Icon(Icons.calculate_outlined), label: const Text('Will it pay? Open the calculator')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cost of the fertilizer, the yield it should add, the mandi price, and what is left. A money decision, not just a
/// farming one.
class ProfitCalculatorScreen extends ConsumerStatefulWidget {
  const ProfitCalculatorScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProfitCalculatorScreen> createState() => _ProfitCalculatorScreenState();
}

class _ProfitCalculatorScreenState extends ConsumerState<ProfitCalculatorScreen> {
  Product? _product;
  CropRef? _crop;
  final _acres = TextEditingController(text: '1');
  final _bags = TextEditingController(text: '2');
  final _price = TextEditingController();
  final _baseline = TextEditingController();
  final _mandi = TextEditingController();
  double _gain = 15;
  bool _predicting = false;
  String? _note;

  @override
  void dispose() {
    for (final c in [_acres, _bags, _price, _baseline, _mandi]) {
      c.dispose();
    }
    super.dispose();
  }

  void _chooseProduct(Product p) => setState(() {
        _product = p;
        _price.text = p.priceInRupees.round().toString();
      });

  void _chooseCrop(CropRef c) => setState(() {
        _crop = c;
        _baseline.text = c.districtAvgQpa.toString();
        _mandi.text = c.msp.round().toString();
      });

  Future<void> _usePrediction() async {
    final product = _product;
    final crop = _crop;
    final acres = double.tryParse(_acres.text);
    if (product == null || crop == null || acres == null || acres <= 0) {
      setState(() => _note = 'Choose the product, the crop and the acres first');
      return;
    }
    setState(() => _predicting = true);
    try {
      final p = await ref.read(reviewRepositoryProvider).predict(productId: product.id, acres: acres, crop: crop.name);
      if (mounted) {
        setState(() {
          _gain = ((p.lowPct + p.highPct) / 2).clamp(0, 60).toDouble();
          _note = 'Using the middle of the prediction: ${p.lowPct}% to ${p.highPct}%';
        });
      }
    } catch (err) {
      if (mounted) setState(() => _note = '$err');
    } finally {
      if (mounted) setState(() => _predicting = false);
    }
  }

  ProfitResult? _result() {
    final acres = double.tryParse(_acres.text.trim());
    final bags = double.tryParse(_bags.text.trim());
    final price = double.tryParse(_price.text.trim());
    final baseline = double.tryParse(_baseline.text.trim());
    final mandi = double.tryParse(_mandi.text.trim());
    if ([acres, bags, price, baseline, mandi].contains(null) || acres! <= 0) return null;
    return ProfitMath.calculate(acres: acres, bagsPerAcre: bags!, pricePerBag: price!, baselineQpa: baseline!, gainPercent: _gain, pricePerQuintal: mandi!);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final products = ref.watch(productsProvider).value?.where((p) => p.category == ProductCategory.organic || p.category == ProductCategory.fertilizer).toList() ?? const <Product>[];
    final crops = ref.watch(cropsProvider).value ?? const <CropRef>[];
    if (_product == null && widget.productId != null) {
      final match = products.where((p) => p.id == widget.productId).firstOrNull;
      if (match != null) WidgetsBinding.instance.addPostFrameCallback((_) => mounted && _product == null ? _chooseProduct(match) : null);
    }
    final r = _result();
    return Scaffold(
      appBar: AppBar(title: const Text('Will it pay?')),
      body: ResponsiveScope(
        child: ListView(
          padding: context.pagePadding.copyWith(bottom: AppSpacing.xl),
          children: [
            Text('Fertilizer', style: text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [for (final p in products) ChoiceChip(key: Key('product-${p.id}'), label: Text(p.name), selected: _product?.id == p.id, onSelected: (_) => _chooseProduct(p))]),
            AppSpacing.gapMd,
            Text('Crop', style: text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [for (final c in crops) ChoiceChip(key: Key('crop-${c.name}'), label: Text(c.name), selected: _crop?.name == c.name, onSelected: (_) => _chooseCrop(c))]),
            AppSpacing.gapMd,
            Row(children: [
              Expanded(child: TextField(key: const Key('acres'), controller: _acres, onChanged: (_) => setState(() {}), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Acres'))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: TextField(key: const Key('bags'), controller: _bags, onChanged: (_) => setState(() {}), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bags per acre'))),
            ]),
            AppSpacing.gapSm,
            Row(children: [
              Expanded(child: TextField(key: const Key('price'), controller: _price, onChanged: (_) => setState(() {}), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per bag (₹)'))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: TextField(key: const Key('baseline'), controller: _baseline, onChanged: (_) => setState(() {}), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Usual yield (q/acre)'))),
            ]),
            AppSpacing.gapSm,
            TextField(key: const Key('mandi'), controller: _mandi, onChanged: (_) => setState(() {}), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mandi price (₹ per quintal)', helperText: 'A typical price to start with. Change it to today\'s mandi rate.')),
            AppSpacing.gapMd,
            Row(children: [Expanded(child: Text('Expected extra yield: ${_gain.round()}%', key: const Key('gain-label'), style: text.titleSmall)), TextButton(key: const Key('use-prediction'), onPressed: _predicting ? null : _usePrediction, child: const Text('Use the prediction'))]),
            Slider(key: const Key('gain'), value: _gain, min: 0, max: 60, divisions: 60, label: '${_gain.round()}%', onChanged: (v) => setState(() => _gain = v)),
            if (_note != null) Text(_note!, key: const Key('calc-note'), style: text.bodySmall?.copyWith(color: colors.textMuted)),
            AppSpacing.gapMd,
            if (r == null)
              Text('Fill in the boxes to see the numbers.', style: text.bodyMedium?.copyWith(color: colors.textMuted))
            else
              Container(
                key: const Key('profit-result'),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: (r.pays ? colors.success : colors.danger).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: r.pays ? colors.success : colors.danger)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Line('Fertilizer cost', formatRupees(r.cost), key: const Key('cost')),
                  _Line('Extra harvest', '${r.extraQuintals.toStringAsFixed(1)} quintals', key: const Key('extra-q')),
                  _Line('Extra income at the mandi', formatRupees(r.extraRevenue), key: const Key('revenue')),
                  const Divider(),
                  Row(children: [
                    Expanded(child: Text(r.pays ? 'Estimated profit' : 'Estimated loss', style: text.titleMedium)),
                    AnimatedCount(key: const Key('net'), value: r.net.abs(), format: (v) => formatRupees(v.toDouble()), style: text.headlineSmall?.copyWith(color: r.pays ? colors.success : colors.danger, fontWeight: FontWeight.w800)),
                  ]),
                  if (r.roiPercent != null) Text('${r.roiPercent!.toStringAsFixed(0)}% return on what you spend', key: const Key('roi'), style: text.bodyMedium),
                  if (r.breakEvenPercent != null) Text('It pays for itself if your yield rises by at least ${r.breakEvenPercent!.toStringAsFixed(1)}%.', key: const Key('break-even'), style: text.bodySmall?.copyWith(color: colors.textMuted)),
                ]),
              ),
            AppSpacing.gapSm,
            Text('An estimate, not a promise: rain, seed and how you apply it change the result. Prices are typical; use your local mandi rate.', style: text.labelSmall?.copyWith(color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [Expanded(child: Text(label)), Text(value, style: Theme.of(context).textTheme.titleSmall)]));
}
