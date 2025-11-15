import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reading_session_service.dart';
import '../data/today_reading_stats_model.dart';
import '../../auth/providers/auth_providers.dart';

/// Provider for ReadingSessionService instance.
final readingSessionServiceProvider = Provider<ReadingSessionService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReadingSessionService(client);
});

/// Provider for today's reading statistics.
/// 
/// Auto-disposes when not watched to avoid unnecessary queries.
final todayReadingStatsProvider =
    FutureProvider.autoDispose<TodayReadingStats>((ref) async {
  final service = ref.read(readingSessionServiceProvider);
  return service.getTodayStats();
});

