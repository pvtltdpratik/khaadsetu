import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_button.dart';
import 'update_controller.dart';

/// Wraps the whole app. It checks for a newer version when the app opens, when it comes back to the front and every few
/// hours, downloads it quietly, and then asks to restart. A forced update cannot be put off.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> with WidgetsBindingObserver {
  Timer? _timer;
  int? _postponed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(hours: 4), (_) => ref.read(updateControllerProvider.notifier).check());
    // After the first frame, so starting the app is never slowed by this.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(updateControllerProvider.notifier).check());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Coming back is a new chance to ask again about a postponed restart.
    setState(() => _postponed = null);
    unawaited(ref.read(updateControllerProvider.notifier).resumed());
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(updateControllerProvider);
    final info = s.info;
    final forced = info?.mandatory ?? false;
    final askRestart = (s.phase == UpdatePhase.ready || s.phase == UpdatePhase.needsPermission) && info != null && (forced || _postponed != info.versionCode);
    final blockDownload = forced && (s.phase == UpdatePhase.downloading || s.phase == UpdatePhase.failed);
    return Stack(children: [
      widget.child,
      if (askRestart || blockDownload) ...[
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Center(
          child: Material(
            type: MaterialType.transparency,
            child: _UpdateCard(
              state: s,
              onRestart: () => ref.read(updateControllerProvider.notifier).restartNow(),
              onLater: forced || info == null ? null : () => setState(() => _postponed = info.versionCode),
              onRetry: () => ref.read(updateControllerProvider.notifier).check(force: true),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.state, required this.onRestart, required this.onLater, required this.onRetry});

  final UpdateState state;
  final VoidCallback onRestart;
  final VoidCallback? onLater;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final info = state.info!;
    final downloading = state.phase == UpdatePhase.downloading;
    final failed = state.phase == UpdatePhase.failed;
    final permission = state.phase == UpdatePhase.needsPermission;
    return Container(
      key: const Key('update-card'),
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(failed ? Icons.error_outline : Icons.system_update_alt_rounded, color: failed ? c.danger : c.primary),
          AppSpacing.gapSm,
          Expanded(child: Tx(downloading || failed ? 'Updating the app' : 'Restart required', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
        ]),
        AppSpacing.gapSm,
        Text('Version ${info.versionName} is ${downloading ? 'downloading' : 'ready'}.', style: text.bodyLarge),
        if (info.notes.isNotEmpty) ...[AppSpacing.gapSm, Text(info.notes, style: text.bodyMedium?.copyWith(color: c.textMuted))],
        AppSpacing.gapMd,
        if (downloading) ...[
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(key: const Key('update-progress'), value: state.progress == 0 ? null : state.progress, minHeight: 10)),
          const SizedBox(height: 6),
          Text('${(state.progress * 100).floor()}%', style: text.bodySmall),
        ] else if (failed) ...[
          Text(state.error ?? 'The update could not be downloaded.', style: text.bodyMedium?.copyWith(color: c.danger)),
          AppSpacing.gapMd,
          AppButton(key: const Key('update-retry'), label: 'Try again', expand: true, onPressed: onRetry),
        ] else ...[
          Tx(
            permission
                ? 'Allow this app to install updates on the page that opened, then come back here.'
                : 'The app needs to restart to finish the update. Android will ask you to tap Install; then open the app again.',
            key: const Key('update-message'),
            style: text.bodyMedium,
          ),
          AppSpacing.gapMd,
          AppButton(key: const Key('update-restart'), label: permission ? 'Open the setting' : 'Restart now', expand: true, icon: Icons.restart_alt_rounded, onPressed: onRestart),
          if (onLater != null) ...[
            AppSpacing.gapSm,
            AppButton(key: const Key('update-later'), label: 'Later', expand: true, variant: AppButtonVariant.text, onPressed: onLater),
          ],
        ],
      ]),
    );
  }
}
