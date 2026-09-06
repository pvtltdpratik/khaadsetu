import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';

/// Maps [ProductCategory] to display icon/color/label — the one place this
/// mapping lives, since several widgets (tile, card, detail, compare) need it.
class ProductCategoryStyle {
  const ProductCategoryStyle._();

  static IconData iconFor(ProductCategory category) => switch (category) {
        ProductCategory.fertilizer => Icons.eco_rounded,
        ProductCategory.organic => Icons.compost_rounded,
        ProductCategory.pesticide => Icons.pest_control_rounded,
        ProductCategory.seed => Icons.grass_rounded,
        ProductCategory.equipment => Icons.handyman_rounded,
      };

  static Color colorFor(ProductCategory category, AppColorTokens colors) => switch (category) {
        ProductCategory.fertilizer => colors.primary,
        ProductCategory.organic => colors.secondary,
        ProductCategory.pesticide => colors.danger,
        ProductCategory.seed => colors.warning,
        ProductCategory.equipment => colors.info,
      };

  static String labelFor(ProductCategory category) => switch (category) {
        ProductCategory.fertilizer => 'Fertilizer',
        ProductCategory.organic => 'Organic',
        ProductCategory.pesticide => 'Pesticide',
        ProductCategory.seed => 'Seed',
        ProductCategory.equipment => 'Equipment',
      };
}
