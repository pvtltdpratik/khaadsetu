/// Screen-size buckets. Widths are logical pixels of the *available
/// constraints*, not necessarily the window — see [ResponsiveScope].
enum Breakpoint {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == Breakpoint.mobile;
  bool get isTablet => this == Breakpoint.tablet;
  bool get isDesktop => this == Breakpoint.desktop;

  /// Tablet and wider — where multi-column layouts start making sense.
  bool get isTabletUp => index >= Breakpoint.tablet.index;
}

class Breakpoints {
  const Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  /// Readable line length cap for wide screens.
  static const double maxContentWidth = 1200;

  /// Comfortable max width for a modal on a large screen.
  static const double maxDialogWidth = 480;

  static Breakpoint of(double width) {
    if (width >= desktop) return Breakpoint.desktop;
    if (width >= tablet) return Breakpoint.tablet;
    return Breakpoint.mobile;
  }
}
