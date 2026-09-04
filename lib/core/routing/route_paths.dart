/// Central registry of route paths. Screens navigate via these constants
/// instead of hand-typed strings, so a path rename is a one-file change.
class RoutePaths {
  const RoutePaths._();

  static const root = '/';

  // Farmer App route group.
  static const farmerHome = '/farmer';

  // Village Center Operator App route group.
  static const operatorHome = '/operator';
}
