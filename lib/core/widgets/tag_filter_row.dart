import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Horizontally scrolling "All" + one chip per option, generic over the
/// option type — reused for crop, district, and problem-type filters, each
/// with a different [labelBuilder] instead of three near-duplicate widgets.
class TagFilterRow<T> extends StatelessWidget {
  const TagFilterRow({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final List<T> options;
  final T? selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length + 1,
            separatorBuilder: (_, _) => AppSpacing.gapSm,
            itemBuilder: (context, i) {
              if (i == 0) {
                return ChoiceChip(
                  label: const Text('All'),
                  selected: selected == null,
                  onSelected: (_) => onChanged(null),
                );
              }
              final option = options[i - 1];
              return ChoiceChip(
                label: Text(labelBuilder(option)),
                selected: selected == option,
                onSelected: (_) => onChanged(option),
              );
            },
          ),
        ),
      ],
    );
  }
}
