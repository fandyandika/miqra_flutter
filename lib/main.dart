import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env/env.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  try {
    await dotenv.load(fileName: ".env.dev");
  } catch (e) {
    // .env.dev not found, continue with empty env vars
  }

  // Run app immediately, initialize services in background (non-blocking)
  runApp(const ProviderScope(child: MiqraApp()));
  
  // Initialize services asynchronously without blocking
  unawaited(_initializeServicesAsync());
}

Future<void> _initializeServicesAsync() async {
  // Initialize Sentry only if DSN is provided
  final sentryDsn = Env.sentryDsn;
  if (sentryDsn.isNotEmpty) {
    try {
      await SentryFlutter.init((o) {
        o.dsn = sentryDsn;
        o.tracesSampleRate = 0.2;
        o.profilesSampleRate = 0.2;
      }).timeout(const Duration(seconds: 5), onTimeout: () {
        // Timeout - continue without Sentry
      });
    } catch (e) {
      // Sentry init failed, continue without it
    }
  }

  // Initialize Supabase
  try {
    final supabaseUrl = Env.supabaseUrl;
    final supabaseAnonKey = Env.supabaseAnonKey;
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Future.any([
        Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey),
        Future.delayed(const Duration(seconds: 5)),
      ]).timeout(const Duration(seconds: 6));
    }
  } catch (e) {
    // Supabase init failed or timed out, continue without it
  }
}


class MiqraApp extends StatelessWidget {
  const MiqraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Miqra',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
