import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/responsive/responsive_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/operator_center.dart';
import '../providers/operator_center_providers.dart';

/// The operator's center at a glance, with the open/closed switch: turning it
/// off tells farmers the center is closed and ranks it lower for them.
class MyCenterCard extends ConsumerStatefulWidget {
  const MyCenterCard({super.key});

  @override
  ConsumerState<MyCenterCard> createState() => _MyCenterCardState();
}

class _MyCenterCardState extends ConsumerState<MyCenterCard> {
  bool _saving = false;

  Future<void> _setOpen(bool open) async {
    setState(() => _saving = true);
    try {
      await ref.read(operatorCenterRepositoryProvider).update(isOpen: open);
      ref.invalidate(operatorCenterProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(open ? 'You are now open for farmers' : 'You are now closed to farmers')));
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final center = ref.watch(operatorCenterProvider);
    return center.when(
      loading: () => const SizedBox(height: 80, child: AppLoadingIndicator()),
      error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(operatorCenterProvider)),
      data: (c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.isOpen ? colors.success.withValues(alpha: 0.6) : colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_rounded, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: text.titleMedium),
                      Text(c.place, style: text.bodySmall?.copyWith(color: colors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit hours and contact',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showAdaptiveModal<bool>(context: context, builder: (context) => _EditCenterSheet(center: c)),
                ),
              ],
            ),
            // A ListTile paints on the nearest Material; inside this decorated box it
            // needs its own, or its ink is hidden (and Flutter asserts in debug).
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: c.isOpen,
                onChanged: _saving ? null : _setOpen,
                title: Text(c.isOpen ? 'Open for farmers' : 'Closed'),
                subtitle: Text('Hours ${c.opensAt} – ${c.closesAt}${c.phone.isEmpty ? '' : ' · ${c.phone}'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCenterSheet extends ConsumerStatefulWidget {
  const _EditCenterSheet({required this.center});

  final OperatorCenter center;

  @override
  ConsumerState<_EditCenterSheet> createState() => _EditCenterSheetState();
}

class _EditCenterSheetState extends ConsumerState<_EditCenterSheet> {
  late TimeOfDay _opens = _parse(widget.center.opensAt);
  late TimeOfDay _closes = _parse(widget.center.closesAt);
  late final _phone = TextEditingController(text: widget.center.phone);
  late final _name = TextEditingController(text: widget.center.operatorName);
  bool _saving = false;
  String? _error;

  static TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(bool opening) async {
    final picked = await showTimePicker(context: context, initialTime: opening ? _opens : _closes);
    if (picked != null) setState(() => opening ? _opens = picked : _closes = picked);
  }

  Future<void> _save() async {
    if (_closes.hour * 60 + _closes.minute <= _opens.hour * 60 + _opens.minute) {
      setState(() => _error = 'Closing time must be after opening time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(operatorCenterRepositoryProvider).update(
            opensAt: _fmt(_opens),
            closesAt: _fmt(_closes),
            phone: _phone.text.trim(),
            operatorName: _name.text.trim(),
          );
      ref.invalidate(operatorCenterProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      if (mounted) setState(() => _error = '$err');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hours and contact', style: text.titleLarge),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: _saving ? null : () => _pick(true), icon: const Icon(Icons.access_time_rounded), label: Text('Opens ${_fmt(_opens)}'))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: OutlinedButton.icon(onPressed: _saving ? null : () => _pick(false), icon: const Icon(Icons.access_time_filled_rounded), label: Text('Closes ${_fmt(_closes)}'))),
            ],
          ),
          AppSpacing.gapMd,
          TextField(controller: _name, enabled: !_saving, decoration: const InputDecoration(labelText: 'Your name (shown to farmers)')),
          AppSpacing.gapMd,
          TextField(controller: _phone, enabled: !_saving, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (farmers can call this)')),
          if (_error != null) ...[
            AppSpacing.gapSm,
            Text(_error!, style: text.bodySmall?.copyWith(color: context.colors.danger)),
          ],
          AppSpacing.gapMd,
          AppButton(label: 'Save', expand: true, isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
