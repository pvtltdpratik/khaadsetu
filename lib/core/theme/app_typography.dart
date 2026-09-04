import 'package:flutter/material.dart';

/// Type scale. Sizes skew larger than a typical consumer app — the primary
/// audience reads outdoors on modest-density screens, so legibility beats
/// density. Responsive screens swap *which style* they use (titleLarge ->
/// headlineMedium) rather than multiplying font sizes.
class AppTypography {
  const AppTypography._();

  /// Set to your font family (e.g. GoogleFonts) or leave null for the
  /// platform default.
  static const String? fontFamily = null;

  static TextTheme textTheme(Color primary, Color secondary, Color muted) {
    return TextTheme(
      displaySmall: _s(38, FontWeight.w700, primary, height: 1.15),
      headlineLarge: _s(32, FontWeight.w700, primary, height: 1.2),
      headlineMedium: _s(28, FontWeight.w700, primary, height: 1.25),
      headlineSmall: _s(24, FontWeight.w600, primary, height: 1.3),
      titleLarge: _s(20, FontWeight.w600, primary, height: 1.35),
      titleMedium: _s(17, FontWeight.w600, primary, height: 1.4),
      titleSmall: _s(15, FontWeight.w600, secondary, height: 1.4),
      bodyLarge: _s(17, FontWeight.w400, primary, height: 1.5),
      bodyMedium: _s(15, FontWeight.w400, secondary, height: 1.5),
      bodySmall: _s(13, FontWeight.w400, muted, height: 1.45),
      labelLarge: _s(15, FontWeight.w600, primary, height: 1.2),
      labelMedium: _s(13, FontWeight.w500, secondary, height: 1.2),
      labelSmall: _s(12, FontWeight.w500, muted, height: 1.2),
    );
  }

  static TextStyle _s(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}
