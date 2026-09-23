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
import '../../domain/entities/community_post.dart';
import '../community_options.dart';
import '../providers/community_providers.dart';
import '../widgets/community_post_card.dart';
import '../widgets/problem_type_style.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  int _section = 0; // 0 = Forum, 1 = Schemes
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(communityFeedProvider.notifier).loadMore();
    }
  }

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
                  if (_section == 0)
                    FilledButton.icon(
                      onPressed: () => context.push(RoutePaths.farmerCommunityNewPost),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New post'),
                    ),
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
    final feedAsync = ref.watch(communityFeedProvider);
    final colors = context.colors;

    return feedAsync.when(
      data: (feed) {
        final isTabletUp = context.breakpoint.isTabletUp;

        return RefreshIndicator(
          onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            // Pull-to-refresh needs at least one always-scrollable physics,
            // even when there are too few posts to fill the viewport.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      TagFilterRow<String>(
                        label: 'Crop',
                        options: kCommunityCrops,
                        selected: feed.filters.crop,
                        labelBuilder: (c) => c,
                        onChanged: (c) => ref.read(communityFeedProvider.notifier).setFilters(
                              CommunityFilters(crop: c, district: feed.filters.district, problemType: feed.filters.problemType),
                            ),
                      ),
                      AppSpacing.gapSm,
                      TagFilterRow<String>(
                        label: 'District',
                        options: kCommunityDistricts,
                        selected: feed.filters.district,
                        labelBuilder: (d) => d,
                        onChanged: (d) => ref.read(communityFeedProvider.notifier).setFilters(
                              CommunityFilters(crop: feed.filters.crop, district: d, problemType: feed.filters.problemType),
                            ),
                      ),
                      AppSpacing.gapSm,
                      TagFilterRow<ProblemType>(
                        label: 'Problem type',
                        options: ProblemType.values,
                        selected: feed.filters.problemType,
                        labelBuilder: ProblemTypeStyle.labelFor,
                        onChanged: (p) => ref.read(communityFeedProvider.notifier).setFilters(
                              CommunityFilters(crop: feed.filters.crop, district: feed.filters.district, problemType: p),
                            ),
                      ),
                      AppSpacing.gapSm,
                    ],
                  ),
                ),
              ),
              if (feed.posts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined, size: 40, color: colors.textMuted),
                          AppSpacing.gapSm,
                          Text(
                            'No posts match these filters',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (isTabletUp)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: context.gridColumns,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 1.6,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => CommunityPostCard(post: feed.posts[i], onTap: () => context.push(RoutePaths.farmerCommunityPost(feed.posts[i].postId))),
                      childCount: feed.posts.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CommunityPostCard(post: feed.posts[i], onTap: () => context.push(RoutePaths.farmerCommunityPost(feed.posts[i].postId))),
                      ),
                      childCount: feed.posts.length,
                    ),
                  ),
                ),
              if (feed.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            ],
          ),
        );
      },
      loading: () => const AppLoadingIndicator(),
      error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(communityFeedProvider)),
    );
  }
}
