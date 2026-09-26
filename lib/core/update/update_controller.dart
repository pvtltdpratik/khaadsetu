import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../device/device_id_provider.dart';
import '../flavor/app_flavor.dart';
import 'update_platform.dart';
import 'update_service.dart';

enum UpdatePhase { idle, downloading, ready, needsPermission, failed }

class UpdateState {
  const UpdateState({this.phase = UpdatePhase.idle, this.info, this.progress = 0, this.error, this.file});

  final UpdatePhase phase;
  final UpdateInfo? info;
  final double progress;
  final String? error;
  final File? file;

  UpdateState copy({UpdatePhase? phase, UpdateInfo? info, double? progress, String? error, File? file}) =>
      UpdateState(phase: phase ?? this.phase, info: info ?? this.info, progress: progress ?? this.progress, error: error, file: file ?? this.file);
}

final updatePlatformProvider = Provider<UpdatePlatform>((ref) => const AndroidUpdatePlatform());
final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// Where the update is kept. Overridden in tests.
final updateDirectoryProvider = Provider<Future<Directory> Function()>((ref) => () async => Directory('${(await getTemporaryDirectory()).path}${Platform.pathSeparator}app_updates'));

/// Keeps the app up to date by itself: asks the server, downloads a newer build quietly in the background, and when it
/// is ready says so, so the app can ask the person to restart. Android cannot install without the person's tap, so
/// "restart" means: hand the file to Android's installer, which replaces the app.
class UpdateController extends Notifier<UpdateState> {
  DateTime? _lastCheck;
  bool _busy = false;

  @override
  UpdateState build() => const UpdateState();

  /// [force] skips the "not more than every few hours" pause (used by the settings button).
  Future<void> check({bool force = false}) async {
    final platform = ref.read(updatePlatformProvider);
    if (!platform.supported || _busy) return;
    if (!force && _lastCheck != null && DateTime.now().difference(_lastCheck!) < const Duration(hours: 4)) return;
    if (state.phase == UpdatePhase.ready || state.phase == UpdatePhase.needsPermission) return;
    _busy = true;
    try {
      _lastCheck = DateTime.now();
      final installed = await platform.installedVersion();
      final info = await ref.read(updateServiceProvider).check(
            flavor: ref.read(appFlavorProvider).name,
            versionCode: installed.code,
            deviceId: await ref.read(deviceIdProvider.future),
          );
      if (info == null) {
        state = const UpdateState();
        return;
      }
      await _download(info);
    } catch (_) {
      // Offline or the server is down: nothing to say, the next check tries again.
      if (state.phase == UpdatePhase.downloading) state = state.copy(phase: UpdatePhase.failed, error: 'The update download stopped. It will continue later.');
    } finally {
      _busy = false;
    }
  }

  Future<void> _download(UpdateInfo info) async {
    state = UpdateState(phase: UpdatePhase.downloading, info: info);
    try {
      final dir = await ref.read(updateDirectoryProvider)();
      final file = await ref.read(updateServiceProvider).download(info, dir, onProgress: (p) {
        // Whole percents only, so the screen is not rebuilt for every network chunk.
        if ((p * 100).floor() != (state.progress * 100).floor()) state = state.copy(progress: p);
      });
      state = UpdateState(phase: UpdatePhase.ready, info: info, progress: 1, file: file);
    } on UpdateException catch (e) {
      state = UpdateState(phase: UpdatePhase.failed, info: info, error: e.message);
    }
  }

  /// "Restart now": installs the downloaded update. If Android does not yet allow this app to install, it first sends the
  /// person to that switch, and the next call (after they come back) goes on.
  Future<void> restartNow() async {
    final file = state.file;
    if (file == null) return;
    final platform = ref.read(updatePlatformProvider);
    if (!await platform.canInstall()) {
      state = state.copy(phase: UpdatePhase.needsPermission);
      await platform.openInstallSettings();
      return;
    }
    state = state.copy(phase: UpdatePhase.ready);
    await platform.install(file.path);
  }

  /// Called when the app comes back to the front: after the person allowed installing, go straight on.
  Future<void> resumed() async {
    if (state.phase == UpdatePhase.needsPermission && await ref.read(updatePlatformProvider).canInstall()) {
      state = state.copy(phase: UpdatePhase.ready);
    } else {
      await check();
    }
  }
}

final updateControllerProvider = NotifierProvider<UpdateController, UpdateState>(UpdateController.new);
