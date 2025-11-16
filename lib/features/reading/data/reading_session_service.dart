import 'package:supabase_flutter/supabase_flutter.dart';
import 'reading_session_model.dart';
import 'today_reading_stats_model.dart';

/// Service for managing reading sessions with Supabase.
class ReadingSessionService {
  final SupabaseClient client;

  ReadingSessionService(this.client);

  /// Logs a reading session via RPC function.
  /// 
  /// Returns the created session with calculated letters_count and hasanat.
  Future<ReadingSession> logSession({
    required int surahNumber,
    required int ayahStart,
    required int ayahEnd,
    required String readingMode, // 'surah' or 'focus'
  }) async {
    try {
      final result = await client.rpc(
        'log_reading_session',
        params: {
          'p_surah': surahNumber,
          'p_ayah_start': ayahStart,
          'p_ayah_end': ayahEnd,
          'p_mode': readingMode,
        },
      );

      if (result == null) {
        throw Exception('RPC returned null');
      }

      return ReadingSession.fromMap(result as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to log reading session: $e');
    }
  }

  /// Gets today's reading statistics.
  /// 
  /// Calculates "today" in local timezone and aggregates data from reading_sessions.
  Future<TodayReadingStats> getTodayStats() async {
    try {
      // Get today's start and end in UTC (Supabase stores timestamptz)
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Convert to ISO strings for Supabase query
      final todayStartIso = todayStart.toUtc().toIso8601String();
      final todayEndIso = todayEnd.toUtc().toIso8601String();

      // Query reading_sessions for today
      final response = await client
          .from('reading_sessions')
          .select('surah_number, ayah_start, ayah_end, hasanat')
          .gte('created_at', todayStartIso)
          .lt('created_at', todayEndIso)
          .order('created_at', ascending: false);

      final sessions = response as List<dynamic>;

      if (sessions.isEmpty) {
        return TodayReadingStats.empty();
      }

      // Aggregate statistics
      int totalAyat = 0;
      int totalHasanat = 0;

      for (final session in sessions) {
        final map = session as Map<String, dynamic>;
        final ayahStart = map['ayah_start'] as int;
        final ayahEnd = map['ayah_end'] as int;
        final hasanat = map['hasanat'] as int;

        // Calculate ayat count: end - start + 1
        totalAyat += (ayahEnd - ayahStart + 1);
        totalHasanat += hasanat;
      }

      return TodayReadingStats(
        totalAyat: totalAyat,
        totalHasanat: totalHasanat,
        sessionCount: sessions.length,
      );
    } catch (e) {
      // Return empty stats on error (don't crash the app)
      return TodayReadingStats.empty();
    }
  }

  /// Deletes the most recent reading session for the current user.
  /// 
  /// Only deletes the last session to prevent accidental mass deletion.
  Future<void> deleteLastSession() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await client
        .from('reading_sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      final sessionId = response['id'] as String;
      await client
          .from('reading_sessions')
          .delete()
          .eq('id', sessionId);
    }
  }
}

