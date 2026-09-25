import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../farmer/centers/presentation/widgets/contact_actions.dart';
import '../resale_providers.dart';

/// Cash the center owes farmers whose fertilizer sold and who chose to be paid in cash.
class CashPayoutsScreen extends ConsumerWidget {
  const CashPayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final due = ref.watch(cashDueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cash to hand over')),
      body: ResponsiveScope(
        child: due.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(cashDueProvider)),
          data: (list) => list.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('No cash to hand over. When a farmer\'s fertilizer sells and they chose cash, it appears here.', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted))))
              : ListView(padding: context.pagePadding, children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Row(children: [
                      Expanded(child: Text('Total to pay out', style: text.titleSmall)),
                      Text(formatRupees(list.fold(0.0, (s, p) => s + p.amount)), key: const Key('cash-total'), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  AppSpacing.gapSm,
                  for (final p in list)
                    Card(
                      key: Key('cash-${p.saleId}'),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${p.sellerName}  ·  ${formatRupees(p.amount)}', style: text.titleSmall),
                          Text(p.productName, style: text.bodySmall?.copyWith(color: colors.textMuted)),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(spacing: AppSpacing.sm, children: [
                            if (p.sellerPhone.isNotEmpty) OutlinedButton.icon(onPressed: () => callPhone(context, p.sellerPhone), icon: const Icon(Icons.call_rounded, size: 18), label: const Text('Call')),
                            FilledButton.icon(
                              key: Key('cash-paid-${p.saleId}'),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Hand ${formatRupees(p.amount)} to ${p.sellerName}?'),
                                    content: const Text('Only confirm once you have given them the cash.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not yet')),
                                      FilledButton(key: const Key('confirm-cash'), onPressed: () => Navigator.pop(context, true), child: const Text('Cash given')),
                                    ],
                                  ),
                                );
                                if (ok != true) return;
                                try {
                                  await ref.read(resaleRepositoryProvider).markCashPaid(p.saleId);
                                  ref.invalidate(cashDueProvider);
                                } catch (err) {
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
                                }
                              },
                              icon: const Icon(Icons.payments_outlined, size: 18),
                              label: const Text('Mark as paid'),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                ]),
        ),
      ),
    );
  }
}
