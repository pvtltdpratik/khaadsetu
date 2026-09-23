import 'package:flutter/material.dart';

/// The app's motion language: how long things take and how they ease, in one
/// place so every screen moves the same way.
class Motion {
  const Motion._();

  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);

  /// Things arriving: quick start, soft landing.
  static const enter = Curves.easeOutCubic;

  /// Things that should feel a little alive (a badge, a check mark).
  static const pop = Curves.easeOutBack;

  /// The gap between neighbours in a staggered list.
  static const stagger = Duration(milliseconds: 55);

  /// Only the first few items are staggered; a long list should not make the
  /// last row wait seconds to appear.
  static const maxStaggered = 8;

  /// True when the person asked the system for less motion (or a test disables
  /// animations). Every animation in the app checks this and shows the final
  /// state straight away.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// How long item [index] of a list waits before it starts.
  static Duration delayFor(int index) => stagger * index.clamp(0, maxStaggered);
}
