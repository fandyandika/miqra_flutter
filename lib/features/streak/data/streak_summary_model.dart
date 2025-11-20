/// Model for a single day in the streak calendar.
class StreakDay {
  final DateTime date;
  final bool read;

  const StreakDay({
    required this.date,
    required this.read,
  });

  /// Creates StreakDay from JSON.
  /// 
  /// Expects: {"date": "YYYY-MM-DD", "read": true/false}
  factory StreakDay.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String;
    final date = DateTime.parse(dateStr);
    // Normalize to local date (remove time component)
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    return StreakDay(
      date: dateOnly,
      read: json['read'] as bool? ?? false,
    );
  }

  /// Converts StreakDay to Map (for debugging/testing).
  Map<String, dynamic> toMap() {
    return {
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'read': read,
    };
  }
}

/// Model for streak summary data from Supabase RPC.
class StreakSummary {
  final bool todayRead;
  final int currentStreak;
  final int bestStreak;
  final List<StreakDay> calendar;

  const StreakSummary({
    required this.todayRead,
    required this.currentStreak,
    required this.bestStreak,
    required this.calendar,
  });

  /// Creates StreakSummary from JSON response.
  /// 
  /// Expects:
  /// {
  ///   "today_read": true,
  ///   "current_streak": 5,
  ///   "best_streak": 12,
  ///   "calendar": [{"date": "2025-02-19", "read": true}, ...]
  /// }
  factory StreakSummary.fromJson(Map<String, dynamic> json) {
    final calendarJson = json['calendar'] as List<dynamic>? ?? [];
    final calendar = calendarJson
        .map((item) => StreakDay.fromJson(item as Map<String, dynamic>))
        .toList();

    return StreakSummary(
      todayRead: json['today_read'] as bool? ?? false,
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      calendar: calendar,
    );
  }

  /// Creates an empty/default StreakSummary.
  factory StreakSummary.empty() {
    return const StreakSummary(
      todayRead: false,
      currentStreak: 0,
      bestStreak: 0,
      calendar: [],
    );
  }

  /// Converts StreakSummary to Map (for debugging/testing).
  Map<String, dynamic> toMap() {
    return {
      'today_read': todayRead,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'calendar': calendar.map((day) => day.toMap()).toList(),
    };
  }
}

