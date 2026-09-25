import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/animation/fade_slide_in.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/responsive/responsive_layout.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../surplus/presentation/widgets/create_surplus_sheet.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/restock_request.dart';
import '../providers/inventory_providers.dart';
import '../widgets/item_settings_sheet.dart';
import '../widgets/receive_stock_sheet.dart';
import '../widgets/restock_request_sheet.dart';
import '../widgets/stock_level_indicator.dart';

/// Opens the receive-stock sheet and reports what happened.
Future<void> showReceiveStock(BuildContext context, {InventoryItem? item}) async {
  final result = await showAdaptiveModal<ReceiveResult>(context: context, builder: (context) => ReceiveStockSheet(item: item));
  if (result == null || !context.mounted) return;
  final d = result.discrepancy;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(d == null
        ? '${result.item.name} stock is now ${result.item.currentStock}'
        : 'Added to stock. Reported: expected ${d.expected}, counted ${d.received}. The supply team will review it.'),
  ));
}

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final requestsAsync = ref.watch(restockRequestsProvider);

    return ResponsiveScope(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(inventoryItemsProvider)
              ..invalidate(restockRequestsProvider);
            await ref.read(inventoryItemsProvider.future);
          },
          child: ListView(
            padding: context.pagePadding,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Inventory', style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton(
                    key: const Key('farmer-resale'),
                    tooltip: 'Farmer resale',
                    icon: const Icon(Icons.recycling_outlined),
                    onPressed: () => context.go(RoutePaths.operatorResale),
                  ),
                  IconButton(
                    tooltip: 'Surplus stock',
                    icon: const Icon(Icons.sell_outlined),
                    onPressed: () => context.go(RoutePaths.operatorSurplus),
                  ),
                  FilledButton.icon(
                    onPressed: () => showReceiveStock(context),
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Receive stock'),
                  ),
                ],
              ),
              AppSpacing.gapLg,
              requestsAsync.when(
                data: (requests) {
                  final open = requests.where((r) => r.status != RestockRequestStatus.fulfilled).toList();
                  if (open.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Restock requests', style: Theme.of(context).textTheme.titleMedium),
                      AppSpacing.gapSm,
                      for (final request in open) ...[
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
                data: (items) => items.isEmpty ? const _EmptyShelves() : _Items(items: items),
                loading: () => const AppLoadingIndicator(),
                error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(inventoryItemsProvider)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two columns on wider screens. Tiles size to their content (no fixed aspect
/// ratio), so nothing can overflow however much a tile has to say.
class _Items extends StatelessWidget {
  const _Items({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    // Low stock first: those are what needs attention.
    final sorted = [...items]..sort((a, b) => (b.isLowStock ? 1 : 0) - (a.isLowStock ? 1 : 0));
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = context.breakpoint.isTabletUp ? 2 : 1;
        final width = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (i, item) in sorted.indexed)
              SizedBox(width: width, child: FadeSlideIn(key: ValueKey(item.id), index: i, child: _InventoryTile(item: item))),
          ],
        );
      },
    );
  }
}

class _EmptyShelves extends StatelessWidget {
  const _EmptyShelves();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: colors.textMuted),
          AppSpacing.gapMd,
          Text('Your shelves are empty', style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.gapXs,
          Text(
            'Receive your first delivery to start selling. Farmers can only order what is on your shelves.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          AppSpacing.gapMd,
          FilledButton.icon(
            onPressed: () => showReceiveStock(context),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Receive stock'),
          ),
        ],
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
      decoration: BoxDecoration(
        border: Border.all(color: item.isLowStock ? colors.danger.withValues(alpha: 0.5) : colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.name, style: Theme.of(context).textTheme.titleSmall)),
              IconButton(
                tooltip: 'Reorder level and capacity',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.tune_rounded, size: 20),
                onPressed: () => showAdaptiveModal<bool>(context: context, builder: (context) => ItemSettingsSheet(item: item)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          StockLevelIndicator(item: item),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_box_outlined, size: 18),
                label: const Text('Receive'),
                onPressed: () => showReceiveStock(context, item: item),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('Request restock'),
                onPressed: () => showAdaptiveModal<void>(context: context, builder: (context) => RestockRequestSheet(item: item)),
              ),
              if (item.available > 0)
                TextButton.icon(
                  icon: const Icon(Icons.sell_outlined, size: 18),
                  label: const Text('Sell as surplus'),
                  onPressed: () => showAdaptiveModal<void>(context: context, builder: (context) => CreateSurplusSheet(shelfItem: item)),
                ),
            ],
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
      RestockRequestStatus.pending => 'Waiting for approval',
      RestockRequestStatus.approved => 'Approved, on its way',
      RestockRequestStatus.fulfilled => 'Delivered',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(child: Text('${request.itemName} × ${request.requestedQuantity}', style: Theme.of(context).textTheme.bodyMedium)),
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
