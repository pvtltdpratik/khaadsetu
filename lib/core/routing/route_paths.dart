/// Central registry of route paths. Screens navigate via these constants
/// instead of hand-typed strings, so a path rename is a one-file change.
class RoutePaths {
  const RoutePaths._();

  static const root = '/';
  static const suspended = '/suspended';

  /// Signed in with a kind of account this APK is not for (e.g. an operator in the farmer app).
  static const wrongApp = '/wrong-app';

  /// The test build's role picker.
  static const devPicker = '/dev';
  static const pendingOperator = '/pending-operator';

  // Platform admin panel.
  static const adminRoot = '/admin';
  static const adminOverview = '/admin/overview';
  static const adminOperators = '/admin/operators';
  static const adminFarmers = '/admin/farmers';
  static const adminCenters = '/admin/centers';
  static const adminSupply = '/admin/supply';
  static const adminDelivery = '/admin/delivery';
  static const adminCenterNew = '/admin/centers/new';
  static String adminOperator(String userId) => '/admin/operators/${Uri.encodeComponent(userId)}';
  static String adminFarmer(String userId) => '/admin/farmers/${Uri.encodeComponent(userId)}';
  static String adminCenter(String centerId) => '/admin/centers/${Uri.encodeComponent(centerId)}';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';

  // Farmer App route group. `farmerRoot` exists only to redirect into the
  // shell's initial branch; screens should navigate to the branch paths.
  static const farmerRoot = '/farmer';
  static const farmerHome = '/farmer/home';
  static const farmerNotifications = '/farmer/home/notifications';
  // Delivering for other farmers, and having a load carried: reached from the home tab.
  static const farmerDeliver = '/farmer/home/deliver';
  static const farmerDeliverWallet = '/farmer/home/deliver/wallet';
  static const farmerDeliverTrips = '/farmer/home/deliver/trips';
  static const farmerAssistant = '/farmer/home/assistant';
  static const farmerLoads = '/farmer/home/loads';
  static const farmerLoadNew = '/farmer/home/loads/new';
  static String farmerLoad(String id) => '/farmer/home/loads/${Uri.encodeComponent(id)}';

  // The profile tab and what hangs off it.
  static const farmerProfile = '/farmer/profile';
  static const farmerProfileContact = '/farmer/profile/contact';
  static const farmerProfileAddresses = '/farmer/profile/addresses';
  static const farmerProfileAddressNew = '/farmer/profile/addresses/edit';
  static const farmerProfileActivity = '/farmer/profile/activity';
  static const farmerProfileFarm = '/farmer/profile/farm';
  static const farmerSchemes = '/farmer/profile/schemes';
  static const farmerSellSurplus = '/farmer/profile/sell';
  static const farmerSellSurplusNew = '/farmer/profile/sell/new';
  static String farmerSellSurplusListing(String id) => '/farmer/profile/sell/${Uri.encodeComponent(id)}';
  static const farmerWallet = '/farmer/profile/wallet';
  // The structured fertilizer log, what it earns, the yield prediction and the profit calculator.
  static const farmerLog = '/farmer/profile/log';
  static String farmerLogFertilizer(String productId) => '/farmer/profile/log/new/${Uri.encodeComponent(productId)}';
  static String farmerLogMid(String reviewId) => '/farmer/profile/log/${Uri.encodeComponent(reviewId)}/mid';
  static String farmerLogHarvest(String reviewId) => '/farmer/profile/log/${Uri.encodeComponent(reviewId)}/harvest';
  static const farmerRewards = '/farmer/profile/rewards';
  static String farmerYieldPredict(String productId) => '/farmer/profile/predict/${Uri.encodeComponent(productId)}';
  static const farmerCalculator = '/farmer/profile/calculator';
  static String farmerCalculatorFor(String productId) => '/farmer/profile/calculator?product=${Uri.encodeComponent(productId)}';

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

  // Village centers and orders live under the marketplace tab.
  static const farmerCenters = '/farmer/marketplace/centers';
  static const farmerSurplus = '/farmer/marketplace/surplus';
  static const farmerChooseVillage = '/farmer/marketplace/location';
  static const farmerOrders = '/farmer/marketplace/orders';
  static String farmerOrder(String orderId) => '/farmer/marketplace/orders/${Uri.encodeComponent(orderId)}';

  static const farmerMarketplaceComparePattern = '/farmer/marketplace/compare/:idA/:idB';
  static String farmerMarketplaceCompare(String idA, String idB) =>
      '/farmer/marketplace/compare/$idA/$idB';

  static const farmerCommunity = '/farmer/community';

  static const farmerCommunityNewPost = '/farmer/community/new';

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
  static const operatorNotifications = '/operator/dashboard/notifications';

  static const operatorOrders = '/operator/orders';
  static const operatorOrdersNew = '/operator/orders/new';
  static const operatorOrderDetailPattern = '/operator/orders/:orderId';
  static String operatorOrderDetail(String orderId) =>
      '/operator/orders/$orderId';

  static const operatorInventory = '/operator/inventory';
  static const operatorSurplus = '/operator/inventory/surplus';
  // Farmers' leftover fertilizer, checked and taken in at the center.
  static const operatorResale = '/operator/inventory/resale';
  static const operatorResaleWalkIn = '/operator/inventory/resale/new';
  static const operatorResaleCash = '/operator/inventory/resale/cash';
  static String operatorResaleListing(String id) => '/operator/inventory/resale/${Uri.encodeComponent(id)}';
  static String operatorResaleInspect(String id) => '/operator/inventory/resale/${Uri.encodeComponent(id)}/inspect';
  static const adminResale = '/admin/resale';

  static const operatorFarmers = '/operator/farmers';
  static const operatorFarmerDetailPattern = '/operator/farmers/:farmerId';
  static String operatorFarmerDetail(String farmerId) =>
      '/operator/farmers/$farmerId';

  static const operatorEarnings = '/operator/earnings';
  static const operatorDeliveries = '/operator/deliveries';
}
