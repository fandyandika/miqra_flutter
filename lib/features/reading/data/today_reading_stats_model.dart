/// Statistics for today's reading activity.
class TodayReadingStats {
  final int totalAyat;
  final int totalHasanat;
  final int sessionCount;

  const TodayReadingStats({
    required this.totalAyat,
    required this.totalHasanat,
    required this.sessionCount,
  });

  /// Creates empty stats (for initial state).
  factory TodayReadingStats.empty() {
    return const TodayReadingStats(
      totalAyat: 0,
      totalHasanat: 0,
      sessionCount: 0,
    );
  }
}

