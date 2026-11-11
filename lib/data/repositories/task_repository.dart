import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';

import '../../core/time_math.dart';
import '../storage/fallback_storage.dart';
import '../../models/task.dart';

class TaskRepository {
  TaskRepository(this.isar, {FallbackStorage? fallbackStorage})
    : _fallbackStorage = fallbackStorage;

  static const _storageKey = 'focus_clock.tasks.v1';
  final Isar? isar;
  final FallbackStorage? _fallbackStorage;
  final List<Task> _memoryTasks = [];
  final StreamController<void> _memController =
      StreamController<void>.broadcast();
  int _memoryIdCounter = 1;
  bool _memoryLoaded = false;
  Future<void>? _memoryLoad;
  Future<void> _writeQueue = Future<void>.value();

  Future<void> _ensureMemoryLoaded() async {
    if (_memoryLoaded || _fallbackStorage == null) return;
    _memoryLoad ??= () async {
      final raw = await _fallbackStorage.read(_storageKey);
      if (raw != null) {
        final envelope = jsonDecode(raw);
        if (envelope is! Map<String, dynamic> ||
            envelope['version'] != 1 ||
            envelope['tasks'] is! List) {
          throw const FormatException('Unsupported saved tasks format.');
        }
        _memoryTasks.addAll((envelope['tasks'] as List).map(_taskFromJson));
        _memoryIdCounter = envelope['nextId'] as int? ?? 1;
        for (final task in _memoryTasks) {
          if (task.id >= _memoryIdCounter) _memoryIdCounter = task.id + 1;
        }
      }
      _memoryLoaded = true;
    }();
    await _memoryLoad;
  }

  Future<void> _persistMemory() {
    if (_fallbackStorage == null) return Future<void>.value();
    final snapshot = jsonEncode({
      'version': 1,
      'nextId': _memoryIdCounter,
      'tasks': _memoryTasks.map(_taskToJson).toList(),
    });
    _writeQueue = _writeQueue.then(
      (_) => _fallbackStorage.write(_storageKey, snapshot),
    );
    return _writeQueue;
  }

  Map<String, Object?> _taskToJson(Task task) => {
    'id': task.id,
    'title': task.title,
    'description': task.description,
    'importance': task.importance,
    'deadline': task.deadline?.toIso8601String(),
    'isCompleted': task.isCompleted,
    'createdAt': task.createdAt.toIso8601String(),
    'updatedAt': task.updatedAt?.toIso8601String(),
    'activityId': task.activityId,
    'startMinute': task.startMinute,
    'endMinute': task.endMinute,
    'date': task.date?.toIso8601String(),
    'ampmHalf': task.ampmHalf.index,
    'subtasks': task.subtasks,
  };

