import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/streak_service.dart';
import '../data/streak_summary_model.dart';
import '../../auth/providers/auth_providers.dart';

/// Provider for StreakService instance.
final streakServiceProvider = Provider<StreakService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StreakService(client);
});

/// Provider for streak summary data.
/// 
/// Auto-disposes when not watched to avoid unnecessary queries.
final streakSummaryProvider =
    FutureProvider.autoDispose<StreakSummary>((ref) async {
  final service = ref.read(streakServiceProvider);
  return service.getStreakSummary(days: 30);
});

/// Helper provider: Whether user read today.
final streakTodayReadProvider = Provider<bool>((ref) {
  final summaryAsync = ref.watch(streakSummaryProvider);
  return summaryAsync.when(
    data: (summary) => summary.todayRead,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Helper provider: Current streak count.
final streakCurrentProvider = Provider<int>((ref) {
  final summaryAsync = ref.watch(streakSummaryProvider);
  return summaryAsync.when(
    data: (summary) => summary.currentStreak,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Helper provider: Best streak count.
final streakBestProvider = Provider<int>((ref) {
  final summaryAsync = ref.watch(streakSummaryProvider);
  return summaryAsync.when(
    data: (summary) => summary.bestStreak,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Helper provider: Calendar list of streak days.
final streakCalendarProvider = Provider<List<StreakDay>>((ref) {
  final summaryAsync = ref.watch(streakSummaryProvider);
  return summaryAsync.when(
    data: (summary) => summary.calendar,
    loading: () => [],
    error: (_, __) => [],
  );
});

