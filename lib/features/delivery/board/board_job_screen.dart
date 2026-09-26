import 'package:flutter/material.dart';
import '../../../core/l10n/app_locale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/price_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/kit.dart';
import '../presentation/providers/delivery_providers.dart';
import 'board_api.dart';

/// One job before deciding: the pay, the route, what is being carried, and which of his vehicles suits it. A long
/// delivery is asked for, not taken: the pickup center has to approve.
class BoardJobScreen extends ConsumerStatefulWidget {
  const BoardJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<BoardJobScreen> createState() => _BoardJobScreenState();
}

class _BoardJobScreenState extends ConsumerState<BoardJobScreen> {
  String? _vehicleId;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _take(Json job) async {
    setState(() => _busy = true);
    try {
      final out = await ref.read(boardApiProvider).take(widget.jobId, vehicleId: _vehicleId ?? job.obj('suggestedVehicle').str('id'), note: _note.text.trim());
      ref.invalidate(partnerProfileProvider);
      if (!mounted) return;
      final asked = out.str('kind') == 'requested';
      snack(context, asked ? 'Asked the village center. You will be told their answer.' : 'The delivery is yours.');
      Navigator.of(context).pop();
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
    final job = ref.watch(boardJobProvider(widget.jobId));
    return Scaffold(
      appBar: AppBar(title: const Tx('Delivery job')),
      body: ResponsiveScope(
        child: job.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(boardJobProvider(widget.jobId))),
          data: (j) {
            final options = j.list('vehicleOptions');
            final pickup = j.obj('pickup');
            final drop = j.obj('drop');
            final asks = j.flag('needsApproval');
            final chosen = options.where((o) => o.str('vehicleId') == (_vehicleId ?? j.obj('suggestedVehicle').str('id'))).firstOrNull;
            final canGo = j.flag('approved') && (chosen?.flag('fits') ?? false);
            return ListView(padding: context.pagePadding, children: [
              KitCard(
                child: Column(children: [
                  Text(formatRupeesExact(j.num_('fee')), key: const Key('job-pay'), style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: colors.primary)),
                  Text('for ${j.num_('distanceKm').toStringAsFixed(1)} km · ${j.num_('weightKg').toStringAsFixed(0)} kg', style: text.bodyMedium),
                  if (asks) ...[AppSpacing.gapSm, const StatusPill('Long distance: the center must approve', tone: Tone.info)],
                ]),
              ),
              KitCard(
                index: 1,
                title: 'Route',
                icon: Icons.route_outlined,
                child: Column(children: [
                  KitRow('Pickup', [pickup.str('centerName'), pickup.str('label')].where((s) => s.isNotEmpty).join(' · ')),
                  KitRow('Drop', drop.str('village', drop.str('label'))),
                  if (j['toPickupKm'] != null) KitRow('From you to pickup', '${j.num_('toPickupKm').toStringAsFixed(1)} km'),
                  if (j.str('pickupBy').isNotEmpty) KitRow('Pick up before', j.str('pickupBy').replaceFirst('T', '  ').substring(0, 17)),
                  Padding(padding: const EdgeInsets.only(top: 6), child: Text('The exact address and phone number are shown after you take the job.', style: text.bodySmall?.copyWith(color: colors.textMuted))),
                ]),
              ),
              KitCard(
                index: 2,
                title: 'Carrying',
                icon: Icons.inventory_2_outlined,
                child: j.list('lines').isEmpty
                    ? Text(j.str('items', j.str('note', 'Goods')), style: text.bodyMedium)
                    : Column(children: [for (final l in j.list('lines')) KitRow(l.str('name'), '× ${l.int_('quantity')}')]),
              ),
              KitCard(
                index: 3,
                title: 'Your vehicle',
                icon: Icons.local_shipping_outlined,
                child: options.isEmpty
                    ? Text('Add a vehicle and get it checked to take jobs.', style: text.bodyMedium?.copyWith(color: colors.warning))
                    : Column(children: [
                        for (final o in options)
                          ListTile(
                            key: Key('option-${o.str('vehicleId')}'),
                            contentPadding: EdgeInsets.zero,
                            selected: o.str('vehicleId') == (_vehicleId ?? j.obj('suggestedVehicle').str('id')),
                            leading: Icon(o.str('vehicleId') == (_vehicleId ?? j.obj('suggestedVehicle').str('id')) ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                            enabled: o.flag('fits'),
                            onTap: () => setState(() => _vehicleId = o.str('vehicleId')),
                            title: Text('${o.str('label')} · ${o.str('registrationNumber')}'),
                            subtitle: Text(o.flag('fits') ? (o.flag('best') ? 'Best fit for this job' : 'Fits') : o['reasons'] is List ? (o['reasons'] as List).join('. ') : 'Does not fit'),
                          ),
                      ]),
              ),
              if (asks)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TextField(key: const Key('job-note'), controller: _note, maxLength: 300, decoration: const InputDecoration(labelText: 'A word for the center (optional)', hintText: 'When you can start, your experience…')),
                ),
              AppButton(
                key: const Key('job-take'),
                label: asks ? 'Ask the village center' : 'Take this delivery',
                expand: true,
                isLoading: _busy,
                onPressed: canGo ? () => _take(j) : null,
              ),
              if (!j.flag('approved')) Padding(padding: const EdgeInsets.only(top: 8), child: Text(j.str('hint', 'Become an approved delivery partner first.'), style: text.bodySmall?.copyWith(color: colors.warning))),
            ]);
          },
        ),
      ),
    );
  }
}
