import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/admin_models.dart';

/// A small coloured pill: a person's or center's standing at a glance.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// The badge for where a person stands (active / suspended / awaiting a center).
class SegmentBadge extends StatelessWidget {
  const SegmentBadge({super.key, required this.segment});

  final PersonSegment segment;

  static String labelFor(PersonSegment s) => switch (s) {
        PersonSegment.active => 'Active',
        PersonSegment.suspended => 'Suspended',
        PersonSegment.unassigned => 'Awaiting center',
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return switch (segment) {
      PersonSegment.active => StatusBadge(label: labelFor(segment), color: colors.success, icon: Icons.check_circle_outline_rounded),
      PersonSegment.suspended => StatusBadge(label: labelFor(segment), color: colors.danger, icon: Icons.block_rounded),
      PersonSegment.unassigned => StatusBadge(label: labelFor(segment), color: colors.warning, icon: Icons.hourglass_top_rounded),
    };
  }
}

/// A row of single-choice filter chips. `null` means "All".
class FilterChips<T> extends StatelessWidget {
  const FilterChips({super.key, required this.options, required this.selected, required this.onChanged, this.countFor});

  /// Label per option, in display order. The `null` key is the "All" chip.
  final Map<T?, String> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  /// Optional count shown on a chip, e.g. "Suspended (3)".
  final int? Function(T? option)? countFor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final entry in options.entries)
          ChoiceChip(
            label: Text(countFor?.call(entry.key) == null ? entry.value : '${entry.value} (${countFor!(entry.key)})'),
            selected: selected == entry.key,
            onSelected: (_) => onChanged(entry.key),
          ),
      ],
    );
  }
}

/// A search box that waits for a pause in typing before reporting, so the
/// list is not re-fetched on every keystroke.
class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({super.key, required this.hint, required this.onChanged, this.delay = const Duration(milliseconds: 350)});

  final String hint;
  final ValueChanged<String> onChanged;
  final Duration delay;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _timer?.cancel();
    _timer = Timer(widget.delay, () => widget.onChanged(value.trim()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _changed,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: true,
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _controller.clear();
                  _timer?.cancel();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label, style: text.bodySmall?.copyWith(color: colors.textMuted))),
            Expanded(
              child: Text(value, style: text.bodyMedium?.copyWith(color: onTap == null ? null : colors.primary)),
            ),
            if (onTap != null) Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// A titled, bordered block.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          AppSpacing.gapSm,
          child,
        ],
      ),
    );
  }
}

/// Confirms a risky action. Returns null if cancelled; otherwise the optional
/// reason the admin typed (empty when [askReason] is false or left blank).
Future<String?> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  bool askReason = false,
}) {
  final reason = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (askReason) ...[
            AppSpacing.gapMd,
            TextField(
              controller: reason,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Reason (optional, shown to the person)'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: context.colors.danger, foregroundColor: context.colors.onDanger) : null,
          onPressed: () => Navigator.pop(context, reason.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Lets the admin choose one of [options]; null if cancelled.
Future<T?> pickOne<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) titleOf,
  String Function(T)? subtitleOf,
  String emptyMessage = 'Nothing to choose from.',
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: options.isEmpty
            ? Text(emptyMessage)
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      title: Text(titleOf(option)),
                      subtitle: subtitleOf == null ? null : Text(subtitleOf(option)),
                      onTap: () => Navigator.pop(context, option),
                    ),
                ],
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    ),
  );
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
