import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/gov_scheme.dart';
import '../providers/schemes_providers.dart';
import '../widgets/scheme_card.dart';

/// Embedded in [CommunityFeedScreen]'s "Schemes" segment — not routed to
/// directly, so it has no Scaffold/app bar of its own.
class SchemesListView extends ConsumerWidget {
  const SchemesListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemesAsync = ref.watch(schemesProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
        child: schemesAsync.when(
          data: (schemes) => ListView.separated(
            padding: context.pagePadding,
            itemCount: schemes.length,
            separatorBuilder: (_, _) => AppSpacing.gapSm,
            itemBuilder: (context, i) => _SchemeTile(
              scheme: schemes[i],
              onTap: () => context.push(RoutePaths.farmerCommunityScheme(schemes[i].id)),
            ),
          ),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(schemesProvider)),
        ),
      ),
    );
  }
}

class _SchemeTile extends ConsumerWidget {
  const _SchemeTile({required this.scheme, required this.onTap});

  final GovScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibleAsync = ref.watch(schemeEligibilityProvider(scheme));
    return SchemeCard(
      scheme: scheme,
      isEligible: eligibleAsync.whenOrNull(data: (e) => e) ?? false,
      onTap: onTap,
    );
  }
}
