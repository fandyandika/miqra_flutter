import 'package:go_router/go_router.dart';
import '../features/quran/presentation/reader_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const ReaderScreen(),
    ),
  ],
);

