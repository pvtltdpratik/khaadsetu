import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/auth/supabase_config.dart';
import 'core/flavor/app_flavor.dart';

/// What every `main_*.dart` runs: start Supabase, then the app as [flavor].
Future<void> runShetSamrudhi(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  runApp(ProviderScope(
    overrides: [appFlavorProvider.overrideWithValue(flavor)],
    child: const ShetSamrudhiApp(),
  ));
}
