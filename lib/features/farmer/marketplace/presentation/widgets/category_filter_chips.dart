import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/product.dart';
import 'product_category_style.dart';

/// Horizontally scrolling filter chips: "All" plus one per [ProductCategory].
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({super.key, required this.selected, required this.onChanged});

  /// Null means "All".
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ProductCategory.values.length + 1,
        separatorBuilder: (_, _) => AppSpacing.gapSm,
        itemBuilder: (context, i) {
          if (i == 0) {
            return ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            );
          }
          final category = ProductCategory.values[i - 1];
          return ChoiceChip(
            label: Text(ProductCategoryStyle.labelFor(category)),
            selected: selected == category,
            onSelected: (_) => onChanged(category),
          );
        },
      ),
    );
  }
}
