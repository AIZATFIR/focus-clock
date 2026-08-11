import 'package:isar/isar.dart';

import '../../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._isar);
  final Isar? _isar;

  Stream<AppSettings> watch() {
    if (_isar == null) return Stream.value(AppSettings());
    return _isar.appSettings
        .watchObject(0, fireImmediately: true)
        .map((s) => s ?? AppSettings());
  }

  Future<AppSettings> get() async {
    if (_isar == null) return AppSettings();
    return (await _isar.appSettings.get(0)) ?? AppSettings();
  }

  Future<void> update(AppSettings s) async {
    if (_isar == null) return;
    await _isar.writeTxn(() => _isar.appSettings.put(s));
  }
}
