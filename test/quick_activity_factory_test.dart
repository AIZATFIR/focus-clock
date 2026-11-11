import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/core/time_math.dart';
import 'package:focus_clock/features/focusclock/quick_activity_factory.dart';
import 'package:focus_clock/features/focusclock/widgets/quick_activity_sheet.dart';

void main() {
  const draft = QuickActivityDraft(title: 'Study LKS', durationMinutes: 60);
  final date = DateTime(2026, 11, 10, 18);
  final createdAt = DateTime(2026, 11, 10, 9);

  test('stores a PM time correctly on the 12-hour dial', () {
    final activity = createActivityFromQuickDraft(
      draft,
      startMinute: 630,
      is24h: false,
      selectedHalf: AmPmHalf.pm,
      date: date,
      colorValue: 0xFFF0C987,
      createdAt: createdAt,
    );

    expect(activity.title, 'Study LKS');
    expect(activity.ampmHalf, AmPmHalf.pm);
    expect(activity.startMinute, 630);
    expect(activity.endMinute, 690);
    expect(activity.date, DateTime(2026, 11, 10));
    expect(activity.createdAt, createdAt);
  });

  test('stores absolute 24-hour time in its half-day partition', () {
    final activity = createActivityFromQuickDraft(
      draft,
      startMinute: 825,
      is24h: true,
      selectedHalf: AmPmHalf.am,
      date: date,
      colorValue: 0xFFF0C987,
      createdAt: createdAt,
    );

    expect(activity.ampmHalf, AmPmHalf.pm);
    expect(activity.startMinute, 105);
    expect(activity.endMinute, 165);
  });

  test('keeps an activity ending at midnight within the final day minute', () {
    final activity = createActivityFromQuickDraft(
      const QuickActivityDraft(title: 'Read', durationMinutes: 5),
      startMinute: 1435,
      is24h: true,
      selectedHalf: AmPmHalf.pm,
      date: date,
      colorValue: 0xFFF0C987,
      createdAt: createdAt,
    );

    expect(activity.ampmHalf, AmPmHalf.pm);
    expect(activity.startMinute, 715);
    expect(activity.endMinute, 720);
  });
}
