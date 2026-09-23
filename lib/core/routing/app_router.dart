import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/domain/entities/admin_models.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/screens/admin_center_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_centers_screen.dart';
import '../../features/admin/presentation/screens/admin_overview_screen.dart';
import '../../features/admin/presentation/screens/admin_people_screen.dart';
import '../../features/admin/presentation/screens/admin_user_detail_screen.dart';
import '../../features/admin/presentation/screens/create_center_screen.dart';
import '../../features/auth/presentation/screens/session_gate_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/farmer/home/presentation/screens/farmer_home_screen.dart';
import '../../features/farmer/notifications/presentation/screens/notifications_screen.dart';
import '../../features/farmer/presentation/farmer_shell.dart';
import '../../features/farmer/soil_health/presentation/screens/soil_scan_capture_screen.dart';
import '../../features/farmer/soil_health/presentation/screens/soil_scan_history_screen.dart';
import '../../features/farmer/soil_health/presentation/screens/soil_scan_result_screen.dart';
import '../../features/farmer/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/farmer/marketplace/presentation/screens/product_comparison_screen.dart';
import '../../features/farmer/marketplace/presentation/screens/product_detail_screen.dart';
import '../../features/farmer/centers/presentation/screens/nearby_centers_screen.dart';
import '../../features/farmer/centers/presentation/screens/village_picker_screen.dart';
import '../../features/farmer/community/presentation/screens/community_feed_screen.dart';
import '../../features/farmer/orders/presentation/screens/my_orders_screen.dart';
import '../../features/farmer/community/presentation/screens/create_post_screen.dart';
import '../../features/farmer/community/presentation/screens/post_detail_screen.dart';
import '../../features/farmer/schemes/presentation/screens/scheme_detail_screen.dart';
import '../../features/operator/earnings/presentation/screens/earnings_screen.dart';
import '../../features/operator/farmers/presentation/screens/farmer_detail_screen.dart';
import '../../features/operator/farmers/presentation/screens/farmers_list_screen.dart';
import '../../features/operator/inventory/presentation/screens/inventory_screen.dart';
import '../../features/operator/orders/presentation/screens/order_detail_screen.dart';
import '../../features/operator/orders/presentation/screens/orders_list_screen.dart';
import '../../features/operator/orders/presentation/screens/walk_in_pos_screen.dart';
import '../../features/operator/presentation/operator_shell.dart';
import '../../features/operator/presentation/screens/operator_dashboard_screen.dart';
import '../auth/auth_providers.dart';
import '../auth/session_profile.dart';
import 'route_paths.dart';

/// App-wide router. Farmer and Operator routes are kept as separate groups
/// (distinct top-level paths, no shared parent route) so each app's nested
/// routes and shell can evolve independently in later phases.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  // The redirect depends on who the SERVER says the user is, which arrives a
  // moment after sign-in (and can change, e.g. when an admin suspends them), so
  // the router re-runs its redirect when either the session or that profile changes.
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(sessionProfileProvider, (_, _) => refresh.ping());
  return GoRouter(
    initialLocation: RoutePaths.root,
    refreshListenable: Listenable.merge([ref.watch(authRefreshProvider), refresh]),
    redirect: (context, state) {
      final signedIn = auth.currentSession != null;
      final onAuthScreen =
          state.matchedLocation == RoutePaths.signIn || state.matchedLocation == RoutePaths.signUp;
      if (!signedIn) return onAuthScreen ? null : RoutePaths.signIn;
      // Signed in: route by the server's word (null while it is still loading),
      // so a farmer never lands in the operator app, an operator never in the
      // admin panel, and so on.
      return redirectForSession(ref.read(sessionProfileProvider).value, state.matchedLocation);
    },
    routes: [
      GoRoute(
        path: RoutePaths.root,
        builder: (context, state) => const SessionGateScreen(),
      ),
      GoRoute(
        path: RoutePaths.suspended,
        builder: (context, state) => const SuspendedScreen(),
      ),
      GoRoute(
        path: RoutePaths.pendingOperator,
        builder: (context, state) => const PendingOperatorScreen(),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RoutePaths.signUp,
        builder: (context, state) => const SignUpScreen(),
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
                routes: [
                  // Relative segment — must stay in sync with the absolute
                  // constant in route_paths.dart used for navigation.
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
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
                    path: 'centers',
                    builder: (context, state) => NearbyCentersScreen(args: state.extra is NearbyCentersArgs ? state.extra! as NearbyCentersArgs : const NearbyCentersArgs()),
                  ),
                  GoRoute(
                    path: 'location',
                    builder: (context, state) => const VillagePickerScreen(),
                  ),
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const MyOrdersScreen(),
                    routes: [
                      GoRoute(
                        path: ':orderId',
                        builder: (context, state) => FarmerOrderDetailScreen(orderId: state.pathParameters['orderId']!),
                      ),
                    ],
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
                    path: 'new',
                    builder: (context, state) => const CreatePostScreen(),
                  ),
                  GoRoute(
                    path: 'post/:postId',
                    builder: (context, state) => PostDetailScreen(postId: state.pathParameters['postId']!),
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

      // --- Platform admin panel ---
      GoRoute(
        path: RoutePaths.adminRoot,
        redirect: (context, state) => RoutePaths.adminOverview,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminOverview,
                builder: (context, state) => const AdminOverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminOperators,
                builder: (context, state) {
                  final segment = _segmentFromQuery(state.uri.queryParameters['segment']);
                  // Keyed by the filter so a link like "operators awaiting a
                  // center" re-applies it even when this tab is already open.
                  return AdminPeopleScreen(key: ValueKey('operators-$segment'), role: PersonRole.operator, initialSegment: segment);
                },
                routes: [
                  GoRoute(
                    path: ':userId',
                    builder: (context, state) => AdminUserDetailScreen(userId: state.pathParameters['userId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminFarmers,
                builder: (context, state) {
                  final segment = _segmentFromQuery(state.uri.queryParameters['segment']);
                  return AdminPeopleScreen(key: ValueKey('farmers-$segment'), role: PersonRole.farmer, initialSegment: segment);
                },
                routes: [
                  GoRoute(
                    path: ':userId',
                    builder: (context, state) => AdminUserDetailScreen(userId: state.pathParameters['userId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminCenters,
                builder: (context, state) {
                  final filter = centerFilterFromQuery(state.uri.queryParameters['filter']);
                  return AdminCentersScreen(key: ValueKey('centers-$filter'), initialFilter: filter);
                },
                routes: [
                  // 'new' is declared before ':centerId' so it matches first.
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const CreateCenterScreen(),
                  ),
                  GoRoute(
                    path: ':centerId',
                    builder: (context, state) => AdminCenterDetailScreen(centerId: state.pathParameters['centerId']!),
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
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
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
                builder: (context, state) => const InventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.operatorFarmers,
                builder: (context, state) => const FarmersListScreen(),
                routes: [
                  // Relative segment — must stay in sync with the absolute
                  // constant in route_paths.dart used for navigation.
                  GoRoute(
                    path: ':farmerId',
                    builder: (context, state) => FarmerDetailScreen(
                      farmerId: state.pathParameters['farmerId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.operatorEarnings,
                builder: (context, state) => const EarningsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

PersonSegment? _segmentFromQuery(String? raw) {
  for (final s in PersonSegment.values) {
    if (s.name == raw) return s;
  }
  return null;
}

/// A [Listenable] the router can be told to re-check its redirect through.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}
