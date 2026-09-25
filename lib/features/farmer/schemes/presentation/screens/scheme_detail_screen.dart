import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/gov_scheme.dart';
import '../../domain/entities/scheme_application.dart';
import '../../domain/entities/scheme_eligibility_result.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/schemes_providers.dart';
import '../widgets/application_status_badge.dart';
import '../widgets/eligibility_badge.dart';

class SchemeDetailScreen extends ConsumerWidget {
  const SchemeDetailScreen({super.key, required this.schemeId});

  final String schemeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemeAsync = ref.watch(schemeProvider(schemeId));

    return ResponsiveScope(
      child: SafeArea(
        child: schemeAsync.when(
          data: (scheme) => _SchemeBody(scheme: scheme),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(
            message: '$err',
            onRetry: () => ref.invalidate(schemeProvider(schemeId)),
          ),
        ),
      ),
    );
  }
}

class _SchemeBody extends ConsumerStatefulWidget {
  const _SchemeBody({required this.scheme});

  final GovScheme scheme;

  @override
  ConsumerState<_SchemeBody> createState() => _SchemeBodyState();
}

class _SchemeBodyState extends ConsumerState<_SchemeBody> {
  bool _isApplying = false;

  Future<void> _apply() async {
    setState(() => _isApplying = true);
    try {
      await ref.read(schemesRepositoryProvider).applyToScheme(widget.scheme.id);
      ref.invalidate(schemeApplicationProvider(widget.scheme.id));
      ref.invalidate(farmerProfileProvider); // applying adds a notification
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  /// Opens the profile questions; when the farmer comes back, their answers are re-checked.
  Future<void> _answerQuestions() async {
    await context.push(RoutePaths.farmerProfileFarm);
    ref.invalidate(schemeEligibilityProvider(widget.scheme.id));
    ref.invalidate(eligibilitySummaryProvider);
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final scheme = widget.scheme;
    final eligibility = ref.watch(schemeEligibilityProvider(scheme.id));
    final applicationAsync = ref.watch(schemeApplicationProvider(scheme.id));
    final status = eligibility.value?.status;

    return ListView(
      padding: context.pagePadding,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.canPop() ? context.pop() : context.go(RoutePaths.farmerCommunity),
            ),
            AppSpacing.gapSm,
            Expanded(child: Text('Scheme Details', style: text.titleLarge)),
          ],
        ),
        AppSpacing.gapMd,
        Text(scheme.name, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(scheme.agency, style: text.bodyMedium?.copyWith(color: colors.textMuted)),
        AppSpacing.gapSm,
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (status != null && scheme.isForFarmers) EligibilityBadge(status: status),
          Text('${scheme.level == 'state' ? 'Maharashtra' : 'Central'} scheme  ·  ${scheme.sector}', style: text.labelMedium?.copyWith(color: colors.textMuted)),
        ]),
        AppSpacing.gapMd,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Benefit', style: text.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(scheme.benefit, style: text.titleMedium),
            ],
          ),
        ),
        AppSpacing.gapMd,
        Text(scheme.description, style: text.bodyMedium),
        if (scheme.isForFarmers) ...[
          AppSpacing.gapLg,
          _EligibilitySection(result: eligibility, onAnswer: _answerQuestions),
        ],
        AppSpacing.gapLg,
        Text('Who can get it', style: text.titleMedium),
        AppSpacing.gapSm,
        for (final criterion in scheme.eligibilityCriteria)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: colors.textMuted)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(criterion, style: text.bodyMedium)),
              ],
            ),
          ),
        if (scheme.components.isNotEmpty) ...[
          AppSpacing.gapLg,
          Text('What you can get', style: text.titleMedium),
          AppSpacing.gapSm,
          Container(
            key: const Key('components'),
            decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(children: [
              for (var i = 0; i < scheme.components.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.divider),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(scheme.components[i].title, style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(scheme.components[i].assistance, style: text.titleSmall),
                  ]),
                ),
              ],
            ]),
          ),
        ],
        if (scheme.howToApply.isNotEmpty || scheme.contact.isNotEmpty || scheme.website.isNotEmpty) ...[
          AppSpacing.gapLg,
          Text('How to apply', style: text.titleMedium),
          AppSpacing.gapSm,
          if (scheme.howToApply.isNotEmpty) Text(scheme.howToApply, style: text.bodyMedium),
          if (scheme.contact.isNotEmpty) ...[AppSpacing.gapSm, _Line(icon: Icons.support_agent_outlined, text: scheme.contact)],
          if (scheme.website.isNotEmpty) ...[AppSpacing.gapXs, _Line(icon: Icons.language_outlined, text: scheme.website)],
        ],
        if (scheme.applicationDeadline != null) ...[
          AppSpacing.gapSm,
          Row(
            children: [
              Icon(Icons.event_outlined, size: 16, color: colors.textMuted),
              const SizedBox(width: 4),
              Text('Apply before ${_formatDate(scheme.applicationDeadline!)}', style: text.bodyMedium?.copyWith(color: colors.textMuted)),
            ],
          ),
        ],
        if (scheme.isForFarmers) ...[
          AppSpacing.gapLg,
          Text('Application status', style: text.titleMedium),
          AppSpacing.gapSm,
          applicationAsync.when(
            data: (application) => _ApplicationSection(
              application: application,
              canApply: status != EligibilityStatus.notEligible,
              isApplying: _isApplying,
              onApply: _apply,
            ),
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(message: '$err'),
          ),
        ],
        AppSpacing.gapLg,
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: context.colors.textMuted),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: SelectableText(text, style: Theme.of(context).textTheme.bodyMedium)),
    ]);
  }
}

