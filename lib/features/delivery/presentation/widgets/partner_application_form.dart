import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/delivery_models.dart';
import '../providers/delivery_providers.dart';
import '../providers/document_picker.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _missingWords = {
  'vehicleType': 'the type of vehicle',
  'vehicleNumber': 'the vehicle number',
  'capacityKg': 'how much it can carry',
  'phone': 'your phone number',
  'licence': 'a photo of your driving licence',
  'rc': 'a photo of the RC',
};

/// Becoming a delivery partner: the vehicle, the papers, when and how far. Nothing
/// here is a separate login: it is the same farmer, with one more thing they can do.
///
/// Details are saved with one button (which also makes the application exist on the
/// server, so photos can be attached to it), papers upload the moment they are
/// chosen, and "Send for checking" goes to the village center chosen below.
class PartnerApplicationForm extends ConsumerStatefulWidget {
  const PartnerApplicationForm({super.key, required this.profile, this.submit = true});

  final PartnerProfile profile;

  /// False when an approved partner is only changing details: there is nothing to send again.
  final bool submit;

  @override
  ConsumerState<PartnerApplicationForm> createState() => _PartnerApplicationFormState();
}

class _PartnerApplicationFormState extends ConsumerState<PartnerApplicationForm> {
  late VehicleType? _vehicle = widget.profile.vehicleType;
  late final _number = TextEditingController(text: widget.profile.vehicleNumber);
  late final _capacity = TextEditingController(text: widget.profile.capacityKg?.toString() ?? '');
  late final _phone = TextEditingController(text: widget.profile.phone);
  late double _range = widget.profile.maxDistanceKm.clamp(1, 50).toDouble();
  late final Set<int> _days = {...widget.profile.days};
  late String _from = widget.profile.freeFrom;
  late String _until = widget.profile.freeUntil;
  late String? _centerId = widget.profile.reviewCenterId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The "send" button and the list of what is missing follow what is typed.
    for (final c in [_number, _capacity, _phone]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _number.dispose();
    _capacity.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _say(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs [work] with the buttons off, and shows the server's message if it fails.
  Future<void> _run(Future<void> Function() work) async {
    setState(() => _busy = true);
    try {
      await work();
    } catch (err) {
      _say('$err');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, dynamic> _changes() => {
        if (_vehicle != null) 'vehicleType': _vehicle!.name,
        if (_number.text.trim().isNotEmpty) 'vehicleNumber': _number.text.trim(),
        if (int.tryParse(_capacity.text.trim()) != null) 'capacityKg': int.parse(_capacity.text.trim()),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        'maxDistanceKm': _range.round(),
        'days': (_days.toList()..sort()),
        'freeFrom': _from,
        'freeUntil': _until,
        'reviewCenterId': ?_centerId,
      };

  Future<void> _save() => _run(() async {
        await ref.read(deliveryRepositoryProvider).savePartner(_changes());
        ref.invalidate(partnerProfileProvider);
        _say('Saved');
      });

  Future<void> _pickDocument(String kind, {required bool camera}) => _run(() async {
        final doc = await ref.read(documentPickerProvider).pick(camera: camera);
        if (doc == null) return;
        await ref.read(deliveryRepositoryProvider).uploadDocument(kind: kind, bytes: doc.bytes, filename: doc.filename);
        ref.invalidate(partnerProfileProvider);
      });

  Future<void> _submit() => _run(() async {
        final repo = ref.read(deliveryRepositoryProvider);
        await repo.savePartner(_changes());
        await repo.submitApplication();
        ref.invalidate(partnerProfileProvider);
        _say('Sent to the village center for checking');
      });

  Future<void> _pickTime({required bool from}) async {
    final current = (from ? _from : _until).split(':');
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.tryParse(current[0]) ?? 6, minute: int.tryParse(current[1]) ?? 0));
    if (picked == null) return;
    final text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => from ? _from = text : _until = text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final p = widget.profile;
    final centers = ref.watch(reviewCentersProvider);
    final saved = p.status != PartnerStatus.none; // the application exists on the server

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p.status == PartnerStatus.rejected)
          Container(
            key: const Key('rejected-note'),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: colors.danger.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.danger)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('The village center could not approve this', style: text.titleSmall?.copyWith(color: colors.danger)),
              if ((p.rejectionReason ?? '').isNotEmpty) Text(p.rejectionReason!, style: text.bodyMedium),
              Text('Fix what they said and send it again.', style: text.bodySmall),
            ]),
          ),
        Text('Earn by delivering for other farmers', style: text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('If you have a bike, pickup or tractor, you can bring orders to farms near you and keep the delivery fee. The village center checks your papers first.', style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
        AppSpacing.gapLg,

        Text('Your vehicle', style: text.titleSmall),
        AppSpacing.gapSm,
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final v in VehicleType.values)
              ChoiceChip(
                key: Key('vehicle-${v.name}'),
                label: Text(v.label),
                selected: _vehicle == v,
                onSelected: _busy ? null : (_) => setState(() => _vehicle = v),
              ),
          ],
        ),
        if (_vehicle != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('A ${_vehicle!.label.toLowerCase()} can carry ${_vehicle!.minKg} to ${_vehicle!.maxKg} kg.', style: text.bodySmall?.copyWith(color: colors.textMuted))),
        AppSpacing.gapSm,
        TextField(key: const Key('vehicle-number'), controller: _number, enabled: !_busy, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Vehicle number', hintText: 'MH 12 AB 1234')),
        AppSpacing.gapSm,
        TextField(key: const Key('vehicle-capacity'), controller: _capacity, enabled: !_busy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'How much can it carry (kg)')),
        AppSpacing.gapSm,
        TextField(key: const Key('partner-phone'), controller: _phone, enabled: !_busy, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Your mobile number', prefixIcon: Icon(Icons.call_outlined))),
        AppSpacing.gapLg,

        Text('When and how far', style: text.titleSmall),
        AppSpacing.gapSm,
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (var d = 0; d < 7; d++)
              FilterChip(
                key: Key('day-$d'),
                label: Text(_dayNames[d]),
                selected: _days.contains(d),
                onSelected: _busy ? null : (on) => setState(() => on ? _days.add(d) : _days.remove(d)),
              ),
          ],
        ),
        AppSpacing.gapSm,
        Row(children: [
          Expanded(child: OutlinedButton.icon(key: const Key('free-from'), onPressed: _busy ? null : () => _pickTime(from: true), icon: const Icon(Icons.schedule_rounded, size: 18), label: Text('From $_from'))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: OutlinedButton.icon(key: const Key('free-until'), onPressed: _busy ? null : () => _pickTime(from: false), icon: const Icon(Icons.schedule_rounded, size: 18), label: Text('Until $_until'))),
        ]),
        AppSpacing.gapSm,
        Text('I will go up to ${_range.round()} km from where I am', style: text.bodyMedium),
        Slider(key: const Key('range'), value: _range, min: 1, max: 50, divisions: 49, label: '${_range.round()} km', onChanged: _busy ? null : (v) => setState(() => _range = v)),
        AppSpacing.gapMd,

        Text('Who checks my papers', style: text.titleSmall),
        AppSpacing.gapSm,
        centers.when(
          loading: () => const LinearProgressIndicator(),
          error: (err, _) => Text('$err', style: text.bodyMedium?.copyWith(color: colors.danger)),
          data: (list) => list.isEmpty
              ? Text('Turn on your location or choose your village first, so we can show the village centers near you.', style: text.bodyMedium)
              : DropdownButtonFormField<String>(
                  key: const Key('review-center'),
                  initialValue: list.any((c) => c.center.centerId == _centerId) ? _centerId : null,
                  decoration: const InputDecoration(labelText: 'Village center'),
                  items: [
                    for (final c in list) DropdownMenuItem(value: c.center.centerId, child: Text('${c.center.name} · ${c.distanceKm.toStringAsFixed(1)} km', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _centerId = v),
                ),
        ),
        AppSpacing.gapLg,

        Text('Your papers', style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(saved ? 'Take a clear photo of each. Only you and the village center can see them.' : 'Save your details first, then add the photos.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
        AppSpacing.gapSm,
        _DocumentTile(kind: 'licence', title: 'Driving licence', doc: p.licence, enabled: saved && !_busy, onPick: (camera) => _pickDocument('licence', camera: camera)),
        AppSpacing.gapSm,
        _DocumentTile(kind: 'rc', title: 'Vehicle RC (registration)', doc: p.rc, enabled: saved && !_busy, onPick: (camera) => _pickDocument('rc', camera: camera)),
        AppSpacing.gapLg,

        if (!widget.submit)
          FilledButton(key: const Key('save-details'), onPressed: _busy ? null : _save, child: const Text('Save changes'))
        else
          Row(children: [
            Expanded(child: OutlinedButton(key: const Key('save-details'), onPressed: _busy ? null : _save, child: const Text('Save details'))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: FilledButton(key: const Key('submit-application'), onPressed: _busy || !_readyToSend(p) ? null : _submit, child: Text(_busy ? 'Please wait…' : 'Send for checking'))),
          ]),
        if (widget.submit && !_readyToSend(p)) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_stillNeeded(p), key: const Key('still-needed'), style: text.bodySmall?.copyWith(color: colors.textMuted)),
        ],
      ],
    );
  }

  /// Ready when the server has every detail and both photos, and a center is chosen.
  bool _readyToSend(PartnerProfile p) {
    final fieldsFilled = _vehicle != null && _number.text.trim().isNotEmpty && int.tryParse(_capacity.text.trim()) != null && _phone.text.trim().isNotEmpty;
    return fieldsFilled && p.licence != null && p.rc != null && _centerId != null && _days.isNotEmpty;
  }

  String _stillNeeded(PartnerProfile p) {
    final gaps = [
      if (_vehicle == null) _missingWords['vehicleType'],
      if (_number.text.trim().isEmpty) _missingWords['vehicleNumber'],
      if (int.tryParse(_capacity.text.trim()) == null) _missingWords['capacityKg'],
      if (_phone.text.trim().isEmpty) _missingWords['phone'],
      if (p.licence == null) _missingWords['licence'],
      if (p.rc == null) _missingWords['rc'],
      if (_centerId == null) 'a village center to check them',
      if (_days.isEmpty) 'at least one day you are free',
    ];
    return 'Still needed: ${gaps.join(', ')}.';
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.kind, required this.title, required this.doc, required this.enabled, required this.onPick});

  final String kind;
  final String title;
  final PartnerDocument? doc;
  final bool enabled;
  final void Function(bool camera) onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      key: Key('doc-$kind'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: doc == null ? colors.border : colors.success)),
      child: Row(
        children: [
          Icon(doc == null ? Icons.description_outlined : Icons.check_circle_rounded, color: doc == null ? colors.textMuted : colors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: text.titleSmall),
              Text(doc == null ? 'Not added yet' : 'Added (${(doc!.sizeBytes / 1024).round()} KB)', style: text.bodySmall?.copyWith(color: colors.textMuted)),
            ]),
          ),
          IconButton(key: Key('camera-$kind'), tooltip: 'Take a photo', onPressed: enabled ? () => onPick(true) : null, icon: const Icon(Icons.photo_camera_outlined)),
          IconButton(key: Key('gallery-$kind'), tooltip: 'Choose from gallery', onPressed: enabled ? () => onPick(false) : null, icon: const Icon(Icons.photo_library_outlined)),
        ],
      ),
    );
  }
}
