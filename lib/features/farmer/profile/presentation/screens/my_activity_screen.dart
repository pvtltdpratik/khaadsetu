import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../centers/presentation/widgets/contact_actions.dart';
import '../../domain/profile_models.dart';
import '../providers/profile_providers.dart';

/// The farmer's own community posts and the replies they wrote on other people's posts.
class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(myActivityProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My community activity'),
          bottom: TabBar(tabs: [
            Tab(text: 'Posts (${activity.value?.posts.length ?? 0})'),
            Tab(text: 'Replies (${activity.value?.replies.length ?? 0})'),
          ]),
        ),
        body: activity.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(myActivityProvider)),
          data: (data) => TabBarView(children: [_Posts(posts: data.posts), _Replies(replies: data.replies)]),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: colors.textMuted),
          AppSpacing.gapSm,
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
        ]),
      ),
    );
  }
}

class _Posts extends StatelessWidget {
  const _Posts({required this.posts});

  final List<ActivityPost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const _Empty(icon: Icons.edit_note_outlined, message: 'You have not asked anything yet. Ask the community about your crop.');
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: posts.length,
      separatorBuilder: (_, _) => AppSpacing.gapSm,
      itemBuilder: (context, i) {
        final p = posts[i];
        return Card(
          child: ListTile(
            onTap: () => context.push(RoutePaths.farmerCommunityPost(p.postId)),
            title: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('${p.commentCount} answers  ·  ${p.likeCount} likes  ·  ${formatDay(p.createdAt)}', style: text.bodySmall?.copyWith(color: colors.textMuted)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }
}

class _Replies extends StatelessWidget {
  const _Replies({required this.replies});

  final List<ActivityReply> replies;

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const _Empty(icon: Icons.chat_bubble_outline, message: 'You have not replied to anyone yet. Your replies help other farmers.');
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: replies.length,
      separatorBuilder: (_, _) => AppSpacing.gapSm,
      itemBuilder: (context, i) {
        final r = replies[i];
        return Card(
          child: InkWell(
            onTap: () => context.push(RoutePaths.farmerCommunityPost(r.postId)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('On: ${r.postTitle}', style: text.labelMedium?.copyWith(color: colors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Text(r.content, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(formatDay(r.createdAt), style: text.bodySmall?.copyWith(color: colors.textMuted)),
              ]),
            ),
          ),
        );
      },
    );
  }
}
