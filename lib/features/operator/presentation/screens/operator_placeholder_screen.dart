import 'package:flutter/material.dart';

import '../../../../core/widgets/coming_soon_view.dart';

/// Stand-in for the Village Center Operator App dashboard until Phase 6
/// builds it out. Exists so the `/operator` route group is reachable and
/// testable end to end.
class OperatorPlaceholderScreen extends StatelessWidget {
  const OperatorPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operator App')),
      body: const ComingSoonView(
        icon: Icons.storefront_rounded,
        title: 'Operator dashboard arrives in Phase 6',
      ),
    );
  }
}
