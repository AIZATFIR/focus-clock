import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';

import '../../data/storage/fallback_storage.dart';
import '../../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._isar, {FallbackStorage? fallbackStorage})
    : _fallbackStorage = fallbackStorage;

  static const _storageKey = 'focus_clock.settings.v1';
  final Isar? _isar;
  final FallbackStorage? _fallbackStorage;
  AppSettings _memorySettings = AppSettings();
  bool _loaded = false;
  Future<void>? _loadFuture;
  Future<void> _writeQueue = Future<void>.value();
  final StreamController<AppSettings> _memController =
      StreamController<AppSettings>.broadcast();

  Future<void> _ensureLoaded() async {
    if (_loaded || _fallbackStorage == null) return;
    _loadFuture ??= () async {
      final raw = await _fallbackStorage.read(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
          throw const FormatException('Unsupported saved settings format.');
        }
        _memorySettings = _decodeSettings(decoded['settings']);
      }
      _loaded = true;
    }();
    await _loadFuture;
  }

  Future<void> _persist() {
    if (_fallbackStorage == null) return Future<void>.value();
    final snapshot = jsonEncode({
      'version': 1,
      'settings': _encodeSettings(_memorySettings),
    });
    _writeQueue = _writeQueue.then(
      (_) => _fallbackStorage.write(_storageKey, snapshot),
    );
    return _writeQueue;
  }

  Stream<AppSettings> watch() {
    if (_isar == null) return _watchMemory();
    return _isar.appSettings
        .watchObject(0, fireImmediately: true)
        .map((s) => s ?? AppSettings());
  }

  Stream<AppSettings> _watchMemory() async* {
    await _ensureLoaded();
    yield _memorySettings;
    await for (final s in _memController.stream) {
      yield s;
    }
  }

  Future<AppSettings> get() async {
    if (_isar != null) return (await _isar.appSettings.get(0)) ?? AppSettings();
    await _ensureLoaded();
    return _memorySettings;
  }

  Future<void> update(AppSettings s) async {
    if (_isar != null) {
      await _isar.writeTxn(() => _isar.appSettings.put(s));
      return;
    }
    await _ensureLoaded();
    _memorySettings = s;
    await _persist();
    _memController.add(s);
  }

  Map<String, Object?> _encodeSettings(AppSettings s) => {
    'is24h': s.is24h,
    'is24hTime': s.is24hTime,
    'is24hDial': s.is24hDial,
    'showCurrentTime': s.showCurrentTime,
    'currentTimeFormat': s.currentTimeFormat,
    'floatTimeText': s.floatTimeText,
    'glowStyle': s.glowStyle,
    'notifLeadMinutes': s.notifLeadMinutes,
    'themeMode': s.themeMode,
    'themePalette': s.themePalette,
    'trueBlack': s.trueBlack,
    'clockHandsMode': s.clockHandsMode,
    'showMinuteLabels': s.showMinuteLabels,
    'clockFaceTheme': s.clockFaceTheme,
    'keyLeftPanel': s.keyLeftPanel,
    'keyRightPanel': s.keyRightPanel,
    'keyAiChat': s.keyAiChat,
    'keyPrecisionMode': s.keyPrecisionMode,
    'keyPlanningMode': s.keyPlanningMode,
    'enableAiAssistant': s.enableAiAssistant,
    'enableLeftPanel': s.enableLeftPanel,
    'enableRightPanel': s.enableRightPanel,
    'aiBaseUrl': s.aiBaseUrl,
    'aiModel': s.aiModel,
    'hasCompletedOnboarding': s.hasCompletedOnboarding,
    'focusGoal': s.focusGoal,
  };

  AppSettings _decodeSettings(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Saved settings are malformed.');
    }
    final s = AppSettings();
    s.is24h = value['is24h'] as bool? ?? s.is24h;
    s.is24hTime = value['is24hTime'] as bool? ?? s.is24hTime;
    s.is24hDial = value['is24hDial'] as bool? ?? s.is24hDial;
    s.showCurrentTime = value['showCurrentTime'] as bool? ?? s.showCurrentTime;
    s.currentTimeFormat =
        value['currentTimeFormat'] as String? ?? s.currentTimeFormat;
    s.floatTimeText = value['floatTimeText'] as bool? ?? s.floatTimeText;
    s.glowStyle = value['glowStyle'] as String? ?? s.glowStyle;
    s.notifLeadMinutes =
        value['notifLeadMinutes'] as int? ?? s.notifLeadMinutes;
    s.themeMode = value['themeMode'] as String? ?? s.themeMode;
    s.themePalette = value['themePalette'] as String? ?? s.themePalette;
    s.trueBlack = value['trueBlack'] as bool? ?? s.trueBlack;
    s.clockHandsMode = value['clockHandsMode'] as int? ?? s.clockHandsMode;
    s.showMinuteLabels =
        value['showMinuteLabels'] as bool? ?? s.showMinuteLabels;
    s.clockFaceTheme = value['clockFaceTheme'] as int? ?? s.clockFaceTheme;
    s.keyLeftPanel = value['keyLeftPanel'] as String? ?? s.keyLeftPanel;
    s.keyRightPanel = value['keyRightPanel'] as String? ?? s.keyRightPanel;
    s.keyAiChat = value['keyAiChat'] as String? ?? s.keyAiChat;
    s.keyPrecisionMode =
        value['keyPrecisionMode'] as String? ?? s.keyPrecisionMode;
    s.keyPlanningMode =
        value['keyPlanningMode'] as String? ?? s.keyPlanningMode;
    s.enableAiAssistant =
        value['enableAiAssistant'] as bool? ?? s.enableAiAssistant;
    s.enableLeftPanel = value['enableLeftPanel'] as bool? ?? s.enableLeftPanel;
    s.enableRightPanel =
        value['enableRightPanel'] as bool? ?? s.enableRightPanel;
    s.aiBaseUrl = value['aiBaseUrl'] as String? ?? s.aiBaseUrl;
    s.aiModel = value['aiModel'] as String? ?? s.aiModel;
    s.hasCompletedOnboarding =
        value['hasCompletedOnboarding'] as bool? ?? s.hasCompletedOnboarding;
    s.focusGoal = value['focusGoal'] as String? ?? s.focusGoal;
    return s;
  }
}
