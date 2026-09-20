/// Base URL and key for the KHAAD Setu API (the Express server, see its
/// `API.md`). Every data source goes through `ApiClient`, so this is the one
/// place to point the app at a different server — never hardcode a host
/// anywhere else.
///
/// "localhost" means something different depending on where the app runs:
///
///   flutter run -d chrome                                            # default is fine — web shares the machine's localhost
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000      # Android emulator (10.0.2.2 reaches the host machine)
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.23:3000  # physical phone — your computer's LAN IP, same Wi-Fi as the phone
///   flutter run --dart-define=API_BASE_URL=http://EC2_PUBLIC_IP      # deployed server behind Nginx
///
/// If the server has `API_KEY` set, pass the same value with
/// `--dart-define=API_KEY=...`; it is sent as `X-API-Key` on every request.
class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const apiKey = String.fromEnvironment('API_KEY');
}
