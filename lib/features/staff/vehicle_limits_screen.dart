import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';

final vehicleCategoriesProvider = FutureProvider.autoDispose<List<Json>>((ref) async => asJsonList(await ref.watch(apiClientProvider).get('/v1/admin/vehicles/categories')));

/// How far each kind of vehicle may go for one delivery, and what it costs to run. The starting numbers are guesses
/// (only the heavy truck's 1000 km is fixed), so the admin sets them here once they are known.
class VehicleLimitsScreen extends ConsumerWidget {
  const VehicleLimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(vehicleCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle limits')),
      body: ResponsiveScope(
        child: data.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(vehicleCategoriesProvider)),
          data: (list) => ListView(padding: context.pagePadding, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('Up to the normal distance a partner just accepts. Beyond it, up to the furthest distance, the pickup center must approve.', style: Theme.of(context).textTheme.bodySmall),
            ),
            for (final (i, c) in list.indexed)
              KitCard(
                index: i,
                onTap: () async {
                  final saved = await showDialog<bool>(context: context, builder: (_) => _EditDialog(category: c));
                  if (saved == true) ref.invalidate(vehicleCategoriesProvider);
                },
                title: c.str('label'),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                child: Column(children: [
                  KitRow('Normal distance', '${c.int_('normalDistanceKm')} km'),
                  KitRow('Furthest distance', c['maxDistanceKm'] == null ? 'Same as normal' : '${c.int_('maxDistanceKm')} km'),
                  KitRow('Running cost', c['runningCostPerKm'] == null ? 'Not set' : '₹${c.num_('runningCostPerKm').toStringAsFixed(0)} per km'),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

class _EditDialog extends ConsumerStatefulWidget {
  const _EditDialog({required this.category});

  final Json category;

  @override
  ConsumerState<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends ConsumerState<_EditDialog> {
  late final _normal = TextEditingController(text: '${widget.category.int_('normalDistanceKm')}');
  late final _max = TextEditingController(text: widget.category['maxDistanceKm'] == null ? '' : '${widget.category.int_('maxDistanceKm')}');
  late final _cost = TextEditingController(text: widget.category['runningCostPerKm'] == null ? '' : widget.category.num_('runningCostPerKm').toStringAsFixed(0));
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_normal, _max, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).put('/v1/admin/vehicles/categories/${Uri.encodeComponent(widget.category.str('id'))}', body: {
        'normalDistanceKm': int.tryParse(_normal.text.trim()),
        'maxDistanceKm': _max.text.trim().isEmpty ? null : int.tryParse(_max.text.trim()),
        'runningCostPerKm': _cost.text.trim().isEmpty ? null : double.tryParse(_cost.text.trim()),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.category.str('label')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(key: const Key('limit-normal'), controller: _normal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Normal distance (km)')),
          TextField(key: const Key('limit-max'), controller: _max, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Furthest distance (km)', helperText: 'Empty = same as normal')),
          TextField(key: const Key('limit-cost'), controller: _cost, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Running cost per km (₹)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          AppButton(key: const Key('limit-save'), label: 'Save', isLoading: _busy, onPressed: _save),
        ],
      );
}
