import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../farmer/marketplace/domain/entities/product.dart';
import '../../../../farmer/marketplace/presentation/providers/marketplace_providers.dart';
import '../../../inventory/domain/entities/inventory_item.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/entities/surplus_lot.dart';
import '../providers/surplus_providers.dart';

/// What is wrong with a new lot, or null when it is fine. Kept apart from the
/// widget so the rules are easy to test; the server checks them all again.
String? surplusProblem({
  required bool hasProduct,
  required int? quantity,
  required double? price,
  required double? catalogPrice,
  required bool fromShelf,
  required int shelfAvailable,
}) {
  if (!hasProduct) return 'Choose a product.';
  if (quantity == null || quantity < 1) return 'Enter how many units (at least 1).';
  if (fromShelf && quantity > shelfAvailable) {
    return shelfAvailable == 0
        ? 'None of this product is free on your shelf right now.'
        : 'Only $shelfAvailable are free on your shelf (the rest are reserved for orders).';
  }
  if (price == null || price < 0) return 'Enter the surplus price per unit.';
  if (catalogPrice != null && price >= catalogPrice) {
    return 'The surplus price must be lower than the regular price (Rs ${_money(catalogPrice)}).';
  }
  return null;
}

String _money(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

/// Lists units for sale below the regular price. Pass [shelfItem] to start from
/// a product already on the shelf (the "take from my shelf" switch is then on).
class CreateSurplusSheet extends ConsumerStatefulWidget {
  const CreateSurplusSheet({super.key, this.shelfItem});

  final InventoryItem? shelfItem;

  @override
  ConsumerState<CreateSurplusSheet> createState() => _CreateSurplusSheetState();
}

class _CreateSurplusSheetState extends ConsumerState<CreateSurplusSheet> {
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _note = TextEditingController();
  Product? _product;
  SurplusCondition _condition = SurplusCondition.nearExpiry;
  DateTime? _bestBefore;
  late bool _fromShelf = widget.shelfItem != null;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  String? get _productId => widget.shelfItem?.id ?? _product?.id;
  double? get _catalogPrice => widget.shelfItem?.unitPrice ?? _product?.priceInRupees;
  String? get _unit => widget.shelfItem?.unit ?? _product?.unitLabel;

  int _shelfAvailable(List<InventoryItem>? shelf) {
    final id = _productId;
    if (id == null || shelf == null) return 0;
    return shelf.where((i) => i.id == id).firstOrNull?.available ?? 0;
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _bestBefore ?? today.add(const Duration(days: 30)),
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _bestBefore = picked);
  }

  Future<void> _submit(List<InventoryItem>? shelf) async {
    final quantity = int.tryParse(_quantity.text.trim());
    final price = double.tryParse(_price.text.trim());
    final problem = surplusProblem(
      hasProduct: _productId != null,
      quantity: quantity,
      price: price,
      catalogPrice: _catalogPrice,
      fromShelf: _fromShelf,
      shelfAvailable: _shelfAvailable(shelf),
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final lot = await ref.read(surplusRepositoryProvider).create(
            productId: _productId!,
            quantity: quantity!,
            unitPrice: price!,
            condition: _condition,
            bestBefore: _bestBefore,
            note: _note.text,
            fromShelf: _fromShelf,
          );
      refreshSurplus(ref);
      if (mounted) Navigator.of(context).pop(lot);
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
    final catalog = widget.shelfItem == null ? ref.watch(productsProvider) : null;
    final shelf = ref.watch(inventoryItemsProvider).asData?.value;
    final shelfFree = _shelfAvailable(shelf);
    final catalogPrice = _catalogPrice;

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
          Text('Sell as surplus', style: text.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Near-expiry, opened, returned or damaged-pack units, at a lower price. Farmers nearby see them marked down.',
            style: text.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          AppSpacing.gapMd,
          if (widget.shelfItem != null)
            Text(widget.shelfItem!.name, style: text.titleSmall)
          else
            catalog!.when(
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
          AppSpacing.gapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  enabled: !_submitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: 'How many', suffixText: _unit),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _price,
                  enabled: !_submitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: InputDecoration(
                    labelText: 'Price each (Rs)',
                    helperText: catalogPrice == null ? null : 'Regular: Rs ${_money(catalogPrice)}',
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          DropdownButtonFormField<SurplusCondition>(
            initialValue: _condition,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Why is it cheaper'),
            items: [for (final c in SurplusCondition.forCenters) DropdownMenuItem(value: c, child: Text(c.label))],
            onChanged: _submitting ? null : (c) => setState(() => _condition = c ?? _condition),
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              Expanded(
                child: Text(
                  _bestBefore == null ? 'Best before: not set' : 'Best before: ${_bestBefore!.day}/${_bestBefore!.month}/${_bestBefore!.year}',
                  style: text.bodyMedium,
                ),
              ),
              TextButton(onPressed: _submitting ? null : _pickDate, child: Text(_bestBefore == null ? 'Set date' : 'Change')),
              if (_bestBefore != null) IconButton(tooltip: 'Clear date', onPressed: () => setState(() => _bestBefore = null), icon: const Icon(Icons.close_rounded, size: 18)),
            ],
          ),
          TextField(
            controller: _note,
            enabled: !_submitting,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'Note for farmers (optional)', hintText: 'e.g. 2 bags have torn stitching'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _fromShelf,
            onChanged: _submitting ? null : (v) => setState(() => _fromShelf = v),
            title: const Text('Take these from my shelf'),
            subtitle: Text(
              _productId == null
                  ? 'Off means these are extra units from outside your deliveries.'
                  : _fromShelf
                      ? '$shelfFree free on your shelf now. They come off the shelf and go back if you withdraw the offer.'
                      : 'Off: extra units from outside your deliveries. Your shelf is not changed.',
            ),
          ),
          if (_error != null) ...[
            AppSpacing.gapSm,
            Text(_error!, style: text.bodySmall?.copyWith(color: colors.danger)),
          ],
          AppSpacing.gapMd,
          AppButton(label: 'List surplus', icon: Icons.sell_outlined, expand: true, isLoading: _submitting, onPressed: () => _submit(shelf)),
        ],
      ),
    );
  }
}
