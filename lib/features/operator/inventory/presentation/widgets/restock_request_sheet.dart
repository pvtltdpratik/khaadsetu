import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../domain/entities/inventory_item.dart';
import '../providers/inventory_providers.dart';

/// Bottom sheet (mobile) / dialog (tablet+) for requesting a restock —
/// opened via `showAdaptiveModal` from the inventory screen.
class RestockRequestSheet extends ConsumerStatefulWidget {
  const RestockRequestSheet({super.key, required this.item});

  final InventoryItem item;

  @override
  ConsumerState<RestockRequestSheet> createState() => _RestockRequestSheetState();
}

class _RestockRequestSheetState extends ConsumerState<RestockRequestSheet> {
  int _quantity = 20;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(inventoryRepositoryProvider).requestRestock(
            itemId: widget.item.id,
            quantity: _quantity,
          );
      ref.invalidate(restockRequestsProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request restock', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${widget.item.name} — currently ${widget.item.currentStock} ${widget.item.unit}s',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          AppSpacing.gapLg,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: _quantity > 10 ? () => setState(() => _quantity -= 10) : null,
              ),
              SizedBox(
                width: 100,
                child: Text(
                  '$_quantity ${widget.item.unit}s',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () => setState(() => _quantity += 10),
              ),
            ],
          ),
          AppSpacing.gapLg,
          AppButton(
            label: 'Submit request',
            icon: Icons.send_outlined,
            expand: true,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
