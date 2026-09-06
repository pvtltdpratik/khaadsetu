import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/product.dart';
import 'price_format.dart';
import 'product_placeholder_image.dart';
import 'soil_match_badge.dart';
import 'star_rating.dart';

/// Mobile row layout for a product.
class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    required this.matchesSoil,
    required this.onTap,
    this.compareMode = false,
    this.isSelectedForCompare = false,
  });

  final Product product;
  final bool matchesSoil;
  final VoidCallback onTap;
  final bool compareMode;
  final bool isSelectedForCompare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelectedForCompare ? colors.primary : colors.border,
              width: isSelectedForCompare ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ProductPlaceholderImage(category: product.category),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      product.brand,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        StarRating(rating: product.rating, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                    if (matchesSoil) ...[const SizedBox(height: AppSpacing.xxs), const SoilMatchBadge()],
                  ],
                ),
              ),
              AppSpacing.gapSm,
              if (compareMode)
                Icon(
                  isSelectedForCompare ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: isSelectedForCompare ? colors.primary : colors.textMuted,
                )
              else
                Text(formatRupees(product.priceInRupees), style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
