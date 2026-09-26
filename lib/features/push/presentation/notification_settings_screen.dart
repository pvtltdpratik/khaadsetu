import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../domain/push_models.dart';
import 'push_providers.dart';

/// Which kinds of notification to receive, and when not to be disturbed. Everything is still saved in the list;
/// these switches only decide what makes the phone buzz.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _change(BuildContext context, WidgetRef ref, Future<void> Function() save) async {
    try {
      await save();
      ref.invalidate(notificationSettingsProvider);
    } catch (err) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref, QuietHours quiet, {required bool start}) async {
    final current = start ? quiet.from : quiet.until;
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(current.split(':')[0]), minute: int.parse(current.split(':')[1])));
    if (picked == null || !context.mounted) return;
    final text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await _change(context, ref, () => ref.read(pushRepositoryProvider).setQuietHours(start ? quiet.copyWith(from: text) : quiet.copyWith(until: text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(notificationSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: ResponsiveScope(
        child: settings.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(notificationSettingsProvider)),
          data: (s) => ListView(padding: context.pagePadding, children: [
            Text('Choose what you want to hear about, even when the app is closed. Everything still appears in your notification list.', style: text.bodyMedium?.copyWith(color: colors.textMuted)),
            AppSpacing.gapMd,
            for (final c in pushChannels)
              SwitchListTile(
                key: Key('channel-${c.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(c.label),
                subtitle: Text(c.description),
                value: s.isOn(c.id),
                onChanged: (on) => _change(context, ref, () => ref.read(pushRepositoryProvider).setChannel(c.id, enabled: on)),
              ),
            const Divider(height: AppSpacing.xl),
            SwitchListTile(
              key: const Key('quiet-enabled'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Quiet hours'),
              subtitle: const Text('No alerts during these hours, except codes and orders that are ready.'),
              value: s.quiet.enabled,
              onChanged: (on) => _change(context, ref, () => ref.read(pushRepositoryProvider).setQuietHours(s.quiet.copyWith(enabled: on))),
            ),
            if (s.quiet.enabled)
              Row(children: [
                Expanded(child: OutlinedButton.icon(key: const Key('quiet-from'), onPressed: () => _pickTime(context, ref, s.quiet, start: true), icon: const Icon(Icons.bedtime_outlined), label: Text('From ${s.quiet.from}'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: OutlinedButton.icon(key: const Key('quiet-until'), onPressed: () => _pickTime(context, ref, s.quiet, start: false), icon: const Icon(Icons.wb_sunny_outlined), label: Text('Until ${s.quiet.until}'))),
              ]),
          ]),
        ),
      ),
    );
  }
}
