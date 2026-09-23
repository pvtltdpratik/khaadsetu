import 'package:flutter/material.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Two large selectable cards for picking a [UserRole]. Used at sign-up and on
/// the one-time chooser for accounts that predate roles.
class RoleSelector extends StatelessWidget {
  const RoleSelector({super.key, required this.selected, required this.onChanged, this.enabled = true});

  final UserRole? selected;
  final ValueChanged<UserRole> onChanged;
  final bool enabled;

  static IconData _icon(UserRole role) => switch (role) {
        UserRole.farmer => Icons.agriculture_rounded,
        UserRole.operator => Icons.storefront_rounded,
      };

  static String _description(UserRole role) => switch (role) {
        UserRole.farmer => 'Scan soil, buy inputs, ask the community',
        UserRole.operator => 'Run a village center: orders, stock, farmers',
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final role in UserRole.values) ...[
          Semantics(
            button: true,
            selected: selected == role,
            child: Material(
              color: selected == role ? colors.primaryContainer : colors.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: enabled ? () => onChanged(role) : null,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected == role ? colors.primary : colors.border,
                      width: selected == role ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_icon(role), color: colors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(role.label, style: Theme.of(context).textTheme.titleSmall),
                            Text(
                              _description(role),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (selected == role) Icon(Icons.check_circle_rounded, color: colors.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (role != UserRole.values.last) AppSpacing.gapSm,
        ],
      ],
    );
  }
}
