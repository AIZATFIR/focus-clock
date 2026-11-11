import '../../core/time_math.dart';
import '../../models/activity.dart';
import 'widgets/quick_activity_sheet.dart';

Activity createActivityFromQuickDraft(
  QuickActivityDraft draft, {
  required int startMinute,
  required bool is24h,
  required AmPmHalf selectedHalf,
  required DateTime date,
  required int colorValue,
  DateTime? createdAt,
}) {
  final start24 = is24h
      ? startMinute
      : startMinute + (selectedHalf == AmPmHalf.pm ? 720 : 0);
  final half = toDbHalf(start24);
  final now = createdAt ?? DateTime.now();

  return Activity()
    ..title = draft.title.trim()
    ..startMinute = toDbMinute(start24)
    ..endMinute = toDbEndMinute(start24 + draft.durationMinutes, half)
    ..ampmHalf = half
    ..date = dateOnly(date)
    ..colorValue = colorValue
    ..description = ''
    ..focusGoalLink = draft.focusGoalLink
    ..recurrence = 'none'
    ..createdAt = now
    ..updatedAt = now;
}
