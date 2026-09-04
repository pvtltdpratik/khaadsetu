import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'breakpoints.dart';

/// Publishes the breakpoint resolved from real layout constraints, so
/// widgets nested inside a narrow panel (e.g. a side rail's body) see that
/// panel's width rather than the whole window's.
///
/// Wrap the app body once, at the router shell level, and again around any
/// panel whose children should measure themselves against the panel instead
/// of the window.
class ResponsiveScope extends StatelessWidget {
  const ResponsiveScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return _ResponsiveData(
          breakpoint: Breakpoints.of(width),
          width: width,
          child: child,
        );
      },
    );
  }
}

class _ResponsiveData extends InheritedWidget {
  const _ResponsiveData({
    required this.breakpoint,
    required this.width,
    required super.child,
  });

  final Breakpoint breakpoint;
  final double width;

  @override
  bool updateShouldNotify(_ResponsiveData old) =>
      old.breakpoint != breakpoint || old.width != width;
}

extension ResponsiveX on BuildContext {
  /// Resolved breakpoint. Falls back to the window width when no
  /// [ResponsiveScope] is above this context.
  Breakpoint get breakpoint {
    final data = dependOnInheritedWidgetOfExactType<_ResponsiveData>();
    return data?.breakpoint ?? Breakpoints.of(MediaQuery.sizeOf(this).width);
  }

  double get availableWidth {
    final data = dependOnInheritedWidgetOfExactType<_ResponsiveData>();
    return data?.width ?? MediaQuery.sizeOf(this).width;
  }

  /// Pick a value per breakpoint. Only [mobile] is required; larger sizes
  /// fall back down the chain, so `responsive(mobile: 1, desktop: 3)` gives
  /// tablet the mobile value.
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (breakpoint) {
      case Breakpoint.desktop:
        return desktop ?? tablet ?? mobile;
      case Breakpoint.tablet:
        return tablet ?? mobile;
      case Breakpoint.mobile:
        return mobile;
    }
  }

  /// Standard page gutter for the current size.
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: responsive(
          mobile: AppSpacing.md,
          tablet: AppSpacing.xl,
          desktop: AppSpacing.xxl,
        ),
        vertical: responsive(mobile: AppSpacing.md, tablet: AppSpacing.lg),
      );

  /// Grid columns for card/product lists.
  int get gridColumns => responsive(mobile: 1, tablet: 2, desktop: 3);
}

/// Centers and caps content width on large screens so text lines and card
/// rows stay readable instead of stretching edge-to-edge.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? context.pagePadding,
          child: child,
        ),
      ),
    );
  }
}
