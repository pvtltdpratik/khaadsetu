import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/price_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../delivery/presentation/providers/document_picker.dart';
import '../domain/review_models.dart';
import 'review_providers.dart';

Future<Uint8List?> _pickPhoto(BuildContext context, WidgetRef ref) async {
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
  if (camera == null || !context.mounted) return null;
  return (await ref.read(documentPickerProvider).pick(camera: camera))?.bytes;
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({required this.label, required this.bytes, required this.onTap});

  final String label;
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      key: const Key('photo'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        height: 110,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: colors.border)),
        child: bytes == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: colors.primary), const SizedBox(height: 4), Text(label)])
            : Image.memory(bytes!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined))),
      ),
    );
  }
}

/// Phase 2: how the crop looks a month on. Mostly taps, about a minute.
class MidSeasonScreen extends ConsumerStatefulWidget {
  const MidSeasonScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  ConsumerState<MidSeasonScreen> createState() => _MidSeasonScreenState();
}

class _MidSeasonScreenState extends ConsumerState<MidSeasonScreen> {
  String? _color;
  String? _leaf;
  String? _soil;
  bool _pest = false;
  final _note = TextEditingController();
  Uint8List? _photo;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_color == null || _leaf == null || _soil == null) return setState(() => _error = 'Tap an answer for each question');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final coins = await ref.read(reviewRepositoryProvider).submitMid(
            widget.reviewId,
            MidNotes(colorChange: _color!, leafHealth: _leaf!, pestDisease: _pest, soilFeel: _soil!, unexpected: _note.text.trim()),
            photo: _photo,
          );
      ref
        ..invalidate(myLogsProvider)
        ..invalidate(rewardsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thank you! You earned $coins coins.')));
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
    final text = Theme.of(context).textTheme;
    Widget question(String title, List<Choice> options, String? value, ValueChanged<String> on, String key) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [for (final o in options) ChoiceChip(key: Key('$key-${o.api}'), label: Text(o.label), selected: value == o.api, onSelected: (_) => setState(() => on(o.api)))]),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('How is the crop?')),
      body: ResponsiveScope(
        child: ListView(
          padding: context.pagePadding.copyWith(bottom: AppSpacing.xl),
          children: [
            question('Colour of the crop', const [Choice('improved', 'Improved'), Choice('no_change', 'No change'), Choice('worsened', 'Worsened')], _color, (v) => _color = v, 'color'),
            question('Leaves', const [Choice('greener', 'Greener'), Choice('same', 'Same'), Choice('yellowing', 'Yellowing')], _leaf, (v) => _leaf = v, 'leaf'),
            question('Soil feel', const [Choice('better', 'Better'), Choice('same', 'Same'), Choice('worse', 'Worse')], _soil, (v) => _soil = v, 'soil'),
            SwitchListTile(key: const Key('pest'), contentPadding: EdgeInsets.zero, value: _pest, onChanged: (v) => setState(() => _pest = v), title: const Text('Pests or disease since applying')),
            TextField(key: const Key('unexpected'), controller: _note, maxLines: 2, maxLength: 300, decoration: const InputDecoration(labelText: 'Anything unexpected? (optional)')),
            AppSpacing.gapSm,
            _PhotoButton(label: 'A photo of the crop (optional)', bytes: _photo, onTap: () async {
              final bytes = await _pickPhoto(context, ref);
              if (bytes != null && mounted) setState(() => _photo = bytes);
            }),
            AppSpacing.gapMd,
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text(_error!, key: const Key('form-error'), style: text.bodyMedium?.copyWith(color: context.colors.danger))),
            AppButton(label: 'Send (+10 coins)', icon: Icons.send_rounded, expand: true, isLoading: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Phase 3: the harvest. The farmer sees last season's yield and the district average next to the box, so the number
/// they enter means something.
class HarvestScreen extends ConsumerStatefulWidget {
  const HarvestScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  ConsumerState<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends ConsumerState<HarvestScreen> {
  final _yield = TextEditingController();
  final _last = TextEditingController();
  final _comment = TextEditingController();
  int _overall = 0;
  int _value = 0;
  int _ease = 0;
  String? _again;
  bool? _recommend;
  Uint8List? _photo;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _yield.dispose();
    _last.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit(MyLog log, CropRef? crop) async {
    final y = double.tryParse(_yield.text.trim());
    if (y == null || y <= 0) return setState(() => _error = 'Enter your yield in quintals per acre');
    if (_overall == 0 || _value == 0 || _ease == 0) return setState(() => _error = 'Give all three star ratings');
    if (_again == null) return setState(() => _error = 'Say whether you would use it again');
    if (_recommend == null) return setState(() => _error = 'Say whether you would recommend it to similar farmers');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref.read(reviewRepositoryProvider).submitHarvest(
            widget.reviewId,
            HarvestInput(yieldQpa: y, lastSeasonQpa: double.tryParse(_last.text.trim()), starsOverall: _overall, starsValue: _value, starsEase: _ease, useAgain: _again!, recommend: _recommend!, comment: _comment.text.trim()),
            photo: _photo,
          );
      ref
        ..invalidate(myLogsProvider)
        ..invalidate(rewardsProvider);
      if (!mounted) return;
      setState(() => _saving = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result.heldForCheck ? 'Thank you: we will check it' : 'Your harvest is logged'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (result.improvementPct != null) Text('Your yield was ${result.improvementPct! >= 0 ? '+' : ''}${result.improvementPct!.toStringAsFixed(1)}% against ${_last.text.trim().isEmpty ? 'the district average' : 'last season'}.', key: const Key('gain-line')),
            if (result.heldForCheck) const Padding(padding: EdgeInsets.only(top: 8), child: Text('An agronomist checks unusual results before other farmers see them.')),
            const SizedBox(height: 8),
            const Text('You earned:', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final e in result.earned) Text('• $e', key: Key('earned-${result.earned.indexOf(e)}')),
            if (result.streak > 1) Text('${result.streak} seasons in a row!'),
          ]),
          actions: [FilledButton(key: const Key('harvest-ok'), onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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

  Widget _stars(String key, int value, ValueChanged<int> on) => Row(children: [
        for (var i = 1; i <= 5; i++) IconButton(key: Key('$key-$i'), visualDensity: VisualDensity.compact, onPressed: () => setState(() => on(i)), icon: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded, color: context.colors.warning, size: 30)),
      ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final logs = ref.watch(myLogsProvider);
    final crops = ref.watch(cropsProvider).value ?? const <CropRef>[];
    final log = logs.value?.where((l) => l.reviewId == widget.reviewId).firstOrNull;
    final crop = log == null ? null : crops.where((c) => c.name == log.crop).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Log your harvest')),
      body: ResponsiveScope(
        child: ListView(
          padding: context.pagePadding.copyWith(bottom: AppSpacing.xl),
          children: [
            if (log != null) Text('${log.productName} on ${log.crop}', style: text.titleMedium),
            AppSpacing.gapSm,
            TextField(key: const Key('yield'), controller: _yield, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Yield (quintals per acre)', suffixText: 'q/acre')),
            if (crop != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('District average for ${crop.name.toLowerCase()}: ${crop.districtAvgQpa} quintals/acre', key: const Key('district-avg'), style: text.bodySmall?.copyWith(color: colors.textMuted))),
            AppSpacing.gapSm,
            TextField(key: const Key('last-season'), controller: _last, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Last season on this field (optional)', suffixText: 'q/acre')),
            AppSpacing.gapMd,
            Text('How was it?', style: text.titleSmall),
            Text('Overall'),
            _stars('overall', _overall, (v) => _overall = v),
            Text('Value for money'),
            _stars('value', _value, (v) => _value = v),
            Text('Ease of application'),
            _stars('ease', _ease, (v) => _ease = v),
            AppSpacing.gapSm,
            Text('Would you use it again?', style: text.titleSmall),
            Wrap(spacing: AppSpacing.sm, children: [for (final o in const [('yes', 'Yes'), ('maybe', 'Maybe'), ('no', 'No')]) ChoiceChip(key: Key('again-${o.$1}'), label: Text(o.$2), selected: _again == o.$1, onSelected: (_) => setState(() => _again = o.$1))]),
            AppSpacing.gapSm,
            Text('Would you recommend it to farmers with similar soil and crop?', style: text.titleSmall),
            Wrap(spacing: AppSpacing.sm, children: [
              ChoiceChip(key: const Key('recommend-yes'), label: const Text('Yes'), selected: _recommend == true, onSelected: (_) => setState(() => _recommend = true)),
              ChoiceChip(key: const Key('recommend-no'), label: const Text('No'), selected: _recommend == false, onSelected: (_) => setState(() => _recommend = false)),
            ]),
            AppSpacing.gapMd,
            TextField(key: const Key('comment'), controller: _comment, maxLines: 4, maxLength: 1000, decoration: const InputDecoration(labelText: 'अजून काही सांगायचे आहे का?', helperText: 'Write in Marathi or English. Tap the microphone on your keyboard to speak instead.')),
            AppSpacing.gapSm,
            _PhotoButton(label: 'A photo of the harvest (optional)', bytes: _photo, onTap: () async {
              final bytes = await _pickPhoto(context, ref);
              if (bytes != null && mounted) setState(() => _photo = bytes);
            }),
            AppSpacing.gapMd,
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Text(_error!, key: const Key('form-error'), style: text.bodyMedium?.copyWith(color: colors.danger))),
            AppButton(label: 'Send my harvest (+50 coins)', icon: Icons.send_rounded, expand: true, isLoading: _saving, onPressed: log == null ? null : () => _submit(log, crop)),
            const SizedBox(height: AppSpacing.xs),
            Text('You will also get priority access to next season\'s recommendations and the Verified Farmer badge.', textAlign: TextAlign.center, style: text.labelSmall?.copyWith(color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Coins, badges, coupons and the streak, in one place. Coins turn into wallet money.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  static const badgeInfo = {
    'verified_farmer': ('Verified Farmer', 'You completed a full season log.'),
    'champion_farmer': ('Champion Farmer', 'Three seasons in a row.'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final rewards = ref.watch(rewardsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My rewards')),
      body: ResponsiveScope(
        child: rewards.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('$err')),
          data: (r) => ListView(padding: context.pagePadding, children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(children: [
                Text('${r.coins}', key: const Key('coin-balance'), style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: colors.primary)),
                const Text('coins'),
                const SizedBox(height: AppSpacing.sm),
                Text('${r.coinBatch} coins = ${formatRupees(r.coinBatchRupees.toDouble())} in your wallet', style: text.bodySmall),
                AppSpacing.gapSm,
                FilledButton(
                  key: const Key('redeem'),
                  onPressed: r.coins >= r.coinBatch
                      ? () async {
                          final batches = r.coins ~/ r.coinBatch;
                          try {
                            final rupees = await ref.read(reviewRepositoryProvider).redeem(batches * r.coinBatch);
                            ref.invalidate(rewardsProvider);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${formatRupees(rupees.toDouble())} added to your wallet.')));
                          } catch (err) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
                          }
                        }
                      : null,
                  child: Text(r.coins >= r.coinBatch ? 'Redeem ${(r.coins ~/ r.coinBatch) * r.coinBatch} coins' : 'Earn ${r.coinBatch - r.coins} more coins to redeem'),
                ),
              ]),
            ),
            AppSpacing.gapMd,
            Text('Badges', style: text.titleMedium),
            if (r.badges.isEmpty) Text('Finish a harvest log to become a Verified Farmer. Three seasons in a row makes you a Champion Farmer.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
            for (final b in r.badges)
              ListTile(key: Key('badge-$b'), contentPadding: EdgeInsets.zero, leading: Icon(b == 'champion_farmer' ? Icons.emoji_events_rounded : Icons.verified_rounded, color: colors.warning), title: Text(badgeInfo[b]?.$1 ?? b), subtitle: Text(badgeInfo[b]?.$2 ?? '')),
            if (r.streak > 0) Text('${r.streak} season${r.streak == 1 ? '' : 's'} in a row', key: const Key('streak'), style: text.bodyMedium),
            if (r.priorityUntil != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Priority access to next season\'s recommendations until ${r.priorityUntil!.day}/${r.priorityUntil!.month}/${r.priorityUntil!.year}', key: const Key('priority'), style: text.bodySmall)),
            AppSpacing.gapMd,
            Text('Coupons', style: text.titleMedium),
            if (r.coupons.isEmpty) Text('Log your baseline before applying a fertilizer to get a 5% coupon.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
            for (final c in r.coupons)
              Card(
                key: Key('coupon-${c.code}'),
                child: ListTile(
                  leading: Icon(Icons.local_offer_outlined, color: c.usable ? colors.primary : colors.textMuted),
                  title: SelectableText(c.code, style: text.titleSmall?.copyWith(color: c.usable ? null : colors.textMuted)),
                  subtitle: Text('${c.percent.toStringAsFixed(0)}% off  ·  ${c.used ? 'used' : (c.expired ? 'expired' : 'valid until ${c.expiresAt.day}/${c.expiresAt.month}/${c.expiresAt.year}')}'),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
