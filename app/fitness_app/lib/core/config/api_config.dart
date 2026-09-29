/// API base URL via `--dart-define=API_BASE_URL=...`.
///
/// Defaults:
/// - iOS simulator / macOS / Chrome: `http://localhost:3001`
/// - Android emulator: `http://10.0.2.2:3001` (localhost внутри эмулятора — не хост)
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3001',
);
