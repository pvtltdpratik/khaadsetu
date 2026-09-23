import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/post_comment.dart';
import '../providers/community_providers.dart';
import '../widgets/comment_input.dart';
import '../widgets/comment_tile.dart';
import '../widgets/problem_type_style.dart';

/// Post + comment thread. Stacked on mobile (one scroll, input pinned at the
/// bottom); on tablet/desktop the post sits on the left and the thread is a
/// side panel with its own scroll and input, so a long answer never pushes
/// the post out of view.
class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(postDetailProvider(postId));

    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: SafeArea(
          child: detailAsync.when(
            data: (detail) => _DetailBody(postId: postId, detail: detail),
            loading: () => const AppLoadingIndicator(),
            error: (err, _) => AppErrorView(
              message: '$err',
              onRetry: () => ref.invalidate(postDetailProvider(postId)),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.postId, required this.detail});

  final String postId;
  final PostDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(postDetailProvider(postId).notifier);
    final content = _PostContent(detail: detail, onToggleLike: notifier.toggleLike);
    final thread = _Thread(comments: detail.comments);
    final input = CommentInput(onSubmit: notifier.addComment);

    if (context.breakpoint.isTabletUp) {
      return ContentContainer(
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.lg), child: content),
            ),
            VerticalDivider(width: 1, color: context.colors.border),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.md), child: thread),
                  ),
                  input,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [content, AppSpacing.gapLg, thread],
            ),
          ),
        ),
        input,
      ],
    );
  }
}

class _PostContent extends StatefulWidget {
  const _PostContent({required this.detail, required this.onToggleLike});

  final PostDetail detail;
  final Future<void> Function() onToggleLike;

  @override
  State<_PostContent> createState() => _PostContentState();
}

class _PostContentState extends State<_PostContent> {
  bool _liking = false;

  Future<void> _like() async {
    if (_liking) return;
    setState(() => _liking = true);
    try {
      await widget.onToggleLike();
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final post = widget.detail.post;
    final liked = widget.detail.likedByMe;
    final typeColor = ProblemTypeStyle.colorFor(post.problemTypeTag, colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            Chip(
              avatar: Icon(ProblemTypeStyle.iconFor(post.problemTypeTag), size: 16, color: typeColor),
              label: Text(ProblemTypeStyle.labelFor(post.problemTypeTag)),
            ),
            if (post.cropTag.isNotEmpty) Chip(avatar: const Icon(Icons.grass_rounded, size: 16), label: Text(post.cropTag)),
            if (post.districtTag.isNotEmpty)
              Chip(avatar: const Icon(Icons.place_outlined, size: 16), label: Text(post.districtTag)),
          ],
        ),
        AppSpacing.gapSm,
        Text(post.title, style: text.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${post.farmerName} · ${formatAgo(post.createdAt)}',
          style: text.labelMedium?.copyWith(color: colors.textMuted),
        ),
        AppSpacing.gapMd,
        Text(post.content, style: text.bodyLarge),
        AppSpacing.gapMd,
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _liking ? null : _like,
              icon: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? colors.danger : null,
              ),
              label: Text('${post.likeCount}'),
            ),
            AppSpacing.gapMd,
            Icon(Icons.mode_comment_outlined, size: 18, color: colors.textMuted),
            const SizedBox(width: AppSpacing.xs),
            Text('${post.commentCount}', style: text.labelLarge?.copyWith(color: colors.textMuted)),
          ],
        ),
      ],
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({required this.comments});

  final List<PostComment> comments;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Answers & comments (${comments.length})', style: Theme.of(context).textTheme.titleMedium),
        AppSpacing.gapSm,
        if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text('No answers yet — be the first to reply.', style: TextStyle(color: colors.textMuted)),
          )
        else
          for (final c in comments)
            Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: CommentTile(comment: c)),
      ],
    );
  }
}
