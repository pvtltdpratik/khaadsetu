import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../farmer/centers/domain/entities/nearby_center.dart';
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../../domain/entities/delivery_models.dart';
import '../providers/delivery_providers.dart';
import '../widgets/delivery_option.dart';
import '../widgets/delivery_tracking_card.dart';
import '../widgets/live_refresh.dart';
import '../widgets/partner_job_cards.dart';
import '../widgets/place_picker_field.dart';
import '../widgets/rating_sheet.dart';

/// Loads I asked another farmer's vehicle to carry: newest first.
class MyLoadsScreen extends ConsumerWidget {
  const MyLoadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loads = ref.watch(myLoadsProvider);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Loads I sent')),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('send-load'),
          onPressed: () => context.push(RoutePaths.farmerLoadNew),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Send a load'),
        ),
        body: SafeArea(
          child: loads.when(
            skipLoadingOnReload: true,
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myLoadsProvider)),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, 96),
              children: [
                ContentContainer(
                  maxWidth: 720,
                  child: list.isEmpty
                      ? Container(
                          key: const Key('no-loads'),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
                          child: const Text('Need something carried to another farm? Seed, a sack of grain, a borrowed tool. Tap "Send a load" and a delivery partner will take it.'),
                        )
                      : Column(children: [
                          for (final (i, l) in list.indexed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: FadeSlideIn(
                                index: i,
                                child: Material(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    key: Key('load-${l.jobId}'),
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => context.push(RoutePaths.farmerLoad(l.jobId)),
                                    child: Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                                      child: Row(children: [
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(l.description, style: text.titleSmall),
                                            Text(l.stage, style: text.bodySmall?.copyWith(color: colors.textMuted)),
                                          ]),
                                        ),
                                        Text(formatRupees(l.fee), style: text.titleSmall),
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
      ),
    );
  }
}

/// One load being carried: who has it, where it is, the codes, the way to call it off.
class LoadDetailScreen extends ConsumerWidget {
  const LoadDetailScreen({super.key, required this.jobId});

  final String jobId;

  void _refresh(WidgetRef ref) => ref
    ..invalidate(loadProvider(jobId))
    ..invalidate(myLoadsProvider);

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() work) async {
    try {
      await work();
      _refresh(ref);
    } catch (err) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      _refresh(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final load = ref.watch(loadProvider(jobId));
    final repo = ref.read(deliveryRepositoryProvider);
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Your load')),
        body: SafeArea(
          child: load.when(
            skipLoadingOnReload: true,
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(loadProvider(jobId))),
            data: (d) => LiveRefresh(
              active: d.status.isLive,
              onTick: () => ref.invalidate(loadProvider(jobId)),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  ContentContainer(
                    maxWidth: 720,
                    child: DeliveryTrackingCard(
                      delivery: d,
                      onHandOver: () async {
                        final code = await showDeliveryCodeDialog(context, title: 'Hand over the load', help: 'Ask the delivery partner for the 4-digit handover code in their app, then give them the load.', action: 'Hand over');
                        if (code == null || !context.mounted) return;
                        await _run(context, ref, () => repo.handOverLoad(jobId: jobId, otp: code));
                      },
                      onCancel: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel this request?'),
                            content: const Text('The delivery partner is told not to come.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel request')),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) await _run(context, ref, () => repo.cancelLoad(jobId));
                      },
                      onRate: () async {
                        final rating = await showRatingDialog(context, title: 'How was the delivery?');
                        if (rating == null || !context.mounted) return;
                        await _run(context, ref, () => repo.rateLoad(jobId: jobId, stars: rating.stars, comment: rating.comment));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ask for a load to be carried: where from and to, how heavy, who pays the fee.
/// A farmer already going that way (a posted trip) can be chosen instead of
/// whoever is free.
class SendLoadScreen extends ConsumerStatefulWidget {
  const SendLoadScreen({super.key});

  @override
  ConsumerState<SendLoadScreen> createState() => _SendLoadScreenState();
}

class _SendLoadScreenState extends ConsumerState<SendLoadScreen> {
  GeoPoint? _from;
  GeoPoint? _to;
  final _fromPhone = TextEditingController();
  final _toPhone = TextEditingController();
  final _toNote = TextEditingController();
  final _weight = TextEditingController();
  final _what = TextEditingController();
  String _feePayer = 'sender';
  String? _tripId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_fromPhone, _toPhone, _weight, _what]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_fromPhone, _toPhone, _toNote, _weight, _what]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _kg {
    final v = double.tryParse(_weight.text.trim());
    return v != null && v >= 1 && v <= 5000 ? v : null;
  }

  LoadRequest? _request() {
    final kg = _kg;
    if (_from == null || _to == null || kg == null) return null;
    if (!isValidMobile(_fromPhone.text) || !isValidMobile(_toPhone.text) || _what.text.trim().length < 2) return null;
    return LoadRequest(
      from: _from!,
      fromPhone: _fromPhone.text.trim(),
      to: _to!,
      toPhone: _toPhone.text.trim(),
      weightKg: kg,
      description: _what.text.trim(),
      feePayer: _feePayer,
      toVillage: _to!.label,
      toNote: _toNote.text.trim(),
      tripId: _tripId,
    );
  }

  Future<void> _send(LoadRequest request) async {
    setState(() => _busy = true);
    try {
      final sent = await ref.read(deliveryRepositoryProvider).sendLoad(request);
      ref.invalidate(myLoadsProvider);
      if (mounted) context.pushReplacement(RoutePaths.farmerLoad(sent.jobId));
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final kg = _kg;
    final routeReady = _from != null && _to != null && kg != null;
    final args = routeReady ? RouteArgs(from: _from!, to: _to!, weightKg: kg) : null;
    final quote = args == null ? null : ref.watch(loadQuoteProvider(args));
    final request = _request();
    final canSend = request != null && (quote?.value?.available ?? false) && !_busy;

    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Send a load')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              ContentContainer(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('A delivery partner will collect it from you and bring it to the other farm. You keep a code for the receiver; the partner keeps one for you.', style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
                    AppSpacing.gapMd,
                    PlacePickerField(key: const Key('load-from'), label: 'Collect from', icon: Icons.trip_origin_rounded, value: _from, onChanged: (p) => setState(() {
                          _from = p;
                          _tripId = null;
                        })),
                    AppSpacing.gapSm,
                    TextField(key: const Key('load-from-phone'), controller: _fromPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Your mobile number', prefixIcon: Icon(Icons.call_outlined))),
                    AppSpacing.gapMd,
                    PlacePickerField(key: const Key('load-to'), label: 'Deliver to', value: _to, onChanged: (p) => setState(() {
                          _to = p;
                          _tripId = null;
                        })),
                    AppSpacing.gapSm,
                    TextField(key: const Key('load-to-phone'), controller: _toPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Receiver mobile number', prefixIcon: Icon(Icons.call_outlined))),
                    AppSpacing.gapSm,
                    TextField(key: const Key('load-to-note'), controller: _toNote, maxLength: 300, decoration: const InputDecoration(labelText: 'Where exactly? (optional)', hintText: 'Blue gate, behind the school')),
                    AppSpacing.gapMd,
                    TextField(key: const Key('load-what'), controller: _what, maxLength: 200, decoration: const InputDecoration(labelText: 'What is it?', hintText: 'Two sacks of seed potatoes')),
                    AppSpacing.gapSm,
                    TextField(key: const Key('load-weight'), controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'How heavy (kg)')),
                    AppSpacing.gapMd,
                    Text('Who pays the delivery fee, in cash?', style: text.titleSmall),
                    AppSpacing.gapSm,
                    SegmentedButton<String>(
                      key: const Key('fee-payer'),
                      showSelectedIcon: false,
                      segments: const [ButtonSegment(value: 'sender', label: Text('I pay')), ButtonSegment(value: 'receiver', label: Text('Receiver pays'))],
                      selected: {_feePayer},
                      onSelectionChanged: (s) => setState(() => _feePayer = s.first),
                    ),
                    AppSpacing.gapMd,
                    if (quote != null)
                      quote.when(
                        skipLoadingOnReload: true,
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('$err', style: text.bodyMedium?.copyWith(color: colors.danger)),
                        data: (q) => Container(
                          key: const Key('load-quote'),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(12)),
                          child: q.available
                              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text('Delivery fee', style: text.titleSmall)),
                                    Text(formatRupees(q.fee ?? 0), key: const Key('load-fee'), style: text.titleMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
                                  ]),
                                  Text('About ${q.roadKm.toStringAsFixed(1)} km. ${q.note}', style: text.bodySmall),
                                ])
                              : Text(q.note, style: text.bodyMedium),
                        ),
                      ),
                    if (args != null) _TripChoices(args: args, selected: _tripId, onSelected: (id) => setState(() => _tripId = id)),
                    AppSpacing.gapLg,
                    FilledButton.icon(
                      key: const Key('send-submit'),
                      onPressed: canSend ? () => _send(request) : null,
                      icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.local_shipping_outlined),
                      label: Text(_tripId == null ? 'Ask for a delivery partner' : 'Book this trip'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Farmers already going the same way, so the load rides with them.
class _TripChoices extends ConsumerWidget {
  const _TripChoices({required this.args, required this.selected, required this.onSelected});

  final RouteArgs args;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final board = ref.watch(tripBoardProvider(BoardArgs(location: FarmerLocation(latitude: args.from.latitude, longitude: args.from.longitude, source: LocationSource.pin), weightKg: args.weightKg)));
    final trips = (board.value ?? const <Trip>[]).where((t) => t.from.distanceKm(args.from) <= 8 && t.to.distanceKm(args.to) <= 8).toList();
    if (trips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Going your way', style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text('These farmers are already making the trip and have room.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
        AppSpacing.gapSm,
        for (final t in trips)
          Card(
            key: Key('board-${t.id}'),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: selected == t.id ? colors.primary : colors.border, width: selected == t.id ? 2 : 1)),
            child: ListTile(
              onTap: () => onSelected(selected == t.id ? null : t.id),
              leading: Icon(selected == t.id ? Icons.check_circle_rounded : Icons.route_outlined, color: colors.primary),
              title: Text('${t.partnerName ?? 'A farmer'} · ${formatDay(t.date)}'),
              subtitle: Text('${t.from.label} → ${t.to.label} · ${t.leftKg} kg room${t.ratingAvg == null ? '' : ' · ★ ${t.ratingAvg!.toStringAsFixed(1)}'}'),
            ),
          ),
      ]),
    );
  }
}
