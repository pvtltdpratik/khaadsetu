import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_eligibility_result.dart';
import '../providers/schemes_providers.dart';
import '../widgets/scheme_card.dart';

/// The scheme directory: search, a sector filter, and "for me" (only the ones the farmer's saved
/// answers do not rule out). Embedded in the community tab and shown full screen from the
/// profile tab, so it has no Scaffold of its own.
class SchemesListView extends ConsumerStatefulWidget {
  const SchemesListView({super.key});

  @override
  ConsumerState<SchemesListView> createState() => _SchemesListViewState();
}

class _SchemesListViewState extends ConsumerState<SchemesListView> {
  final _search = TextEditingController();
  String _query = '';
  String? _sector;
  bool _forMe = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<GovScheme> _filtered(List<GovScheme> all, Map<String, SchemeEligibilityResult> eligibility) {
    final q = _query.trim().toLowerCase();
    return all.where((s) {
      if (_sector != null && s.sector != _sector) return false;
      if (q.isNotEmpty && !('${s.name} ${s.description} ${s.sector} ${s.benefit}'.toLowerCase().contains(q))) return false;
      if (_forMe) {
        if (!s.isForFarmers) return false;
        final e = eligibility[s.id];
        if (e != null && e.status == EligibilityStatus.notEligible) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final schemesAsync = ref.watch(schemesProvider);
    final eligibility = ref.watch(eligibilitySummaryProvider).value ?? const <String, SchemeEligibilityResult>{};
    final colors = context.colors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
        child: schemesAsync.when(
          data: (all) {
            final sectors = <String>{for (final s in all) s.sector}.toList()..sort();
            final shown = _filtered(all, eligibility);
            final eligibleCount = all.where((s) => s.isForFarmers && eligibility[s.id]?.status == EligibilityStatus.eligible).length;
            final askCount = all.where((s) => s.isForFarmers && eligibility[s.id]?.status == EligibilityStatus.possible).length;
            return ListView(
              padding: context.pagePadding,
              children: [
                TextField(
                  key: const Key('scheme-search'),
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search schemes: insurance, seeds, drip…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() { _search.clear(); _query = ''; })),
                  ),
                ),
                AppSpacing.gapSm,
                if (eligibility.isNotEmpty)
                  Container(
                    key: const Key('eligibility-banner'),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Row(children: [
                      Icon(Icons.verified_outlined, color: colors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          askCount == 0
                              ? 'You are eligible for $eligibleCount scheme${eligibleCount == 1 ? '' : 's'}.'
                              : 'Eligible for $eligibleCount. $askCount more could fit: answer a few questions once and we check them all.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton(onPressed: () => context.push(RoutePaths.farmerProfileFarm), child: Text(askCount == 0 ? 'Update' : 'Answer')),
                    ]),
                  ),
                AppSpacing.gapSm,
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    FilterChip(key: const Key('for-me'), label: const Text('For me'), selected: _forMe, onSelected: (v) => setState(() => _forMe = v)),
                    const SizedBox(width: AppSpacing.sm),
                    ChoiceChip(label: const Text('All'), selected: _sector == null, onSelected: (_) => setState(() => _sector = null)),
                    for (final s in sectors) ...[
                      const SizedBox(width: AppSpacing.sm),
                      ChoiceChip(key: Key('sector-$s'), label: Text(s), selected: _sector == s, onSelected: (_) => setState(() => _sector = _sector == s ? null : s)),
                    ],
                  ]),
                ),
                AppSpacing.gapSm,
                Text('${shown.length} scheme${shown.length == 1 ? '' : 's'}', key: const Key('scheme-count'), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.textMuted)),
                AppSpacing.gapSm,
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: Text('No schemes match', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted))),
                  ),
                for (var i = 0; i < shown.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: FadeSlideIn(
                      index: i,
                      child: SchemeCard(
                        scheme: shown[i],
                        eligibility: eligibility[shown[i].id],
                        onTap: () => context.push(RoutePaths.farmerCommunityScheme(shown[i].id)),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(schemesProvider)),
        ),
      ),
    );
  }
}

/// The directory on a page of its own, for the profile tab.
class SchemesScreen extends StatelessWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Government schemes')), body: const SchemesListView());
}
