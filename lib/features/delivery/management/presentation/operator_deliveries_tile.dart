import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/animation/pressable.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'management_providers.dart';

/// On the operator's dashboard: the way into home delivery, saying what needs
/// them (a delivery with no driver, an application to check) without opening it.
class OperatorDeliveriesTile extends ConsumerWidget {
  const OperatorDeliveriesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final attention = ref.watch(operatorDeliveryAttentionProvider).value;
    final needs = attention == null ? 0 : attention.needDriver + attention.applications;
    final parts = [
      if (attention != null && attention.needDriver > 0) '${attention.needDriver} need${attention.needDriver == 1 ? 's' : ''} a driver',
      if (attention != null && attention.applications > 0) '${attention.applications} application${attention.applications == 1 ? '' : 's'} to check',
    ];
    return Pressable(
      child: Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('open-deliveries'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(RoutePaths.operatorDeliveries),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: needs > 0 ? colors.warning : colors.border)),
          child: Row(children: [
            Icon(Icons.local_shipping_outlined, color: colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Home deliveries', style: text.titleSmall),
                Text(parts.isEmpty ? 'Orders going out with delivery partners, and who can carry them' : parts.join(' · '), key: const Key('deliveries-summary'), style: text.bodySmall?.copyWith(color: needs > 0 ? colors.warning : colors.textMuted)),
              ]),
            ),
            if (needs > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(color: colors.warning, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text('$needs', style: text.labelMedium?.copyWith(color: colors.onWarning, fontWeight: FontWeight.w800)),
              ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ]),
        ),
      ),
      ),
    );
  }
}
