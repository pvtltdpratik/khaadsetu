import 'package:flutter/material.dart';
import 'core/update/update_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/flavor/app_flavor.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/farmer/notifications/domain/entities/app_notification.dart';
import 'features/farmer/notifications/presentation/notification_navigation.dart';
import 'features/push/presentation/push_providers.dart';

class ShetSamrudhiApp extends ConsumerWidget {
  const ShetSamrudhiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final flavor = ref.watch(appFlavorProvider);

    return MaterialApp.router(
      title: flavor.title,
      // The test APK says so on every screen, so nobody mistakes it for the real app.
      builder: (context, child) {
        final page = child ?? const SizedBox.shrink();
        final shown = flavor.isDev ? Banner(message: 'DEV BUILD', location: BannerLocation.bottomStart, color: Colors.deepOrange, child: page) : page;
        // Newer versions arrive straight from our server, without any app store.
        final updating = UpdateGate(child: shown);
        // Once somebody is signed in, this phone can receive notifications even when the app is closed, and a tap on
        // one leads to what it is about.
        return PushRegistrar(
          onOpened: (data) => openNotificationTarget(router, ref.read, NotificationType.parse(data['type']), data['refId']),
          child: updating,
        );
      },
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
