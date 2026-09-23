import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/widgets/sign_out_button.dart';

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = [
  _Destination(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Overview'),
  _Destination(Icons.storefront_outlined, Icons.storefront_rounded, 'Operators'),
  _Destination(Icons.agriculture_outlined, Icons.agriculture_rounded, 'Farmers'),
  _Destination(Icons.location_on_outlined, Icons.location_on_rounded, 'Centers'),
];

/// Chrome for the platform admin panel: four sections, a bottom bar on phones
/// and a side rail from tablet up (extended with labels on desktop).
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

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
                onDestinationSelected: _select,
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
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
                    labelType: context.breakpoint.isDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _select,
                    trailing: const Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(padding: EdgeInsets.only(bottom: 16), child: SignOutButton()),
                      ),
                    ),
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
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
