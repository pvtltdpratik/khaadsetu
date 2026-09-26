import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/price_format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';

/// Who is deciding: a village center (its own queue) or the platform admin (everything, including what a center could not decide).
enum StaffScope {
  operator('/v1/operator'),
  admin('/v1/admin');

  const StaffScope(this.base);
  final String base;
}

/// The three queues an operator or admin answers: vehicles, long deliveries and farmer-made products.
class StaffApi {
  const StaffApi(this._api, this.scope);

  final ApiClient _api;
  final StaffScope scope;

  String get _b => scope.base;
  static String _e(String v) => Uri.encodeComponent(v);

  Future<List<Json>> vehicles({String status = 'pending'}) async => asJsonList(await _api.get('$_b/vehicles', query: {'status': status}));
  Future<List<Json>> longRequests() async => asJsonList(await _api.get('$_b/long-requests', query: scope == StaffScope.admin ? {'status': 'all'} : null));
  Future<List<Json>> products() async => asJsonList(await _api.get('$_b/own/listings'));

  Future<void> decideVehicle(String id, String action, {String reason = ''}) async {
    await _api.post('$_b/vehicles/${_e(id)}/$action', body: {if (reason.isNotEmpty) 'reason': reason});
  }

  Future<void> decideRequest(String id, String action, {String reason = ''}) async {
    await _api.post('$_b/long-requests/${_e(id)}/$action', body: {if (reason.isNotEmpty) 'reason': reason});
  }

  Future<void> decideProduct(String id, String action, {String reason = ''}) async {
    await _api.post('$_b/own/listings/${_e(id)}/$action', body: {if (reason.isNotEmpty) 'reason': reason});
  }
}

final staffApiProvider = Provider.family<StaffApi, StaffScope>((ref, scope) => StaffApi(ref.watch(apiClientProvider), scope));
final staffVehiclesProvider = FutureProvider.autoDispose.family<List<Json>, StaffScope>((ref, s) => ref.watch(staffApiProvider(s)).vehicles());
final staffRequestsProvider = FutureProvider.autoDispose.family<List<Json>, StaffScope>((ref, s) => ref.watch(staffApiProvider(s)).longRequests());
final staffProductsProvider = FutureProvider.autoDispose.family<List<Json>, StaffScope>((ref, s) => ref.watch(staffApiProvider(s)).products());

Future<String?> askReason(BuildContext context, String title) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(key: const Key('reason-field'), controller: controller, autofocus: true, maxLength: 300, decoration: const InputDecoration(hintText: 'The farmer will read this')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(key: const Key('reason-ok'), onPressed: () => Navigator.pop(context, controller.text.trim().isEmpty ? null : controller.text.trim()), child: const Text('Send')),
      ],
    ),
  );
}

/// One screen for everything waiting for an answer: vehicles, long deliveries and farmer-made products.
class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key, required this.scope});

  final StaffScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int n(AsyncValue<List<Json>> v) => v.value?.length ?? 0;
    final v = n(ref.watch(staffVehiclesProvider(scope)));
    final r = n(ref.watch(staffRequestsProvider(scope)));
    final p = n(ref.watch(staffProductsProvider(scope)));
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('To check'),
          bottom: TabBar(tabs: [
            Tab(key: const Key('tab-vehicles'), text: 'Vehicles ($v)'),
            Tab(key: const Key('tab-long'), text: 'Long trips ($r)'),
            Tab(key: const Key('tab-products'), text: 'Products ($p)'),
          ]),
        ),
        body: ResponsiveScope(
          child: TabBarView(children: [
            _Queue(provider: staffVehiclesProvider(scope), empty: 'No vehicle is waiting for you.', card: (j, done) => _VehicleCard(scope: scope, v: j, done: done)),
            _Queue(provider: staffRequestsProvider(scope), empty: 'No long delivery is waiting for an answer.', card: (j, done) => _RequestCard(scope: scope, r: j, done: done)),
            _Queue(provider: staffProductsProvider(scope), empty: 'No farmer-made product is waiting to be checked.', card: (j, done) => _ProductCard(scope: scope, p: j, done: done)),
          ]),
        ),
      ),
    );
  }
}

class _Queue extends ConsumerWidget {
  const _Queue({required this.provider, required this.empty, required this.card});

