import 'package:flutter/material.dart';

/// 4pt spacing scale. Never write a raw EdgeInsets number in a widget.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Common gaps, so `SizedBox(height: 16)` stops appearing everywhere.
  static const gapXs = SizedBox(height: xs, width: xs);
  static const gapSm = SizedBox(height: sm, width: sm);
  static const gapMd = SizedBox(height: md, width: md);
  static const gapLg = SizedBox(height: lg, width: lg);
  static const gapXl = SizedBox(height: xl, width: xl);
}

/// Minimum touch target side length recommended for farmers using the app
/// outdoors, often with wet or gloved hands — larger than the 48dp Material
/// baseline.
class AppTouchTarget {
  const AppTouchTarget._();

  static const double min = 52;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
}
