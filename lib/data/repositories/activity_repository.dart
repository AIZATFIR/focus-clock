import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';

import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../services/notification_service.dart';
import '../storage/fallback_storage.dart';

class ActivityRepository {
  ActivityRepository(
    this._isar,
    this._notifier, {
    FallbackStorage? fallbackStorage,
  }) : _fallbackStorage = fallbackStorage;
  static const _storageKey = 'focus_clock.activities.v1';
  final Isar? _isar;
  final NotificationService _notifier;
  final FallbackStorage? _fallbackStorage;

  // In-Memory Fallback when Isar is unavailable (Web without IndexedDB/WASM or test runner)
  final Map<int, Activity> _memStore = {};
  int _memIdCounter = 1;
  final StreamController<void> _memController =
      StreamController<void>.broadcast();
  bool _memoryLoaded = false;
  Future<void>? _memoryLoad;
  Future<void> _memoryWriteQueue = Future<void>.value();

  Future<void> _ensureMemoryLoaded() async {
    if (_memoryLoaded || _fallbackStorage == null) return;
    _memoryLoad ??= () async {
      final raw = await _fallbackStorage.read(_storageKey);
      if (raw != null) {
        final envelope = jsonDecode(raw);
        if (envelope is! Map<String, dynamic> ||
            envelope['version'] != 1 ||
            envelope['activities'] is! List) {
          throw const FormatException('Unsupported saved activities format.');
        }
        for (final item in envelope['activities'] as List) {
          final activity = _activityFromJson(item);
          _memStore[activity.id] = activity;
        }
        _memIdCounter = envelope['nextId'] as int? ?? 1;
      }
      _memoryLoaded = true;
    }();
    await _memoryLoad;
  }

  Future<void> _persistMemory() {
    if (_fallbackStorage == null) return Future<void>.value();
    final snapshot = jsonEncode({
      'version': 1,
      'nextId': _memIdCounter,
      'activities': _memStore.values.map(_activityToJson).toList(),
    });
    _memoryWriteQueue = _memoryWriteQueue.then(
      (_) => _fallbackStorage.write(_storageKey, snapshot),
    );
    return _memoryWriteQueue;
  }

  Map<String, Object?> _activityToJson(Activity a) => {
    'id': a.id,
    'presetId': a.presetId,
    'iconKey': a.iconKey,
    'title': a.title,
    'startMinute': a.startMinute,
    'endMinute': a.endMinute,
    'ampmHalf': a.ampmHalf.index,
    'date': a.date.toIso8601String(),
    'description': a.description,
    'colorValue': a.colorValue,
    'recurrence': a.recurrence,
    'recurrenceEndDate': a.recurrenceEndDate?.toIso8601String(),
    'groupId': a.groupId,
    'importance': a.importance,
    'deadline': a.deadline?.toIso8601String(),
    'isCompleted': a.isCompleted,
    'isLocked': a.isLocked,
    'excludedDates': a.excludedDates.map((d) => d.toIso8601String()).toList(),
    'createdAt': a.createdAt.toIso8601String(),
    'updatedAt': a.updatedAt.toIso8601String(),
  };

