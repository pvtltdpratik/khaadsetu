import 'package:flutter/material.dart';

import 'motion.dart';

/// A number that counts up to its value when it first appears and glides to
/// each new value after that, instead of jumping.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.format,
    this.duration = Motion.slow,
    this.textAlign,
  });

  final num value;
  final TextStyle? style;

  /// Turns the animated value into text; by default a whole number.
  final String Function(num value)? format;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    String show(num v) => format != null ? format!(v) : v.round().toString();
    if (Motion.reduced(context)) return Text(show(value), style: style, textAlign: textAlign);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Motion.enter,
      builder: (context, v, _) => Text(show(v), style: style, textAlign: textAlign),
    );
  }
}
