import 'package:isar/isar.dart';

import '../../models/preset.dart';
import '../../core/theme.dart';

class PresetRepository {
  PresetRepository(this._isar);
  final Isar? _isar;

  Stream<List<Preset>> watchAll() {
    if (_isar == null) {
      return Stream.value(_defaultPresets());
    }
    return _isar.presets.where().sortByCreatedAt().watch(fireImmediately: true);
  }

  Future<int> upsert(Preset p) async {
    if (_isar == null) return p.id;
    return _isar.writeTxn(() => _isar.presets.put(p));
  }

  Future<bool> delete(int id) async {
    if (_isar == null) return true;
    return _isar.writeTxn(() => _isar.presets.delete(id));
  }

  Future<List<Preset>> getAll() async {
    if (_isar == null) return _defaultPresets();
    return _isar.presets.where().sortByCreatedAt().findAll();
  }

  List<Preset> _defaultPresets() => [
        Preset()
          ..id = 1
          ..name = 'Deepwork'
          ..colorValue = presetColors[11]
          ..iconKey = '💻'
          ..createdAt = DateTime.now(),
        Preset()
          ..id = 2
          ..name = 'Intentional Rest'
          ..colorValue = presetColors[15]
          ..iconKey = '🧘'
          ..createdAt = DateTime.now(),
        Preset()
          ..id = 3
          ..name = 'Social activity'
          ..colorValue = presetColors[2]
          ..iconKey = '🤝'
          ..createdAt = DateTime.now(),
        Preset()
          ..id = 4
          ..name = 'Hobbies'
          ..colorValue = presetColors[14]
          ..iconKey = '🎨'
          ..createdAt = DateTime.now(),
        Preset()
          ..id = 5
          ..name = 'Exercise'
          ..colorValue = presetColors[7]
          ..iconKey = '🏃'
          ..createdAt = DateTime.now(),
        Preset()
          ..id = 6
          ..name = 'Wind down'
          ..colorValue = presetColors[13]
          ..iconKey = '💆'
          ..createdAt = DateTime.now(),
        Preset()
          ..id = 7
          ..name = 'Sleep'
          ..colorValue = presetColors[16]
          ..iconKey = '😴'
          ..createdAt = DateTime.now(),
      ];
}
