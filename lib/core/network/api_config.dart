/// Base URL for the Soil Sense backend (see `server/` — FastAPI, `POST
/// /v1/analyze`, `GET /v1/history`).
///
/// "localhost" means something different depending on where the app is
/// actually running, so this is the one place to override it — never
/// hardcode a host anywhere else in the app:
///
///   flutter run -d chrome                                            # default is fine — web shares the machine's localhost
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000      # Android emulator (10.0.2.2 reaches the host machine)
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.23:8000  # physical phone — use your computer's LAN IP, same Wi-Fi as the phone,
///                                                                     # and start the backend with `uvicorn app.main:app --host 0.0.0.0` so it accepts non-localhost connections
///
/// The iOS simulator, like web, can reach the host's localhost directly,
/// so the default also covers it.
class ApiConfig {
  const ApiConfig._();

  static const soilSenseBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
