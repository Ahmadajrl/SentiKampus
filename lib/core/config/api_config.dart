/// Konfigurasi URL API untuk Flutter Android SentiKampus.
///
/// Di Android Emulator, `10.0.2.2` menunjuk ke host Windows (localhost).
/// Gunakan `--dart-define=API_BASE_URL=http://...` untuk override.
class ApiConfig {
  const ApiConfig._();

  /// Base URL FastAPI backend.
  /// Default: http://10.0.2.2:8000 (Android Emulator → host Windows)
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
