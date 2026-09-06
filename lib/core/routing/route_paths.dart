/// Central registry of route paths. Screens navigate via these constants
/// instead of hand-typed strings, so a path rename is a one-file change.
class RoutePaths {
  const RoutePaths._();

  static const root = '/';

  // Farmer App route group. `farmerRoot` exists only to redirect into the
  // shell's initial branch; screens should navigate to the branch paths.
  static const farmerRoot = '/farmer';
  static const farmerHome = '/farmer/home';
  static const farmerSoilScan = '/farmer/soil-scan';
  static const farmerSoilScanHistory = '/farmer/soil-scan/history';

  /// Route pattern for registration (go_router) — use [farmerSoilScanResult]
  /// to build an actual link.
  static const farmerSoilScanResultPattern = '/farmer/soil-scan/result/:scanId';
  static String farmerSoilScanResult(String scanId) =>
      '/farmer/soil-scan/result/$scanId';

  static const farmerMarketplace = '/farmer/marketplace';

  static const farmerMarketplaceProductPattern = '/farmer/marketplace/product/:productId';
  static String farmerMarketplaceProduct(String productId) =>
      '/farmer/marketplace/product/$productId';

  static const farmerMarketplaceComparePattern = '/farmer/marketplace/compare/:idA/:idB';
  static String farmerMarketplaceCompare(String idA, String idB) =>
      '/farmer/marketplace/compare/$idA/$idB';

  static const farmerCommunity = '/farmer/community';

  // Village Center Operator App route group.
  static const operatorHome = '/operator';
}