  final FutureProvider<List<Json>> provider;
  final String empty;
  final Widget Function(Json item, VoidCallback done) card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(provider).when(
          skipLoadingOnReload: true,
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(provider)),
          data: (list) => RefreshIndicator(
            onRefresh: () => ref.refresh(provider.future),
            child: ListView(padding: context.pagePadding, children: [
              if (list.isEmpty) Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text(empty, key: const Key('queue-empty'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted))),
              for (final j in list) card(j, () => ref.invalidate(provider)),
            ]),
          ),
        );
  }
}

/// Approve / send back buttons that ask for a reason when sending back.
class _Decision extends StatefulWidget {
  const _Decision({required this.idKey, required this.onApprove, required this.onReject, this.approveLabel = 'Approve', this.rejectLabel = 'Send back'});

  final String idKey;
  final Future<void> Function() onApprove;
  final Future<void> Function(String reason) onReject;
  final String approveLabel;
  final String rejectLabel;

  @override
  State<_Decision> createState() => _DecisionState();
}

class _DecisionState extends State<_Decision> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) snack(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: AppButton(
            key: Key('reject-${widget.idKey}'),
            label: widget.rejectLabel,
            variant: AppButtonVariant.outlined,
            onPressed: _busy
                ? null
                : () async {
                    final reason = await askReason(context, widget.rejectLabel);
                    if (reason != null) await _run(() => widget.onReject(reason));
                  },
          ),
        ),
        AppSpacing.gapSm,
        Expanded(child: AppButton(key: Key('approve-${widget.idKey}'), label: widget.approveLabel, isLoading: _busy, onPressed: () => _run(widget.onApprove))),
      ]);
}

class _VehicleCard extends ConsumerWidget {
  const _VehicleCard({required this.scope, required this.v, required this.done});

