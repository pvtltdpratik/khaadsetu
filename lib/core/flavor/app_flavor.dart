import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which app this build is. One codebase makes four APKs (see `build_all.sh`):
/// each `lib/main_*.dart` names its flavor, and the router then lets only that
/// flavor's kind of account in. The role itself always comes from the server
/// (`GET /v1/me`), so a flavor can narrow who may use an APK but never widen it.
enum AppFlavor {
  /// The farmer APK.
  farmer('ShetSamrudhi'),

  /// The village center operator APK.
  center('ShetSamrudhi Center'),

  /// The platform admin APK.
  admin('ShetSamrudhi Admin'),

  /// The test APK: every role, with a "DEV BUILD" banner and a role picker.
  dev('ShetSamrudhi DEV'),

  /// Unrestricted and unlabelled: what plain `lib/main.dart` runs, and the default in tests.
  all('ShetSamrudhi');

  const AppFlavor(this.title);

  /// The name shown in task switchers and error screens.
  final String title;

  /// Whether this build shows the "DEV BUILD" banner and the role picker.
  bool get isDev => this == dev;
}

/// The running app's flavor. Each entry point overrides it before `runApp`.
final appFlavorProvider = Provider<AppFlavor>((ref) => AppFlavor.all);
