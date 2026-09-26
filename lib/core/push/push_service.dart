import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/push/domain/push_models.dart';

/// What the app does with a notification that was tapped: the data the server attached (`type`, `refId`, ...).
typedef PushOpened = void Function(Map<String, String> data);

/// Receives push notifications from Firebase. Swappable so tests and builds without Firebase need no plugin.
abstract class PushService {
  /// Whether this build can receive pushes at all.
  bool get available;

  /// Starts listening. [onToken] gets the phone's token now and whenever it changes; [onOpened] gets the data of a
  /// notification the user tapped, whether the app was open, in the background, or closed.
  Future<void> start({required Future<void> Function(String token) onToken, required PushOpened onOpened});

  /// Stops listening and forgets this phone's token.
  Future<void> stop();
}

/// Used when the build has no Firebase values, and in tests.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  bool get available => false;

  @override
  Future<void> start({required Future<void> Function(String token) onToken, required PushOpened onOpened}) async {}

  @override
  Future<void> stop() async {}
}

class FirebasePushService implements PushService {
  FirebasePushService(this._options);

  final FirebaseOptions _options;
  final _local = FlutterLocalNotificationsPlugin();
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  bool get available => true;

  @override
  Future<void> start({required Future<void> Function(String token) onToken, required PushOpened onOpened}) async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: _options);

      await _local.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          onOpened((jsonDecode(payload) as Map).map((k, v) => MapEntry('$k', '$v')));
        },
      );
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Android 13 and later ask before showing notifications.
      await android?.requestNotificationsPermission();
      // One channel per category, so the phone's own settings can tune each, and the server's messages land in the right one.
      for (final c in pushChannels) {
        await android?.createNotificationChannel(AndroidNotificationChannel(c.id, c.label, description: c.description, importance: Importance.high));
      }

      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) await onToken(token);
      _subscriptions
        ..add(messaging.onTokenRefresh.listen((t) => onToken(t)))
        // With the app open, Firebase shows nothing by itself, so show it the same way.
        ..add(FirebaseMessaging.onMessage.listen(_showWhileOpen))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpened(_strings(m.data))));
      final launchedBy = await messaging.getInitialMessage();
      if (launchedBy != null) onOpened(_strings(launchedBy.data));
    } catch (err) {
      // Push is a convenience: a failure here must never stop the app.
      debugPrint('Push could not start: $err');
    }
  }

  Map<String, String> _strings(Map<String, dynamic> data) => data.map((k, v) => MapEntry(k, '$v'));

  Future<void> _showWhileOpen(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    final channel = message.data['channel'] as String? ?? 'alerts';
    await _local.show(
      id: message.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(android: AndroidNotificationDetails(channel, channel, importance: Importance.high, priority: Priority.high)),
      payload: jsonEncode(_strings(message.data)),
    );
  }

  @override
  Future<void> stop() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    try {
      if (Firebase.apps.isNotEmpty) await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
