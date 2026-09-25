import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animation/animated_count.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/review_models.dart';
import '../review_providers.dart';

/// The reviews on a product page: a summary worked out from real harvests, filters to find farmers like you, and one
/// structured card per farmer. Nothing here is written by hand.
class AgronomicReviewsSection extends ConsumerStatefulWidget {
  const AgronomicReviewsSection({super.key, required this.productId, required this.productName});

  final String productId;
  final String productName;

  @override
  ConsumerState<AgronomicReviewsSection> createState() => _AgronomicReviewsSectionState();
}

class _AgronomicReviewsSectionState extends ConsumerState<AgronomicReviewsSection> {
  ReviewFilter _filter = const ReviewFilter();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final result = ref.watch(productReviewsProvider((productId: widget.productId, filter: _filter)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('What farmers found', style: text.titleMedium),
      Text('Real results from farmers who bought this here, on their own farms.', style: text.bodySmall?.copyWith(color: colors.textMuted)),
      AppSpacing.gapSm,
      result.when(
        loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: AppLoadingIndicator()),
        error: (err, _) => Text('Could not load the reviews: $err', style: text.bodySmall?.copyWith(color: colors.danger)),
        data: (data) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (data.summary.count == 0 && _filter.isEmpty)
            Container(
              key: const Key('no-agronomic-reviews'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text('No harvest results yet. Be the first: log how you use it, and other farmers with your soil and crop will see what happened.', style: text.bodyMedium),
            )
          else ...[
            _SummaryCard(summary: data.summary),
            AppSpacing.gapSm,
            _Filters(filter: _filter, onChanged: (f) => setState(() => _filter = f)),
            AppSpacing.gapSm,
            Text('${data.matching} review${data.matching == 1 ? '' : 's'}${_filter.isEmpty ? '' : ' match your filters'}', key: const Key('matching-count'), style: text.labelMedium?.copyWith(color: colors.textMuted)),
            AppSpacing.gapXs,
            if (data.reviews.isEmpty)
              Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Center(child: Text('No farmer like that has logged a harvest yet.', style: text.bodyMedium?.copyWith(color: colors.textMuted))))
            else
              for (final r in data.reviews) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: ReviewOutcomeCard(card: r)),
          ],
        ]),
      ),
      AppSpacing.gapSm,
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
        FilledButton.icon(key: const Key('log-my-use'), onPressed: () => context.push(RoutePaths.farmerLogFertilizer(widget.productId)), icon: const Icon(Icons.edit_note_rounded), label: const Text('Log how I use it')),
        OutlinedButton.icon(key: const Key('predict-yield'), onPressed: () => context.push(RoutePaths.farmerYieldPredict(widget.productId)), icon: const Icon(Icons.trending_up_rounded), label: const Text('Predict my yield')),
        OutlinedButton.icon(key: const Key('profit-calc'), onPressed: () => context.push(RoutePaths.farmerCalculatorFor(widget.productId)), icon: const Icon(Icons.calculate_outlined), label: const Text('Will it pay?')),
      ]),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final gain = summary.improvementAvg;
    return Container(
      key: const Key('review-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(summary.overall == null ? '—' : summary.overall!.toStringAsFixed(1), key: const Key('overall'), style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text(' / 5', style: text.titleMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('from ${summary.count} harvest${summary.count == 1 ? '' : 's'}', style: text.bodyMedium)),
        ]),
        if (gain != null) ...[
          AppSpacing.gapSm,
          Row(children: [
            Icon(gain >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: gain >= 0 ? colors.success : colors.danger),
            const SizedBox(width: AppSpacing.xs),
            Text('Average yield ', style: text.bodyMedium),
            AnimatedCount(key: const Key('avg-gain'), value: gain, format: (v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%', style: text.titleMedium?.copyWith(color: gain >= 0 ? colors.success : colors.danger, fontWeight: FontWeight.w800)),
          ]),
        ],
        if (summary.bestLine != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('Best results on: ${summary.bestLine}', key: const Key('best-line'), style: text.bodySmall)),
        if (summary.topRatedFor.isNotEmpty) ...[
          AppSpacing.gapSm,
          Text('Top rated for', style: text.labelMedium),
          for (final t in summary.topRatedFor) Row(children: [Icon(Icons.check_circle_rounded, size: 16, color: colors.success), const SizedBox(width: 6), Expanded(child: Text(t, style: text.bodyMedium))]),
        ],
        if (summary.watchOutFor.isNotEmpty) ...[
          AppSpacing.gapSm,
          Text('Watch out for', style: text.labelMedium),
          for (final w in summary.watchOutFor) Row(children: [Icon(Icons.warning_amber_rounded, size: 16, color: colors.warning), const SizedBox(width: 6), Expanded(child: Text(w, style: text.bodyMedium))]),
        ],
      ]),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.filter, required this.onChanged});

  final ReviewFilter filter;
  final ValueChanged<ReviewFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String key, String label, bool on, VoidCallback tap) => Padding(padding: const EdgeInsets.only(right: AppSpacing.sm), child: FilterChip(key: Key(key), label: Text(label), selected: on, onSelected: (_) => tap()));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        chip('filter-improved', 'Yield improved', filter.improved, () => onChanged(filter.copyWith(improved: !filter.improved))),
        for (final s in soilChoices.take(4)) chip('filter-soil-${s.api}', '${s.label} soil', filter.soil == s.api, () => onChanged(filter.copyWith(soil: filter.soil == s.api ? null : s.api))),
        for (final s in const [('kharif', 'Kharif'), ('rabi', 'Rabi')]) chip('filter-season-${s.$1}', s.$2, filter.season == s.$1, () => onChanged(filter.copyWith(season: filter.season == s.$1 ? null : s.$1))),
        for (final s in const [('small', 'Under 2 acres'), ('medium', '2 to 5 acres'), ('large', 'Over 5 acres')]) chip('filter-size-${s.$1}', s.$2, filter.size == s.$1, () => onChanged(filter.copyWith(size: filter.size == s.$1 ? null : s.$1))),
      ]),
    );
  }
}

