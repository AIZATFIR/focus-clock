import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/core/time_math.dart';
import 'package:focus_clock/data/repositories/activity_repository.dart';
import 'package:focus_clock/data/storage/fallback_storage.dart';
import 'package:focus_clock/models/activity.dart';
import 'package:focus_clock/models/app_settings.dart';
import 'package:focus_clock/data/repositories/settings_repository.dart';
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
    expect(restored.single.recurrenceEndDate, DateTime(2026, 12, 30));
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
}
