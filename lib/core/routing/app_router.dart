import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_selector_screen.dart';
import '../../features/farmer/presentation/screens/farmer_placeholder_screen.dart';
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
      GoRoute(
        path: RoutePaths.farmerHome,
        builder: (context, state) => const FarmerPlaceholderScreen(),
      ),

      // --- Village Center Operator App route group ---
      GoRoute(
        path: RoutePaths.operatorHome,
        builder: (context, state) => const OperatorPlaceholderScreen(),
      ),
    ],
  );
});
