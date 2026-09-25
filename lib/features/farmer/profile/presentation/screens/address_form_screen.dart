import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/location/place_namer.dart';
import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../centers/domain/repositories/centers_repository.dart';
import '../../../centers/presentation/providers/centers_providers.dart';
import '../../domain/profile_models.dart';
import '../providers/profile_providers.dart';

final _phonePattern = RegExp(r'^\+?[0-9][0-9 -]{7,14}[0-9]$');
const _labels = ['Home', 'Farm', 'Work', 'Other'];

/// Adds an address, or edits [existing]. "Use my current location" reads the phone's GPS and
/// fills the pin and, where the phone can name the place, the village, district and PIN code.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  final SavedAddress? existing;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.fullName);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _line1 = TextEditingController(text: widget.existing?.line1);
  late final _line2 = TextEditingController(text: widget.existing?.line2);
  late final _landmark = TextEditingController(text: widget.existing?.landmark);
  late final _village = TextEditingController(text: widget.existing?.village);
  late final _taluka = TextEditingController(text: widget.existing?.taluka);
  late final _district = TextEditingController(text: widget.existing?.district);
  late final _pincode = TextEditingController(text: widget.existing?.pincode);
  late String _label = widget.existing?.label ?? 'Home';
  late bool _default = widget.existing?.isDefault ?? false;
  double? _lat;
  double? _lng;
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.existing?.latitude;
    _lng = widget.existing?.longitude;
    if (widget.existing == null) _prefillContact();
  }

  // A new address usually belongs to the farmer themselves.
  Future<void> _prefillContact() async {
    try {
      final contact = await ref.read(contactProvider.future);
      if (mounted && _phone.text.isEmpty) _phone.text = contact.phone;
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _line1, _line2, _landmark, _village, _taluka, _district, _pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useLocation() async {
    setState(() => _locating = true);
    String? problem;
    try {
      final fix = await ref.read(deviceLocationProvider).current();
      final place = await ref.read(placeNamerProvider).nameOf(fix.latitude, fix.longitude);
      if (!mounted) return;
      setState(() {
        _lat = fix.latitude;
        _lng = fix.longitude;
        if (place != null) {
          if (place.village.isNotEmpty) _village.text = place.village;
          if (place.district.isNotEmpty) _district.text = place.district;
          if (place.taluka.isNotEmpty && _taluka.text.isEmpty) _taluka.text = place.taluka;
          if (place.pincode.isNotEmpty) _pincode.text = place.pincode;
          if (place.street.isNotEmpty && _line1.text.isEmpty) _line1.text = place.street;
        }
      });
    } on LocationUnavailable catch (err) {
      problem = err.message;
    } catch (_) {
      problem = 'Could not read your location.';
    }
    if (!mounted) return;
    setState(() => _locating = false);
    if (problem != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$problem You can type the address instead.')));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final address = SavedAddress(
      addressId: widget.existing?.addressId ?? '',
      label: _label,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      landmark: _landmark.text.trim(),
      village: _village.text.trim(),
      taluka: _taluka.text.trim(),
      district: _district.text.trim(),
      pincode: _pincode.text.trim(),
      latitude: _lat,
      longitude: _lng,
    );
    final repo = ref.read(profileRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.addAddress(address, makeDefault: _default);
      } else {
        await repo.updateAddress(address);
        if (_default && !widget.existing!.isDefault) await repo.makeDefault(address.addressId);
      }
      ref.invalidate(addressesProvider);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).maybePop();
    } catch (err) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }
  }

  String? _required(String? v, String what) => (v ?? '').trim().isEmpty ? 'Enter $what' : null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'New address' : 'Edit address')),
      body: ResponsiveScope(
        child: Form(
          key: _form,
          child: ListView(
            padding: context.pagePadding,
            children: [
              OutlinedButton.icon(
                key: const Key('use-my-location'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(AppTouchTarget.min)),
                onPressed: _locating ? null : _useLocation,
                icon: _locating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location_rounded),
                label: Text(_lat == null ? 'Use my current location' : 'Location pinned (tap to refresh)'),
              ),
              if (_lat != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('GPS: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                ),
              AppSpacing.gapMd,
              Wrap(spacing: AppSpacing.sm, children: [
                for (final l in _labels) ChoiceChip(key: Key('label-$l'), label: Text(l), selected: _label == l, onSelected: (_) => setState(() => _label = l)),
              ]),
              AppSpacing.gapMd,
              TextFormField(key: const Key('addr-name'), controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => _required(v, 'a name')),
              AppSpacing.gapSm,
              TextFormField(
                key: const Key('addr-phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
                validator: (v) => _phonePattern.hasMatch((v ?? '').trim()) ? null : 'Enter a valid mobile number',
              ),
              AppSpacing.gapSm,
              TextFormField(key: const Key('addr-line1'), controller: _line1, decoration: const InputDecoration(labelText: 'House / gat / survey number, street'), validator: (v) => _required(v, 'the address')),
              AppSpacing.gapSm,
              TextFormField(controller: _line2, decoration: const InputDecoration(labelText: 'Area, colony (optional)')),
              AppSpacing.gapSm,
              TextFormField(controller: _landmark, decoration: const InputDecoration(labelText: 'Landmark (optional)')),
              AppSpacing.gapSm,
              Row(children: [
                Expanded(child: TextFormField(key: const Key('addr-village'), controller: _village, decoration: const InputDecoration(labelText: 'Village / town'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: TextFormField(controller: _taluka, decoration: const InputDecoration(labelText: 'Taluka'))),
              ]),
              AppSpacing.gapSm,
              Row(children: [
                Expanded(child: TextFormField(key: const Key('addr-district'), controller: _district, decoration: const InputDecoration(labelText: 'District'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    key: const Key('addr-pin'),
                    controller: _pincode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(labelText: 'PIN code', counterText: ''),
                    validator: (v) => RegExp(r'^[1-9][0-9]{5}$').hasMatch((v ?? '').trim()) ? null : 'Enter a 6-digit PIN',
                  ),
                ),
              ]),
              SwitchListTile(contentPadding: EdgeInsets.zero, value: _default, onChanged: (v) => setState(() => _default = v), title: const Text('Make this my default address')),
              AppSpacing.gapMd,
              AppButton(label: 'Save address', expand: true, isLoading: _saving, onPressed: _save),
              AppSpacing.gapLg,
            ],
          ),
        ),
      ),
    );
  }
}
