import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String _env(String k) {
    final fromEnv = String.fromEnvironment(k, defaultValue: '');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return dotenv.env[k] ?? '';
  }

  static String get supabaseUrl => _env('SUPABASE_URL');
  static String get supabaseAnonKey => _env('SUPABASE_ANON_KEY');
  static String get sentryDsn => _env('SENTRY_DSN');
  static String get appEnv => _env('APP_ENV').isEmpty ? 'dev' : _env('APP_ENV');
}

