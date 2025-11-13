import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/quran/presentation/reader_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import 'go_router_refresh_stream.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = ref.read(authRepositoryProvider).onAuthState();
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const ReaderScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
      // Contoh protected route (aktifkan nanti):
      // GoRoute(
      //   path: '/write-example',
      //   builder: (_, __) => const SomeWriteScreen(),
      //   redirect: (ctx, state) {
      //     final hasSession = ref.read(authUserProvider) != null;
      //     return hasSession ? null : '/login';
      //   },
      // ),
    ],
    redirect: (context, state) {
      final user = ref.read(authUserProvider);
      final loggingIn = state.matchedLocation == '/login' || 
                       state.matchedLocation == '/register' || 
                       state.matchedLocation == '/forgot';
      if (user == null && loggingIn) return null; // stay in auth pages
      if (user == null && state.matchedLocation.startsWith('/write')) return '/login';
      if (user != null && loggingIn) return '/'; // already logged-in
      return null;
    },
  );
});
