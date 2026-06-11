import 'dart:async';

import 'package:isar/isar.dart';

import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../services/notification_service.dart';

class ActivityRepository {
  ActivityRepository(this._isar, this._notifier);
  final Isar _isar;
  final NotificationService _notifier;

  Stream<List<Activity>> watchByDateAndHalf(DateTime date, AmPmHalf half) {
    final d = dateOnly(date);
    // Direct activities for this date+half
    final direct = _isar.activitys
        .filter()
        .dateEqualTo(d)
        .ampmHalfEqualTo(half)
        .sortByStartMinute()
        .watch(fireImmediately: true);

    // Merge with recurring activities
    return _mergeWithRecurring(direct, d, half: half);
  }

  Stream<List<Activity>> watchByDate(DateTime date) {
    final d = dateOnly(date);
    final direct = _isar.activitys
        .filter()
        .dateEqualTo(d)
        .sortByAmpmHalf()
        .thenByStartMinute()
        .watch(fireImmediately: true);

    return _mergeWithRecurring(direct, d);
  }

  /// Merges direct activities with projected recurring activities.
  Stream<List<Activity>> _mergeWithRecurring(
    Stream<List<Activity>> direct,
    DateTime targetDate, {
    AmPmHalf? half,
  }) {
    return direct.asyncMap((list) async {
      final recurring = await _getRecurring(targetDate, half: half);
      // Only add recurring entries not already covered by an explicit entry
      final existingTitles = list.map((a) => '${a.title}_${a.startMinute}').toSet();
      final projected = recurring.where((r) =>
          !existingTitles.contains('${r.title}_${r.startMinute}'));
      final all = [...list, ...projected];
      all.sort((a, b) {
        final halfCmp = a.ampmHalf.index.compareTo(b.ampmHalf.index);
        if (halfCmp != 0) return halfCmp;
        return a.startMinute.compareTo(b.startMinute);
      });
      return all;
    });
  }

  Future<List<Activity>> _getRecurring(DateTime targetDate,
      {AmPmHalf? half}) async {
    // Fetch all recurring activities
    final all = await _isar.activitys
        .filter()
        .not()
        .recurrenceEqualTo('none')
        .findAll();

    return all.where((a) {
      // Skip same-date originals (already included directly)
      if (dateOnly(a.date) == targetDate) return false;
      if (half != null && a.ampmHalf != half) return false;

      if (a.recurrence == 'daily') return true;
      if (a.recurrence == 'weekly') {
        return a.date.weekday == targetDate.weekday;
      }
      return false;
    }).map((a) {
      // Project to target date (keep same time/half)
      final projected = Activity()
        ..id = a.id // same id = tap opens original
        ..presetId = a.presetId
        ..iconKey = a.iconKey
        ..title = a.title
        ..startMinute = a.startMinute
        ..endMinute = a.endMinute
        ..ampmHalf = a.ampmHalf
        ..date = targetDate
        ..description = a.description
        ..colorValue = a.colorValue
        ..recurrence = a.recurrence
        ..createdAt = a.createdAt
        ..updatedAt = a.updatedAt;
      return projected;
    }).toList();
  }

  Future<int> upsert(Activity a, {int notifLeadMinutes = 1}) async {
    a.updatedAt = DateTime.now();
    final id = await _isar.writeTxn(() => _isar.activitys.put(a));
    await _notifier.scheduleForActivity(a, leadMinutes: notifLeadMinutes);
    return id;
  }

  Future<bool> delete(int id) async {
    await _notifier.cancelForActivity(id);
    return _isar.writeTxn(() => _isar.activitys.delete(id));
  }

  Future<Activity?> get(int id) => _isar.activitys.get(id);

  Future<List<Activity>> getByDate(DateTime date) async {
    final d = dateOnly(date);
    final direct = await _isar.activitys
        .filter()
        .dateEqualTo(d)
        .sortByAmpmHalf()
        .thenByStartMinute()
        .findAll();
    final recurring = await _getRecurring(d);
    final existingTitles =
        direct.map((a) => '${a.title}_${a.startMinute}').toSet();
    final projected = recurring
        .where((r) => !existingTitles.contains('${r.title}_${r.startMinute}'));
    final all = [...direct, ...projected];
    all.sort((a, b) {
      final hc = a.ampmHalf.index.compareTo(b.ampmHalf.index);
      return hc != 0 ? hc : a.startMinute.compareTo(b.startMinute);
    });
    return all;
  }
}
