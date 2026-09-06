import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_selector_screen.dart';
import '../../features/farmer/home/presentation/screens/farmer_home_screen.dart';
import '../../features/farmer/presentation/farmer_shell.dart';
import '../../features/farmer/soil_health/presentation/screens/soil_scan_capture_screen.dart';
import '../../features/farmer/soil_health/presentation/screens/soil_scan_history_screen.dart';
import '../../features/farmer/soil_health/presentation/screens/soil_scan_result_screen.dart';
import '../../features/farmer/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/farmer/marketplace/presentation/screens/product_comparison_screen.dart';
import '../../features/farmer/marketplace/presentation/screens/product_detail_screen.dart';
import '../../features/farmer/community/presentation/screens/community_feed_screen.dart';
import '../../features/farmer/community/presentation/screens/post_detail_screen.dart';
import '../../features/farmer/schemes/presentation/screens/scheme_detail_screen.dart';
import '../../features/operator/orders/presentation/screens/order_detail_screen.dart';
import '../../features/operator/orders/presentation/screens/orders_list_screen.dart';
import '../../features/operator/orders/presentation/screens/walk_in_pos_screen.dart';
import '../../features/operator/presentation/operator_shell.dart';
import '../../features/operator/presentation/screens/operator_dashboard_screen.dart';
import '../widgets/coming_soon_view.dart';
import 'route_paths.dart';

/// App-wide router. Farmer and Operator routes are kept as separate groups
/// (distinct top-level paths, no shared parent route) so each app's nested
/// routes and shell can evolve independently in later phases.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.root,
    routes: [
      GoRoute(
        path: RoutePaths.root,
        builder: (context, state) => const AppSelectorScreen(),
      ),

      // --- Farmer App route group ---
      // Bare '/farmer' only redirects into the shell's initial branch;
      // screens should link to the branch paths below directly.
      GoRoute(
        path: RoutePaths.farmerRoot,
        redirect: (context, state) => RoutePaths.farmerHome,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            FarmerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.farmerHome,
                builder: (context, state) => const FarmerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.farmerSoilScan,
                builder: (context, state) => const SoilScanCaptureScreen(),
                routes: [
                  // Relative segments — must stay in sync with the absolute
                  // constants in route_paths.dart used for navigation.
                  GoRoute(
                    path: 'result/:scanId',
                    builder: (context, state) => SoilScanResultScreen(
                      scanId: state.pathParameters['scanId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const SoilScanHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.farmerMarketplace,
                builder: (context, state) => MarketplaceScreen(
                  preselectedProductId: state.uri.queryParameters['preselect'],
                ),
                routes: [
                  // Relative segments — must stay in sync with the absolute
                  // constants in route_paths.dart used for navigation.
                  GoRoute(
                    path: 'product/:productId',
                    builder: (context, state) => ProductDetailScreen(
                      productId: state.pathParameters['productId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'compare/:idA/:idB',
                    builder: (context, state) => ProductComparisonScreen(
                      idA: state.pathParameters['idA']!,
                      idB: state.pathParameters['idB']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.farmerCommunity,
                builder: (context, state) => const CommunityFeedScreen(),
                routes: [
                  // Relative segments — must stay in sync with the absolute
                  // constants in route_paths.dart used for navigation.
                  GoRoute(
                    path: 'post/:postId',
                    builder: (context, state) => PostDetailScreen(
                      postId: state.pathParameters['postId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'scheme/:schemeId',
                    builder: (context, state) => SchemeDetailScreen(
                      schemeId: state.pathParameters['schemeId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // --- Village Center Operator App route group ---
      GoRoute(
        path: RoutePaths.operatorRoot,
        redirect: (context, state) => RoutePaths.operatorDashboard,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            OperatorShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.operatorDashboard,
                builder: (context, state) => const OperatorDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.operatorOrders,
                builder: (context, state) => const OrdersListScreen(),
                routes: [
                  // Relative segments — must stay in sync with the absolute
                  // constants in route_paths.dart used for navigation.
                  // 'new' declared before ':orderId' so it matches the
                  // literal segment first.
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const WalkInPosScreen(),
                  ),
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => OrderDetailScreen(
                      orderId: state.pathParameters['orderId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.operatorInventory,
                builder: (context, state) => const ComingSoonView(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory arrives in Phase 7',
                  subtitle: 'Stock levels and restock requests.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.operatorFarmers,
                builder: (context, state) => const ComingSoonView(
                  icon: Icons.people_alt_outlined,
                  title: 'Farmer list arrives in Phase 7',
                  subtitle: 'Last visit, active crop, and follow-ups.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.operatorEarnings,
                builder: (context, state) => const ComingSoonView(
                  icon: Icons.payments_outlined,
                  title: 'Earnings arrive in Phase 7',
                  subtitle: 'Commission summary and payout history.',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
