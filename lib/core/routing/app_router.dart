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
import '../../features/operator/presentation/screens/operator_placeholder_screen.dart';
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
        path: RoutePaths.operatorHome,
        builder: (context, state) => const OperatorPlaceholderScreen(),
      ),
    ],
  );
});
