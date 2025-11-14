import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env/env.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'features/quran/utils/quran_font_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load ligatures for Quran font (non-blocking if fails)
  try {
    await QuranFontHelper.loadLigatures();
    await QuranFontHelper.loadSurahNameLigatures();
  } catch (_) {}
  
  // Load .env file from assets (as per Flutter best practices)
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    // Will try to use --dart-define or fallback to empty values
  }

  // Get credentials (priority: --dart-define > .env file)
  final supabaseUrl = Env.supabaseUrl;
  final supabaseAnonKey = Env.supabaseAnonKey;
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Supabase credentials missing.\n'
      'Please ensure assets/.env exists with SUPABASE_URL and SUPABASE_ANON_KEY\n'
      'Or use --dart-define flags when running the app.',
    );
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
