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

  static const farmerCommunityPostPattern = '/farmer/community/post/:postId';
  static String farmerCommunityPost(String postId) =>
      '/farmer/community/post/$postId';

  static const farmerCommunitySchemePattern = '/farmer/community/scheme/:schemeId';
  static String farmerCommunityScheme(String schemeId) =>
      '/farmer/community/scheme/$schemeId';

  // Village Center Operator App route group. `operatorRoot` exists only to
  // redirect into the shell's initial branch, matching `farmerRoot`.
  static const operatorRoot = '/operator';
  static const operatorDashboard = '/operator/dashboard';

  static const operatorOrders = '/operator/orders';
  static const operatorOrdersNew = '/operator/orders/new';
  static const operatorOrderDetailPattern = '/operator/orders/:orderId';
  static String operatorOrderDetail(String orderId) =>
      '/operator/orders/$orderId';

  static const operatorInventory = '/operator/inventory';

  static const operatorFarmers = '/operator/farmers';
  static const operatorFarmerDetailPattern = '/operator/farmers/:farmerId';
  static String operatorFarmerDetail(String farmerId) =>
      '/operator/farmers/$farmerId';

  static const operatorEarnings = '/operator/earnings';
}
