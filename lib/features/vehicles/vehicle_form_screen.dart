import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';
import 'vehicle_api.dart';

/// Adds a vehicle, or changes one that is not being checked. Choosing a model from the list fills in the company, the
/// fuel and the kind; the owner still gives the plate and the load he actually carries.
class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.existing});

  final Json? existing;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _key = GlobalKey<FormState>();
  late final _plate = TextEditingController(text: widget.existing?.str('registrationNumber'));
  late final _capacity = TextEditingController(text: widget.existing == null ? '' : '${widget.existing!.int_('capacityKg')}');
  late final _company = TextEditingController(text: widget.existing?.str('company'));
  late final _model = TextEditingController(text: widget.existing?.str('modelName'));
  late final _year = TextEditingController(text: widget.existing?.str('makeYear'));
  late final _cost = TextEditingController(text: widget.existing?.str('runningCostPerKm'));
  late final _driver = TextEditingController(text: widget.existing?.str('driverName'));
  late final _driverPhone = TextEditingController(text: widget.existing?.str('driverPhone'));
  late final _licence = TextEditingController(text: widget.existing?.str('driverLicence'));
  String? _category;
  String? _modelId;
  String? _body;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.str('categoryId');
    _modelId = widget.existing?['modelId'] as String?;
    final body = widget.existing?.str('bodyType') ?? '';
    _body = body.isEmpty ? null : body;
  }

  @override
  void dispose() {
    for (final c in [_plate, _capacity, _company, _model, _year, _cost, _driver, _driverPhone, _licence]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    if (_category == null) {
      snack(context, 'Choose the kind of vehicle');
      return;
    }
    setState(() => _busy = true);
    final body = <String, dynamic>{
      'categoryId': _category,
      'modelId': _modelId,
      'registrationNumber': _plate.text.trim(),
      'capacityKg': int.parse(_capacity.text.trim()),
      if (_company.text.trim().isNotEmpty) 'company': _company.text.trim(),
      if (_model.text.trim().isNotEmpty) 'modelName': _model.text.trim(),
      if (int.tryParse(_year.text.trim()) != null) 'makeYear': int.parse(_year.text.trim()),
      'bodyType': ?_body,
      'runningCostPerKm': double.tryParse(_cost.text.trim()),
      if (_driver.text.trim().isNotEmpty) 'driverName': _driver.text.trim(),
      if (_driverPhone.text.trim().isNotEmpty) 'driverPhone': _driverPhone.text.trim(),
      if (_licence.text.trim().isNotEmpty) 'driverLicence': _licence.text.trim(),
    };
    try {
      final api = ref.read(vehicleApiProvider);
      final saved = widget.existing == null ? await api.create(body) : await api.update(widget.existing!.str('id'), body);
      if (mounted) Navigator.of(context).pop(saved.str('id'));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(vehicleCatalogProvider);
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add a vehicle' : 'Change vehicle')),
      body: ResponsiveScope(
        child: catalog.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(vehicleCatalogProvider)),
          data: (c) {
            final categories = c.list('categories');
            final models = c.list('models').where((m) => _category == null || m.str('categoryId') == _category).toList();
            final selected = categories.where((k) => k.str('id') == _category).firstOrNull;
            return Form(
              key: _key,
              child: ListView(padding: context.pagePadding, children: [
                DropdownButtonFormField<String>(
                  key: const Key('vehicle-category'),
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Kind of vehicle'),
                  items: [for (final k in categories) DropdownMenuItem(value: k.str('id'), child: Text(k.str('label')))],
                  onChanged: (v) => setState(() {
                    _category = v;
                    _modelId = null;
                  }),
                ),
                if (selected != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Usually up to ${selected.int_('furthestKm')} km per delivery'
                      '${selected.flag('needsPermit') ? '. Needs a permit' : ''}${selected.flag('needsFitness') ? ' and a fitness certificate' : ''}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ),
                AppSpacing.gapMd,
                if (models.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    key: const Key('vehicle-model'),
                    initialValue: models.any((m) => m.str('id') == _modelId) ? _modelId : null,
                    decoration: const InputDecoration(labelText: 'Model (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Other / not in the list')),
                      for (final m in models) DropdownMenuItem<String?>(value: m.str('id'), child: Text('${m.str('company')} ${m.str('model')}')),
                    ],
                    onChanged: (v) => setState(() {
                      _modelId = v;
                      final m = models.where((x) => x.str('id') == v).firstOrNull;
                      if (m != null) {
                        _company.text = m.str('company');
                        _model.text = m.str('model');
                        if (_capacity.text.isEmpty && m.num_('payloadKg') > 0) _capacity.text = '${m.int_('payloadKg')}';
                      }
                    }),
                  ),
                if (models.isNotEmpty) AppSpacing.gapMd,
                TextFormField(
                  key: const Key('vehicle-plate'),
                  controller: _plate,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Registration number', hintText: 'MH12AB1234'),
                  validator: (v) => (v ?? '').trim().length < 4 ? 'Enter the number on the plate' : null,
                ),
                AppSpacing.gapMd,
                TextFormField(
                  key: const Key('vehicle-capacity'),
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Load it carries (kg)'),
                  validator: (v) => (int.tryParse((v ?? '').trim()) ?? 0) < 1 ? 'Enter the load in kg' : null,
                ),
                AppSpacing.gapMd,
                Row(children: [
                  Expanded(child: TextFormField(controller: _company, decoration: const InputDecoration(labelText: 'Company'))),
                  AppSpacing.gapSm,
                  Expanded(child: TextFormField(controller: _model, decoration: const InputDecoration(labelText: 'Model name'))),
                ]),
                AppSpacing.gapMd,
                Row(children: [
                  Expanded(child: TextFormField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year made'))),
                  AppSpacing.gapSm,
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _body,
                      decoration: const InputDecoration(labelText: 'Body'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('—')),
                        DropdownMenuItem(value: 'open', child: Text('Open')),
                        DropdownMenuItem(value: 'closed', child: Text('Closed')),
                        DropdownMenuItem(value: 'trolley', child: Text('Trolley')),
                      ],
                      onChanged: (v) => setState(() => _body = v),
                    ),
                  ),
                ]),
                AppSpacing.gapMd,
                TextFormField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Running cost per km (₹, optional)',
                    helperText: selected != null && selected.num_('runningCostPerKm') > 0 ? 'If you leave it empty, ₹${selected.num_('runningCostPerKm').toStringAsFixed(0)} per km is used' : null,
                  ),
                ),
                AppSpacing.gapLg,
                Text('Driver (if someone else drives)', style: Theme.of(context).textTheme.titleSmall),
                AppSpacing.gapSm,
                TextFormField(controller: _driver, decoration: const InputDecoration(labelText: 'Driver name')),
                AppSpacing.gapSm,
                TextFormField(controller: _driverPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Driver phone')),
                AppSpacing.gapSm,
                TextFormField(controller: _licence, decoration: const InputDecoration(labelText: 'Licence number')),
                AppSpacing.gapLg,
                AppButton(key: const Key('vehicle-save'), label: 'Save', expand: true, isLoading: _busy, onPressed: _save),
              ]),
            );
          },
        ),
      ),
    );
  }
}
