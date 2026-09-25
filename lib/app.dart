import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/flavor/app_flavor.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

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
        return flavor.isDev ? Banner(message: 'DEV BUILD', location: BannerLocation.bottomStart, color: Colors.deepOrange, child: page) : page;
      },
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
