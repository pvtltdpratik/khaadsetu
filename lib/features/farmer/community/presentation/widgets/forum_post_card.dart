import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/forum_post.dart';
import 'problem_type_style.dart';

class ForumPostCard extends StatelessWidget {
  const ForumPostCard({super.key, required this.post, required this.onTap});

  final ForumPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typeColor = ProblemTypeStyle.colorFor(post.problemType, colors);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(ProblemTypeStyle.iconFor(post.problemType), size: 16, color: typeColor),
                  const SizedBox(width: 4),
                  Text(
                    ProblemTypeStyle.labelFor(post.problemType),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: typeColor),
                  ),
                  const Spacer(),
                  Text(
                    '${post.crop} · ${post.district}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Text(post.title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              AppSpacing.gapSm,
              Row(
                children: [
                  Text(post.authorName, style: Theme.of(context).textTheme.labelSmall),
                  const Spacer(),
                  Icon(Icons.favorite_border_rounded, size: 14, color: colors.textMuted),
                  const SizedBox(width: 2),
                  Text('${post.likeCount}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                  AppSpacing.gapSm,
                  Icon(Icons.mode_comment_outlined, size: 14, color: colors.textMuted),
                  const SizedBox(width: 2),
                  Text('${post.replyCount}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
