import 'package:flutter/material.dart';

import 'breakpoints.dart';
import 'responsive.dart';

/// Swap the whole widget tree per breakpoint. Use when the layout *shape*
/// changes; for values that merely scale, use `context.responsive(...)`.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScope(
      child: Builder(
        builder: (context) {
          final builder = context.responsive<WidgetBuilder>(
            mobile: mobile,
            tablet: tablet,
            desktop: desktop,
          );
          return builder(context);
        },
      ),
    );
  }
}

/// Column on mobile, Row on tablet and up. Covers the common "stack it on a
/// phone" case without a bespoke breakpoint check on every screen.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.flexes,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.stackBelow = Breakpoint.tablet,
  });

  final List<Widget> children;
  final double spacing;

  /// Optional flex weights for the row layout; length must match [children].
  final List<int>? flexes;
  final CrossAxisAlignment crossAxisAlignment;

  /// Stack vertically for breakpoints smaller than this.
  final Breakpoint stackBelow;

  @override
  Widget build(BuildContext context) {
    final stacked = context.breakpoint.index < stackBelow.index;

    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        spaced.add(
          stacked ? SizedBox(height: spacing) : SizedBox(width: spacing),
        );
      }
      final child = children[i];
      spaced.add(
        stacked ? child : Expanded(flex: flexes?[i] ?? 1, child: child),
      );
    }

    return stacked
        ? Column(crossAxisAlignment: crossAxisAlignment, children: spaced)
        : Row(crossAxisAlignment: crossAxisAlignment, children: spaced);
  }
}

/// Grid whose column count follows the breakpoint. Pass [maxItemExtent]
/// instead of relying on breakpoints when item width matters more than a
/// fixed column count.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.childAspectRatio,
    this.maxItemExtent,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  final List<Widget> children;
  final double spacing;
  final double? childAspectRatio;
  final double? maxItemExtent;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final delegate = maxItemExtent != null
        ? SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxItemExtent!,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio ?? 1.3,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.gridColumns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio:
                childAspectRatio ?? context.responsive(mobile: 1.6, tablet: 1.3),
          );

    return GridView.builder(
      padding: padding ?? EdgeInsets.zero,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: delegate,
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// Bottom sheet on mobile, centered dialog on tablet/desktop — the natural
/// input surface changes with the screen, even for the same content.
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  if (context.breakpoint.isTabletUp) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxDialogWidth),
          child: builder(context),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    builder: builder,
  );
}
