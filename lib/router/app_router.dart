import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/quran/presentation/reader_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Auth guard will be implemented here later
      // Deep links from Supabase will be handled automatically by Supabase SDK
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const ReaderScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          // Get email from query parameter or extra
          final email = state.uri.queryParameters['email'] ?? 
                       (state.extra as Map<String, dynamic>?)?['email'] as String? ?? 
                       '';
          return VerifyEmailScreen(email: email);
        },
      ),
    ],
  );
});

