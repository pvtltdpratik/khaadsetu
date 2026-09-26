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
import '../../vehicles/vehicle_api.dart';
import 'board_api.dart';
import 'board_job_screen.dart';

/// Distance bands a partner can pick: (label, min, max) in km. "Long" is the only band that needs a center's approval.
const distanceBands = <(String, String?, String?)>[
  ('Any distance', null, null),
  ('Up to 5 km', null, '5'),
  ('5 – 20 km', '5', '20'),
  ('20 – 100 km', '20', '100'),
  ('100 km +', '100', null),
];

/// "Deliver & Earn": every open job he could do, with filters that are remembered for next time.
class DeliveryBoardScreen extends ConsumerStatefulWidget {
  const DeliveryBoardScreen({super.key});

  @override
  ConsumerState<DeliveryBoardScreen> createState() => _DeliveryBoardScreenState();
}

class _DeliveryBoardScreenState extends ConsumerState<DeliveryBoardScreen> {
  /// null until the first answer: then it shows what the server remembered, and edits create a new key.
  Map<String, String>? _filters;

  String get _key => _filters == null ? '' : encodeFilters(_filters!);

  Map<String, String> _fromServer(Json f) => {for (final e in f.entries) if (e.value != null && e.value is! Map) e.key: '${e.value}'};

