import 'dart:async';
import 'dart:convert';
import 'package:isar/isar.dart';

import '../../models/preset.dart';
import '../../core/theme.dart';
import '../storage/fallback_storage.dart';

class PresetRepository {
  PresetRepository(this._isar, {FallbackStorage? fallbackStorage})
    : _fallbackStorage = fallbackStorage;
  static const _storageKey = 'focus_clock.presets.v1';
  final Isar? _isar;
  final FallbackStorage? _fallbackStorage;

  final Map<int, Preset> _memPresets = {};
  int _memIdCounter = 100;
  final StreamController<void> _memController =
      StreamController<void>.broadcast();
  bool _memoryLoaded = false;
  Future<void>? _memoryLoad;
  Future<void> _writeQueue = Future<void>.value();

  Future<void> _ensureMemoryLoaded() async {
    if (_memoryLoaded) return;
    _memoryLoad ??= () async {
      final raw = await _fallbackStorage?.read(_storageKey);
      if (raw == null) {
        for (final preset in _defaultPresets()) {
          _memPresets[preset.id] = preset;
        }
      } else {
        final envelope = jsonDecode(raw);
        if (envelope is! Map<String, dynamic> ||
            envelope['version'] != 1 ||
            envelope['presets'] is! List) {
          throw const FormatException('Unsupported saved presets format.');
        }
        for (final item in envelope['presets'] as List) {
          final preset = _presetFromJson(item);
          _memPresets[preset.id] = preset;
        }
        _memIdCounter = envelope['nextId'] as int? ?? 100;
      }
      for (final id in _memPresets.keys) {
        if (id >= _memIdCounter) _memIdCounter = id + 1;
      }
      _memoryLoaded = true;
    }();
    await _memoryLoad;
  }

  Future<void> _persistMemory() {
    if (_fallbackStorage == null) return Future<void>.value();
    final snapshot = jsonEncode({
      'version': 1,
      'nextId': _memIdCounter,
      'presets': _memPresets.values.map(_presetToJson).toList(),
    });
    _writeQueue = _writeQueue.then(
      (_) => _fallbackStorage.write(_storageKey, snapshot),
    );
    return _writeQueue;
  }

  Map<String, Object?> _presetToJson(Preset preset) => {
    'id': preset.id,
    'name': preset.name,
    'colorValue': preset.colorValue,
    'iconKey': preset.iconKey,
    'createdAt': preset.createdAt.toIso8601String(),
  };

  Preset _presetFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Saved preset is malformed.');
    }
    return Preset()
      ..id = value['id'] as int
      ..name = value['name'] as String
      ..colorValue = value['colorValue'] as int
      ..iconKey = value['iconKey'] as String?
      ..createdAt = DateTime.parse(value['createdAt'] as String);
  }

  Stream<List<Preset>> watchAll() {
    if (_isar == null) {
      return _watchMemory();
    }
    return _isar.presets.where().sortByCreatedAt().watch(fireImmediately: true);
  }

  Stream<List<Preset>> _watchMemory() async* {
    await _ensureMemoryLoaded();
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
      await _ensureMemoryLoaded();
      if (p.id == Isar.autoIncrement || p.id <= 0) {
        p.id = _memIdCounter++;
      }
      _memPresets[p.id] = p;
      await _persistMemory();
      _memController.add(null);
      return p.id;
    }
    return _isar.writeTxn(() => _isar.presets.put(p));
  }

  Future<bool> delete(int id) async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
      _memPresets.remove(id);
      await _persistMemory();
      _memController.add(null);
      return true;
    }
    return _isar.writeTxn(() => _isar.presets.delete(id));
  }

  Future<List<Preset>> getAll() async {
    if (_isar == null) {
      await _ensureMemoryLoaded();
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