/// One farmer's case study: their farm, what they applied, and what came of it.
class ReviewOutcomeCard extends StatelessWidget {
  const ReviewOutcomeCard({super.key, required this.card});

  final ReviewCard card;

  static String _yield(double? v) => v == null ? '—' : v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final c = card;
    final gain = c.improvementPct;
    Widget line(IconData icon, String value) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 15, color: colors.textMuted), const SizedBox(width: 6), Expanded(child: Text(value, style: text.bodySmall))]));
    return Container(
      key: Key('outcome-${c.reviewId}'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surface, border: Border.all(color: c.featured ? colors.warning : colors.border, width: c.featured ? 2 : 1), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(c.farmer, style: text.titleSmall)),
          if (c.featured) Icon(Icons.emoji_events_rounded, color: colors.warning, size: 20),
        ]),
        const SizedBox(height: AppSpacing.xs),
        line(Icons.grass_rounded, 'Crop: ${c.crop}${c.variety.isEmpty ? '' : ' (${c.variety})'}  ·  Soil: ${labelOf(soilChoices, c.soilType)}'),
        line(Icons.square_foot_rounded, 'Farm: ${c.acres.toStringAsFixed(c.acres == c.acres.roundToDouble() ? 0 : 1)} acres  ·  ${labelOf(irrigationChoices, c.irrigation)}'),
        line(Icons.calendar_month_outlined, 'Season: ${c.season.split('-').first[0].toUpperCase()}${c.season.split('-').first.substring(1)} ${c.season.split('-').last}'),
        if (c.npkBefore != null) line(Icons.science_outlined, 'Before: ${c.npkBefore}${c.scoreBefore == null ? '' : '  ·  soil score ${c.scoreBefore}/100'}'),
        line(Icons.agriculture_outlined, 'Applied: ${_yield(c.qtyPerAcre)} ${c.unit.isEmpty ? '' : c.unit} per acre at ${labelOf(stageChoices, c.growthStage).toLowerCase()} stage, ${labelOf(methodChoices, c.method).toLowerCase()}'),
        if (c.yieldQpa != null) ...[
          const Divider(height: AppSpacing.md),
          Row(children: [
            Text('${_yield(c.yieldQpa)} q/acre', key: Key('yield-${c.reviewId}'), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: AppSpacing.sm),
            if (gain != null) Text('${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(1)}%', key: Key('gain-${c.reviewId}'), style: text.titleSmall?.copyWith(color: gain >= 0 ? colors.success : colors.danger)),
          ]),
          Text([if (c.lastSeasonQpa != null) 'Last season ${_yield(c.lastSeasonQpa)}', if (c.districtAvgQpa != null) 'District average ${_yield(c.districtAvgQpa)}', if (c.scoreAfter != null) 'Soil score after ${c.scoreAfter}/100'].join('  ·  '), style: text.bodySmall?.copyWith(color: colors.textMuted)),
        ],
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          for (var i = 1; i <= 5; i++) Icon(i <= c.starsOverall ? Icons.star_rounded : Icons.star_outline_rounded, size: 18, color: colors.warning),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text('${c.starsValue == null ? '' : 'Value ${c.starsValue}/5  '}${c.starsEase == null ? '' : 'Ease ${c.starsEase}/5  '}${c.useAgain == 'yes' ? 'Would use again' : c.useAgain == 'no' ? 'Would not use again' : c.useAgain == 'maybe' ? 'Might use again' : ''}', style: text.labelSmall)),
        ]),
        if (c.comment.isNotEmpty) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(c.comment, style: text.bodyMedium)),
        if (c.hasMidPhoto || c.hasHarvestPhoto) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Row(children: [Icon(Icons.photo_camera_outlined, size: 15, color: colors.textMuted), const SizedBox(width: 6), Text('Has ${[if (c.hasMidPhoto) 'crop', if (c.hasHarvestPhoto) 'harvest'].join(' and ')} photo', style: text.labelSmall?.copyWith(color: colors.textMuted))])),
        const SizedBox(height: AppSpacing.xs),
        Wrap(spacing: AppSpacing.sm, children: [
          _Badge(icon: Icons.verified_rounded, label: 'Verified Purchase', color: colors.success),
          if (c.agronomistReviewed) _Badge(icon: Icons.school_rounded, label: 'Agronomist Reviewed', color: colors.info),
        ]),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: color), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700))]),
      );
}
