import 'package:isar/isar.dart';

import '../../models/preset.dart';

class PresetRepository {
  PresetRepository(this._isar);
  final Isar _isar;

  Stream<List<Preset>> watchAll() =>
      _isar.presets.where().sortByCreatedAt().watch(fireImmediately: true);

  Future<int> upsert(Preset p) =>
      _isar.writeTxn(() => _isar.presets.put(p));

  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.presets.delete(id));

  Future<List<Preset>> getAll() =>
      _isar.presets.where().sortByCreatedAt().findAll();
}
