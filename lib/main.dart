import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/env/env.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'features/quran/utils/quran_font_helper.dart';
import 'features/quran/data/last_read_hive.dart';
import 'features/quran/data/last_read_service.dart';
import 'features/bookmark/data/bookmark_hive.dart';
import 'features/bookmark/data/bookmark_service.dart';
import 'features/settings/data/reader_settings_hive.dart';
import 'features/settings/data/reader_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(LastReadPositionAdapter());
  Hive.registerAdapter(BookmarkFolderAdapter());
  Hive.registerAdapter(BookmarkItemAdapter());
  Hive.registerAdapter(SurahProgressAdapter());
  Hive.registerAdapter(ReaderSettingsAdapter());
  await LastReadService.init();
  await BookmarkService.init();
  await ReaderSettingsService.init();
  
  // Load ligatures for Quran font (non-blocking if fails)
  try {
    await QuranFontHelper.loadLigatures();
    await QuranFontHelper.loadSurahNameLigatures();
  } catch (_) {}
  
  // Load .env file from root (standard Flutter practice)
  // Note: Supabase tutorial shows hardcoded credentials for quickstart only.
  // This implementation uses .env file (dev) or --dart-define (production) which is more secure.
  try {
    await dotenv.load();
  } catch (e) {
    // Will try to use --dart-define or fallback to empty values
  }

  // Get credentials (priority: --dart-define > .env file)
  // Supports both legacy anon key and new publishable key (sb_publishable_xxx)
  final supabaseUrl = Env.supabaseUrl;
  final supabaseAnonKey = Env.supabaseAnonKey;
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty || 
      supabaseUrl == 'your_supabase_url_here' || 
      supabaseAnonKey == 'your_supabase_anon_key_here') {
    // Show error screen instead of crashing
    runApp(const ProviderScope(child: _ConfigErrorApp()));
    return;
  }

  // Initialize Sentry with Supabase init inside appRunner
  final sentryDsn = Env.sentryDsn;
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
        options.profilesSampleRate = 0.2;
      },
      appRunner: () async {
        // Initialize Supabase inside Sentry appRunner
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        
        // Run app AFTER Supabase is ready
        runApp(const ProviderScope(child: MiqraApp()));
      },
    );
  } else {
    // No Sentry - initialize Supabase directly
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    
    // Run app AFTER Supabase is ready
    runApp(const ProviderScope(child: MiqraApp()));
  }
}

class MiqraApp extends ConsumerWidget {
  const MiqraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Miqra',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miqra',
      theme: buildAppTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Configuration Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Supabase credentials missing.\n\n'
                  'Please ensure .env exists in project root with:\n'
                  '• SUPABASE_URL\n'
                  '• SUPABASE_ANON_KEY\n\n'
                  'Or use --dart-define flags when running the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  'See .env.example for template',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
