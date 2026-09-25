import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/domain/entities/admin_models.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/screens/admin_center_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_centers_screen.dart';
import '../../features/admin/presentation/screens/admin_overview_screen.dart';
import '../../features/admin/presentation/screens/admin_people_screen.dart';
import '../../features/admin/presentation/screens/admin_supply_screen.dart';
import '../../features/admin/presentation/screens/admin_user_detail_screen.dart';
import '../../features/admin/presentation/screens/create_center_screen.dart';
import '../../features/auth/presentation/screens/session_gate_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/farmer/home/presentation/screens/farmer_home_screen.dart';
import '../../features/farmer/notifications/presentation/screens/notifications_screen.dart';
import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/farmer/presentation/farmer_shell.dart';
import '../../features/farmer/profile/domain/profile_models.dart';
import '../../features/farmer/profile/presentation/screens/address_form_screen.dart';
import '../../features/farmer/profile/presentation/screens/addresses_screen.dart';
import '../../features/farmer/profile/presentation/screens/contact_screen.dart';
import '../../features/farmer/profile/presentation/screens/farm_details_screen.dart';
import '../../features/farmer/profile/presentation/screens/my_activity_screen.dart';
import '../../features/farmer/profile/presentation/screens/profile_screen.dart';
import '../../features/farmer/soil_health/presentation/screens/soil_scan_capture_screen.dart';
import '../../features/farmer/soil_health/presentation/screens/soil_scan_history_screen.dart';
import '../../features/farmer/soil_health/presentation/screens/soil_scan_result_screen.dart';
import '../../features/farmer/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/farmer/marketplace/presentation/screens/product_comparison_screen.dart';
import '../../features/farmer/marketplace/presentation/screens/product_detail_screen.dart';
import '../../features/farmer/centers/presentation/screens/nearby_centers_screen.dart';
import '../../features/farmer/centers/presentation/screens/surplus_nearby_screen.dart';
import '../../features/farmer/centers/presentation/screens/village_picker_screen.dart';
import '../../features/farmer/community/presentation/screens/community_feed_screen.dart';
import '../../features/farmer/orders/presentation/screens/my_orders_screen.dart';
import '../../features/farmer/community/presentation/screens/create_post_screen.dart';
import '../../features/farmer/community/presentation/screens/post_detail_screen.dart';
import '../../features/farmer/schemes/presentation/screens/scheme_detail_screen.dart';
import '../../features/resale/presentation/admin/resale_admin_screen.dart';
import '../../features/resale/presentation/farmer/farmer_wallet_screen.dart';
import '../../features/resale/presentation/operator/cash_payouts_screen.dart';
import '../../features/resale/presentation/operator/inspection_screen.dart';
import '../../features/resale/presentation/operator/resale_queue_screen.dart';
import '../../features/resale/presentation/operator/resale_review_screen.dart';
import '../../features/resale/presentation/farmer/resale_listing_screen.dart';
import '../../features/resale/presentation/farmer/sell_surplus_form_screen.dart';
import '../../features/resale/presentation/farmer/sell_surplus_hub_screen.dart';
import '../../features/farmer/schemes/presentation/screens/schemes_list_view.dart';
import '../../features/operator/earnings/presentation/screens/earnings_screen.dart';
import '../../features/auth/presentation/screens/dev_role_picker_screen.dart';
import '../../features/delivery/management/domain/management_models.dart';
import '../../features/delivery/management/presentation/delivery_management_screen.dart';
import '../../features/delivery/presentation/screens/delivery_hub_screen.dart';
import '../../features/delivery/presentation/screens/loads_screens.dart';
import '../../features/delivery/presentation/screens/trips_screen.dart';
import '../../features/delivery/presentation/screens/wallet_screen.dart';
import '../../features/operator/farmers/presentation/screens/farmer_detail_screen.dart';
import '../../features/operator/farmers/presentation/screens/farmers_list_screen.dart';
import '../../features/operator/inventory/presentation/screens/inventory_screen.dart';
import '../../features/operator/orders/presentation/screens/order_detail_screen.dart';
import '../../features/operator/surplus/presentation/screens/surplus_screen.dart';
import '../../features/operator/orders/presentation/screens/orders_list_screen.dart';
import '../../features/operator/orders/presentation/screens/walk_in_pos_screen.dart';
import '../../features/operator/presentation/operator_shell.dart';
import '../../features/operator/presentation/screens/operator_dashboard_screen.dart';
import '../auth/auth_providers.dart';
import '../flavor/app_flavor.dart';
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
      return redirectForSession(ref.read(sessionProfileProvider).value, state.matchedLocation, flavor: ref.read(appFlavorProvider));
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
        path: RoutePaths.wrongApp,
        builder: (context, state) => const WrongAppScreen(),
      ),
      GoRoute(
        path: RoutePaths.devPicker,
        builder: (context, state) => const DevRolePickerScreen(),
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
                  GoRoute(path: 'assistant', builder: (context, state) => const AssistantScreen()),
                  GoRoute(
                    path: 'deliver',
                    builder: (context, state) => const DeliveryHubScreen(),
                    routes: [
                      GoRoute(path: 'wallet', builder: (context, state) => const WalletScreen()),
                      GoRoute(path: 'trips', builder: (context, state) => const TripsScreen()),
                    ],
                  ),
                  GoRoute(
                    path: 'loads',
                    builder: (context, state) => const MyLoadsScreen(),
                    routes: [
                      // Before ':loadId', so "new" is not read as a load's id.
                      GoRoute(path: 'new', builder: (context, state) => const SendLoadScreen()),
                      GoRoute(path: ':loadId', builder: (context, state) => LoadDetailScreen(jobId: state.pathParameters['loadId']!)),
                    ],
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
                    path: 'surplus',
                    builder: (context, state) => const SurplusNearbyScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.farmerProfile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(path: 'contact', builder: (context, state) => const ContactScreen()),
                  GoRoute(
                    path: 'addresses',
                    builder: (context, state) => const AddressesScreen(),
                    routes: [
                      GoRoute(path: 'edit', builder: (context, state) => AddressFormScreen(existing: state.extra is SavedAddress ? state.extra! as SavedAddress : null)),
                    ],
                  ),
                  GoRoute(path: 'activity', builder: (context, state) => const MyActivityScreen()),
                  GoRoute(path: 'farm', builder: (context, state) => const FarmDetailsScreen()),
                  GoRoute(path: 'schemes', builder: (context, state) => const SchemesScreen()),
                  GoRoute(path: 'wallet', builder: (context, state) => const FarmerWalletScreen()),
                  GoRoute(
                    path: 'sell',
                    builder: (context, state) => const SellSurplusHubScreen(),
                    routes: [
                      // Before ':listingId', so "new" is not read as a listing id.
                      GoRoute(path: 'new', builder: (context, state) => const SellSurplusFormScreen()),
                      GoRoute(path: ':listingId', builder: (context, state) => ResaleListingScreen(listingId: state.pathParameters['listingId']!)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Home delivery: the operator's own center, and the admin's view of every center.
      GoRoute(path: RoutePaths.operatorDeliveries, builder: (context, state) => const DeliveryManagementScreen(scope: ManagementScope.operator)),
      GoRoute(path: RoutePaths.adminDelivery, builder: (context, state) => const DeliveryManagementScreen(scope: ManagementScope.admin)),
      GoRoute(path: RoutePaths.adminResale, builder: (context, state) => const ResaleAdminScreen()),

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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.adminSupply,
                builder: (context, state) {
                  final tab = supplyTabFromQuery(state.uri.queryParameters['tab']);
                  return AdminSupplyScreen(key: ValueKey('supply-$tab'), initialTab: tab);
                },
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
                  GoRoute(
                    path: 'deliver',
                    builder: (context, state) => const DeliveryHubScreen(),
                    routes: [
                      GoRoute(path: 'wallet', builder: (context, state) => const WalletScreen()),
                      GoRoute(path: 'trips', builder: (context, state) => const TripsScreen()),
                    ],
                  ),
                  GoRoute(
                    path: 'loads',
                    builder: (context, state) => const MyLoadsScreen(),
                    routes: [
                      // Before ':loadId', so "new" is not read as a load's id.
                      GoRoute(path: 'new', builder: (context, state) => const SendLoadScreen()),
                      GoRoute(path: ':loadId', builder: (context, state) => LoadDetailScreen(jobId: state.pathParameters['loadId']!)),
                    ],
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
                routes: [
                  // Relative segment; keep in sync with RoutePaths.operatorSurplus.
                  GoRoute(
                    path: 'surplus',
                    builder: (context, state) => const SurplusScreen(),
                  ),
                  GoRoute(
                    path: 'resale',
                    builder: (context, state) => const ResaleQueueScreen(),
                    routes: [
                      // 'new' and 'cash' before ':listingId', so they are not read as a listing id.
                      GoRoute(path: 'new', builder: (context, state) => const InspectionScreen()),
                      GoRoute(path: 'cash', builder: (context, state) => const CashPayoutsScreen()),
                      GoRoute(
                        path: ':listingId',
                        builder: (context, state) => ResaleReviewScreen(listingId: state.pathParameters['listingId']!),
                        routes: [GoRoute(path: 'inspect', builder: (context, state) => InspectionScreen(listingId: state.pathParameters['listingId']!))],
                      ),
                    ],
                  ),
                ],
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
