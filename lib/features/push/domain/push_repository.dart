import 'push_models.dart';

abstract class PushRepository {
  /// Tells the server this phone can receive pushes for the signed-in user.
  Future<void> registerDevice({required String token, required String app});

  /// Stops pushes to this phone (on sign-out).
  Future<void> unregisterDevice(String token);

  Future<NotificationSettings> settings();

  /// Switches one category on or off.
  Future<void> setChannel(String channel, {required bool enabled});

  Future<void> setQuietHours(QuietHours quiet);
}
