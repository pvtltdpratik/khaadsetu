/// Supabase project used for authentication only (sign-in / sign-up); all app
/// data still lives on the KHAAD Setu API.
///
/// The publishable key is designed to ship inside client apps (it only grants
/// what Row Level Security allows, and this project stores no app data), so
/// it is safe as a default. Override either value per build with
/// `--dart-define=SUPABASE_URL=...` / `--dart-define=SUPABASE_KEY=...`.
/// Never put the `service_role` / secret key in the app.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hoidcnxxlppaxfvlshbs.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_aHKxco_BQdM46N7gwJgIkg_xYOpag7L',
  );
}