/// Each rule checked against the farmer's saved answers: met, not met, or "tell us".
class _EligibilitySection extends StatelessWidget {
  const _EligibilitySection({required this.result, required this.onAnswer});

  final AsyncValue<SchemeEligibilityResult> result;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return result.when(
      loading: () => const SizedBox(height: 80, child: AppLoadingIndicator()),
      error: (err, _) => Text('Could not check your eligibility: $err', style: text.bodySmall?.copyWith(color: colors.danger)),
      data: (r) {
        if (r.checks.isEmpty) return const SizedBox.shrink();
        final unknown = r.checks.where((c) => c.status == CheckStatus.unknown).length;
        return Container(
          key: const Key('eligibility-section'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.surface, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your eligibility', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              r.total == 0 ? 'Nothing here can be checked from your profile.' : 'You meet ${r.met} of ${r.total} conditions we can check from your profile.',
              key: const Key('eligibility-summary'),
              style: text.bodySmall?.copyWith(color: colors.textMuted),
            ),
            AppSpacing.gapSm,
            for (final c in r.checks)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _icon(c.status, colors),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      c.status == CheckStatus.unknown ? '${c.label} (tell us)' : c.label,
                      style: text.bodyMedium?.copyWith(color: c.status == CheckStatus.notMet ? colors.danger : null),
                    ),
                  ),
                ]),
              ),
            if (unknown > 0) ...[
              AppSpacing.gapSm,
              AppButton(
                key: const Key('answer-questions'),
                label: 'Answer $unknown question${unknown == 1 ? '' : 's'} to be sure',
                variant: AppButtonVariant.outlined,
                icon: Icons.fact_check_outlined,
                expand: true,
                onPressed: onAnswer,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Saved on your profile, so you never answer twice.', style: text.labelSmall?.copyWith(color: colors.textMuted)),
            ],
          ]),
        );
      },
    );
  }

  Widget _icon(CheckStatus s, AppColorTokens colors) => switch (s) {
        CheckStatus.met => Icon(Icons.check_circle_rounded, size: 18, color: colors.success),
        CheckStatus.notMet => Icon(Icons.cancel_rounded, size: 18, color: colors.danger),
        CheckStatus.unknown => Icon(Icons.help_outline_rounded, size: 18, color: colors.warning),
        CheckStatus.info => Icon(Icons.info_outline_rounded, size: 18, color: colors.textMuted),
      };
}

class _ApplicationSection extends StatelessWidget {
  const _ApplicationSection({
    required this.application,
    required this.canApply,
    required this.isApplying,
    required this.onApply,
  });

  final SchemeApplication application;
  final bool canApply;
  final bool isApplying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    if (application.status == ApplicationStatus.notApplied) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppButton(
          key: const Key('apply-now'),
          label: 'Apply now',
          icon: Icons.send_outlined,
          isLoading: isApplying,
          onPressed: canApply ? onApply : null,
        ),
        if (!canApply)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('Your saved answers do not meet this scheme.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.danger)),
          ),
      ]);
    }
    return Row(
      children: [
        ApplicationStatusBadge(status: application.status),
        if (application.appliedDate != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Applied on ${application.appliedDate!.day}/${application.appliedDate!.month}/${application.appliedDate!.year}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.textMuted),
          ),
        ],
      ],
    );
  }
}
