import 'package:flutter/material.dart';

import 'motion.dart';

/// Fades and slides its child in, once, when it first appears.
///
/// Give list items their [index] and they arrive one after another (only the
/// first few are staggered, see [Motion.maxStaggered]). The delay is part of
/// one controller's timeline rather than a timer, so nothing is left pending
/// when the widget goes away and tests settle normally.
///
/// It plays once per element: rebuilding with new data does not replay it,
/// and with reduced motion on the child is simply shown.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.duration = Motion.medium,
    this.offset = const Offset(0, 16),
  });

  final Widget child;

  /// Position in a list, used for the stagger. Ignored when [delay] is given.
  final int index;
  final Duration? delay;
  final Duration duration;

  /// Where it starts, in logical pixels from its final place.
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  bool _started = false;

  Duration get _delay => widget.delay ?? Motion.delayFor(widget.index);

  @override
  void initState() {
    super.initState();
    final total = _delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    // The first part of the timeline is the wait; the rest is the movement.
    final start = total.inMicroseconds == 0 ? 0.0 : _delay.inMicroseconds / total.inMicroseconds;
    _curve = CurvedAnimation(parent: _controller, curve: Interval(start, 1, curve: Motion.enter));
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
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        if (t >= 1) return child!;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: widget.offset * (1 - t), child: child),
        );
      },
    );
  }
}
