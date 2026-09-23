import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Registers a new village center. The coordinates matter: they decide which
/// farmers see this center, so the village search fills them in and they can
/// still be corrected by hand.
class CreateCenterScreen extends ConsumerStatefulWidget {
  const CreateCenterScreen({super.key});

  @override
  ConsumerState<CreateCenterScreen> createState() => _CreateCenterScreenState();
}

class _CreateCenterScreenState extends ConsumerState<CreateCenterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _village = TextEditingController();
  final _district = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _phone = TextEditingController();
  TimeOfDay _opens = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closes = const TimeOfDay(hour: 18, minute: 0);
  AdminUser? _operator;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_name, _village, _district, _latitude, _longitude, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String? _coordinate(String? v, String name, double min, double max) {
    final value = double.tryParse((v ?? '').trim());
    if (value == null) return 'Enter the $name as a number';
    if (value < min || value > max) return '$name must be between $min and $max';
    return null;
  }

  Future<void> _pickTime(bool opening) async {
    final picked = await showTimePicker(context: context, initialTime: opening ? _opens : _closes);
    if (picked != null) setState(() => opening ? _opens = picked : _closes = picked);
  }

  Future<void> _chooseOperator() async {
    final operators = await ref.read(adminRepositoryProvider).users(role: PersonRole.operator, segment: PersonSegment.unassigned);
    if (!mounted) return;
    final picked = await pickOne<AdminUser>(
      context,
      title: 'Choose an operator',
      options: operators,
      titleOf: (u) => u.displayName,
      subtitleOf: (u) => u.email,
      emptyMessage: 'No operators are waiting for a center. You can assign one later.',
    );
    if (picked != null) setState(() => _operator = picked);
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if ((_closes.hour * 60 + _closes.minute) <= (_opens.hour * 60 + _opens.minute)) {
      showMessage(context, 'Closing time must be after opening time');
      return;
    }
    setState(() => _submitting = true);
    try {
      final created = await ref.read(adminRepositoryProvider).createCenter(
            name: _name.text,
            village: _village.text,
            district: _district.text,
            latitude: double.parse(_latitude.text.trim()),
            longitude: double.parse(_longitude.text.trim()),
            phone: _phone.text,
            operatorName: _operator?.displayName,
            operatorId: _operator?.userId,
            opensAt: _hhmm(_opens),
            closesAt: _hhmm(_closes),
          );
      refreshAdminData(ref);
      if (!mounted) return;
      showMessage(context, '${created.name} created');
      context.pushReplacement(RoutePaths.adminCenter(created.centerId));
    } catch (err) {
      if (mounted) {
        setState(() => _submitting = false);
        showMessage(context, '$err');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.breakpoint.isTabletUp;
    Widget pair(Widget a, Widget b) => wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), AppSpacing.gapMd, Expanded(child: b)])
        : Column(children: [a, AppSpacing.gapMd, b]);

    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('New village center')),
        body: SafeArea(
          child: SingleChildScrollView(
            child: ContentContainer(
              maxWidth: 720,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      enabled: !_submitting,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Center name', hintText: 'e.g. Krishi Seva Kendra'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
                    ),
                    AppSpacing.gapMd,
                    _VillageField(
                      controller: _village,
                      enabled: !_submitting,
                      onPicked: (v) => setState(() {
                        _village.text = v.name;
                        _district.text = v.district;
                        _latitude.text = v.latitude.toString();
                        _longitude.text = v.longitude.toString();
                      }),
                    ),
                    AppSpacing.gapMd,
                    TextFormField(controller: _district, enabled: !_submitting, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'District')),
                    AppSpacing.gapMd,
                    pair(
                      TextFormField(
                        controller: _latitude,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        validator: (v) => _coordinate(v, 'Latitude', -90, 90),
                      ),
                      TextFormField(
                        controller: _longitude,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Longitude'),
                        validator: (v) => _coordinate(v, 'Longitude', -180, 180),
                      ),
                    ),
                    AppSpacing.gapMd,
                    TextFormField(
                      controller: _phone,
                      enabled: !_submitting,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone (shown to farmers)'),
                    ),
                    AppSpacing.gapMd,
                    pair(
                      OutlinedButton.icon(onPressed: _submitting ? null : () => _pickTime(true), icon: const Icon(Icons.access_time_rounded), label: Text('Opens ${_hhmm(_opens)}')),
                      OutlinedButton.icon(onPressed: _submitting ? null : () => _pickTime(false), icon: const Icon(Icons.access_time_filled_rounded), label: Text('Closes ${_hhmm(_closes)}')),
                    ),
                    AppSpacing.gapMd,
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _chooseOperator,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(_operator == null ? 'Assign an operator (optional)' : 'Operator: ${_operator!.displayName}'),
                    ),
                    AppSpacing.gapLg,
                    AppButton(label: 'Create center', icon: Icons.add_location_alt_outlined, isLoading: _submitting, expand: true, onPressed: _submit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The village name, with suggestions from the built-in list that also fill in
/// the district and coordinates. Free text is still allowed.
class _VillageField extends ConsumerWidget {
  const _VillageField({required this.controller, required this.onPicked, required this.enabled});

  final TextEditingController controller;
  final ValueChanged<VillageOption> onPicked;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RawAutocomplete<VillageOption>(
      textEditingController: controller,
      focusNode: FocusNode(),
      displayStringForOption: (v) => v.name,
      optionsBuilder: (value) async {
        final q = value.text.trim();
        if (q.length < 2) return const [];
        try {
          return await ref.read(adminRepositoryProvider).searchVillages(q);
        } catch (_) {
          return const [];
        }
      },
      onSelected: onPicked,
      fieldViewBuilder: (context, textController, focusNode, onSubmit) => TextFormField(
        controller: textController,
        focusNode: focusNode,
        enabled: enabled,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Village', helperText: 'Pick a suggestion to fill in district and coordinates'),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a village' : null,
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final v in options) ListTile(dense: true, title: Text(v.name), subtitle: Text(v.district), onTap: () => onSelected(v)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
