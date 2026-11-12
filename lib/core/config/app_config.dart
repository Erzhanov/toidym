/// Орталықтандырылған API кілттері мен Backend конфигурациясы.
///
/// ЕСКЕРТУ: `SUPABASE_SERVICE_ROLE_KEY` / `sb_secret_...` кілтін ЕШҚАШАН
/// Flutter клиентіне салмаңыз! Тек `SUPABASE_URL` және `SUPABASE_PUBLISHABLE_KEY`
/// клиентте қолдануға арналған.
abstract final class AppConfig {
  /// Нақты Supabase/Lovable Cloud режимін қосу (әдепкі бойынша қосулы;
  /// локалды мок-тесттер үшін `--dart-define=USE_BACKEND=false` беруге болады).
  static const bool useBackend = bool.fromEnvironment(
    'USE_BACKEND',
    defaultValue: true,
  );

  /// Supabase Project ID
  static const String supabaseProjectId = String.fromEnvironment(
    'SUPABASE_PROJECT_ID',
    defaultValue: 'kpmknrlltuzmilvtlshg',
  );

  /// Supabase / Lovable Cloud URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue:
        'https://c--7afbd424-5b38-450a-aab4-ba0d1eca81f2-prod.lovable.cloud',
  );

  /// Жаңа форматтағы Publishable Key (`sb_publishable_...`) немесе ескі `anon` кілт
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_zU3VZGpfslzX80kJ-pjQ7w_S2g3V4DK',
  );

  static const String _legacyAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get supabaseAnonKey =>
      _legacyAnonKey.isNotEmpty ? _legacyAnonKey : _publishableKey;

  /// Әдепкі админ телефондары (қажет болса UI/тексеру үшін)
  static const String adminPhones = String.fromEnvironment(
    'TOIDYM_ADMINS',
    defaultValue: '+77000000001,+77012345678',
  );

  /// Қосымша прокси немесе бэкенд базалық адресі.
  static const String customApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get effectiveBaseUrl {
    if (customApiBaseUrl.isNotEmpty) {
      return customApiBaseUrl;
    }
    if (useBackend && supabaseUrl.isNotEmpty) {
      return supabaseUrl;
    }
    return 'https://api.toidym.kz';
  }

  /// Клиент нақты Supabase-ке қосылуға толық дайын ба?
  static bool get isBackendConfigured =>
      useBackend &&
      supabaseUrl.trim().isNotEmpty &&
      supabaseAnonKey.trim().isNotEmpty;
}
