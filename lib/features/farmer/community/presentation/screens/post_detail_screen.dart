import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/forum_post.dart';
import '../providers/community_providers.dart';
import '../widgets/forum_reply_card.dart';
import '../widgets/problem_type_style.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(forumPostProvider(postId));

    return ResponsiveScope(
      child: SafeArea(
        child: postAsync.when(
          data: (post) => _PostBody(post: post),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(
            message: '$err',
            onRetry: () => ref.invalidate(forumPostProvider(postId)),
          ),
        ),
      ),
    );
  }
}

class _PostBody extends ConsumerWidget {
  const _PostBody({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final repliesAsync = ref.watch(forumRepliesProvider(post.id));
    final typeColor = ProblemTypeStyle.colorFor(post.problemType, colors);

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
            Expanded(child: Text('Post', style: Theme.of(context).textTheme.titleLarge)),
          ],
        ),
        AppSpacing.gapMd,
        Row(
          children: [
            Icon(ProblemTypeStyle.iconFor(post.problemType), size: 16, color: typeColor),
            const SizedBox(width: 4),
            Text(
              ProblemTypeStyle.labelFor(post.problemType),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: typeColor),
            ),
            const Spacer(),
            Text(
              '${post.crop} · ${post.district}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
        AppSpacing.gapSm,
        Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'by ${post.authorName}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
        AppSpacing.gapMd,
        Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
        AppSpacing.gapMd,
        Row(
          children: [
            Icon(Icons.favorite_border_rounded, size: 16, color: colors.textMuted),
            const SizedBox(width: 4),
            Text('${post.likeCount} likes', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
          ],
        ),
        AppSpacing.gapLg,
        Text('Replies (${post.replyCount})', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        repliesAsync.when(
          data: (replies) => Column(
            children: [
              for (final reply in replies) ...[
                ForumReplyCard(reply: reply),
                AppSpacing.gapSm,
              ],
            ],
          ),
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err'),
        ),
      ],
    );
  }
}
