import '../core/time_math.dart';
import '../data/repositories/activity_repository.dart';
import '../models/activity.dart';

class GoalSchedulePlanner {
  static List<DateTime> practiceDates({
    required DateTime now,
    required DateTime targetDate,
    required int daysPerWeek,
    required int startHour,
  }) {
    final today = dateOnly(now);
    final target = dateOnly(targetDate);
    if ((daysPerWeek != 5 && daysPerWeek != 7) ||
        !target.isAfter(today) ||
        startHour < 0 ||
        startHour > 23) {
      return const [];
    }

    final dates = <DateTime>[];
    for (
      var date = today;
      date.isBefore(target);
      date = date.add(const Duration(days: 1))
    ) {
      if (daysPerWeek == 5 && date.weekday > DateTime.friday) continue;
      if (date == today &&
          !DateTime(date.year, date.month, date.day, startHour).isAfter(now)) {
        continue;
      }
      dates.add(date);
    }
    return dates;
  }

  static Future<({DateTime date, Activity activity})?> firstConflict({
    required ActivityRepository repository,
    required List<DateTime> dates,
    required int startHour,
    required int durationMinutes,
  }) async {
    for (final date in dates) {
      final start = DateTime(date.year, date.month, date.day, startHour);
      final end = start.add(Duration(minutes: durationMinutes));
      for (final segment in splitSpan(start, end)) {
        final conflicts = await repository.getConflicting(
          segment.date,
          segment.half,
          segment.start,
          segment.end,
        );
        if (conflicts.isNotEmpty) {
          return (date: segment.date, activity: conflicts.first);
        }
      }
    }
    return null;
  }
}
