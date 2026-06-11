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

  late DateTime createdAt;
  late DateTime updatedAt;
}
