import 'dart:convert';
import 'package:isar/isar.dart';
import '../core/time_math.dart';

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

  // ── Scheduling inside Clock ───────────────────────────────────────────────
  
  /// The ID of the Activity block this task is assigned to
  int? activityId;

  /// The start minute of this task within the clock face
  int? startMinute;

  /// The end minute of this task within the clock face
  int? endMinute;

  /// Direct date scheduling
  DateTime? date;

  /// Direct AM/PM half scheduling
  @enumerated
  AmPmHalf ampmHalf = AmPmHalf.am;

  /// JSON serialized subtasks: {"title": String, "isCompleted": bool}
  List<String> subtasks = [];

  @ignore
  List<SubTask> get subtaskList {
    return subtasks.map((s) {
      try {
        final decoded = jsonDecode(s) as Map<String, dynamic>;
        return SubTask.fromJson(decoded);
      } catch (_) {
        return SubTask(title: s);
      }
    }).toList();
  }

  set subtaskList(List<SubTask> list) {
    subtasks = list.map((s) => jsonEncode(s.toJson())).toList();
  }

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

class SubTask {
  SubTask({required this.title, this.isCompleted = false});
  String title;
  bool isCompleted;

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'isCompleted': isCompleted,
      };
}
