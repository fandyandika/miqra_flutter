import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reading_session_service.dart';
import '../data/today_reading_stats_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../bookmark/data/bookmark_service.dart';

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

/// Provider for total bookmarks count.
final totalBookmarksProvider = FutureProvider.autoDispose<int>((ref) async {
  await BookmarkService.init();
  final folders = await BookmarkService.getFolders();
  int total = 0;
  for (final folder in folders) {
    final bookmarks = await BookmarkService.watchBookmarksByFolder(folder.id).first;
    total += bookmarks.length;
  }
  return total;
});

/// Provider for total reading time in seconds.
/// Calculates from reading_sessions by estimating time based on letters count.
final totalReadingTimeProvider = FutureProvider.autoDispose<Duration>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  
  if (userId == null) {
    return Duration.zero;
  }

  try {
    final response = await client
        .from('reading_sessions')
        .select('letters_count, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final sessions = response as List<dynamic>;
    
    if (sessions.isEmpty) {
      return Duration.zero;
    }

    // Estimate reading time: average reading speed is ~200 words per minute
    // Average Arabic word has ~4 letters, so ~800 letters per minute
    // That's ~13.3 letters per second
    const lettersPerSecond = 13.3;
    
    int totalLetters = 0;
    for (final session in sessions) {
      final map = session as Map<String, dynamic>;
      totalLetters += map['letters_count'] as int? ?? 0;
    }
    
    final seconds = (totalLetters / lettersPerSecond).round();
    return Duration(seconds: seconds);
  } catch (e) {
    return Duration.zero;
  }
});

/// Provider for total unique surahs read count.
final totalSurahsReadProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  
  if (userId == null) {
    return 0;
  }

  try {
    final response = await client
        .from('reading_sessions')
        .select('surah_number')
        .eq('user_id', userId);

    final sessions = response as List<dynamic>;
    final uniqueSurahs = <int>{};
    
    for (final session in sessions) {
      final map = session as Map<String, dynamic>;
      uniqueSurahs.add(map['surah_number'] as int);
    }
    
    return uniqueSurahs.length;
  } catch (e) {
    return 0;
  }
});

