import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../domain/review_models.dart';
import 'review_providers.dart';

/// Phase 1: the baseline, logged before the fertilizer goes on. What the app already knows (soil, scan, farm size) is
/// filled in and cannot be changed here, so the record is the farmer's real farm.
class LogFertilizerScreen extends ConsumerWidget {
  const LogFertilizerScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefill = ref.watch(prefillProvider(productId));
    return Scaffold(
      appBar: AppBar(title: const Text('Log how you use it')),
      body: ResponsiveScope(
        child: prefill.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(prefillProvider(productId))),
          data: (p) => !p.eligible ? const _NotYet() : (p.soilType == null ? const _NeedSoil() : _Form(productId: productId, prefill: p)),
        ),
      ),
    );
  }
}

class _NotYet extends StatelessWidget {
  const _NotYet();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shopping_bag_outlined, size: 56, color: context.colors.textMuted),
            AppSpacing.gapMd,
            Text('Only for products you bought here', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Reviews come from farmers who really used the fertilizer. Collect your order from the village center, then log how you use it.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted)),
          ]),
        ),
      );
}

class _NeedSoil extends StatelessWidget {
  const _NeedSoil();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.terrain_outlined, size: 56, color: context.colors.textMuted),
            AppSpacing.gapMd,
            Text('Tell us your soil type first', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Reviews use your own farm profile, so other farmers can trust them. Add your soil type once and it is used everywhere.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted)),
            AppSpacing.gapMd,
            FilledButton(key: const Key('add-soil'), onPressed: () => context.push(RoutePaths.farmerProfileFarm), child: const Text('Add my soil type')),
          ]),
        ),
      );
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.productId, required this.prefill});

  final String productId;
  final ReviewPrefill prefill;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  String? _crop;
  String _stage = 'vegetative';
  String _method = 'broadcasting';
  String _reason = 'app_recommendation';
  String? _irrigation;
  late final _acres = TextEditingController(text: widget.prefill.acres?.toString() ?? '');
  final _variety = TextEditingController();
  final _qty = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _irrigation = widget.prefill.irrigation;
    final crops = widget.prefill.crops;
    if (crops.length == 1 && widget.prefill.cropNames.contains(crops.first)) _crop = crops.first;
  }

  @override
  void dispose() {
    _acres.dispose();
    _variety.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final acres = double.tryParse(_acres.text.trim());
    final qty = double.tryParse(_qty.text.trim());
    if (_crop == null) return setState(() => _error = 'Choose the crop');
    if (acres == null || acres <= 0) return setState(() => _error = 'Enter the acres you treated');
    if (qty == null || qty <= 0) return setState(() => _error = 'Enter how much you applied per acre');
    if (_irrigation == null) return setState(() => _error = 'Choose how the field is irrigated');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final coupon = await ref.read(reviewRepositoryProvider).start(NewBaseline(
            productId: widget.productId,
            acres: acres,
            crop: _crop!,
            variety: _variety.text.trim(),
            growthStage: _stage,
            irrigation: _irrigation,
            qtyPerAcre: qty,
            method: _method,
            reason: _reason,
          ));
      ref
        ..invalidate(myLogsProvider)
        ..invalidate(loggableProvider)
        ..invalidate(rewardsProvider);
      if (!mounted) return;
      setState(() => _saving = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Baseline saved'),
          content: Text('Here is your 5% coupon for the next order: $coupon.\n\nIn about 4 weeks we will ask how the crop looks, then again after harvest. Each step earns you something.'),
          actions: [FilledButton(key: const Key('baseline-ok'), onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.of(context).maybePop();
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
    final p = widget.prefill;
    Widget chips(List<Choice> options, String? value, ValueChanged<String> on, String keyPrefix) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
          for (final o in options) ChoiceChip(key: Key('$keyPrefix-${o.api}'), label: Text(o.label), selected: value == o.api, onSelected: (_) => on(o.api)),
        ]);
    return ListView(
      padding: context.pagePadding.copyWith(bottom: AppSpacing.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('From your farm profile', style: text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text('Soil: ${labelOf(soilChoices, p.soilType)}${p.district.isEmpty ? '' : '  ·  District: ${p.district}'}', key: const Key('known-soil')),
            if (p.scan != null) Text('Latest soil scan: N ${p.scan!.n}, P ${p.scan!.p}, K ${p.scan!.k}  ·  score ${p.scan!.score}/100', key: const Key('known-scan')) else Text('No soil scan yet. Scan first for a stronger record.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          ]),
        ),
        AppSpacing.gapMd,
        Text('Crop', style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
          for (final c in p.cropNames) ChoiceChip(key: Key('crop-$c'), label: Text(c), selected: _crop == c, onSelected: (_) => setState(() => _crop = c)),
        ]),
        AppSpacing.gapSm,
        TextField(key: const Key('variety'), controller: _variety, decoration: const InputDecoration(labelText: 'Variety (for example JS 335)')),
        AppSpacing.gapMd,
        Text('Crop stage now', style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        chips(stageChoices, _stage, (v) => setState(() => _stage = v), 'stage'),
        AppSpacing.gapMd,
        Row(children: [
          Expanded(child: TextField(key: const Key('acres'), controller: _acres, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Acres treated'))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: TextField(key: const Key('qty'), controller: _qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Applied per acre'))),
        ]),
        AppSpacing.gapMd,
        Text('Irrigation', style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        chips(irrigationChoices, _irrigation, (v) => setState(() => _irrigation = v), 'irrigation'),
        AppSpacing.gapMd,
        Text('How did you apply it?', style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        chips(methodChoices, _method, (v) => setState(() => _method = v), 'method'),
        AppSpacing.gapMd,
        Text('Why this fertilizer?', style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        chips(reasonChoices, _reason, (v) => setState(() => _reason = v), 'reason'),
        AppSpacing.gapMd,
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text(_error!, key: const Key('form-error'), style: text.bodyMedium?.copyWith(color: colors.danger))),
        AppButton(label: 'Save baseline and get 5% off', icon: Icons.local_offer_outlined, expand: true, isLoading: _saving, onPressed: _submit),
        const SizedBox(height: AppSpacing.xs),
        Text('This takes about 3 minutes. Log it before you apply, so the before and after are real.', textAlign: TextAlign.center, style: text.labelSmall?.copyWith(color: colors.textMuted)),
      ],
    );
  }
}
