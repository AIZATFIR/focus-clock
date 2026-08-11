import 'package:isar/isar.dart';

import '../../models/task.dart';

class TaskRepository {
  TaskRepository(this.isar);
  final Isar? isar;

  final List<Task> _memoryTasks = [];

  Future<List<Task>> getAll() async {
    if (isar == null) return List.unmodifiable(_memoryTasks);
    return isar!.tasks.where().sortByCreatedAtDesc().findAll();
  }

  Stream<List<Task>> watchAll() {
    if (isar == null) return Stream.value(_memoryTasks);
    return isar!.tasks.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  Stream<List<Task>> watchByActivity(int activityId) {
    if (isar == null) {
      return Stream.value(
        _memoryTasks.where((t) => t.activityId == activityId).toList(),
      );
    }
    return isar!.tasks.filter().activityIdEqualTo(activityId).watch(fireImmediately: true);
  }

  Future<int> add(Task task) async {
    if (isar == null) {
      task.createdAt = DateTime.now();
      task.id = _memoryTasks.length + 1;
      _memoryTasks.add(task);
      return task.id;
    }
    return isar!.writeTxn(() async {
      task.createdAt = DateTime.now();
      return await isar!.tasks.put(task);
    });
  }

  Future<bool> update(Task task) async {
    if (isar == null) {
      task.updatedAt = DateTime.now();
      final idx = _memoryTasks.indexWhere((t) => t.id == task.id);
      if (idx >= 0) _memoryTasks[idx] = task;
      return true;
    }
    return isar!.writeTxn(() async {
      task.updatedAt = DateTime.now();
      await isar!.tasks.put(task);
      return true;
    });
  }

  Future<bool> delete(int id) async {
    if (isar == null) {
      _memoryTasks.removeWhere((t) => t.id == id);
      return true;
    }
    return isar!.writeTxn(() async {
      return await isar!.tasks.delete(id);
    });
  }

  Future<void> toggleCompletion(int id) async {
    if (isar == null) {
      final task = _memoryTasks.firstWhere((t) => t.id == id, orElse: () => Task());
      if (task.title.isNotEmpty) {
        task.isCompleted = !task.isCompleted;
        task.updatedAt = DateTime.now();
      }
      return;
    }
    await isar!.writeTxn(() async {
      final task = await isar!.tasks.get(id);
      if (task != null) {
        task.isCompleted = !task.isCompleted;
        task.updatedAt = DateTime.now();
        await isar!.tasks.put(task);
      }
    });
  }

  Future<void> updateEisenhower(int id, int quadrant) async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      final task = await isar!.tasks.get(id);
      if (task != null) {
        task.importance = (quadrant == 0 || quadrant == 1) ? 1 : 0;
        if (quadrant == 0 || quadrant == 2) {
          if (!task.isUrgent) {
            task.deadline = DateTime.now();
          }
        } else {
          task.deadline = null;
        }
        task.updatedAt = DateTime.now();
        await isar!.tasks.put(task);
      }
    });
  }
}
