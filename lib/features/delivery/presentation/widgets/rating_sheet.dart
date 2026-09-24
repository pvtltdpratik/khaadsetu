import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Asks for 1 to 5 stars and an optional word. Returns null when dismissed.
Future<({int stars, String comment})?> showRatingDialog(BuildContext context, {required String title, String hint = 'Say a few words (optional)'}) {
  return showDialog<({int stars, String comment})>(
    context: context,
    builder: (context) => _RatingDialog(title: title, hint: hint),
  );
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: Key('star-$i'),
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  iconSize: 34,
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_border_rounded, color: i <= _stars ? colors.warning : colors.textMuted),
                ),
            ],
          ),
          AppSpacing.gapSm,
          TextField(controller: _comment, maxLength: 300, maxLines: 2, decoration: InputDecoration(hintText: widget.hint)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
        FilledButton(onPressed: _stars == 0 ? null : () => Navigator.pop(context, (stars: _stars, comment: _comment.text.trim())), child: const Text('Send')),
      ],
    );
  }
}
