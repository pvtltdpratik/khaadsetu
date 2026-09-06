import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/forum_post.dart';

class ProblemTypeStyle {
  const ProblemTypeStyle._();

  static IconData iconFor(ProblemType type) => switch (type) {
        ProblemType.pest => Icons.bug_report_outlined,
        ProblemType.disease => Icons.coronavirus_outlined,
        ProblemType.nutrientDeficiency => Icons.science_outlined,
        ProblemType.weather => Icons.cloud_outlined,
        ProblemType.market => Icons.trending_up_rounded,
        ProblemType.general => Icons.forum_outlined,
      };

  static Color colorFor(ProblemType type, AppColorTokens colors) => switch (type) {
        ProblemType.pest => colors.danger,
        ProblemType.disease => colors.danger,
        ProblemType.nutrientDeficiency => colors.warning,
        ProblemType.weather => colors.info,
        ProblemType.market => colors.secondary,
        ProblemType.general => colors.textMuted,
      };

  static String labelFor(ProblemType type) => switch (type) {
        ProblemType.pest => 'Pest',
        ProblemType.disease => 'Disease',
        ProblemType.nutrientDeficiency => 'Nutrient',
        ProblemType.weather => 'Weather',
        ProblemType.market => 'Market',
        ProblemType.general => 'General',
      };
}
