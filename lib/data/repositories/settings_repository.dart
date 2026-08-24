import 'dart:async';
import 'package:isar/isar.dart';

import '../../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._isar);
  final Isar? _isar;

  AppSettings _memorySettings = AppSettings();
  final StreamController<AppSettings> _memController = StreamController<AppSettings>.broadcast();

  Stream<AppSettings> watch() {
    if (_isar == null) {
      return _watchMemory();
    }
    return _isar.appSettings
        .watchObject(0, fireImmediately: true)
        .map((s) => s ?? AppSettings());
  }

  Stream<AppSettings> _watchMemory() async* {
    yield _memorySettings;
    await for (final s in _memController.stream) {
      yield s;
    }
  }

  Future<AppSettings> get() async {
    if (_isar == null) return _memorySettings;
    return (await _isar.appSettings.get(0)) ?? AppSettings();
  }

  Future<void> update(AppSettings s) async {
    if (_isar == null) {
      _memorySettings = s;
      _memController.add(s);
      return;
    }
    await _isar.writeTxn(() => _isar.appSettings.put(s));
  }
}
