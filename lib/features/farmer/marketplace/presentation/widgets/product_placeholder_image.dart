import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import 'product_category_style.dart';

/// Stands in for a product photo — there are no real product images in this
/// mock catalog, so every listing renders as a category-colored icon tile
/// instead of fetching or fabricating an image URL.
class ProductPlaceholderImage extends StatelessWidget {
  const ProductPlaceholderImage({super.key, required this.category, this.size = 56});

  final ProductCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = ProductCategoryStyle.colorFor(category, colors);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(ProductCategoryStyle.iconFor(category), color: color, size: size * 0.5),
    );
  }
}