  Task _taskFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Saved task is malformed.');
    }
    DateTime? date(String key) =>
        value[key] == null ? null : DateTime.parse(value[key] as String);
    final halfIndex = value['ampmHalf'] as int? ?? 0;
    if (halfIndex < 0 || halfIndex >= AmPmHalf.values.length) {
      throw const FormatException('Saved task has an invalid day half.');
    }
    return Task()
      ..id = value['id'] as int
      ..title = value['title'] as String
      ..description = value['description'] as String?
      ..importance = (value['importance'] as num?)?.toInt() ?? 0
      ..deadline = date('deadline')
      ..isCompleted = value['isCompleted'] as bool? ?? false
      ..createdAt = DateTime.parse(value['createdAt'] as String)
      ..updatedAt = date('updatedAt')
      ..activityId = value['activityId'] as int?
      ..startMinute = value['startMinute'] as int?
      ..endMinute = value['endMinute'] as int?
      ..date = date('date')
      ..ampmHalf = AmPmHalf.values[halfIndex]
      ..subtasks = (value['subtasks'] as List? ?? const []).cast<String>();
  }

  Future<List<Task>> getAll() async {
    if (isar != null) {
      return isar!.tasks.where().sortByCreatedAtDesc().findAll();
    }
    await _ensureMemoryLoaded();
    final result = List<Task>.of(_memoryTasks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  Stream<List<Task>> watchAll() {
    if (isar != null) {
      return isar!.tasks.where().sortByCreatedAtDesc().watch(
        fireImmediately: true,
      );
    }
    return _watchMemoryAll();
  }

  Stream<List<Task>> _watchMemoryAll() async* {
    await _ensureMemoryLoaded();
    yield await getAll();
    await for (final _ in _memController.stream) {
      yield await getAll();
    }
  }

  Stream<List<Task>> watchByActivity(int activityId) {
    if (isar != null) {
      return isar!.tasks
          .filter()
          .activityIdEqualTo(activityId)
          .watch(fireImmediately: true);
    }
    return _watchMemoryByActivity(activityId);
  }

  Stream<List<Task>> _watchMemoryByActivity(int activityId) async* {
    await _ensureMemoryLoaded();
    List<Task> query() =>
        _memoryTasks.where((task) => task.activityId == activityId).toList();
    yield query();
    await for (final _ in _memController.stream) {
      yield query();
    }
  }

  Future<int> add(Task task) async {
    if (isar != null) {
      return isar!.writeTxn(() async {
        task.createdAt = DateTime.now();
        return isar!.tasks.put(task);
      });
    }
    await _ensureMemoryLoaded();
    task.createdAt = DateTime.now();
    if (task.id == Isar.autoIncrement || task.id <= 0) {
      task.id = _memoryIdCounter++;
    } else {
      _memoryIdCounter = task.id >= _memoryIdCounter
          ? task.id + 1
          : _memoryIdCounter;
    }
    _memoryTasks.add(task);
    await _persistMemory();
    _memController.add(null);
    return task.id;
  }

  Future<bool> update(Task task) async {
    if (isar != null) {
      return isar!.writeTxn(() async {
        task.updatedAt = DateTime.now();
        await isar!.tasks.put(task);
        return true;
      });
    }
    await _ensureMemoryLoaded();
    task.updatedAt = DateTime.now();
    final idx = _memoryTasks.indexWhere((item) => item.id == task.id);
    if (idx >= 0) _memoryTasks[idx] = task;
    await _persistMemory();
    _memController.add(null);
    return true;
  }

  Future<bool> delete(int id) async {
    if (isar != null) {
      return isar!.writeTxn(() => isar!.tasks.delete(id));
    }
    await _ensureMemoryLoaded();
    _memoryTasks.removeWhere((task) => task.id == id);
    await _persistMemory();
    _memController.add(null);
    return true;
  }

  Future<void> toggleCompletion(int id) async {
    if (isar != null) {
      await isar!.writeTxn(() async {
        final task = await isar!.tasks.get(id);
        if (task != null) {
          task.isCompleted = !task.isCompleted;
          task.updatedAt = DateTime.now();
          await isar!.tasks.put(task);
        }
      });
      return;
    }
    await _ensureMemoryLoaded();
    final index = _memoryTasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    _memoryTasks[index]
      ..isCompleted = !_memoryTasks[index].isCompleted
      ..updatedAt = DateTime.now();
    await _persistMemory();
    _memController.add(null);
  }

  Future<void> updateEisenhower(int id, int quadrant) async {
    Future<void> updateTask(
      Task? task,
      Future<void> Function(Task) save,
    ) async {
      if (task == null) return;
      task.importance = (quadrant == 0 || quadrant == 1) ? 1 : 0;
      if (quadrant == 0 || quadrant == 2) {
        if (!task.isUrgent) task.deadline = DateTime.now();
      } else {
        task.deadline = null;
      }
      task.updatedAt = DateTime.now();
      await save(task);
    }

    if (isar != null) {
      await isar!.writeTxn(() async {
        await updateTask(
          await isar!.tasks.get(id),
          (task) async => isar!.tasks.put(task),
        );
      });
      return;
    }
    await _ensureMemoryLoaded();
    final index = _memoryTasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    await updateTask(_memoryTasks[index], (_) async {});
    await _persistMemory();
    _memController.add(null);
  }
}
