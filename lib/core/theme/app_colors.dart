import 'package:flutter/material.dart';

/// Layer 1 — raw palette. Private on purpose: widgets must never read these
/// directly. Rebranding the app means editing only this class.
class _Palette {
  const _Palette._();

  // Greens — crops, growth, primary brand color.
  static const green50 = Color(0xFFEEF5E9);
  static const green300 = Color(0xFF9CC583);
  static const green600 = Color(0xFF4B7530);
  static const green700 = Color(0xFF3A5C25);

  // Warm browns — soil, earth, secondary accent.
  static const brown300 = Color(0xFFC9A17A);
  static const brown500 = Color(0xFF9C6B3E);

  // Soft yellows — highlights, warnings, harvest tones.
  static const yellow400 = Color(0xFFEFC55E);
  static const yellow600 = Color(0xFFC99A2E);

  // Status colors.
  static const red400 = Color(0xFFE18178);
  static const red600 = Color(0xFFB94A3D);
  static const blue400 = Color(0xFF7FA8C9);
  static const blue600 = Color(0xFF3E7BA6);

  static const white = Color(0xFFFFFFFF);
  static const cream50 = Color(0xFFFBF8F2);
  static const cream100 = Color(0xFFF4EEE0);
  static const grey200 = Color(0xFFE4DFD3);
  static const grey400 = Color(0xFFA79E8C);
  static const grey500 = Color(0xFF8A8272);
  static const grey700 = Color(0xFF4A4538);
  static const grey900 = Color(0xFF2B2820);

  // Dark-mode neutrals: elevation reads as a lighter surface, not a shadow.
  static const dark0 = Color(0xFF171510);
  static const dark1 = Color(0xFF221F18);
  static const dark2 = Color(0xFF2D2A20);
  static const dark3 = Color(0xFF3A362A);
}

/// Layer 2 — semantic tokens. The single source of truth for every color in
/// the app. Add a field here and the compiler forces you to give it a light
/// *and* a dark value.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.onSurface,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.info,
    required this.overlay,
    required this.shadow,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color secondary;
  final Color onSecondary;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSunken;
  final Color onSurface;

  final Color border;
  final Color divider;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color info;

  final Color overlay;
  final Color shadow;

  static const light = AppColorTokens(
    primary: _Palette.green600,
    onPrimary: _Palette.white,
    primaryContainer: _Palette.green50,
    secondary: _Palette.brown500,
    onSecondary: _Palette.white,
    background: _Palette.cream50,
    surface: _Palette.white,
    surfaceElevated: _Palette.white,
    surfaceSunken: _Palette.cream100,
    onSurface: _Palette.grey900,
    border: _Palette.grey200,
    divider: _Palette.grey200,
    textPrimary: _Palette.grey900,
    textSecondary: _Palette.grey700,
    textMuted: _Palette.grey500,
    textInverse: _Palette.white,
    success: _Palette.green600,
    onSuccess: _Palette.white,
    warning: _Palette.yellow600,
    onWarning: _Palette.grey900,
    danger: _Palette.red600,
    onDanger: _Palette.white,
    info: _Palette.blue600,
    overlay: Color(0x8A000000),
    shadow: Color(0x1F000000),
  );

  static const dark = AppColorTokens(
    // Lighter, less saturated accents: green600 vibrates on near-black.
    primary: _Palette.green300,
    onPrimary: _Palette.grey900,
    primaryContainer: _Palette.green700,
    secondary: _Palette.brown300,
    onSecondary: _Palette.grey900,
    background: _Palette.dark0,
    surface: _Palette.dark1,
    surfaceElevated: _Palette.dark2,
    surfaceSunken: _Palette.dark0,
    onSurface: _Palette.cream100,
    border: _Palette.dark3,
    divider: _Palette.dark3,
    textPrimary: _Palette.cream100,
    textSecondary: _Palette.grey200,
    textMuted: _Palette.grey400,
    textInverse: _Palette.grey900,
    success: _Palette.green300,
    onSuccess: _Palette.grey900,
    warning: _Palette.yellow400,
    onWarning: _Palette.grey900,
    danger: _Palette.red400,
    onDanger: _Palette.grey900,
    info: _Palette.blue400,
    overlay: Color(0xB3000000),
    shadow: Color(0x66000000),
  );

  @override
  AppColorTokens copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSunken,
    Color? onSurface,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
    Color? info,
    Color? overlay,
    Color? shadow,
  }) {
    return AppColorTokens(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      onSurface: onSurface ?? this.onSurface,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      info: info ?? this.info,
      overlay: overlay ?? this.overlay,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorTokens(
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryContainer: c(primaryContainer, other.primaryContainer),
      secondary: c(secondary, other.secondary),
      onSecondary: c(onSecondary, other.onSecondary),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      onSurface: c(onSurface, other.onSurface),
      border: c(border, other.border),
      divider: c(divider, other.divider),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      textInverse: c(textInverse, other.textInverse),
      success: c(success, other.success),
      onSuccess: c(onSuccess, other.onSuccess),
      warning: c(warning, other.warning),
      onWarning: c(onWarning, other.onWarning),
      danger: c(danger, other.danger),
      onDanger: c(onDanger, other.onDanger),
      info: c(info, other.info),
      overlay: c(overlay, other.overlay),
      shadow: c(shadow, other.shadow),
    );
  }
}

/// `context.colors.success` — the only way widgets read app-specific colors.
extension AppColorsX on BuildContext {
  AppColorTokens get colors =>
      Theme.of(this).extension<AppColorTokens>() ?? AppColorTokens.light;
}
