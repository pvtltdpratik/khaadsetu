import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../../domain/entities/delivery_models.dart';
import '../../presentation/widgets/live_refresh.dart';
import '../../presentation/widgets/partner_job_cards.dart';
import '../domain/management_models.dart';
import 'management_providers.dart';
import 'partner_review_screen.dart';

/// Home delivery, for a village center (its own deliveries, the people who asked it
/// to check them, and the cash it is owed) or for the platform admin (everything,
/// read and review only).
class DeliveryManagementScreen extends StatelessWidget {
  const DeliveryManagementScreen({super.key, required this.scope});

  final ManagementScope scope;

  @override
  Widget build(BuildContext context) {
    final operator = scope == ManagementScope.operator;
    return ResponsiveScope(
      child: DefaultTabController(
        length: operator ? 3 : 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Home delivery'),
            bottom: TabBar(tabs: [
              const Tab(key: Key('tab-deliveries'), text: 'Deliveries'),
              const Tab(key: Key('tab-partners'), text: 'Partners'),
              if (operator) const Tab(key: Key('tab-cash'), text: 'Cash'),
            ]),
          ),
          body: SafeArea(
            child: TabBarView(children: [
              _DeliveriesTab(scope: scope),
              _PartnersTab(scope: scope),
              if (operator) const _CashTab(),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Deliveries
// ---------------------------------------------------------------------------

const _statusFilters = <(String, DeliveryStatus?)>[
  ('All', null),
  ('Finding a driver', DeliveryStatus.open),
  ('Collecting', DeliveryStatus.assigned),
  ('On the road', DeliveryStatus.inTransit),
  ('Delivered', DeliveryStatus.delivered),
  ('Called off', DeliveryStatus.fallback),
];

class _DeliveriesTab extends ConsumerStatefulWidget {
  const _DeliveriesTab({required this.scope});

  final ManagementScope scope;

  @override
  ConsumerState<_DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends ConsumerState<_DeliveriesTab> {
  DeliveryStatus? _status;
  bool _busy = false;

  DeliveriesQuery get _query => DeliveriesQuery(widget.scope, _status);

  void _refresh() => ref.invalidate(managedDeliveriesProvider(_query));

  void _say(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handover(ManagedDelivery d) async {
    final code = await showDeliveryCodeDialog(
      context,
      title: 'Hand over the goods',
      help: 'Ask the delivery partner for the 4-digit code in their app. Give the goods only after you have typed it.',
      action: 'Hand over',
    );
    if (code == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(managementRepositoryProvider(widget.scope)).handover(d.id, code);
      _say('Handed over. The farmer has been told it is on its way.');
    } catch (err) {
      _say('$err');
    } finally {
      _refresh();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDriver(ManagedDelivery d) async {
    final partnerId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CandidatesSheet(scope: widget.scope, delivery: d),
    );
    if (partnerId == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(managementRepositoryProvider(widget.scope)).assign(d.id, partnerId);
      _say('Assigned. The partner and the farmer have been told.');
    } catch (err) {
      _say('$err');
    } finally {
      _refresh();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(managedDeliveriesProvider(_query));
    final operator = widget.scope == ManagementScope.operator;
    return LiveRefresh(
      interval: const Duration(seconds: 30),
      onTick: _refresh,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              for (final (label, status) in _statusFilters)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(key: Key('filter-$label'), label: Text(label), selected: _status == status, onSelected: (_) => setState(() => _status = status)),
                ),
            ]),
          ),
          Expanded(
            child: list.when(
              skipLoadingOnReload: true,
              loading: () => const AppLoadingIndicator(),
              error: (err, _) => AppErrorView(message: '$err', onRetry: _refresh),
              data: (items) => RefreshIndicator(
                onRefresh: () async {
                  _refresh();
                  await ref.read(managedDeliveriesProvider(_query).future);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  children: [
                    ContentContainer(
                      maxWidth: 720,
                      child: items.isEmpty
                          ? Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Center(key: const Key('no-deliveries'), child: Text(_status == null ? 'No deliveries yet.' : 'No deliveries in this state.')))
                          : Column(children: [
                              for (final (i, d) in items.indexed)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: FadeSlideIn(index: i, child: _DeliveryCard(delivery: d, operator: operator, busy: _busy, onPickDriver: () => _pickDriver(d), onHandover: () => _handover(d))),
                                ),
                            ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery, required this.operator, required this.busy, required this.onPickDriver, required this.onHandover});

  final ManagedDelivery delivery;
  final bool operator;
  final bool busy;
  final VoidCallback onPickDriver;
  final VoidCallback onHandover;

  static (String, Color Function(AppColorTokens)) _badge(DeliveryStatus s) => switch (s) {
        DeliveryStatus.open => ('Finding a driver', (c) => c.warning),
        DeliveryStatus.assigned => ('Driver collecting', (c) => c.info),
        DeliveryStatus.inTransit => ('On the road', (c) => c.info),
        DeliveryStatus.delivered => ('Delivered', (c) => c.success),
        DeliveryStatus.cancelled => ('Cancelled', (c) => c.textMuted),
        DeliveryStatus.fallback => ('Collect at center', (c) => c.textMuted),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final d = delivery;
    final (label, colorOf) = _badge(d.status);
    final color = colorOf(colors);
    final kg = d.weightKg == d.weightKg.roundToDouble() ? d.weightKg.toStringAsFixed(0) : d.weightKg.toStringAsFixed(1);
    return Container(
      key: Key('delivery-${d.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: d.needsDriver ? colors.warning : colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(d.isP2p ? 'Farmer to farmer · ${d.buyerName}' : '${d.buyerName} · ${d.dropVillage.isEmpty ? 'a farm' : d.dropVillage}', style: text.titleSmall)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text(label, style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Text('$kg kg · ${d.distanceKm.toStringAsFixed(1)} km · fee ${formatRupees(d.fee)}${d.goodsAmount > 0 ? ' · goods ${formatRupees(d.goodsAmount)}' : ''}', style: text.bodyMedium),
          if (d.centerName != null) Text(d.centerName!, style: text.bodySmall?.copyWith(color: colors.textMuted)),
          if (d.hasPartner) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              Icon(Icons.local_shipping_outlined, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('${d.partnerName ?? 'Partner'} · ${d.vehicleType?.label ?? ''} ${d.vehicleNumber ?? ''}${d.ratingAvg == null || d.ratingAvg == 0 ? '' : ' · ★ ${d.ratingAvg!.toStringAsFixed(1)}'}', style: text.bodySmall)),
              if ((d.partnerPhone ?? '').isNotEmpty) IconButton(tooltip: 'Call partner', visualDensity: VisualDensity.compact, onPressed: () => callPhone(context, d.partnerPhone!), icon: const Icon(Icons.call_rounded, size: 20)),
            ]),
          ],
          if (d.status == DeliveryStatus.open) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              d.needsDriver ? 'Nobody has taken this yet. You can pick someone yourself.' : (d.offersPending > 0 ? 'Offered to ${d.offersPending} partner${d.offersPending == 1 ? '' : 's'} now.' : 'Looking for a partner.'),
              key: Key('open-note-${d.id}'),
              style: text.bodySmall?.copyWith(color: d.needsDriver ? colors.warning : colors.textMuted),
            ),
          ],
          if (operator && (d.status == DeliveryStatus.open || d.status == DeliveryStatus.assigned)) ...[
            AppSpacing.gapSm,
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              if (d.status == DeliveryStatus.assigned)
                FilledButton.icon(key: Key('handover-${d.id}'), onPressed: busy ? null : onHandover, icon: const Icon(Icons.inventory_2_outlined, size: 18), label: const Text('Hand over the goods')),
              OutlinedButton.icon(
                key: Key('driver-${d.id}'),
                onPressed: busy ? null : onPickDriver,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: Text(d.status == DeliveryStatus.open ? 'Pick a driver' : 'Change driver'),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _CandidatesSheet extends ConsumerWidget {
  const _CandidatesSheet({required this.scope, required this.delivery});

  final ManagementScope scope;
  final ManagedDelivery delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Who can carry ${delivery.weightKg.toStringAsFixed(0)} kg?', style: text.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
            child: Text('Approved partners whose vehicle can take it, free ones first. Call them before you choose.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
          ),
          Expanded(
            child: FutureBuilder<List<AssignCandidate>>(
              future: ref.read(managementRepositoryProvider(scope)).candidates(delivery.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
                final list = snapshot.data ?? const [];
                if (list.isEmpty) return const Center(key: Key('no-candidates'), child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Text('No approved partner can take this load right now.')));
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return ListTile(
                      key: Key('candidate-${c.userId}'),
                      leading: Icon(c.freeNow ? Icons.check_circle_rounded : Icons.schedule_rounded, color: c.freeNow ? colors.success : colors.textMuted),
                      title: Text(c.name),
                      subtitle: Text('${c.vehicleType?.label ?? ''} ${c.vehicleNumber} · ${c.capacityKg} kg${c.toPickupKm == null ? '' : ' · ${c.toPickupKm!.toStringAsFixed(1)} km away'}${c.freeNow ? ' · free now' : ' · not on duty'}'),
                      trailing: FilledButton(key: Key('assign-${c.userId}'), onPressed: () => Navigator.pop(context, c.userId), child: const Text('Assign')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Partners
// ---------------------------------------------------------------------------

const _partnerFilters = <(String, PartnerStatus?)>[
  ('All', null),
  ('Waiting', PartnerStatus.pending),
  ('Approved', PartnerStatus.approved),
  ('Suspended', PartnerStatus.suspended),
  ('Turned down', PartnerStatus.rejected),
];

class _PartnersTab extends ConsumerStatefulWidget {
  const _PartnersTab({required this.scope});

  final ManagementScope scope;

  @override
  ConsumerState<_PartnersTab> createState() => _PartnersTabState();
}

class _PartnersTabState extends ConsumerState<_PartnersTab> {
  PartnerStatus? _status = PartnerStatus.pending;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final query = PartnersQuery(widget.scope, _status, _search);
    final list = ref.watch(managedPartnersProvider(query));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: TextField(key: const Key('partner-search'), onSubmitted: (v) => setState(() => _search = v.trim()), decoration: const InputDecoration(hintText: 'Search by name, village or vehicle number', prefixIcon: Icon(Icons.search_rounded))),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            for (final (label, status) in _partnerFilters)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(key: Key('pfilter-$label'), label: Text(label), selected: _status == status, onSelected: (_) => setState(() => _status = status)),
              ),
          ]),
        ),
        Expanded(
          child: list.when(
            skipLoadingOnReload: true,
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(managedPartnersProvider(query))),
            data: (items) => ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                ContentContainer(
                  maxWidth: 720,
                  child: items.isEmpty
                      ? Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Center(key: const Key('no-partners'), child: Text(_status == PartnerStatus.pending ? 'Nobody is waiting to be checked.' : 'No partners here.')))
                      : Column(children: [
                          for (final (i, p) in items.indexed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: FadeSlideIn(
                                index: i,
                                child: Material(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    key: Key('partner-${p.userId}'),
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PartnerReviewScreen(scope: widget.scope, userId: p.userId)));
                                      ref.invalidate(managedPartnersProvider(query));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: p.status == PartnerStatus.pending ? colors.warning : colors.border)),
                                      child: Row(children: [
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(p.name, style: text.titleSmall),
                                            Text('${p.vehicleType?.label ?? 'Vehicle'} · ${p.vehicleNumber}${p.capacityKg == null ? '' : ' · ${p.capacityKg} kg'}', style: text.bodySmall),
                                            Text('${p.village.isEmpty ? '' : '${p.village} · '}${p.submittedAt == null ? 'not sent yet' : 'sent ${formatDay(p.submittedAt!)}'}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
                                          ]),
                                        ),
                                        _StatusChip(status: p.status),
                                        Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                                      ]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PartnerStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, color) = switch (status) {
      PartnerStatus.pending => ('Waiting', colors.warning),
      PartnerStatus.approved => ('Approved', colors.success),
      PartnerStatus.suspended => ('Suspended', colors.danger),
      PartnerStatus.rejected => ('Turned down', colors.danger),
      _ => ('Draft', colors.textMuted),
    };
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ---------------------------------------------------------------------------
// Cash
// ---------------------------------------------------------------------------

/// Records what a partner handed over. A dialog of its own so it owns its text box.
class _CashDialog extends StatefulWidget {
  const _CashDialog({required this.owed});

  final CashOwed owed;

  @override
  State<_CashDialog> createState() => _CashDialogState();
}

class _CashDialogState extends State<_CashDialog> {
  late final _controller = TextEditingController(text: widget.owed.owed.round().toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Cash from ${widget.owed.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${widget.owed.name} owes ${formatRupees(widget.owed.owed)} for goods delivered. Count the cash, then record what they handed over.'),
          AppSpacing.gapSm,
          TextField(key: const Key('cash-amount'), controller: _controller, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Amount handed over (₹)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(key: const Key('cash-record'), onPressed: () => Navigator.pop(context, double.tryParse(_controller.text)), child: const Text('Record')),
        ],
      );
}

class _CashTab extends ConsumerWidget {
  const _CashTab();

  Future<void> _record(BuildContext context, WidgetRef ref, CashOwed c) async {
    final amount = await showDialog<double>(context: context, builder: (_) => _CashDialog(owed: c));
    if (amount == null || amount <= 0 || !context.mounted) return;
    try {
      await ref.read(managementRepositoryProvider(ManagementScope.operator)).settleCash(c.partnerId, amount);
      ref.invalidate(cashOwedProvider);
    } catch (err) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final list = ref.watch(cashOwedProvider);
    return list.when(
      loading: () => const AppLoadingIndicator(),
      error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(cashOwedProvider)),
      data: (items) => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ContentContainer(
            maxWidth: 720,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Delivery partners collect the goods money from buyers in cash. It is owed to this center until they hand it over.', style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
              AppSpacing.gapMd,
              if (items.isEmpty)
                Container(key: const Key('no-cash'), padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(14)), child: const Text('No partner owes this center any cash.'))
              else
                for (final c in items)
                  Card(
                    key: Key('cash-${c.partnerId}'),
                    child: ListTile(
                      title: Text(c.name),
                      subtitle: Text('Owes ${formatRupees(c.owed)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (c.phone.isNotEmpty) IconButton(tooltip: 'Call', onPressed: () => callPhone(context, c.phone), icon: const Icon(Icons.call_rounded)),
                        FilledButton(key: Key('record-${c.partnerId}'), onPressed: () => _record(context, ref, c), child: const Text('Record cash')),
                      ]),
                    ),
                  ),
            ]),
          ),
        ],
      ),
    );
  }
}
