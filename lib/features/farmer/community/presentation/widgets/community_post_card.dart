import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/community_post.dart';
import 'problem_type_style.dart';

/// Every text field here is capped with `maxLines`, so cards come out a
/// predictable height regardless of how long a title or post gets — that
/// matters more than usual on the tablet+ grid, which lays these out in a
/// fixed-aspect-ratio cell (see `community_feed_screen.dart`).
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({super.key, required this.post, required this.onTap});

  final CommunityPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typeColor = ProblemTypeStyle.colorFor(post.problemTypeTag, colors);

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
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(ProblemTypeStyle.iconFor(post.problemTypeTag), size: 16, color: typeColor),
                  const SizedBox(width: 4),
                  Text(
                    ProblemTypeStyle.labelFor(post.problemTypeTag),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: typeColor),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      '${post.cropTag} · ${post.districtTag}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              AppSpacing.gapSm,
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.farmerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.favorite_border_rounded, size: 14, color: colors.textMuted),
                  const SizedBox(width: 2),
                  Text('${post.likeCount}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                  AppSpacing.gapSm,
                  Icon(Icons.mode_comment_outlined, size: 14, color: colors.textMuted),
                  const SizedBox(width: 2),
                  Text('${post.commentCount}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
