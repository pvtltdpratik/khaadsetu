import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import '../delivery/presentation/providers/delivery_providers.dart';
import '../delivery/presentation/providers/document_picker.dart';
import 'vehicle_api.dart';
import 'vehicle_form_screen.dart';
import 'vehicles_screen.dart';

const vehiclePhotoKinds = {'front': 'Front', 'side': 'Side', 'back': 'Back', 'plate': 'Number plate', 'loading': 'Loading area'};
const vehicleDocKinds = {'rc': 'RC', 'insurance': 'Insurance', 'puc': 'Pollution (PUC)', 'fitness': 'Fitness', 'permit': 'Permit'};

Tone paperTone(String state) => switch (state) { 'valid' => Tone.good, 'expiring' => Tone.warn, 'expired' || 'missing' => Tone.bad, _ => Tone.neutral };

/// One vehicle: its photos and papers, what is still missing, and sending it to a village center to be checked.
class VehicleDetailScreen extends ConsumerStatefulWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  bool _busy = false;
  String? _centerId;

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) snack(context, '$e');
    } finally {
      ref.invalidate(myVehiclesProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _askSource() => showModalBottomSheet<bool>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take a photo'), onTap: () => Navigator.pop(context, true)),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(context, false)),
          ]),
        ),
      );

  Future<void> _photo(String kind) async {
    final camera = await _askSource();
    if (camera == null) return;
    await _run(() async {
      final doc = await ref.read(documentPickerProvider).pick(camera: camera);
      if (doc == null) return;
      await ref.read(vehicleApiProvider).uploadPhoto(widget.vehicleId, kind, doc.bytes);
      ref.invalidate(apiImageProvider('/v1/delivery/vehicles/${widget.vehicleId}/photos/$kind'));
    });
  }

  Future<void> _paper(String kind, {required bool needsExpiry}) async {
    final camera = await _askSource();
    if (camera == null || !mounted) return;
    String? expiry;
    if (needsExpiry) {
      final picked = await showDatePicker(
        context: context,
        helpText: 'Valid until',
        initialDate: DateTime.now().add(const Duration(days: 180)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 15)),
      );
      if (picked == null) return;
      expiry = picked.toIso8601String().substring(0, 10);
    }
    await _run(() async {
      final doc = await ref.read(documentPickerProvider).pick(camera: camera);
      if (doc == null) return;
      await ref.read(vehicleApiProvider).uploadDocument(widget.vehicleId, kind, doc.bytes, expiresOn: expiry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final vehicles = ref.watch(myVehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle')),
      body: ResponsiveScope(
        child: vehicles.when(
          skipLoadingOnReload: true,
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myVehiclesProvider)),
          data: (list) {
            final v = list.where((x) => x.str('id') == widget.vehicleId).firstOrNull;
            if (v == null) return const Center(child: Text('This vehicle is gone'));
            final status = v.str('status');
            final editable = status == 'draft' || status == 'rejected' || status == 'approved';
            final papers = v.obj('papers');
            final docs = v.obj('documents');
            final photos = v['photos'] is List ? [for (final p in v['photos'] as List) '$p'] : <String>[];
            final canSend = status == 'draft' || status == 'rejected';
            final missing = v['missing'] is List ? [for (final m in v['missing'] as List) '$m'] : <String>[];
            return ListView(padding: context.pagePadding, children: [
              KitCard(
                title: v.str('registrationNumber'),
                icon: Icons.local_shipping_outlined,
                trailing: StatusPill(vehicleStatusText(status), tone: vehicleTone(status)),
                child: Column(children: [
                  KitRow('Kind', v.str('categoryLabel')),
                  KitRow('Vehicle', [v.str('company'), v.str('modelName'), v.str('makeYear')].where((s) => s.isNotEmpty).join(' ')),
                  KitRow('Carries', '${v.int_('capacityKg')} kg'),
                  KitRow('Goes up to', '${v.int_('furthestKm')} km'),
                  if (v['costPerKm'] != null) KitRow('Running cost', '₹${v.num_('costPerKm').toStringAsFixed(0)} per km'),
                  if (v.str('driverName').isNotEmpty) KitRow('Driver', v.str('driverName')),
                  if (status == 'rejected' && v.str('rejectionReason').isNotEmpty) ...[
                    AppSpacing.gapSm,
                    Text('Why it was sent back: ${v.str('rejectionReason')}', key: const Key('vehicle-rejection'), style: text.bodyMedium?.copyWith(color: colors.danger)),
                  ],
                  if (editable)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const Key('vehicle-edit'),
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute<String>(builder: (_) => VehicleFormScreen(existing: v)));
                          ref.invalidate(myVehiclesProvider);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Change details'),
                      ),
                    ),
                ]),
              ),
              KitCard(
                index: 1,
                title: 'Photos (${photos.length} of ${vehiclePhotoKinds.length})',
                icon: Icons.photo_camera_outlined,
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in vehiclePhotoKinds.entries)
                    PhotoSlot(
                      key: Key('photo-${e.key}'),
                      label: e.value,
                      done: photos.contains(e.key),
                      previewPath: '/v1/delivery/vehicles/${widget.vehicleId}/photos/${e.key}',
                      busy: _busy,
                      onPick: status == 'pending' || status == 'suspended' ? null : () => _photo(e.key),
                    ),
                ]),
              ),
              KitCard(
                index: 2,
                title: 'Papers',
                icon: Icons.description_outlined,
                child: Column(children: [
                  for (final e in vehicleDocKinds.entries)
                    if (e.key == 'rc' || e.key == 'insurance' || e.key == 'puc' || (e.key == 'fitness' && v.flag('needsFitness')) || (e.key == 'permit' && v.flag('needsPermit')) || docs.containsKey(e.key))
                      ListTile(
                        key: Key('paper-${e.key}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.value),
                        subtitle: Text(docs.obj(e.key).str('expiresOn').isEmpty ? (e.key == 'rc' ? 'One-time paper' : 'Not added') : 'Valid until ${docs.obj(e.key).str('expiresOn')}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          StatusPill(switch (papers.str(e.key)) { 'valid' => 'Valid', 'expiring' => 'Ends soon', 'expired' => 'Expired', 'missing' => 'Missing', _ => 'Not needed' }, tone: paperTone(papers.str(e.key))),
                          IconButton(
                            icon: const Icon(Icons.upload_file_outlined),
                            tooltip: 'Add ${e.value}',
                            onPressed: _busy || status == 'pending' || status == 'suspended' ? null : () => _paper(e.key, needsExpiry: e.key != 'rc'),
                          ),
                        ]),
                      ),
                ]),
              ),
              if (canSend)
                KitCard(
                  index: 3,
                  title: 'Send to a village center',
                  icon: Icons.verified_outlined,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (missing.isNotEmpty)
                      Text('Still needed: ${missing.join(', ')}', key: const Key('vehicle-missing'), style: text.bodyMedium?.copyWith(color: colors.warning))
                    else
                      Text('Everything is ready. A village center will check it.', style: text.bodyMedium),
                    AppSpacing.gapSm,
                    ref.watch(reviewCentersProvider).maybeWhen(
                          data: (centers) => centers.isEmpty
                              ? const SizedBox.shrink()
                              : DropdownButtonFormField<String>(
                                  key: const Key('vehicle-center'),
                                  initialValue: _centerId,
                                  decoration: const InputDecoration(labelText: 'Village center'),
                                  items: [for (final c in centers) DropdownMenuItem(value: c.center.centerId, child: Text('${c.center.name} · ${c.distanceKm.toStringAsFixed(1)} km'))],
                                  onChanged: (id) => setState(() => _centerId = id),
                                ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                    AppSpacing.gapMd,
                    AppButton(
                      key: const Key('vehicle-submit'),
                      label: 'Send for checking',
                      expand: true,
                      isLoading: _busy,
                      onPressed: v.flag('canSubmit') ? () => _run(() async {
                            await ref.read(vehicleApiProvider).submit(widget.vehicleId, centerId: _centerId);
                            if (context.mounted) snack(context, 'Sent. You will be told when it is checked.');
                          }) : null,
                    ),
                  ]),
                ),
              if (status == 'pending')
                KitCard(index: 3, child: Text('The village center is checking this vehicle. You will be told when it is done.', key: const Key('vehicle-pending'), style: text.bodyMedium)),
              if (status == 'draft')
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('vehicle-delete'),
                    onPressed: () => _run(() async {
                      await ref.read(vehicleApiProvider).remove(widget.vehicleId);
                      if (context.mounted) Navigator.of(context).pop();
                    }),
                    icon: Icon(Icons.delete_outline, color: colors.danger),
                    label: Text('Delete this vehicle', style: TextStyle(color: colors.danger)),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}
