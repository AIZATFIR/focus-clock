import 'package:isar/isar.dart';

import '../../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._isar);
  final Isar _isar;

  Stream<AppSettings> watch() => _isar.appSettings
      .watchObject(0, fireImmediately: true)
      .map((s) => s ?? AppSettings());

  Future<AppSettings> get() async =>
      (await _isar.appSettings.get(0)) ?? AppSettings();

  Future<void> update(AppSettings s) =>
      _isar.writeTxn(() => _isar.appSettings.put(s));
}
