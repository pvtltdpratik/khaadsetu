import 'package:firebase_core/firebase_core.dart';

import '../flavor/app_flavor.dart';

/// The Firebase project's values, passed at build time like the API address (see `build_all.bat`): these are the
/// app's public identifiers from the Firebase console, not secrets. With any of them missing, push is simply off
/// and the app works as before.
class PushConfig {
  const PushConfig._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');

  // Each app is registered in Firebase under its own package name, so each has its own app id.
  static const _farmerAppId = String.fromEnvironment('FIREBASE_APP_ID_FARMER');
  static const _centerAppId = String.fromEnvironment('FIREBASE_APP_ID_CENTER');
  static const _adminAppId = String.fromEnvironment('FIREBASE_APP_ID_ADMIN');
  static const _devAppId = String.fromEnvironment('FIREBASE_APP_ID_DEV');

  static String appIdFor(AppFlavor flavor) => switch (flavor) {
        AppFlavor.farmer => _farmerAppId,
        AppFlavor.center => _centerAppId,
        AppFlavor.admin => _adminAppId,
        AppFlavor.dev => _devAppId,
        AppFlavor.all => '',
      };

  /// What the server knows this app as (stored with the phone's token).
  static String appNameFor(AppFlavor flavor) => flavor == AppFlavor.all ? 'app' : flavor.name;

  static FirebaseOptions? optionsFor(AppFlavor flavor) {
    final appId = appIdFor(flavor);
    if (apiKey.isEmpty || projectId.isEmpty || senderId.isEmpty || appId.isEmpty) return null;
    return FirebaseOptions(apiKey: apiKey, appId: appId, messagingSenderId: senderId, projectId: projectId);
  }
}
