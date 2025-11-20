import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/streak_providers.dart';
import '../../data/streak_summary_model.dart';

/// Calendar widget displaying 30-day streak visualization.
class StreakCalendar extends ConsumerWidget {
  const StreakCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(streakCalendarProvider);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (calendar.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort calendar by date (oldest first for display)
    final sortedCalendar = List<StreakDay>.from(calendar)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Group into weeks (7 columns)
    final weeks = <List<StreakDay?>>[];
    List<StreakDay?> currentWeek = [];

    // Add empty slots for days before first date (if needed)
    final firstDate = sortedCalendar.first.date;
    final firstWeekday = firstDate.weekday; // 1 = Monday, 7 = Sunday
    
    // Adjust: Sunday = 0, Monday = 1, ..., Saturday = 6
    final startOffset = (firstWeekday % 7);
    
    for (int i = 0; i < startOffset; i++) {
      currentWeek.add(null);
    }

    for (final day in sortedCalendar) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // Add remaining days if week is incomplete
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional weekday labels
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((label) => SizedBox(
                      width: 32,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // Calendar grid
        ...weeks.map((week) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: week.map((day) => _buildDayCircle(day, todayDate)).toList(),
              ),
            )),
      ],
    );
  }

  Widget _buildDayCircle(StreakDay? day, DateTime todayDate) {
    if (day == null) {
      return const SizedBox(width: 32, height: 32);
    }

    final isToday = day.date.year == todayDate.year &&
        day.date.month == todayDate.month &&
        day.date.day == todayDate.day;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: day.read ? miqraPrimary : Colors.transparent,
        border: Border.all(
          color: day.read
              ? miqraPrimary
              : (isToday ? miqraGold : Colors.grey[300]!),
          width: isToday ? 2 : 1,
        ),
      ),
    );
  }
}

