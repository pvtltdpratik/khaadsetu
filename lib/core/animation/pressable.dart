import 'package:flutter/material.dart';

import 'motion.dart';

/// Gives a tappable thing a small "press in" while a finger (or mouse button)
/// is down on it.
///
/// It listens to raw pointer events rather than taps, so it never competes
/// with the gesture detectors inside [child]: the button or card underneath
/// works exactly as before, it just also dips a little.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.97, this.enabled = true});

  final Widget child;

  /// How small it gets while pressed (1 = no change).
  final double scale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || Motion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.fast,
        curve: Motion.enter,
        child: widget.child,
      ),
    );
  }
}
