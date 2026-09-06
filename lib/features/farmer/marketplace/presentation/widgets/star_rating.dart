import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Row of star icons for a 0-5 rating. [rating] can be fractional (product
/// averages); stars render filled/half/empty accordingly. Integer-only
/// ratings (individual reviews) just render whole stars.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.warning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final diff = rating - i;
        final icon = diff >= 1
            ? Icons.star_rounded
            : diff >= 0.5
                ? Icons.star_half_rounded
                : Icons.star_border_rounded;
        return Icon(icon, size: size, color: color);
      }),
    );
  }
}
