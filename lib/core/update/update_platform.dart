import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the phone itself must do for a self-update. A seam so tests need no Android.
abstract class UpdatePlatform {
  /// Whether this phone can install an APK we downloaded (Android only; an iPhone can only update through Apple).
  bool get supported;

  /// The running app's version code and name.
  Future<({int code, String name})> installedVersion();

  /// Whether Android currently lets this app install packages ("install unknown apps").
  Future<bool> canInstall();

  /// Opens the page where the person switches that on for this app.
  Future<void> openInstallSettings();

  /// Hands the downloaded APK to Android's installer. The app is closed by Android when the new version replaces it.
  Future<void> install(String apkPath);
}

class AndroidUpdatePlatform implements UpdatePlatform {
  const AndroidUpdatePlatform();

  static const _channel = MethodChannel('shetsamrudhi/update');

  @override
  bool get supported => !kIsWeb && Platform.isAndroid;

  @override
  Future<({int code, String name})> installedVersion() async {
    final v = await _channel.invokeMapMethod<String, dynamic>('version') ?? const {};
    return (code: (v['code'] as num?)?.toInt() ?? 0, name: '${v['name'] ?? ''}');
  }

  @override
  Future<bool> canInstall() async => await _channel.invokeMethod<bool>('canInstall') ?? false;

  @override
  Future<void> openInstallSettings() => _channel.invokeMethod<void>('openInstallSettings');

  @override
  Future<void> install(String apkPath) => _channel.invokeMethod<void>('install', {'path': apkPath});
}
