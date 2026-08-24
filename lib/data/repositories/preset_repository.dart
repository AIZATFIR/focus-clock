import 'dart:async';
import 'package:isar/isar.dart';

import '../../models/preset.dart';
import '../../core/theme.dart';

class PresetRepository {
  PresetRepository(this._isar) {
    if (_isar == null) {
      for (final p in _defaultPresets()) {
        _memPresets[p.id] = p;
      }
    }
  }
  final Isar? _isar;

  final Map<int, Preset> _memPresets = {};
  int _memIdCounter = 100;
  final StreamController<void> _memController = StreamController<void>.broadcast();

  Stream<List<Preset>> watchAll() {
    if (_isar == null) {
      return _watchMemory();
    }
    return _isar.presets.where().sortByCreatedAt().watch(fireImmediately: true);
  }

  Stream<List<Preset>> _watchMemory() async* {
    List<Preset> query() {
      final list = _memPresets.values.toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }

    yield query();
    await for (final _ in _memController.stream) {
      yield query();
    }
  }

  Future<int> upsert(Preset p) async {
    if (_isar == null) {
      if (p.id == Isar.autoIncrement || p.id <= 0) {
        p.id = _memIdCounter++;
      }
      _memPresets[p.id] = p;
      _memController.add(null);
      return p.id;
    }
    return _isar.writeTxn(() => _isar.presets.put(p));
  }

  Future<bool> delete(int id) async {
    if (_isar == null) {
      _memPresets.remove(id);
      _memController.add(null);
      return true;
    }
    return _isar.writeTxn(() => _isar.presets.delete(id));
  }

  Future<List<Preset>> getAll() async {
    if (_isar == null) {
      final list = _memPresets.values.toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }
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
