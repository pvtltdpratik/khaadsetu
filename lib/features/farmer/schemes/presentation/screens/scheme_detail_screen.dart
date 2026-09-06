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
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = widget.scheme;
    final eligibleAsync = ref.watch(schemeEligibilityProvider(scheme));
    final applicationAsync = ref.watch(schemeApplicationProvider(scheme.id));
    final isEligible = eligibleAsync.whenOrNull(data: (e) => e) ?? false;

    return ListView(
      padding: context.pagePadding,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(RoutePaths.farmerCommunity),
            ),
            AppSpacing.gapSm,
            Expanded(child: Text('Scheme Details', style: Theme.of(context).textTheme.titleLarge)),
          ],
        ),
        AppSpacing.gapMd,
        Text(scheme.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(scheme.agency, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
        AppSpacing.gapSm,
        EligibilityBadge(isEligible: isEligible),
        AppSpacing.gapMd,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Benefit', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(scheme.benefit, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        AppSpacing.gapMd,
        Text(scheme.description, style: Theme.of(context).textTheme.bodyMedium),
        AppSpacing.gapLg,
        Text('Eligibility criteria', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        for (final criterion in scheme.eligibilityCriteria)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 6, color: colors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(criterion, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        if (scheme.applicationDeadline != null) ...[
          AppSpacing.gapSm,
          Row(
            children: [
              Icon(Icons.event_outlined, size: 16, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Apply before ${_formatDate(scheme.applicationDeadline!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ],
        AppSpacing.gapLg,
        Text('Application status', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        applicationAsync.when(
          data: (application) => _ApplicationSection(
            application: application,
            isEligible: isEligible,
            isApplying: _isApplying,
            onApply: _apply,
          ),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err'),
        ),
      ],
    );
  }
}

class _ApplicationSection extends StatelessWidget {
  const _ApplicationSection({
    required this.application,
    required this.isEligible,
    required this.isApplying,
    required this.onApply,
  });

  final SchemeApplication application;
  final bool isEligible;
  final bool isApplying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    if (application.status == ApplicationStatus.notApplied) {
      return AppButton(
        label: 'Apply now',
        icon: Icons.send_outlined,
        isLoading: isApplying,
        onPressed: isEligible ? onApply : null,
      );
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
