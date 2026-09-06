import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/responsive/responsive_layout.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/price_format.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../inventory/domain/entities/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_providers.dart';

/// A real point-of-sale layout on tablet/desktop — item grid alongside a
/// fixed cart panel, the way an actual till works — collapsing to a stacked
/// list + cart-summary card on mobile.
class WalkInPosScreen extends ConsumerStatefulWidget {
  const WalkInPosScreen({super.key});

  @override
  ConsumerState<WalkInPosScreen> createState() => _WalkInPosScreenState();
}

class _WalkInPosScreenState extends ConsumerState<WalkInPosScreen> {
  final Map<String, int> _cart = {}; // itemId -> quantity
  final _customerNameController = TextEditingController();
  bool _isCheckingOut = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }

  void _changeQuantity(String itemId, int delta) {
    setState(() {
      final next = (_cart[itemId] ?? 0) + delta;
      if (next <= 0) {
        _cart.remove(itemId);
      } else {
        _cart[itemId] = next;
      }
    });
  }

  Future<void> _checkout(List<InventoryItem> items) async {
    setState(() => _isCheckingOut = true);
    try {
      final lineItems = _cart.entries.map((entry) {
        final item = items.firstWhere((i) => i.id == entry.key);
        return OrderLineItem(productName: item.name, quantity: entry.value, unitPrice: item.unitPrice);
      }).toList();
      final order = await ref.read(ordersRepositoryProvider).createWalkInOrder(
            customerName: _customerNameController.text.trim().isEmpty
                ? 'Walk-in customer'
                : _customerNameController.text.trim(),
            items: lineItems,
          );
      ref.invalidate(ordersProvider);
      if (!mounted) return;
      context.pushReplacement(RoutePaths.operatorOrderDetail(order.id));
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return ResponsiveScope(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go(RoutePaths.operatorOrders),
                  ),
                  AppSpacing.gapSm,
                  Text('New Walk-in Sale', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: itemsAsync.when(
                data: (items) => SingleChildScrollView(
                  padding: context.pagePadding,
                  child: ResponsiveRow(
                    spacing: AppSpacing.md,
                    flexes: const [2, 1],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ItemGrid(items: items, cart: _cart, onChangeQuantity: _changeQuantity),
                      _CartPanel(
                        items: items,
                        cart: _cart,
                        customerNameController: _customerNameController,
                        isCheckingOut: _isCheckingOut,
                        onCheckout: () => _checkout(items),
                      ),
                    ],
                  ),
                ),
                loading: () => const AppLoadingIndicator(),
                error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(inventoryItemsProvider)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items, required this.cart, required this.onChangeQuantity});

  final List<InventoryItem> items;
  final Map<String, int> cart;
  final void Function(String itemId, int delta) onChangeQuantity;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.responsive(mobile: 1, tablet: 2),
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: context.responsive(mobile: 3.6, tablet: 2.2),
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        final qty = cart[item.id] ?? 0;
        final colors = context.colors;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.name, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${formatRupees(item.unitPrice)} / ${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: qty > 0 ? () => onChangeQuantity(item.id, -1) : null,
              ),
              Text('$qty', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () => onChangeQuantity(item.id, 1),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.items,
    required this.cart,
    required this.customerNameController,
    required this.isCheckingOut,
    required this.onCheckout,
  });

  final List<InventoryItem> items;
  final Map<String, int> cart;
  final TextEditingController customerNameController;
  final bool isCheckingOut;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cartItems = cart.entries.map((e) => (items.firstWhere((i) => i.id == e.key), e.value)).toList();
    final total = cartItems.fold<double>(0, (sum, e) => sum + e.$1.unitPrice * e.$2);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sale summary', style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.gapSm,
          TextField(
            controller: customerNameController,
            decoration: const InputDecoration(
              hintText: 'Customer name (optional)',
              isDense: true,
            ),
          ),
          AppSpacing.gapMd,
          if (cartItems.isEmpty)
            Text('No items added yet', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted))
          else
            for (final (item, qty) in cartItems)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name} × $qty',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(formatRupees(item.unitPrice * qty), style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
          const Divider(),
          Row(
            children: [
              Expanded(child: Text('Total', style: Theme.of(context).textTheme.titleMedium)),
              Text(formatRupees(total), style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          AppSpacing.gapMd,
          AppButton(
            label: 'Complete sale',
            icon: Icons.point_of_sale_rounded,
            expand: true,
            isLoading: isCheckingOut,
            onPressed: cartItems.isEmpty ? null : onCheckout,
          ),
        ],
      ),
    );
  }
}
