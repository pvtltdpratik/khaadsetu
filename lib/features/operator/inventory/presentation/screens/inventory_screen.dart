import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/responsive/responsive_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';
import '../providers/inventory_providers.dart';
import '../widgets/restock_request_sheet.dart';
import '../widgets/stock_level_indicator.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final requestsAsync = ref.watch(restockRequestsProvider);

    return ResponsiveScope(
      child: SafeArea(
        child: ListView(
          padding: context.pagePadding,
          children: [
            Text('Inventory', style: Theme.of(context).textTheme.headlineSmall),
            AppSpacing.gapLg,
            requestsAsync.when(
              data: (requests) {
                final pending = requests.where((r) => r.status != RestockRequestStatus.fulfilled).toList();
                if (pending.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending restock requests', style: Theme.of(context).textTheme.titleMedium),
                    AppSpacing.gapSm,
                    for (final request in pending) ...[
                      _RestockRequestTile(request: request),
                      AppSpacing.gapSm,
                    ],
                    AppSpacing.gapMd,
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            itemsAsync.when(
              data: (items) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.responsive(mobile: 1, tablet: 2),
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: context.responsive(mobile: 3.0, tablet: 2.4),
                ),
                itemBuilder: (context, i) => _InventoryTile(item: items[i]),
              ),
              loading: () => const AppLoadingIndicator(),
              error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(inventoryItemsProvider)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          StockLevelIndicator(item: item),
          AppSpacing.gapSm,
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_box_outlined, size: 18),
              label: const Text('Request restock'),
              onPressed: () => showAdaptiveModal<void>(
                context: context,
                builder: (context) => RestockRequestSheet(item: item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestockRequestTile extends StatelessWidget {
  const _RestockRequestTile({required this.request});

  final RestockRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (request.status) {
      RestockRequestStatus.pending => colors.warning,
      RestockRequestStatus.approved => colors.info,
      RestockRequestStatus.fulfilled => colors.success,
    };
    final label = switch (request.status) {
      RestockRequestStatus.pending => 'Pending',
      RestockRequestStatus.approved => 'Approved',
      RestockRequestStatus.fulfilled => 'Fulfilled',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${request.itemName} × ${request.requestedQuantity}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
            child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
