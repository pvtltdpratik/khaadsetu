import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive.dart';

class _OperatorDestination {
  const _OperatorDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = [
  _OperatorDestination(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    label: 'Dashboard',
  ),
  _OperatorDestination(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    label: 'Orders',
  ),
  _OperatorDestination(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
    label: 'Inventory',
  ),
  _OperatorDestination(
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt_rounded,
    label: 'Farmers',
  ),
  _OperatorDestination(
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments_rounded,
    label: 'Earnings',
  ),
];

/// Persistent chrome for the Operator App's 5 sections. Unlike [FarmerShell],
/// the rail goes extended (labeled) starting at tablet rather than only at
/// desktop — operators are expected on larger screens as their primary
/// device, so that's the layout this app optimizes for first.
class OperatorShell extends StatelessWidget {
  const OperatorShell({super.key, required this.navigationShell});

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
                    extended: true,
                    minExtendedWidth: 208,
                    labelType: NavigationRailLabelType.none,
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
