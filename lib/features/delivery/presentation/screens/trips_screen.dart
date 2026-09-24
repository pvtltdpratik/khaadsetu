import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animation/fade_slide_in.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../../domain/entities/delivery_models.dart';
import '../providers/delivery_providers.dart';
import '../widgets/place_picker_field.dart';

/// "I am going there on this day and have room." Farmers can book the room for a
/// load of their own, and orders along the same road are offered to me first.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  Future<void> _cancel(BuildContext context, WidgetRef ref, Trip trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this trip?'),
        content: Text(trip.bookings > 0 ? 'Farmers who booked room are told and their loads go back to other partners. If you already accepted one, hand it back first.' : 'Farmers will no longer see it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel trip')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(deliveryRepositoryProvider).cancelTrip(trip.id);
      ref.invalidate(myTripsProvider);
    } catch (err) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(myTripsProvider);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('My trips')),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('post-trip'),
          onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const _PostTripSheet()),
          icon: const Icon(Icons.add_road_rounded),
          label: const Text('Post a trip'),
        ),
        body: SafeArea(
          child: trips.when(
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myTripsProvider)),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, 96),
              children: [
                ContentContainer(
                  maxWidth: 720,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Going somewhere soon? Post your trip and the room you have. Farmers on your way can send a load with you, and you earn the delivery fee.', style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
                      AppSpacing.gapMd,
                      if (list.isEmpty)
                        Container(
                          key: const Key('no-trips'),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
                          child: const Text('No trips posted yet.'),
                        )
                      else
                        for (final (i, t) in list.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: FadeSlideIn(
                              index: i,
                              child: Container(
                                key: Key('trip-${t.id}'),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Icon(Icons.route_rounded, color: colors.primary),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(child: Text('${t.from.label.isEmpty ? 'Start' : t.from.label} → ${t.to.label.isEmpty ? 'End' : t.to.label}', style: text.titleSmall)),
                                    Text(formatDay(t.date), style: text.titleSmall),
                                  ]),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('${t.leftKg} of ${t.spareKg} kg left · ${t.bookings} booking${t.bookings == 1 ? '' : 's'}', style: text.bodyMedium),
                                  if (t.note.isNotEmpty) Text(t.note, style: text.bodySmall?.copyWith(color: colors.textMuted)),
                                  Align(alignment: Alignment.centerRight, child: TextButton(key: Key('cancel-${t.id}'), onPressed: () => _cancel(context, ref, t), child: Text('Cancel trip', style: TextStyle(color: colors.danger)))),
                                ]),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostTripSheet extends ConsumerStatefulWidget {
  const _PostTripSheet();

  @override
  ConsumerState<_PostTripSheet> createState() => _PostTripSheetState();
}

class _PostTripSheetState extends ConsumerState<_PostTripSheet> {
  GeoPoint? _from;
  GeoPoint? _to;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  final _spare = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _spare.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _spare.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: today, lastDate: today.add(const Duration(days: 14)));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _post() async {
    setState(() => _busy = true);
    try {
      await ref.read(deliveryRepositoryProvider).postTrip(from: _from!, to: _to!, date: _date, spareKg: int.parse(_spare.text.trim()), note: _note.text.trim());
      ref.invalidate(myTripsProvider);
      if (mounted) Navigator.pop(context);
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spare = int.tryParse(_spare.text.trim());
    final ready = _from != null && _to != null && spare != null && spare > 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Post a trip', style: Theme.of(context).textTheme.titleLarge),
            AppSpacing.gapMd,
            PlacePickerField(key: const Key('trip-from'), label: 'Going from', icon: Icons.trip_origin_rounded, value: _from, onChanged: (p) => setState(() => _from = p)),
            AppSpacing.gapSm,
            PlacePickerField(key: const Key('trip-to'), label: 'Going to', value: _to, onChanged: (p) => setState(() => _to = p)),
            AppSpacing.gapSm,
            OutlinedButton.icon(key: const Key('trip-date'), onPressed: _pickDate, icon: const Icon(Icons.event_rounded), label: Text('On ${formatDay(_date)}')),
            AppSpacing.gapSm,
            TextField(key: const Key('trip-spare'), controller: _spare, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Room to spare (kg)')),
            AppSpacing.gapSm,
            TextField(key: const Key('trip-note'), controller: _note, maxLength: 300, decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'Going to the market, back by evening')),
            AppSpacing.gapSm,
            FilledButton(key: const Key('trip-submit'), onPressed: ready && !_busy ? _post : null, child: Text(_busy ? 'Posting…' : 'Post trip')),
          ],
        ),
      ),
    );
  }
}
