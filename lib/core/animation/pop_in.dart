import 'package:flutter/material.dart';

import 'motion.dart';

/// Scales and fades its child in with a small overshoot, once: for a moment
/// that deserves a little life (a discount badge, a pickup code appearing).
///
/// Like [FadeSlideIn] the wait is part of one controller's timeline, and with
/// reduced motion the child is just shown.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.slow,
    this.from = 0.6,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// The size it starts at, as a fraction of its final size.
  final double from;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total.inMicroseconds == 0 ? 0.0 : widget.delay.inMicroseconds / total.inMicroseconds;
    _scale = CurvedAnimation(parent: _controller, curve: Interval(start, 1, curve: Motion.pop));
    _fade = CurvedAnimation(parent: _controller, curve: Interval(start, (start + (1 - start) * 0.5).clamp(0, 1), curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (_controller.isCompleted) return child!;
        return Opacity(
          opacity: _fade.value.clamp(0, 1),
          child: Transform.scale(scale: widget.from + (1 - widget.from) * _scale.value, child: child),
        );
      },
    );
  }
}
