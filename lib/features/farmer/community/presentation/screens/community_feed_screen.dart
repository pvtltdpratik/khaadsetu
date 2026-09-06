import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/tag_filter_row.dart';
import '../../../schemes/presentation/screens/schemes_list_view.dart';
import '../../domain/entities/forum_post.dart';
import '../providers/community_providers.dart';
import '../widgets/forum_post_card.dart';
import '../widgets/problem_type_style.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  int _section = 0; // 0 = Forum, 1 = Schemes
  String? _cropFilter;
  String? _districtFilter;
  ProblemType? _problemFilter;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScope(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Community', style: Theme.of(context).textTheme.titleLarge)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Forum'), icon: Icon(Icons.forum_outlined)),
                  ButtonSegment(value: 1, label: Text('Schemes'), icon: Icon(Icons.account_balance_outlined)),
                ],
                selected: {_section},
                onSelectionChanged: (s) => setState(() => _section = s.first),
              ),
            ),
            Expanded(
              child: _section == 0 ? _buildForum(context) : const SchemesListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForum(BuildContext context) {
    final postsAsync = ref.watch(forumPostsProvider);

    return postsAsync.when(
      data: (posts) {
        final crops = posts.map((p) => p.crop).toSet().toList()..sort();
        final districts = posts.map((p) => p.district).toSet().toList()..sort();
        final filtered = posts.where((p) {
          if (_cropFilter != null && p.crop != _cropFilter) return false;
          if (_districtFilter != null && p.district != _districtFilter) return false;
          if (_problemFilter != null && p.problemType != _problemFilter) return false;
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  TagFilterRow<String>(
                    label: 'Crop',
                    options: crops,
                    selected: _cropFilter,
                    labelBuilder: (c) => c,
                    onChanged: (c) => setState(() => _cropFilter = c),
                  ),
                  AppSpacing.gapSm,
                  TagFilterRow<String>(
                    label: 'District',
                    options: districts,
                    selected: _districtFilter,
                    labelBuilder: (d) => d,
                    onChanged: (d) => setState(() => _districtFilter = d),
                  ),
                  AppSpacing.gapSm,
                  TagFilterRow<ProblemType>(
                    label: 'Problem type',
                    options: ProblemType.values,
                    selected: _problemFilter,
                    labelBuilder: ProblemTypeStyle.labelFor,
                    onChanged: (p) => setState(() => _problemFilter = p),
                  ),
                ],
              ),
            ),
            AppSpacing.gapSm,
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No posts match these filters',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: context.pagePadding,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => AppSpacing.gapSm,
                      itemBuilder: (context, i) => ForumPostCard(
                        post: filtered[i],
                        onTap: () => context.push(RoutePaths.farmerCommunityPost(filtered[i].id)),
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => const AppLoadingIndicator(),
      error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(forumPostsProvider)),
    );
  }
}
