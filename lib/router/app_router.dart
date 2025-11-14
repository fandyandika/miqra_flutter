import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/quran/presentation/reader_screen.dart';
import '../features/quran/presentation/screens/surah_list_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/group/presentation/group_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../shared/widgets/miqra_shell_scaffold.dart';
import 'go_router_refresh_stream.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = ref.read(authRepositoryProvider).onAuthState();
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStream),
    routes: [
      // Main app routes with shell
      GoRoute(
        path: '/',
        builder: (ctx, state) => MiqraShellScaffold(
          currentLocation: state.matchedLocation,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/read',
        builder: (ctx, state) => MiqraShellScaffold(
          currentLocation: state.matchedLocation,
          child: const SurahListScreen(),
        ),
      ),
      GoRoute(
        path: '/read/:surahNumber',
        builder: (ctx, state) {
          final surahNumberStr = state.pathParameters['surahNumber'] ?? '1';
          final surahNumber = int.tryParse(surahNumberStr) ?? 1;
          return MiqraShellScaffold(
            currentLocation: state.matchedLocation,
            child: ReaderScreen(surahNumber: surahNumber),
          );
        },
      ),
      GoRoute(
        path: '/progress',
        builder: (ctx, state) => MiqraShellScaffold(
          currentLocation: state.matchedLocation,
          child: const ProgressScreen(),
        ),
      ),
      GoRoute(
        path: '/group',
        builder: (ctx, state) => MiqraShellScaffold(
          currentLocation: state.matchedLocation,
          child: const GroupScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (ctx, state) => MiqraShellScaffold(
          currentLocation: state.matchedLocation,
          child: const ProfileScreen(),
        ),
      ),
      // Auth routes (no shell)
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
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
