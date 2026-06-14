import 'package:isar/isar.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  late String title;

  String? description;

  /// 0 = low, 1 = high
  short importance = 0;

  DateTime? deadline;

  bool isCompleted = false;

  late DateTime createdAt;

  DateTime? updatedAt;

  /// Returns Eisenhower quadrant:
  /// 0: DO FIRST (Urgent & Important)
  /// 1: SCHEDULE (Not Urgent & Important)
  /// 2: DELEGATE (Urgent & Not Important)
  /// 3: ELIMINATE (Not Urgent & Not Important)
  @ignore
  int get eisenhowerQuadrant {
    final urgent = isUrgent;
    final important = importance > 0;
    if (urgent && important) return 0;
    if (!urgent && important) return 1;
    if (urgent && !important) return 2;
    return 3;
  }

  @ignore
  bool get isUrgent {
    if (deadline == null) return false;
    final diff = deadline!.difference(DateTime.now());
    // If it's due in 3 days or already overdue, it's urgent
    return diff.inDays <= 3;
  }
}
