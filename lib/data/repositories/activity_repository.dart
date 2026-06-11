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

  Future<List<Activity>> getGroup(String groupId) =>
      _isar.activitys.filter().groupIdEqualTo(groupId).sortByDate().findAll();

  /// Replace [original] (and its whole group, if any) with [segments]
  /// in one transaction. Used for cross-midnight spans.
  Future<void> replaceSpan({
    required Activity original,
    required List<Activity> segments,
    int notifLeadMinutes = 1,
  }) async {
    final now = DateTime.now();
    for (final s in segments) {
      s.updatedAt = now;
    }
    final oldIds = <int>[];
    await _isar.writeTxn(() async {
      if (original.groupId != null) {
        final olds = await _isar.activitys
            .filter()
            .groupIdEqualTo(original.groupId)
            .findAll();
        oldIds.addAll(olds.map((o) => o.id));
        await _isar.activitys.deleteAll(oldIds);
      } else if (original.id != Isar.autoIncrement) {
        oldIds.add(original.id);
        await _isar.activitys.delete(original.id);
      }
      await _isar.activitys.putAll(segments);
    });
    for (final id in oldIds) {
      await _notifier.cancelForActivity(id);
    }
    // One reminder at the block's true start (first segment)
    await _notifier.scheduleForActivity(segments.first,
        leadMinutes: notifLeadMinutes);
  }

  /// Delete activity; if it belongs to a group, delete every segment.
  Future<void> deleteGroupOf(Activity a) async {
    if (a.groupId == null) {
      await delete(a.id);
      return;
    }
    final group = await getGroup(a.groupId!);
    await _isar.writeTxn(
        () => _isar.activitys.deleteAll(group.map((g) => g.id).toList()));
    for (final g in group) {
      await _notifier.cancelForActivity(g.id);
    }
  }

  Future<bool> delete(int id) async {
    await _notifier.cancelForActivity(id);
    return _isar.writeTxn(() => _isar.activitys.delete(id));
  }

  Future<Activity?> get(int id) => _isar.activitys.get(id);

  /// Watch activities for a whole week (Mon–Sun containing [date]).
  Stream<List<Activity>> watchWeek(DateTime date) {
    final d = dateOnly(date);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return _isar.activitys
        .filter()
        .dateBetween(monday, sunday)
        .sortByDate()
        .thenByAmpmHalf()
        .thenByStartMinute()
        .watch(fireImmediately: true);
  }

  /// Watch all activities from today through the next [days] days (for Eisenhower).
  Stream<List<Activity>> watchUpcoming({int days = 14}) {
    final today = dateOnly(DateTime.now());
    final end = today.add(Duration(days: days));
    return _isar.activitys
        .filter()
        .dateBetween(today, end)
        .sortByDate()
        .thenByAmpmHalf()
        .thenByStartMinute()
        .watch(fireImmediately: true);
  }

  Future<void> markComplete(int id, bool done) async {
    final a = await _isar.activitys.get(id);
    if (a == null) return;
    a.isCompleted = done;
    a.updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.activitys.put(a));
  }

  Future<void> setImportance(int id, int importance) async {
    final a = await _isar.activitys.get(id);
    if (a == null) return;
    a.importance = importance;
    a.updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.activitys.put(a));
  }

  Future<void> setDeadline(int id, DateTime? deadline) async {
    final a = await _isar.activitys.get(id);
    if (a == null) return;
    a.deadline = deadline;
    a.updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.activitys.put(a));
  }

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