  Future<void> _edit(Json current) async {
    final vehicles = ref.read(myVehiclesProvider).value ?? const <Json>[];
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: _filters ?? _fromServer(current.obj('filters')), vehicles: vehicles.where((v) => v.str('status') == 'approved').toList()),
    );
    if (result == null) return;
    setState(() => _filters = result);
    // What he chose is what he sees next time, on any phone.
    ref.read(boardApiProvider).savePrefs(result).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final board = ref.watch(boardProvider(_key));
    return Scaffold(
      appBar: AppBar(
        title: const Tx('Deliver & Earn'),
        actions: [
          IconButton(
            key: const Key('board-requests'),
            tooltip: 'My long-delivery requests',
            icon: const Icon(Icons.hourglass_top_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MyRequestsScreen())),
          ),
          board.maybeWhen(data: (b) => IconButton(key: const Key('board-filter'), tooltip: 'Filters', icon: const Icon(Icons.tune), onPressed: () => _edit(b)), orElse: () => const SizedBox.shrink()),
        ],
      ),
      body: ResponsiveScope(
        child: board.when(
          skipLoadingOnReload: true,
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(boardProvider(_key))),
          data: (b) {
            final items = b.list('items');
            final paused = b.str('pausedUntil');
            return RefreshIndicator(
              onRefresh: () => ref.refresh(boardProvider(_key).future),
              child: ListView(padding: context.pagePadding, children: [
                KitCard(
                  child: Row(children: [
                    Icon(Icons.local_shipping_outlined, color: colors.primary),
                    AppSpacing.gapSm,
                    Expanded(child: Text('${b.int_('total')} job${b.int_('total') == 1 ? '' : 's'} for you', key: const Key('board-total'), style: text.titleSmall)),
                    StatusPill('${b.int_('activeJobs')} of ${b.int_('maxActiveJobs')} active', tone: b.flag('canTakeMore') ? Tone.good : Tone.warn),
                  ]),
                ),
                if (paused.isNotEmpty)
                  KitCard(child: Text('Taking jobs is paused until ${paused.substring(0, 10)} because of cancelled deliveries.', key: const Key('board-paused'), style: text.bodyMedium?.copyWith(color: colors.danger))),
                if (b.str('hint').isNotEmpty) KitCard(child: Text(b.str('hint'), key: const Key('board-hint'), style: text.bodyMedium?.copyWith(color: colors.warning))),
                if (items.isEmpty && b.str('hint').isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('No job matches right now. Try a wider distance in Filters, or pull down to refresh.', key: const Key('board-empty'), textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted)),
                  ),
                for (final (i, j) in items.indexed) _JobCard(job: j, index: i, onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BoardJobScreen(jobId: j.str('id')))).then((_) => ref.invalidate(boardProvider(_key)))),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.index, required this.onTap});

  final Json job;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final pickup = job.obj('pickup');
    final drop = job.obj('drop');
    return KitCard(
      index: index,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(formatRupeesExact(job.num_('fee')), key: Key('job-fee-${job.str('id')}'), style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: colors.primary))),
          if (job.flag('longDistance')) const StatusPill('Long distance', tone: Tone.info),
          if (job.flag('onMyRoute')) ...[const SizedBox(width: 6), const StatusPill('On your route', tone: Tone.good)],
          if (job.str('requested').isNotEmpty) ...[const SizedBox(width: 6), const StatusPill('Asked', tone: Tone.warn)],
        ]),
        AppSpacing.gapXs,
        Row(children: [
          const Icon(Icons.trip_origin, size: 16),
          AppSpacing.gapXs,
          Expanded(child: Text(pickup.str('centerName', pickup.str('label')), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        Row(children: [
          const Icon(Icons.place_outlined, size: 16),
          AppSpacing.gapXs,
          Expanded(child: Text(drop.str('village', drop.str('label')), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        AppSpacing.gapSm,
        Wrap(spacing: 12, children: [
          Text('${job.num_('distanceKm').toStringAsFixed(1)} km', style: text.bodySmall),
          Text('${job.num_('weightKg').toStringAsFixed(0)} kg', style: text.bodySmall),
          if (job['toPickupKm'] != null) Text('${job.num_('toPickupKm').toStringAsFixed(1)} km to pickup', style: text.bodySmall?.copyWith(color: colors.textMuted)),
        ]),
        if (!job.flag('fits'))
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(job.str('message', 'None of your vehicles fits this job'), style: text.bodySmall?.copyWith(color: colors.warning))),
      ]),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.vehicles});

  final Map<String, String> initial;
  final List<Json> vehicles;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Map<String, String> f = {...widget.initial};
  late final _pickup = TextEditingController(text: f['pickup']);
  late final _drop = TextEditingController(text: f['drop']);
  late final _weight = TextEditingController(text: f['weightMax']);
  late final _fee = TextEditingController(text: f['minFee']);

  @override
  void dispose() {
    for (final c in [_pickup, _drop, _weight, _fee]) {
      c.dispose();
    }
    super.dispose();
  }

  void _put(String k, String? v) => setState(() => v == null || v.isEmpty ? f.remove(k) : f[k] = v);

  Map<String, String> _result() {
    _put('pickup', _pickup.text.trim());
    _put('drop', _drop.text.trim());
    _put('weightMax', _weight.text.trim());
    _put('minFee', _fee.text.trim());
    return {...f};
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final band = distanceBands.indexWhere((b) => b.$2 == f['distanceMin'] && b.$3 == f['distanceMax']);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Tx('Filters', style: text.titleMedium),
          AppSpacing.gapSm,
          Tx('Distance', style: text.labelLarge),
          Wrap(spacing: 8, children: [
            for (final (i, b) in distanceBands.indexed)
              ChoiceChip(
                key: Key('band-$i'),
                label: Text(b.$1),
                selected: (band < 0 ? 0 : band) == i,
                onSelected: (_) => setState(() {
                  f.remove('distanceMin');
                  f.remove('distanceMax');
                  if (b.$2 != null) f['distanceMin'] = b.$2!;
                  if (b.$3 != null) f['distanceMax'] = b.$3!;
                }),
              ),
          ]),
          AppSpacing.gapMd,
          Tx('Sort by', style: text.labelLarge),
          Wrap(spacing: 8, children: [
            for (final s in const [('nearest', 'Nearest'), ('earning', 'Earning'), ('earliest', 'Earliest')])
              ChoiceChip(key: Key('sort-${s.$1}'), label: Text(s.$2), selected: (f['sort'] ?? 'nearest') == s.$1, onSelected: (_) => _put('sort', s.$1)),
          ]),
          AppSpacing.gapMd,
          Text('Pickup time', style: text.labelLarge),
          Wrap(spacing: 8, children: [
            for (final s in const [(null, 'Any'), ('morning', 'Morning'), ('afternoon', 'Afternoon'), ('evening', 'Evening')])
              ChoiceChip(label: Text(s.$2), selected: f['slot'] == s.$1, onSelected: (_) => _put('slot', s.$1)),
          ]),
          AppSpacing.gapMd,
          Row(children: [
            Expanded(child: TextField(controller: _pickup, decoration: const InputDecoration(labelText: 'Pickup place'))),
            AppSpacing.gapSm,
            Expanded(child: TextField(controller: _drop, decoration: const InputDecoration(labelText: 'Drop village'))),
          ]),
          AppSpacing.gapSm,
          Row(children: [
            Expanded(child: TextField(controller: _weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max weight (kg)'))),
            AppSpacing.gapSm,
            Expanded(child: TextField(controller: _fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Least pay (₹)'))),
          ]),
          if (widget.vehicles.isNotEmpty) ...[
            AppSpacing.gapSm,
            DropdownButtonFormField<String?>(
              initialValue: f['vehicleId'],
              decoration: const InputDecoration(labelText: 'Only jobs my vehicle can do'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Any of my vehicles')),
                for (final v in widget.vehicles) DropdownMenuItem<String?>(value: v.str('id'), child: Text('${v.str('categoryLabel')} · ${v.str('registrationNumber')}')),
              ],
              onChanged: (v) => _put('vehicleId', v),
            ),
          ],
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Show jobs my vehicles cannot carry too'), value: f['showAll'] == 'true', onChanged: (on) => _put('showAll', on ? 'true' : null)),
          AppSpacing.gapSm,
          Row(children: [
            Expanded(child: AppButton(key: const Key('filter-clear'), label: 'Clear', variant: AppButtonVariant.outlined, onPressed: () => Navigator.pop(context, <String, String>{}))),
            AppSpacing.gapSm,
            Expanded(
              child: AppButton(
                key: const Key('filter-apply'),
                label: 'Show jobs',
                onPressed: () {
                  final r = _result();
                  Navigator.pop(context, r);
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// The long deliveries he asked a center to approve, and what became of each.
class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final requests = ref.watch(myBoardRequestsProvider);
    Tone tone(String s) => switch (s) { 'approved' => Tone.good, 'rejected' || 'expired' => Tone.bad, 'pending' || 'escalated' => Tone.warn, _ => Tone.neutral };
    String label(String s) => switch (s) { 'pending' => 'Waiting for the center', 'escalated' => 'With the admin', 'approved' => 'Approved', 'rejected' => 'Refused', 'withdrawn' => 'Withdrawn', _ => 'Expired' };
    return Scaffold(
      appBar: AppBar(title: const Tx('My requests')),
      body: ResponsiveScope(
        child: requests.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myBoardRequestsProvider)),
          data: (list) => ListView(padding: context.pagePadding, children: [
            if (list.isEmpty) Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('You have not asked for a long delivery yet.', key: const Key('requests-empty'), textAlign: TextAlign.center, style: text.bodyMedium)),
            for (final (i, r) in list.indexed)
              KitCard(
                index: i,
                title: '${r.str('pickupLabel')} → ${r.str('dropVillage')}',
                trailing: StatusPill(label(r.str('status')), tone: tone(r.str('status'))),
                child: Column(children: [
                  KitRow('Distance', '${r.num_('distanceKm').toStringAsFixed(0)} km'),
                  KitRow('Pay', formatRupeesExact(r.num_('fee'))),
                  if (r.str('decisionReason').isNotEmpty) KitRow('Reason', r.str('decisionReason')),
                  if (r.str('status') == 'pending' || r.str('status') == 'escalated')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: Key('withdraw-${r.str('id')}'),
                        onPressed: () async {
                          try {
                            await ref.read(boardApiProvider).withdraw(r.str('id'));
                          } catch (e) {
                            if (context.mounted) snack(context, '$e');
                          }
                          ref.invalidate(myBoardRequestsProvider);
                        },
                        child: const Tx('Withdraw'),
                      ),
                    ),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
