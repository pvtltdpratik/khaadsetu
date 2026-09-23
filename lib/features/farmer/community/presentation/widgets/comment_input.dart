import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Comment box pinned under the thread. The text is only cleared after the
/// server accepts it, so a failed send never costs the user what they typed.
class CommentInput extends StatefulWidget {
  const CommentInput({super.key, required this.onSubmit});

  /// Should throw on failure.
  final Future<void> Function(String content) onSubmit;

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  // Matches the server's minimum (2) so we don't send what it would reject.
  static const _minLength = 2;
  static const _maxLength = 3000;

  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.length < _minLength || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSubmit(text);
      _controller.clear();
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_sending,
              minLines: 1,
              maxLines: 4,
              maxLength: _maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Write an answer or comment…',
                counterText: '',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: AppTouchTarget.min,
            height: AppTouchTarget.min,
            child: _sending
                ? const Padding(padding: EdgeInsets.all(AppSpacing.md), child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton.filled(
                    tooltip: 'Post comment',
                    onPressed: _controller.text.trim().length < _minLength ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
          ),
        ],
      ),
    );
  }
}
