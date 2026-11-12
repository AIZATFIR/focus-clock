import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/core/time_math.dart';
import 'package:focus_clock/data/repositories/activity_repository.dart';
import 'package:focus_clock/models/activity.dart';
import 'package:focus_clock/services/goal_schedule_planner.dart';
import 'package:focus_clock/services/notification_service.dart';

void main() {
  test(
    'skips an elapsed window today and only plans weekdays before target',
    () {
      final dates = GoalSchedulePlanner.practiceDates(
        now: DateTime(2026, 11, 10, 15), // Tuesday, after afternoon window
        targetDate: DateTime(2026, 11, 14),
        daysPerWeek: 5,
        startHour: 14,
      );

      expect(dates, [
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 12),
        DateTime(2026, 11, 13),
      ]);
    },
  );

  test(
    'uses the exact start minute when deciding whether today is available',
    () {
      final beforeStart = GoalSchedulePlanner.practiceDates(
        now: DateTime(2026, 11, 10, 16, 15),
        targetDate: DateTime(2026, 11, 14),
        daysPerWeek: 5,
        startHour: 16,
        startMinuteOfHour: 30,
      );
      final atStart = GoalSchedulePlanner.practiceDates(
        now: DateTime(2026, 11, 10, 16, 30),
        targetDate: DateTime(2026, 11, 14),
        daysPerWeek: 5,
        startHour: 16,
        startMinuteOfHour: 30,
      );

      expect(beforeStart.first, DateTime(2026, 11, 10));
      expect(atStart.first, DateTime(2026, 11, 11));
    },
  );

  test('reports a conflict on a projected recurring activity', () async {
    final repository = ActivityRepository(null, NotificationService());
    final recurring = Activity()
      ..title = 'School'
      ..startMinute = 300
      ..endMinute = 330
      ..ampmHalf = AmPmHalf.pm
      ..date = DateTime(2026, 11, 9)
      ..colorValue = 0xFF4A9EFF
      ..recurrence = 'weekday'
      ..recurrenceEndDate = DateTime(2026, 11, 13)
      ..createdAt = DateTime(2026, 11, 9)
      ..updatedAt = DateTime(2026, 11, 9);
    await repository.upsert(recurring);

    final conflict = await GoalSchedulePlanner.firstConflict(
      repository: repository,
      dates: [DateTime(2026, 11, 10)],
      startHour: 16,
      startMinuteOfHour: 30,
      durationMinutes: 45,
    );

    expect(conflict?.date, DateTime(2026, 11, 10));
    expect(conflict?.activity.title, 'School');
  });

  test('rejects invalid times and durations in conflict checks', () async {
    final repository = ActivityRepository(null, NotificationService());

    await expectLater(
      GoalSchedulePlanner.firstConflict(
        repository: repository,
        dates: [DateTime(2026, 11, 10)],
        startHour: 16,
        startMinuteOfHour: 60,
        durationMinutes: 30,
      ),
      throwsArgumentError,
    );
    await expectLater(
      GoalSchedulePlanner.firstConflict(
        repository: repository,
        dates: [DateTime(2026, 11, 10)],
        startHour: 16,
        durationMinutes: 0,
      ),
      throwsArgumentError,
    );
  });
}
