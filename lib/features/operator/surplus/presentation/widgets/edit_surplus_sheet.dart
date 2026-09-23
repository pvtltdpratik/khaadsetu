import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../domain/entities/surplus_lot.dart';
import '../providers/surplus_providers.dart';

/// Changes a lot's price and note. The units themselves change by selling or
/// withdrawing, so they are not editable here.
class EditSurplusSheet extends ConsumerStatefulWidget {
  const EditSurplusSheet({super.key, required this.lot});

  final SurplusLot lot;

  @override
  ConsumerState<EditSurplusSheet> createState() => _EditSurplusSheetState();
}

class _EditSurplusSheetState extends ConsumerState<EditSurplusSheet> {
  late final _price = TextEditingController(text: widget.lot.unitPrice == widget.lot.unitPrice.roundToDouble() ? widget.lot.unitPrice.toStringAsFixed(0) : '${widget.lot.unitPrice}');
  late final _note = TextEditingController(text: widget.lot.note);
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final price = double.tryParse(_price.text.trim());
    if (price == null || price < 0) {
      setState(() => _error = 'Enter the surplus price per unit.');
      return;
    }
    if (price >= widget.lot.catalogPrice) {
      setState(() => _error = 'The surplus price must be lower than the regular price (Rs ${widget.lot.catalogPrice.toStringAsFixed(0)}).');
      return;
    }
    final priceChanged = price != widget.lot.unitPrice;
    final noteChanged = _note.text.trim() != widget.lot.note;
    if (!priceChanged && !noteChanged) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final lot = await ref.read(surplusRepositoryProvider).update(
            widget.lot.id,
            unitPrice: priceChanged ? price : null,
            note: noteChanged ? _note.text : null,
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
          Text('Edit surplus offer', style: text.titleLarge),
          Text(widget.lot.productName, style: text.bodyMedium?.copyWith(color: colors.textMuted)),
          AppSpacing.gapMd,
          TextField(
            controller: _price,
            enabled: !_submitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(labelText: 'Price each (Rs)', helperText: 'Regular: Rs ${widget.lot.catalogPrice.toStringAsFixed(0)}'),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _note,
            enabled: !_submitting,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'Note for farmers'),
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