  Activity _activityFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Saved activity is malformed.');
    }
    DateTime? date(String key) =>
        value[key] == null ? null : DateTime.parse(value[key] as String);
    final half = value['ampmHalf'] as int? ?? 0;
    return Activity()
      ..id = value['id'] as int
      ..presetId = value['presetId'] as int?
      ..iconKey = value['iconKey'] as String?
      ..title = value['title'] as String
      ..startMinute = value['startMinute'] as int
      ..endMinute = value['endMinute'] as int
      ..ampmHalf = AmPmHalf.values[half]
      ..date = DateTime.parse(value['date'] as String)
      ..description = value['description'] as String? ?? ''
      ..colorValue = value['colorValue'] as int
      ..recurrence = value['recurrence'] as String? ?? 'none'
      ..recurrenceEndDate = date('recurrenceEndDate')
      ..groupId = value['groupId'] as String?
      ..importance = value['importance'] as int? ?? 0
      ..deadline = date('deadline')
      ..isCompleted = value['isCompleted'] as bool? ?? false
      ..isLocked = value['isLocked'] as bool? ?? false
      ..excludedDates = (value['excludedDates'] as List? ?? const [])
          .cast<String>()
          .map(DateTime.parse)
          .toList()
      ..createdAt = DateTime.parse(value['createdAt'] as String)
      ..updatedAt = DateTime.parse(value['updatedAt'] as String);
  }

  Stream<List<Activity>> watchByDateAndHalf(DateTime date, AmPmHalf half) {
    final d = dateOnly(date);
    if (_isar == null) {
      return _watchMemoryByDate(d, half: half);
    }
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
    if (_isar == null) {
      return _watchMemoryByDate(d);
    }
    final direct = _isar.activitys
        .filter()
        .dateEqualTo(d)
        .sortByAmpmHalf()
        .thenByStartMinute()
        .watch(fireImmediately: true);

    return _mergeWithRecurring(direct, d);
  }

  Stream<List<Activity>> _watchMemoryByDate(
    DateTime targetDate, {
    AmPmHalf? half,
  }) async* {
    await _ensureMemoryLoaded();
    Future<List<Activity>> query() async {
      final list = _memStore.values.where((a) {
        if (dateOnly(a.date) != targetDate) return false;
        if (half != null && a.ampmHalf != half) return false;
        return true;
      }).toList();
      return _includeRecurring(list, targetDate, half: half);
    }

    yield await query();
    await for (final _ in _memController.stream) {
      yield await query();
    }
  }

  /// Merges direct activities with projected recurring activities.
  Stream<List<Activity>> _mergeWithRecurring(
    Stream<List<Activity>> direct,
    DateTime targetDate, {
    AmPmHalf? half,
  }) {
    return direct.asyncMap(
      (list) => _includeRecurring(list, targetDate, half: half),
    );
  }

  Future<List<Activity>> _includeRecurring(
    List<Activity> direct,
    DateTime targetDate, {
    AmPmHalf? half,
  }) async {
    if (_isar == null) await _ensureMemoryLoaded();
    final recurring = await _getRecurring(targetDate, half: half);
    final existingTitles = direct
        .map((a) => '${a.title}_${a.startMinute}')
        .toSet();
    final all = [
      ...direct,
      ...recurring.where(
        (a) => !existingTitles.contains('${a.title}_${a.startMinute}'),
      ),
    ];
    all.sort((a, b) {
      final halfCmp = a.ampmHalf.index.compareTo(b.ampmHalf.index);
      return halfCmp != 0 ? halfCmp : a.startMinute.compareTo(b.startMinute);
    });
    return all;
  }

  Future<List<Activity>> _getRecurring(
    DateTime targetDate, {
    AmPmHalf? half,
  }) async {
    final target = dateOnly(targetDate);
    final all = _isar == null
        ? _memStore.values.where((a) => a.recurrence != 'none').toList()
        : await _isar.activitys
              .filter()
              .not()
              .recurrenceEqualTo('none')
              .findAll();

    return all
        .where((a) {
          // Skip same-date originals (already included directly)
          if (dateOnly(a.date) == target) return false;
          if (half != null && a.ampmHalf != half) return false;
          if (a.recurrenceEndDate != null &&
              target.isAfter(dateOnly(a.recurrenceEndDate!))) {
            return false;
          }

          // Skip excluded dates (single-day deletions)
          if (a.excludedDates.any((d) => dateOnly(d) == target)) return false;

          if (a.recurrence == 'daily') return true;
          if (a.recurrence == 'weekday') {
            return target.weekday >= 1 && target.weekday <= 5;
          }
          if (a.recurrence == 'weekly') {
            return a.date.weekday == target.weekday;
          }
          return false;
        })
        .map((a) {
          // Project to target date (keep same time/half)
          final projected = Activity()
            ..id = a
                .id // same id = tap opens original
            ..presetId = a.presetId
            ..iconKey = a.iconKey
            ..title = a.title
            ..startMinute = a.startMinute
            ..endMinute = a.endMinute
            ..ampmHalf = a.ampmHalf
            ..date = target
            ..description = a.description
            ..colorValue = a.colorValue
            ..recurrence = a.recurrence
            ..recurrenceEndDate = a.recurrenceEndDate
            ..isLocked = a.isLocked
            ..excludedDates = a.excludedDates
            ..createdAt = a.createdAt
            ..updatedAt = a.updatedAt;
          return projected;
        })
        .toList();
  }

  Future<int> upsert(Activity a, {int notifLeadMinutes = 1}) async {
    a.date = dateOnly(a.date);
    a.updatedAt = DateTime.now();
    if (_isar == null) {
      await _ensureMemoryLoaded();
      if (a.id == Isar.autoIncrement || a.id <= 0) {
        a.id = _memIdCounter++;
      }
      _memStore[a.id] = a;
      await _persistMemory();
      _memController.add(null);
      return a.id;
    }
    final id = await _isar.writeTxn(() => _isar.activitys.put(a));
    await _notifier.scheduleForActivity(a, leadMinutes: notifLeadMinutes);
    return id;
  }

  /// Delete only a single instance of a recurring activity for [targetDate].
  Future<void> deleteSingleInstance(Activity a, DateTime targetDate) async {
    final target = dateOnly(targetDate);
    if (_isar == null) {
      await _ensureMemoryLoaded();
      final stored = _memStore[a.id];
      if (stored != null && stored.recurrence != 'none') {
        if (!stored.excludedDates.any((d) => dateOnly(d) == target)) {
          stored.excludedDates = [...stored.excludedDates, target];
        }
      } else {
        _memStore.remove(a.id);
      }
      await _persistMemory();
      _memController.add(null);
      return;
    }
    final dbActivity = await _isar.activitys.get(a.id);

    if (dbActivity != null && dbActivity.recurrence != 'none') {
      if (!dbActivity.excludedDates.any((d) => dateOnly(d) == target)) {
        dbActivity.excludedDates = [...dbActivity.excludedDates, target];
        dbActivity.updatedAt = DateTime.now();
        await _isar.writeTxn(() => _isar.activitys.put(dbActivity));
      }
    } else {
      await deleteGroupOf(a);
    }
  }

  /// Duplicate [a] as a new standalone activity on [targetDate].
  Future<int> duplicateActivity(Activity a, DateTime targetDate) async {
    final now = DateTime.now();
    final copy = Activity()
      ..presetId = a.presetId
      ..iconKey = a.iconKey
      ..title = '${a.title} (Copy)'
      ..startMinute = a.startMinute
      ..endMinute = a.endMinute
      ..ampmHalf = a.ampmHalf
      ..date = dateOnly(targetDate)
      ..description = a.description
      ..colorValue = a.colorValue
      ..recurrence = 'none'
      ..recurrenceEndDate = null
      ..importance = a.importance
      ..deadline = a.deadline
      ..isCompleted = false
      ..isLocked = false
      ..createdAt = now
      ..updatedAt = now;

    return upsert(copy);
  }

  /// Toggle lock status of [a].
  Future<void> toggleLock(Activity a, bool locked) async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
      final memAct = _memStore[a.id];
      if (memAct != null) {
        memAct.isLocked = locked;
        await _persistMemory();
        _memController.add(null);
      }
      return;
    }
    final dbActivity = await _isar.activitys.get(a.id);
    if (dbActivity == null) return;
    dbActivity.isLocked = locked;
    dbActivity.updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.activitys.put(dbActivity));
  }

  Future<List<Activity>> getGroup(String groupId) async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
      return _memStore.values.where((a) => a.groupId == groupId).toList();
    }
    return _isar.activitys
        .filter()
        .groupIdEqualTo(groupId)
        .sortByDate()
        .findAll();
  }

  /// Replace [original] (and its whole group, if any) with [segments]
  /// in one transaction. Used for cross-midnight spans.
  Future<void> replaceSpan({
    required Activity original,
    required List<Activity> segments,
    int notifLeadMinutes = 1,
  }) async {
    final now = DateTime.now();
    for (final s in segments) {
      s.date = dateOnly(s.date);
      s.updatedAt = now;
    }
    if (_isar == null) {
      await _ensureMemoryLoaded();
      if (original.groupId != null) {
        _memStore.removeWhere((_, a) => a.groupId == original.groupId);
      } else {
        _memStore.remove(original.id);
      }
      for (final s in segments) {
        if (s.id == Isar.autoIncrement || s.id <= 0) {
          s.id = _memIdCounter++;
        }
        _memStore[s.id] = s;
      }
      await _persistMemory();
      _memController.add(null);
      return;
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
    await _notifier.scheduleForActivity(
      segments.first,
      leadMinutes: notifLeadMinutes,
    );
  }

  /// Delete activity; if it belongs to a group, delete every segment.
  Future<void> deleteGroupOf(Activity a) async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
      if (a.groupId == null) {
        _memStore.remove(a.id);
      } else {
        _memStore.removeWhere((_, act) => act.groupId == a.groupId);
      }
      await _persistMemory();
      _memController.add(null);
      return;
    }
    if (a.groupId == null) {
      await delete(a.id);
      return;
    }
    final group = await getGroup(a.groupId!);
    await _isar.writeTxn(
      () => _isar.activitys.deleteAll(group.map((x) => x.id).toList()),
    );
    for (final g in group) {
      await _notifier.cancelForActivity(g.id);
    }
  }

  Future<bool> delete(int id) async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
      _memStore.remove(id);
      await _persistMemory();
      _memController.add(null);
      return true;
    }
    final result = await _isar.writeTxn(() => _isar.activitys.delete(id));
    await _notifier.cancelForActivity(id);
    return result;
  }

  Future<Activity?> get(int id) async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
      return _memStore[id];
    }
    return _isar.activitys.get(id);
  }

  /// Watch activities for a whole week (Mon–Sun containing [date]).
  Stream<List<Activity>> watchWeek(DateTime date) {
    final d = dateOnly(date);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    if (_isar == null) {
      return Stream.fromFuture(
        _ensureMemoryLoaded().then(
          (_) => _memStore.values.where((a) {
            final ad = dateOnly(a.date);
            return !ad.isBefore(monday) && !ad.isAfter(sunday);
          }).toList(),
        ),
      );
    }
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
    if (_isar == null) {
      return Stream.fromFuture(
        _ensureMemoryLoaded().then(
          (_) => _memStore.values.where((a) {
            final ad = dateOnly(a.date);
            return !ad.isBefore(today) && !ad.isAfter(end);
          }).toList(),
        ),
      );
    }
    return _isar.activitys
        .filter()
        .dateBetween(today, end)
        .sortByDate()
        .thenByAmpmHalf()
        .thenByStartMinute()
        .watch(fireImmediately: true);
  }

  Future<void> markComplete(Activity activity, bool done) async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
      final act = _memStore[activity.id];
      if (act != null) {
        act.isCompleted = done;
        await _persistMemory();
        _memController.add(null);
      }
      return;
    }
    final dbActivity = await _isar.activitys.get(activity.id);
    if (dbActivity == null) return;

    if (dbActivity.recurrence != 'none' &&
        dateOnly(dbActivity.date) != dateOnly(activity.date)) {
      final clone = _cloneForSpecificDate(dbActivity, activity.date)
        ..isCompleted = done;
      await _isar.writeTxn(() => _isar.activitys.put(clone));
    } else {
      dbActivity.isCompleted = done;
      dbActivity.updatedAt = DateTime.now();
      await _isar.writeTxn(() => _isar.activitys.put(dbActivity));
    }
  }

  Future<void> setImportance(Activity activity, int importance) async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
      final act = _memStore[activity.id];
      if (act != null) {
        act.importance = importance;
        await _persistMemory();
        _memController.add(null);
      }
      return;
    }
    final dbActivity = await _isar.activitys.get(activity.id);
    if (dbActivity == null) return;

    if (dbActivity.recurrence != 'none' &&
        dateOnly(dbActivity.date) != dateOnly(activity.date)) {
      final clone = _cloneForSpecificDate(dbActivity, activity.date)
        ..importance = importance;
      await _isar.writeTxn(() => _isar.activitys.put(clone));
    } else {
      dbActivity.importance = importance;
      dbActivity.updatedAt = DateTime.now();
      await _isar.writeTxn(() => _isar.activitys.put(dbActivity));
    }
  }

  Future<void> setDeadline(Activity activity, DateTime? deadline) async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
      final act = _memStore[activity.id];
      if (act != null) {
        act.deadline = deadline;
        await _persistMemory();
        _memController.add(null);
      }
      return;
    }
    final dbActivity = await _isar.activitys.get(activity.id);
    if (dbActivity == null) return;

    if (dbActivity.recurrence != 'none' &&
        dateOnly(dbActivity.date) != dateOnly(activity.date)) {
      final clone = _cloneForSpecificDate(dbActivity, activity.date)
        ..deadline = deadline;
      await _isar.writeTxn(() => _isar.activitys.put(clone));
    } else {
      dbActivity.deadline = deadline;
      dbActivity.updatedAt = DateTime.now();
      await _isar.writeTxn(() => _isar.activitys.put(dbActivity));
    }
  }

  Activity _cloneForSpecificDate(Activity dbActivity, DateTime targetDate) {
    return Activity()
      ..presetId = dbActivity.presetId
      ..iconKey = dbActivity.iconKey
      ..title = dbActivity.title
      ..startMinute = dbActivity.startMinute
      ..endMinute = dbActivity.endMinute
      ..ampmHalf = dbActivity.ampmHalf
      ..date = dateOnly(targetDate)
      ..description = dbActivity.description
      ..colorValue = dbActivity.colorValue
      ..recurrence = 'none'
      ..importance = dbActivity.importance
      ..deadline = dbActivity.deadline
      ..isCompleted = dbActivity.isCompleted
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }

  Future<List<Activity>> getByDate(DateTime date) async {
    final d = dateOnly(date);
    if (_isar == null) {
      await _ensureMemoryLoaded();
      final list = _memStore.values
          .where((a) => dateOnly(a.date) == d)
          .toList();
      return _includeRecurring(list, d);
    }
    final direct = await _isar.activitys
        .filter()
        .dateEqualTo(d)
        .sortByAmpmHalf()
        .thenByStartMinute()
        .findAll();
    return _includeRecurring(direct, d);
  }

  Future<List<Activity>> getConflicting(
    DateTime date,
    AmPmHalf half,
    int start,
    int end, {
    int? excludeId,
  }) async {
    final all = await getByDate(date);
    return all.where((a) {
      if (excludeId != null && a.id == excludeId) return false;
      if (a.ampmHalf != half) return false;
      return rangesOverlap(a.startMinute, a.endMinute, start, end);
    }).toList();
  }
}