  final StaffScope scope;
  final Json v;
  final VoidCallback done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(staffApiProvider(scope));
    final id = v.str('id');
    final papers = v.obj('papers');
    final photos = v['photos'] is List ? [for (final p in v['photos'] as List) '$p'] : <String>[];
    final docs = v.obj('documents');
    return KitCard(
      title: v.str('registrationNumber'),
      icon: Icons.local_shipping_outlined,
      trailing: StatusPill(v.str('categoryLabel'), tone: Tone.info),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        KitRow('Owner', v.str('ownerName', v.str('ownerId'))),
        KitRow('Vehicle', [v.str('company'), v.str('modelName'), v.str('makeYear')].where((s) => s.isNotEmpty).join(' ')),
        KitRow('Carries', '${v.int_('capacityKg')} kg'),
        if (v.str('driverName').isNotEmpty) KitRow('Driver', '${v.str('driverName')} ${v.str('driverPhone')}'),
        AppSpacing.gapSm,
        Wrap(spacing: 6, runSpacing: 4, children: [for (final e in papers.entries) StatusPill('${e.key.toUpperCase()}: ${e.value}', tone: e.value == 'valid' ? Tone.good : (e.value == 'expiring' ? Tone.warn : (e.value == 'notNeeded' ? Tone.neutral : Tone.bad)))]),
        AppSpacing.gapSm,
        SizedBox(
          height: 96,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final k in photos) Padding(padding: const EdgeInsets.only(right: 8), child: ApiImage('${scope.base}/vehicles/$id/photos/$k', height: 96, width: 96)),
            for (final k in docs.keys) Padding(padding: const EdgeInsets.only(right: 8), child: ApiImage('${scope.base}/vehicles/$id/documents/$k', height: 96, width: 96)),
          ]),
        ),
        AppSpacing.gapMd,
        _Decision(
          idKey: id,
          onApprove: () async {
            await api.decideVehicle(id, 'approve');
            done();
          },
          onReject: (reason) async {
            await api.decideVehicle(id, 'reject', reason: reason);
            done();
          },
        ),
      ]),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.scope, required this.r, required this.done});

  final StaffScope scope;
  final Json r;
  final VoidCallback done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(staffApiProvider(scope));
    final id = r.str('id');
    final vehicle = r.obj('vehicle');
    final open = r.str('status') == 'pending' || r.str('status') == 'escalated';
    return KitCard(
      title: '${r.str('pickupLabel')} → ${r.str('dropVillage')}',
      icon: Icons.route_outlined,
      trailing: StatusPill(r.str('status') == 'escalated' ? 'Late: with admin' : r.str('status'), tone: r.str('status') == 'escalated' ? Tone.warn : Tone.info),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        KitRow('Distance', '${r.num_('distanceKm').toStringAsFixed(0)} km · ${r.num_('weightKg').toStringAsFixed(0)} kg'),
        KitRow('Pay', formatRupeesExact(r.num_('fee'))),
        KitRow('Partner', '${r.str('partnerName')}${r.str('partnerVillage').isEmpty ? '' : ', ${r.str('partnerVillage')}'}'),
        KitRow('Record', '${r.int_('deliveriesDone')} deliveries · ${r.num_('ratingAvg').toStringAsFixed(1)}★ · ${r.int_('cancellations')} cancelled'),
        if (vehicle.isNotEmpty) KitRow('Vehicle', '${vehicle.str('categoryLabel')} ${vehicle.str('registrationNumber')} (${vehicle.int_('capacityKg')} kg)'),
        if (r.str('note').isNotEmpty) KitRow('Note', r.str('note')),
        if (open) ...[
          AppSpacing.gapMd,
          _Decision(
            idKey: id,
            approveLabel: 'Approve',
            rejectLabel: 'Refuse',
            onApprove: () async {
              await api.decideRequest(id, 'approve');
              done();
            },
            onReject: (reason) async {
              await api.decideRequest(id, 'reject', reason: reason);
              done();
            },
          ),
        ] else if (r.str('decisionReason').isNotEmpty)
          KitRow('Reason', r.str('decisionReason')),
      ]),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.scope, required this.p, required this.done});

  final StaffScope scope;
  final Json p;
  final VoidCallback done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(staffApiProvider(scope));
    final id = p.str('id');
    final photos = p['photos'] is List ? [for (final x in p['photos'] as List) '$x'] : <String>[];
    final lab = p.obj('labValues');
    final reports = p.list('reports');
    return KitCard(
      title: p.str('name'),
      icon: Icons.eco_outlined,
      trailing: StatusPill(p.str('status'), tone: p.str('status') == 'hidden' ? Tone.bad : Tone.warn),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        KitRow('Farmer', '${p.str('sellerName')}, ${p.str('sellerVillage')}'),
        KitRow('Kind', p.str('categoryLabel')),
        KitRow('Price', '${formatRupeesExact(p.num_('pricePerUnit'))} per ${p.str('unit')}'),
        KitRow('Stock', '${p.num_('quantityAvailable').toStringAsFixed(0)} ${p.str('unit')}'),
        KitRow('Materials', p.str('materials')),
        if (lab.isNotEmpty) KitRow('Lab N-P-K', '${lab.str('n', '-')} - ${lab.str('p', '-')} - ${lab.str('k', '-')}'),
        KitRow('Organic promise', p.flag('organicConfirmed') ? 'Confirmed by the farmer' : 'Not confirmed'),
        if (reports.isNotEmpty) ...[
          AppSpacing.gapSm,
          Text('${reports.length} report${reports.length == 1 ? '' : 's'}: ${reports.map((x) => x.str('reason')).join('; ')}', style: TextStyle(color: context.colors.danger)),
        ],
        AppSpacing.gapSm,
        SizedBox(
          height: 96,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final pos in photos) Padding(padding: const EdgeInsets.only(right: 8), child: ApiImage('${scope.base}/own/listings/$id/photos/$pos', height: 96, width: 96)),
            if (p.flag('hasLabReport')) ApiImage('${scope.base}/own/listings/$id/lab-report', height: 96, width: 96),
          ]),
        ),
        AppSpacing.gapMd,
        if (p.str('status') == 'hidden')
          AppButton(
            key: Key('approve-$id'),
            label: 'Show it again',
            expand: true,
            onPressed: () async {
              await api.decideProduct(id, 'reinstate');
              done();
            },
          )
        else
          _Decision(
            idKey: id,
            onApprove: () async {
              await api.decideProduct(id, 'approve');
              done();
            },
            onReject: (reason) async {
              await api.decideProduct(id, 'reject', reason: reason);
              done();
            },
          ),
      ]),
    );
  }
}
