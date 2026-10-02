import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/animation/pressable.dart';
import '../../../../../core/l10n/app_locale.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/nearby_center.dart';
import '../providers/centers_providers.dart';
import '../widgets/center_card.dart';

/// Finds where the farmer is — nearby real places from GPS, or search by name — then shows the village
/// centers right there, so choosing a location and seeing what serves it is one screen, not two.
class VillagePickerScreen extends ConsumerStatefulWidget {
  const VillagePickerScreen({super.key});

  @override
  ConsumerState<VillagePickerScreen> createState() => _VillagePickerScreenState();
}

class _VillagePickerScreenState extends ConsumerState<VillagePickerScreen> {
  String _query = '';
  Timer? _debounce;
  late Future<List<Village>> _results = _search('');
  late final Future<List<Village>> _nearby = _loadNearby();
  Village? _chosen;
  Future<NearbyResult>? _centers;

  Future<List<Village>> _search(String q) => ref.read(centersRepositoryProvider).villages(q.trim());

  Future<List<Village>> _loadNearby() async {
    try {
      final here = await ref.read(deviceLocationProvider).current();
      return ref.read(centersRepositoryProvider).nearbyVillages(latitude: here.latitude, longitude: here.longitude);
    } catch (_) {
      return const []; // no GPS: the farmer just searches instead
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _results = _search(value);
      });
    });
  }

  Future<void> _pick(Village village) async {
    await ref.read(farmerLocationProvider.notifier).chooseVillage(village);
    if (!mounted) return;
    setState(() {
      _chosen = village;
      _centers = ref.read(centersRepositoryProvider).nearby(location: FarmerLocation(latitude: village.latitude, longitude: village.longitude, source: LocationSource.village, label: village.name));
    });
  }

  void _changeVillage() => setState(() {
        _chosen = null;
        _centers = null;
      });

  @override
  Widget build(BuildContext context) {
    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_chosen == null ? context.t('Choose your village') : _chosen!.display),
          actions: [if (_chosen != null) TextButton(key: const Key('village-done'), onPressed: () => context.pop(), child: Text(context.t('Done')))],
        ),
        body: SafeArea(
          child: ContentContainer(
            maxWidth: 600,
            child: _chosen != null
                ? _CentersNearChosen(village: _chosen!, centers: _centers!, onChangeVillage: _changeVillage)
                : _PickerBody(
                    query: _query,
                    results: _results,
                    nearby: _nearby,
                    onChanged: _onChanged,
                    onRetry: () => setState(() => _results = _search(_query)),
                    onPick: _pick,
                  ),
          ),
        ),
      ),
    );
  }
}

class _PickerBody extends StatelessWidget {
  const _PickerBody({required this.query, required this.results, required this.nearby, required this.onChanged, required this.onRetry, required this.onPick});

  final String query;
  final Future<List<Village>> results;
  final Future<List<Village>> nearby;
  final ValueChanged<String> onChanged;
  final VoidCallback onRetry;
  final ValueChanged<Village> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('village-search'),
          autofocus: false,
          onChanged: onChanged,
          decoration: InputDecoration(hintText: context.t('Search your village or district'), prefixIcon: const Icon(Icons.search_rounded), isDense: true),
        ),
        AppSpacing.gapMd,
        Expanded(
          child: query.trim().isEmpty
              ? FutureBuilder<List<Village>>(
                  future: nearby,
                  builder: (context, snapshot) {
                    final here = snapshot.data ?? const [];
                    if (snapshot.connectionState == ConnectionState.waiting || here.isEmpty) {
                      return FutureBuilder<List<Village>>(future: results, builder: (context, s) => _List(snapshot: s, query: query, onRetry: onRetry, onPick: onPick));
                    }
                    return _VillageList(key: const Key('village-nearby-list'), title: 'Near you', villages: here, onPick: onPick);
                  },
                )
              : FutureBuilder<List<Village>>(future: results, builder: (context, s) => _List(snapshot: s, query: query, onRetry: onRetry, onPick: onPick)),
        ),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.snapshot, required this.query, required this.onRetry, required this.onPick});

  final AsyncSnapshot<List<Village>> snapshot;
  final String query;
  final VoidCallback onRetry;
  final ValueChanged<Village> onPick;

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState != ConnectionState.done) return const AppLoadingIndicator();
    if (snapshot.hasError) return AppErrorView(message: '${snapshot.error}', onRetry: onRetry);
    final villages = snapshot.data!;
    if (villages.isEmpty) {
      return Center(child: Text('${context.t('No village matches')} "$query".', style: TextStyle(color: context.colors.textMuted)));
    }
    return _VillageList(villages: villages, onPick: onPick);
  }
}

class _VillageList extends StatelessWidget {
  const _VillageList({super.key, this.title, required this.villages, required this.onPick});

  final String? title;
  final List<Village> villages;
  final ValueChanged<Village> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (title != null) Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Text(context.t(title!), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.textMuted))),
        for (final (i, v) in villages.indexed) ...[
          FadeSlideIn(
            index: i,
            child: Pressable(
              child: ListTile(leading: const Icon(Icons.place_outlined), title: Text(v.name), subtitle: Text(v.district), onTap: () => onPick(v)),
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

/// Shown right after a village is chosen: the centers that serve it, with a way to pick a different village.
class _CentersNearChosen extends StatelessWidget {
  const _CentersNearChosen({required this.village, required this.centers, required this.onChangeVillage});

  final Village village;
  final Future<NearbyResult> centers;
  final VoidCallback onChangeVillage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      children: [
        Row(children: [
          Expanded(child: Text('${context.t('Village centers near')} ${village.display}', style: Theme.of(context).textTheme.titleMedium)),
          TextButton(key: const Key('village-change'), onPressed: onChangeVillage, child: Text(context.t('Change'))),
        ]),
        AppSpacing.gapSm,
        FutureBuilder<NearbyResult>(
          future: centers,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: AppLoadingIndicator());
            if (snapshot.hasError) return AppErrorView(message: '${snapshot.error}', onRetry: onChangeVillage);
            final list = snapshot.data!.centers;
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(child: Text('${context.t('No village centers near')} ${village.display} ${context.t('yet.')}', textAlign: TextAlign.center, style: TextStyle(color: colors.textMuted))),
              );
            }
            return Column(children: [
              for (final (i, n) in list.indexed)
                Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: FadeSlideIn(index: i, child: CenterCard(nearby: n))),
            ]);
          },
        ),
      ],
    );
  }
}
