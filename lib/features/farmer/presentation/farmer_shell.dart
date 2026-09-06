import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive.dart';

class _FarmerDestination {
  const _FarmerDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = [
  _FarmerDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
  ),
  _FarmerDestination(
    icon: Icons.camera_alt_outlined,
    selectedIcon: Icons.camera_alt_rounded,
    label: 'Soil Scan',
  ),
  _FarmerDestination(
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront_rounded,
    label: 'Marketplace',
  ),
  _FarmerDestination(
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
    label: 'Community',
  ),
];

/// Persistent chrome for the Farmer App's 4 top-level sections: bottom nav on
/// mobile, a side [NavigationRail] on tablet/desktop. Wraps go_router's
/// [StatefulNavigationShell] so each tab keeps its own navigation stack and
/// scroll position when switching away and back.
class FarmerShell extends StatelessWidget {
  const FarmerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScope(
      child: Builder(
        builder: (context) {
          if (!context.breakpoint.isTabletUp) {
            return Scaffold(
              body: SafeArea(child: ResponsiveScope(child: navigationShell)),
              bottomNavigationBar: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onDestinationSelected,
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
            );
          }

          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    extended: context.breakpoint.isDesktop,
                    minExtendedWidth: 200,
                    labelType: context.breakpoint.isDesktop
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _onDestinationSelected,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                  Expanded(child: ResponsiveScope(child: navigationShell)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
