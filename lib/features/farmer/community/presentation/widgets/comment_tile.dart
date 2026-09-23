import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/post_comment.dart';

/// One comment in the thread. The trust signal is the point of this widget:
/// an AI draft is always labelled as such, and only gets the green
/// "verified" treatment once an agronomist has reviewed it — the two states
/// must never look alike, since a farmer may act on this advice.
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final verified = comment.isAgronomistVerified;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: verified ? colors.success : colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: comment.isAiGenerated ? colors.info.withValues(alpha: 0.15) : colors.primaryContainer,
                child: Icon(
                  comment.isAiGenerated ? Icons.auto_awesome : Icons.person_outline,
                  size: 16,
                  color: comment.isAiGenerated ? colors.info : colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  comment.isAiGenerated ? 'AI assistant' : comment.farmerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge,
                ),
              ),
              Text(formatAgo(comment.createdAt), style: text.labelSmall?.copyWith(color: colors.textMuted)),
            ],
          ),
          if (comment.isAiGenerated) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _Badge(label: 'AI-generated', icon: Icons.auto_awesome, color: colors.info),
                if (verified)
                  _Badge(
                    label: comment.agronomistName == null
                        ? 'Verified by agronomist'
                        : 'Verified by ${comment.agronomistName}',
                    icon: Icons.verified_rounded,
                    color: colors.success,
                  )
                else
                  _Badge(label: 'Awaiting expert review', icon: Icons.hourglass_empty_rounded, color: colors.warning),
              ],
            ),
          ] else if (verified) ...[
            const SizedBox(height: AppSpacing.sm),
            _Badge(label: 'Verified agronomist', icon: Icons.verified_rounded, color: colors.success),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(comment.content, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// "just now", "5m ago", "3h ago", "2d ago", then a plain date.
String formatAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}
