import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:focus_clock/core/time_math.dart';
import 'package:focus_clock/data/isar_service.dart';
import 'package:focus_clock/data/repositories/activity_repository.dart';
import 'package:focus_clock/models/activity.dart';
import 'package:focus_clock/services/notification_service.dart';

void main() {
  final start = DateTime(2026, 11, 9); // Monday
  final end = DateTime(2026, 11, 13);

  Activity recurringActivity(String recurrence) => Activity()
    ..title = 'Practice LKS'
    ..startMinute = 480
    ..endMinute = 540
    ..ampmHalf = AmPmHalf.am
    ..date = start
    ..colorValue = 0xFF4A9EFF
    ..recurrence = recurrence
    ..recurrenceEndDate = end
    ..createdAt = start
    ..updatedAt = start;

  test(
    'memory fallback projects weekday recurrence only through its end date',
    () async {
      final repository = ActivityRepository(null, NotificationService());
      await repository.upsert(recurringActivity('weekday'));

      expect(
        (await repository.getByDate(DateTime(2026, 11, 10))).single.title,
        'Practice LKS',
      );
      expect(
        (await repository.watchByDate(DateTime(2026, 11, 10)).first)
            .single
            .title,
        'Practice LKS',
      );
      expect(await repository.getByDate(DateTime(2026, 11, 14)), isEmpty);
      expect(await repository.getByDate(DateTime(2026, 11, 16)), isEmpty);
    },
  );

  test('Isar recurrence ends on the configured date', () async {
    await Isar.initializeIsarCore(download: true);
    final directory = await Directory.systemTemp.createTemp(
      'focus-clock-isar-',
    );
    final isar = await Isar.open(
      IsarService.schemas,
      directory: directory.path,
      inspector: false,
    );
    addTearDown(() async {
      await isar.close(deleteFromDisk: true);
      await directory.delete(recursive: true);
    });
    final repository = ActivityRepository(isar, NotificationService());
    await repository.upsert(recurringActivity('daily'));

    expect(
      (await repository.getByDate(DateTime(2026, 11, 13))).single.title,
      'Practice LKS',
    );
    expect(await repository.getByDate(DateTime(2026, 11, 14)), isEmpty);
  });
}
