import 'package:isar/isar.dart';
import '../core/time_math.dart';

part 'activity.g.dart';

@collection
class Activity {
  Id id = Isar.autoIncrement;

  int? presetId;
  String? iconKey; // emoji from preset

  late String title;

  /// Minute within the half-day (0..720). 0 = 12:00 of that half.
  late int startMinute;
  late int endMinute;

  @Enumerated(EnumType.ordinal)
  late AmPmHalf ampmHalf;

  /// Calendar date (time zeroed).
  @Index()
  late DateTime date;

  String description = '';
  late int colorValue;

  /// Recurrence: 'none' | 'daily' | 'weekly'
  String recurrence = 'none';

  /// Segments of one cross-midnight block share a groupId (null = standalone).
  @Index()
  String? groupId;

  /// Eisenhower importance: 0 = low, 1 = high.
  int importance = 0;

  /// Optional deadline (date only, time zeroed).
  DateTime? deadline;

  /// Whether this activity has been completed.
  bool isCompleted = false;

  late DateTime createdAt;
  late DateTime updatedAt;

  /// Urgency: true if deadline is within 3 days or already past.
  bool get isUrgent {
    if (deadline == null) return false;
    return deadline!.difference(DateTime.now()).inDays <= 3;
  }

  /// Eisenhower quadrant index 0-3.
  /// 0 = Do (urgent+important), 1 = Schedule (not urgent+important),
  /// 2 = Delegate (urgent+not important), 3 = Eliminate (not urgent+not important)
  int get eisenhowerQuadrant {
    final u = isUrgent;
    final i = importance >= 1;
    if (u && i) return 0;
    if (!u && i) return 1;
    if (u && !i) return 2;
    return 3;
  }
}
