import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../domain/entities/inventory_item.dart';
import '../providers/inventory_providers.dart';

/// The reorder level (when to be alerted) and storage capacity for one product.
class ItemSettingsSheet extends ConsumerStatefulWidget {
  const ItemSettingsSheet({super.key, required this.item});

  final InventoryItem item;

  @override
  ConsumerState<ItemSettingsSheet> createState() => _ItemSettingsSheetState();
}

class _ItemSettingsSheetState extends ConsumerState<ItemSettingsSheet> {
  late final _reorder = TextEditingController(text: '${widget.item.lowStockThreshold}');
  late final _capacity = TextEditingController(text: widget.item.maxCapacity?.toString() ?? '');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reorder.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reorder = int.tryParse(_reorder.text.trim());
    final capacityText = _capacity.text.trim();
    final capacity = capacityText.isEmpty ? null : int.tryParse(capacityText);
    String? problem;
    if (reorder == null || reorder < 0) {
      problem = 'Enter the reorder level (0 or more).';
    } else if (capacityText.isNotEmpty && (capacity == null || capacity < 1)) {
      problem = 'Capacity must be 1 or more, or left empty for no limit.';
    } else if (capacity != null && capacity < widget.item.currentStock) {
      problem = 'Capacity cannot be below the ${widget.item.currentStock} you have on hand.';
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(inventoryRepositoryProvider).updateSettings(
            productId: widget.item.id,
            reorderLevel: reorder,
            maxCapacity: capacity,
            clearCapacity: capacity == null && widget.item.maxCapacity != null,
          );
      ref.invalidate(inventoryItemsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      if (mounted) setState(() => _error = '$err');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
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
          Text('Stock settings', style: text.titleLarge),
          Text(widget.item.name, style: text.bodyMedium?.copyWith(color: colors.textMuted)),
          AppSpacing.gapMd,
          TextField(
            controller: _reorder,
            enabled: !_submitting,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Reorder level', helperText: 'You are alerted when stock to sell falls to this'),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _capacity,
            enabled: !_submitting,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Storage capacity (optional)', helperText: 'The most you can store; leave empty for no limit'),
          ),
          if (_error != null) ...[
            AppSpacing.gapSm,
            Text(_error!, style: text.bodySmall?.copyWith(color: colors.danger)),
          ],
          AppSpacing.gapMd,
          AppButton(label: 'Save', expand: true, isLoading: _submitting, onPressed: _submit),
        ],
      ),
    );
  }
}
