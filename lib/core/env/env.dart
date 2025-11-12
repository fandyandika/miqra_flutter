import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String _env(String k) {
    // First priority: --dart-define (from build-time, for production)
    final fromEnv = String.fromEnvironment(k, defaultValue: '');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    
    // Second priority: dotenv (from assets/.env file, for development)
    // Handle case where dotenv is not initialized
    try {
      return dotenv.env[k] ?? '';
    } catch (e) {
      // dotenv not initialized (file not found or not loaded)
      return '';
    }
  }

  static String get supabaseUrl => _env('SUPABASE_URL');
  static String get supabaseAnonKey => _env('SUPABASE_ANON_KEY');
  static String get sentryDsn => _env('SENTRY_DSN');
  static String get appEnv => _env('APP_ENV').isEmpty ? 'dev' : _env('APP_ENV');
}

