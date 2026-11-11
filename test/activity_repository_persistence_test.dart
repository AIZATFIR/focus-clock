import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/core/time_math.dart';
import 'package:focus_clock/data/repositories/activity_repository.dart';
import 'package:focus_clock/data/repositories/preset_repository.dart';
import 'package:focus_clock/data/storage/fallback_storage.dart';
import 'package:focus_clock/models/activity.dart';
import 'package:focus_clock/models/app_settings.dart';
import 'package:focus_clock/models/preset.dart';
import 'package:focus_clock/models/task.dart';
import 'package:focus_clock/data/repositories/settings_repository.dart';
import 'package:focus_clock/data/repositories/task_repository.dart';
import 'package:focus_clock/services/notification_service.dart';

class MemoryFallbackStorage implements FallbackStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test('memory activities survive repository recreation', () async {
    final storage = MemoryFallbackStorage();
    final activity = Activity()
      ..title = 'Study LKS'
      ..startMinute = 60
      ..endMinute = 120
      ..ampmHalf = AmPmHalf.am
      ..date = DateTime(2026, 11, 11)
      ..colorValue = 0xff123456
      ..focusGoalLink = 'Menang LKS nasional'
      ..recurrence = 'weekly'
      ..recurrenceEndDate = DateTime(2026, 12, 30)
      ..createdAt = DateTime(2026, 11, 10)
      ..updatedAt = DateTime(2026, 11, 10);

    await ActivityRepository(
      null,
      NotificationService(),
      fallbackStorage: storage,
    ).upsert(activity);
    final restored = await ActivityRepository(
      null,
      NotificationService(),
      fallbackStorage: storage,
    ).getByDate(DateTime(2026, 11, 11));

    expect(restored, hasLength(1));
    expect(restored.single.title, 'Study LKS');
    expect(restored.single.focusGoalLink, 'Menang LKS nasional');
    expect(restored.single.recurrenceEndDate, DateTime(2026, 12, 30));
  });

  test('old saved activities load with no goal link', () async {
    final storage = MemoryFallbackStorage();
    storage.values['focus_clock.activities.v1'] = jsonEncode({
      'version': 1,
      'nextId': 2,
      'activities': [
        {
          'id': 1,
          'presetId': null,
          'iconKey': null,
          'title': 'Old activity',
          'startMinute': 60,
          'endMinute': 120,
          'ampmHalf': 0,
          'date': '2026-11-11T00:00:00.000',
          'description': '',
          'colorValue': 0xff123456,
          'recurrence': 'none',
          'recurrenceEndDate': null,
          'groupId': null,
          'importance': 0,
          'deadline': null,
          'isCompleted': false,
          'isLocked': false,
          'excludedDates': [],
          'createdAt': '2026-11-10T00:00:00.000',
          'updatedAt': '2026-11-10T00:00:00.000',
        },
      ],
    });

    final restored = await ActivityRepository(
      null,
      NotificationService(),
      fallbackStorage: storage,
    ).getByDate(DateTime(2026, 11, 11));

    expect(restored.single.focusGoalLink, isEmpty);
  });

  test('focus goal survives settings repository recreation', () async {
    final storage = MemoryFallbackStorage();
    final settings = AppSettings()..focusGoal = 'Menang LKS nasional';

    await SettingsRepository(null, fallbackStorage: storage).update(settings);
    final restored = await SettingsRepository(
      null,
      fallbackStorage: storage,
    ).get();

    expect(restored.focusGoal, 'Menang LKS nasional');
  });

  test('tasks and subtasks survive repository recreation', () async {
    final storage = MemoryFallbackStorage();
    final task = Task()
      ..title = 'Bikin prototype LKS'
      ..createdAt = DateTime(2026, 11, 11)
      ..importance = 1
      ..subtaskList = [SubTask(title: 'Buat flow')];

    await TaskRepository(null, fallbackStorage: storage).add(task);
    final restored = await TaskRepository(
      null,
      fallbackStorage: storage,
    ).getAll();

    expect(restored, hasLength(1));
    expect(restored.single.title, 'Bikin prototype LKS');
    expect(restored.single.subtaskList.single.title, 'Buat flow');
  });

  test('custom presets survive repository recreation', () async {
    final storage = MemoryFallbackStorage();
    final preset = Preset()
      ..name = 'Belajar LKS'
      ..colorValue = 0xff123456
      ..iconKey = '📚'
      ..createdAt = DateTime(2026, 11, 11);

    await PresetRepository(null, fallbackStorage: storage).upsert(preset);
    final restored = await PresetRepository(
      null,
      fallbackStorage: storage,
    ).getAll();

    expect(restored.any((p) => p.name == 'Belajar LKS'), isTrue);
    expect(restored.firstWhere((p) => p.name == 'Belajar LKS').iconKey, '📚');
  });

  test('memory task IDs stay unique after deleting an earlier task', () async {
    final repository = TaskRepository(null);
    final first = Task()
      ..title = 'Task 1'
      ..createdAt = DateTime(2026, 11, 11);
    final second = Task()
      ..title = 'Task 2'
      ..createdAt = DateTime(2026, 11, 11);
    final third = Task()
      ..title = 'Task 3'
      ..createdAt = DateTime(2026, 11, 11);

    final firstId = await repository.add(first);
    final secondId = await repository.add(second);
    await repository.delete(firstId);
    final thirdId = await repository.add(third);

    expect(thirdId, isNot(secondId));
  });

  test(
    'memory presets retain built-in defaults when no persistence is given',
    () async {
      expect(await PresetRepository(null).getAll(), isNotEmpty);
    },
  );
}
