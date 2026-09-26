import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/price_format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import 'approvals_screen.dart' show StaffScope;

/// The farmer as a center (or the admin) sees him. Reads what the server allows for that role: a center sees only farmers
/// who dealt with it, the admin sees anyone.
final farmerCardProvider = FutureProvider.autoDispose.family<Json, ({StaffScope scope, String id})>((ref, key) async {
  final path = key.scope == StaffScope.operator ? '/v1/operator/farmers/${Uri.encodeComponent(key.id)}/card' : '/v1/admin/users/${Uri.encodeComponent(key.id)}/card';
  return asJson(await ref.watch(apiClientProvider).get(path));
});

final farmerTimelineProvider = FutureProvider.autoDispose.family<List<Json>, String>((ref, id) async => asJsonList(await ref.watch(apiClientProvider).get('/v1/admin/users/${Uri.encodeComponent(id)}/timeline')));

const _activityKinds = {'soil_test': 'Soil test', 'follow_up': 'Follow-up', 'scheme_help': 'Scheme help', 'visit': 'Visit', 'note': 'Note'};

Tone schemeTone(String status) => switch (status) { 'eligible' || 'open' => Tone.good, 'possible' => Tone.warn, _ => Tone.neutral };
String schemeText(String status) => switch (status) { 'eligible' => 'Eligible', 'open' => 'Open to all', 'possible' => 'May be eligible', _ => 'Not eligible' };

class FarmerCardScreen extends ConsumerWidget {
  const FarmerCardScreen({super.key, required this.scope, required this.farmerId});

  final StaffScope scope;
  final String farmerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final key = (scope: scope, id: farmerId);
    final card = ref.watch(farmerCardProvider(key));
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer')),
      body: ResponsiveScope(
        child: card.when(
          skipLoadingOnReload: true,
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(farmerCardProvider(key))),
          data: (c) {
            final facts = c.obj('facts');
            final totals = c.obj('totals');
            final address = c.obj('address');
            final schemes = c.list('schemes');
            final due = c.num_('creditDue');
            return ListView(padding: context.pagePadding, children: [
              KitCard(
                title: c.str('name'),
                icon: Icons.person_outline,
                trailing: c.str('status') == 'suspended' ? const StatusPill('Suspended', tone: Tone.bad) : null,
                child: Column(children: [
                  KitRow('Village', c.str('village', '-')),
                  KitRow('Phone', c.str('phone', '-')),
                  if (address.isNotEmpty) KitRow('Address', [address.str('line1'), address.str('taluka'), address.str('district'), address.str('pincode')].where((s) => s.isNotEmpty).join(', ')),
                  KitRow('Land', '${c.num_('landHectares').toStringAsFixed(1)} ha'),
                  if (facts.str('landOwnership').isNotEmpty) KitRow('Ownership', facts.str('landOwnership')),
                  if (facts.str('irrigation').isNotEmpty) KitRow('Irrigation', facts.str('irrigation')),
                  if (facts.str('soilType').isNotEmpty) KitRow('Soil', facts.str('soilType')),
                  if ((facts['primaryCrops'] as List? ?? const []).isNotEmpty) KitRow('Crops', (facts['primaryCrops'] as List).join(', ')),
                  if (facts['practisesOrganic'] != null) KitRow('Organic farming', facts['practisesOrganic'] == true ? 'Yes' : 'No'),
                ]),
              ),
              KitCard(
                index: 1,
                title: 'Money',
                icon: Icons.account_balance_wallet_outlined,
                child: Column(children: [
                  KitRow('Bought here', '${totals.int_('orders')} orders · ${formatRupeesExact(totals.num_('spent'))}'),
                  KitRow('Owes', formatRupeesExact(due), bold: due > 0),
                  if (due > 0)
                    Padding(padding: const EdgeInsets.only(top: 6), child: Text('Collect it from the Credit book.', style: text.bodySmall?.copyWith(color: colors.danger))),
                ]),
              ),
              KitCard(
                index: 2,
                title: 'Recent orders',
                icon: Icons.shopping_basket_outlined,
                child: c.list('orders').isEmpty
                    ? Text('No orders yet.', style: text.bodyMedium)
                    : Column(children: [
                        for (final o in c.list('orders').take(8))
                          KitRow('${o.str('id').length > 12 ? o.str('id').substring(0, 12) : o.str('id')} · ${o.str('status')}', formatRupeesExact(o.num_('total'))),
                      ]),
              ),
              KitCard(
                index: 3,
                title: 'Schemes he may get (${schemes.where((s) => s.str('status') == 'eligible' || s.str('status') == 'open').length} eligible)',
                icon: Icons.account_balance_outlined,
                child: Column(children: [
                  for (final s in schemes)
                    ListTile(
                      key: Key('scheme-${s.str('schemeId')}'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(s.str('name')),
                      subtitle: Text(s.str('status') == 'possible' && (s['missing'] as List? ?? const []).isNotEmpty ? 'Still to ask: ${(s['missing'] as List).join(', ')}' : s.str('agency')),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        StatusPill(schemeText(s.str('status')), tone: schemeTone(s.str('status'))),
                        if (s.str('application') != 'notApplied') Text('Applied: ${s.str('application')}', style: text.labelSmall),
                      ]),
                    ),
                ]),
              ),
              _Diary(scope: scope, farmerId: farmerId, entries: c.list('diary'), schemes: schemes, onChanged: () => ref.invalidate(farmerCardProvider(key))),
              if (scope == StaffScope.admin) _Timeline(farmerId: farmerId),
            ]);
          },
        ),
      ),
    );
  }
}

