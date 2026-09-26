import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
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
          if (comment.isAiGenerated) _AiFeedback(commentId: comment.commentId),
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

/// "Was this answer helpful?" under an AI answer. One tap, and it can be changed: it tells us which answers to trust.
class _AiFeedback extends ConsumerStatefulWidget {
  const _AiFeedback({required this.commentId});

  final String commentId;

  @override
  ConsumerState<_AiFeedback> createState() => _AiFeedbackState();
}

class _AiFeedbackState extends ConsumerState<_AiFeedback> {
  bool? _vote;
  bool _busy = false;

  Future<void> _send(bool helpful) async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).post('/v1/community/comments/${Uri.encodeComponent(widget.commentId)}/feedback', body: {'helpful': helpful});
      if (mounted) setState(() => _vote = helpful);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(children: [
        Expanded(child: Text(_vote == null ? 'Was this answer helpful?' : 'Thank you for telling us.', key: const Key('ai-feedback-label'), style: text.labelMedium?.copyWith(color: colors.textMuted))),
        IconButton(key: const Key('ai-helpful'), tooltip: 'Helpful', visualDensity: VisualDensity.compact, onPressed: _busy ? null : () => _send(true), icon: Icon(_vote == true ? Icons.thumb_up : Icons.thumb_up_outlined, size: 20, color: _vote == true ? colors.success : null)),
        IconButton(key: const Key('ai-not-helpful'), tooltip: 'Not helpful', visualDensity: VisualDensity.compact, onPressed: _busy ? null : () => _send(false), icon: Icon(_vote == false ? Icons.thumb_down : Icons.thumb_down_outlined, size: 20, color: _vote == false ? colors.danger : null)),
      ]),
    );
  }
}
