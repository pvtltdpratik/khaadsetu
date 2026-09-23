import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../farmer/marketplace/domain/entities/product.dart';
import '../../../../farmer/marketplace/presentation/providers/marketplace_providers.dart';
import '../../domain/entities/inventory_item.dart';
import '../providers/inventory_providers.dart';

/// Adds stock that has just arrived. For a product already on the shelf pass
/// [item]; without one the operator picks any product from the catalog, which
/// is how a product is put on the shelf the first time.
///
/// If the physical count is not what was expected, the operator can say so and
/// the difference goes to the platform's supply team; the shelf still gets
/// exactly what was counted.
class ReceiveStockSheet extends ConsumerStatefulWidget {
  const ReceiveStockSheet({super.key, this.item});

  final InventoryItem? item;

  @override
  ConsumerState<ReceiveStockSheet> createState() => _ReceiveStockSheetState();
}

class _ReceiveStockSheetState extends ConsumerState<ReceiveStockSheet> {
  final _quantity = TextEditingController();
  final _expected = TextEditingController();
  final _note = TextEditingController();
  Product? _product;
  bool _mismatch = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _expected.dispose();
    _note.dispose();
    super.dispose();
  }

  String? get _productId => widget.item?.id ?? _product?.id;

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _submit() async {
    final qty = _int(_quantity);
    final expected = _mismatch ? _int(_expected) : null;
    String? problem;
    if (_productId == null) {
      problem = 'Choose a product.';
    } else if (qty == null || qty < 1) {
      problem = 'Enter how many arrived (at least 1).';
    } else if (_mismatch && (expected == null || expected < 0)) {
      problem = 'Enter how many you expected.';
    } else if (_mismatch && expected == qty) {
      problem = 'The expected and counted numbers are the same, so there is nothing to report.';
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
      final result = await ref.read(inventoryRepositoryProvider).receiveStock(
            productId: _productId!,
            quantity: qty!,
            expectedQuantity: expected,
            note: _mismatch ? _note.text : null,
          );
      ref
        ..invalidate(inventoryItemsProvider)
        ..invalidate(restockRequestsProvider);
      if (mounted) Navigator.of(context).pop(result);
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
    final item = widget.item;
    final catalog = ref.watch(productsProvider);
    final unit = item?.unit ?? _product?.unitLabel;

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
          Text('Receive stock', style: text.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            item == null ? 'Add a delivery to your shelves.' : '${item.name}: ${item.currentStock} on hand now',
            style: text.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          AppSpacing.gapMd,
          if (item == null)
            catalog.when(
              data: (products) => DropdownButtonFormField<Product>(
                initialValue: _product,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Product'),
                items: [for (final p in products) DropdownMenuItem(value: p, child: Text('${p.name} (${p.unitLabel})', overflow: TextOverflow.ellipsis))],
                onChanged: _submitting ? null : (p) => setState(() => _product = p),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Could not load the product list: $err', style: TextStyle(color: colors.danger)),
            ),
          if (item == null) AppSpacing.gapMd,
          TextField(
            controller: _quantity,
            enabled: !_submitting,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: 'How many arrived', suffixText: unit),
          ),
          AppSpacing.gapSm,
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _mismatch,
            onChanged: _submitting ? null : (v) => setState(() => _mismatch = v ?? false),
            title: const Text('The count is not what I expected'),
            subtitle: const Text('Report it to the supply team'),
          ),
          if (_mismatch) ...[
            TextField(
              controller: _expected,
              enabled: !_submitting,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'How many you expected'),
            ),
            AppSpacing.gapSm,
            TextField(
              controller: _note,
              enabled: !_submitting,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'What happened (optional)', hintText: 'e.g. 2 bags were torn'),
            ),
          ],
          if (_error != null) ...[
            AppSpacing.gapSm,
            Text(_error!, style: text.bodySmall?.copyWith(color: colors.danger)),
          ],
          AppSpacing.gapMd,
          AppButton(label: 'Add to stock', icon: Icons.add_box_outlined, expand: true, isLoading: _submitting, onPressed: _submit),
        ],
      ),
    );
  }
}