class _Diary extends ConsumerStatefulWidget {
  const _Diary({required this.scope, required this.farmerId, required this.entries, required this.schemes, required this.onChanged});

  final StaffScope scope;
  final String farmerId;
  final List<Json> entries;
  final List<Json> schemes;
  final VoidCallback onChanged;

  @override
  ConsumerState<_Diary> createState() => _DiaryState();
}

class _DiaryState extends ConsumerState<_Diary> {
  String _kind = 'follow_up';
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).post('/v1/operator/farmers/${Uri.encodeComponent(widget.farmerId)}/activity', body: {'kind': _kind, 'note': _note.text.trim()});
      _note.clear();
      widget.onChanged();
    } catch (e) {
      if (mounted) snack(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return KitCard(
      index: 4,
      title: 'What you did for him',
      icon: Icons.edit_note_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.entries.isEmpty) Text('Nothing written yet.', key: const Key('diary-empty'), style: text.bodyMedium),
        for (final e in widget.entries.take(10)) KitRow(_activityKinds[e.str('kind')] ?? e.str('kind'), '${e.str('note')} · ${e.str('createdAt').length >= 10 ? e.str('createdAt').substring(0, 10) : ''}'),
        if (widget.scope == StaffScope.operator) ...[
          AppSpacing.gapSm,
          Wrap(spacing: 6, children: [for (final k in _activityKinds.entries) ChoiceChip(key: Key('kind-${k.key}'), label: Text(k.value), selected: _kind == k.key, onSelected: (_) => setState(() => _kind = k.key))]),
          AppSpacing.gapSm,
          TextField(key: const Key('diary-note'), controller: _note, maxLength: 500, decoration: const InputDecoration(labelText: 'Note')),
          AppButton(key: const Key('diary-add'), label: 'Add to diary', isLoading: _busy, onPressed: _add),
        ],
      ]),
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline({required this.farmerId});

  final String farmerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KitCard(
      index: 5,
      title: 'Everything he did',
      icon: Icons.history,
      child: ref.watch(farmerTimelineProvider(farmerId)).when(
            loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
            error: (err, _) => Text('$err'),
            data: (list) => list.isEmpty
                ? const Text('No activity yet.')
                : Column(children: [for (final e in list.take(40)) KitRow(e.str('at').length >= 10 ? e.str('at').substring(0, 10) : '', e.str('title'))]),
          ),
    );
  }
}
