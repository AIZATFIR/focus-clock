import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/activity.dart';
import '../models/app_settings.dart';
import '../models/preset.dart';
import '../models/task.dart';
import '../core/theme.dart';

class IsarService {
  IsarService._(this.isar);
  IsarService.fallback() : isar = null;
  final Isar? isar;

  static Future<IsarService> open() async {
    if (kIsWeb) {
      try {
        await Isar.initializeIsarCore(download: true);
        final isar = await Isar.open(
          [PresetSchema, ActivitySchema, AppSettingsSchema, TaskSchema],
          directory: '',
          inspector: false,
        );
        await _seed(isar);
        return IsarService._(isar);
      } catch (e) {
        debugPrint('Isar Web fallback mode activated: $e');
        return IsarService.fallback();
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [PresetSchema, ActivitySchema, AppSettingsSchema, TaskSchema],
      directory: dir.path,
      inspector: true,
    );
    await _seed(isar);
    return IsarService._(isar);
  }

  static Future<void> _seed(Isar isar) async {
    final hasPresets = await isar.presets.count() > 0;
    if (!hasPresets) {
      await isar.writeTxn(() async {
        await isar.presets.putAll([
          Preset()
            ..name = 'Deepwork'
            ..colorValue = presetColors[11] // Blue
            ..iconKey = '💻'
            ..createdAt = DateTime.now(),
          Preset()
            ..name = 'Intentional Rest'
            ..colorValue = presetColors[15] // Pink
            ..iconKey = '🧘'
            ..createdAt = DateTime.now(),
          Preset()
            ..name = 'Social activity'
            ..colorValue = presetColors[2] // Orange
            ..iconKey = '🤝'
            ..createdAt = DateTime.now(),
          Preset()
            ..name = 'Hobbies'
            ..colorValue = presetColors[14] // Purple
            ..iconKey = '🎨'
            ..createdAt = DateTime.now(),
          Preset()
            ..name = 'Exercise'
            ..colorValue = presetColors[7] // Green
            ..iconKey = '🏃'
            ..createdAt = DateTime.now(),
          Preset()
            ..name = 'Wind down'
            ..colorValue = presetColors[13] // Deep Purple
            ..iconKey = '💆'
            ..createdAt = DateTime.now(),
          Preset()
            ..name = 'Sleep'
            ..colorValue = presetColors[16] // Brown
            ..iconKey = '😴'
            ..createdAt = DateTime.now(),
        ]);
      });
    }
    final hasSettings = await isar.appSettings.count() > 0;
    if (!hasSettings) {
      await isar.writeTxn(() async {
        await isar.appSettings.put(AppSettings());
      });
    }
  }
}
