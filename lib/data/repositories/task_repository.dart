import 'package:isar/isar.dart';

import '../../models/task.dart';

class TaskRepository {
  TaskRepository(this.isar);
  final Isar isar;

  Future<List<Task>> getAll() async {
    return isar.tasks.where().sortByCreatedAtDesc().findAll();
  }

  Stream<List<Task>> watchAll() {
    return isar.tasks.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  Stream<List<Task>> watchByActivity(int activityId) {
    return isar.tasks.filter().activityIdEqualTo(activityId).watch(fireImmediately: true);
  }

  Future<int> add(Task task) async {
    return isar.writeTxn(() async {
      task.createdAt = DateTime.now();
      return await isar.tasks.put(task);
    });
  }

  Future<bool> update(Task task) async {
    return isar.writeTxn(() async {
      task.updatedAt = DateTime.now();
      await isar.tasks.put(task);
      return true;
    });
  }

  Future<bool> delete(int id) async {
    return isar.writeTxn(() async {
      return await isar.tasks.delete(id);
    });
  }

  Future<void> toggleCompletion(int id) async {
    await isar.writeTxn(() async {
      final task = await isar.tasks.get(id);
      if (task != null) {
        task.isCompleted = !task.isCompleted;
        task.updatedAt = DateTime.now();
        await isar.tasks.put(task);
      }
    });
  }

  Future<void> updateEisenhower(int id, int quadrant) async {
    await isar.writeTxn(() async {
      final task = await isar.tasks.get(id);
      if (task != null) {
        // quadrant 0: urgent & important -> deadline=now, importance=1
        // quadrant 1: not urgent & important -> deadline=null, importance=1
        // quadrant 2: urgent & not important -> deadline=now, importance=0
        // quadrant 3: not urgent & not important -> deadline=null, importance=0
        
        task.importance = (quadrant == 0 || quadrant == 1) ? 1 : 0;
        
        if (quadrant == 0 || quadrant == 2) {
          // Set to urgent (if it wasn't already urgent, make it due today)
          if (!task.isUrgent) {
            task.deadline = DateTime.now();
          }
        } else {
          // Set to not urgent
          task.deadline = null;
        }
        
        task.updatedAt = DateTime.now();
        await isar.tasks.put(task);
      }
    });
  }
}
