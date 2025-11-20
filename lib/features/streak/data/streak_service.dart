import 'package:supabase_flutter/supabase_flutter.dart';
import 'streak_summary_model.dart';

/// Service for managing streak data with Supabase.
class StreakService {
  final SupabaseClient client;

  StreakService(this.client);

  /// Gets streak summary from Supabase RPC function.
  /// 
  /// [days] - Number of days to include in calendar (default: 30)
  /// Returns StreakSummary with today_read, current_streak, best_streak, and calendar.
  Future<StreakSummary> getStreakSummary({int days = 30}) async {
    try {
      final result = await client.rpc(
        'get_streak_summary',
        params: {
          'p_days': days,
        },
      );

      if (result == null) {
        return StreakSummary.empty();
      }

      return StreakSummary.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      // Return empty summary on error to avoid breaking UI
      return StreakSummary.empty();
    }
  }
}

