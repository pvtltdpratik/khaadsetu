import 'package:flutter/material.dart';

import 'motion.dart';

/// How every screen change looks: the new page fades in while rising a few
/// pixels, and the page underneath eases back slightly. Set once on the theme
/// so all routes share it.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static final _rise = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).chain(CurveTween(curve: Motion.enter));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: animation.drive(_rise),
        // The screen being covered dims a touch instead of just sitting there.
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.92).animate(secondaryAnimation),
          child: child,
        ),
      ),
    );
  }
}

/// The transition theme to give MaterialApp so every platform moves the same way.
const appPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: AppPageTransitionsBuilder(),
    TargetPlatform.iOS: AppPageTransitionsBuilder(),
    TargetPlatform.macOS: AppPageTransitionsBuilder(),
    TargetPlatform.windows: AppPageTransitionsBuilder(),
    TargetPlatform.linux: AppPageTransitionsBuilder(),
    TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
  },
);
