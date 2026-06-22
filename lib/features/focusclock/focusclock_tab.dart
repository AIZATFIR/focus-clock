import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../models/preset.dart';
import '../../providers/providers.dart';
import '../activity_detail/activity_detail_sheet.dart';
import '../presets/presets_tab.dart';
import 'analog_clock_face.dart';

/// Returns a Preset if user picked one, null if user chose "Custom".
/// Returns false (via pop with no result) if user dismissed.
Future<Object?> _showPresetPicker(BuildContext context) async {
  return showModalBottomSheet<Object>(
    context: context,
    backgroundColor: AppPalette.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _PresetPickerSheet(),
  );
}

class _PresetPickerSheet extends ConsumerStatefulWidget {
  const _PresetPickerSheet();

  @override
  ConsumerState<_PresetPickerSheet> createState() => _PresetPickerSheetState();
}

class _PresetPickerSheetState extends ConsumerState<_PresetPickerSheet> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event, List<Preset> presets) {
    if (event is! KeyDownEvent) return;
    final label = event.logicalKey.keyLabel;
    final n = int.tryParse(label);
    if (n != null && n >= 1 && n <= presets.length) {
      Navigator.pop(context, presets[n - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(presetsProvider).valueOrNull ?? [];
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (e) => _handleKey(e, presets),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pick a preset or create custom',
              style: TextStyle(fontSize: 13, color: AppPalette.textDim),
            ),
            const SizedBox(height: 14),
            if (presets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No presets yet.',
                    style: TextStyle(color: AppPalette.textDim)),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: presets.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final color = Color(p.colorValue);
                  final hasIcon =
                      p.iconKey != null && p.iconKey!.isNotEmpty;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: color.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Number badge
                          if (idx < 9)
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          if (hasIcon) ...[
                            Text(p.iconKey!,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                          ] else ...[
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                    foregroundColor: AppPalette.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                  label: const Text('Custom Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.pop(context, 'custom'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FocusClockTab extends ConsumerStatefulWidget {
  const FocusClockTab({super.key});
  @override
  ConsumerState<FocusClockTab> createState() => _FocusClockTabState();
}

class _FocusClockTabState extends ConsumerState<FocusClockTab>
    with TickerProviderStateMixin {
  Activity? _draggingActivity;
  int? _lastPanMinute;
  bool _crossedHalf = false;
  bool _isPrecisionMode = false;
  bool _hasDragged = false;
  bool _isExiting = false;
  int? _dragClickMinute;
  
  late final AnimationController _revealCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _startupCtrl;
  late final AnimationController _aimLockCtrl;
  late final AnimationController _exitCtrl;

  late final ValueNotifier<int?> _hoverMinuteNotifier;
  late final ValueNotifier<int?> _dragStartNotifier;
  late final ValueNotifier<int?> _dragEndNotifier;
  late final ValueNotifier<bool> _dragConflictNotifier;

  int _snap(int m) => _isPrecisionMode ? m : snap5(m);

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _startupCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _aimLockCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));

    _hoverMinuteNotifier = ValueNotifier<int?>(null);
    _dragStartNotifier = ValueNotifier<int?>(null);
    _dragEndNotifier = ValueNotifier<int?>(null);
    _dragConflictNotifier = ValueNotifier<bool>(false);

    _startupCtrl.forward();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _pulseCtrl.dispose();
    _startupCtrl.dispose();
    _aimLockCtrl.dispose();
    _exitCtrl.dispose();
    _hoverMinuteNotifier.dispose();
    _dragStartNotifier.dispose();
    _dragEndNotifier.dispose();
    _dragConflictNotifier.dispose();
    super.dispose();
  }

  double get _grow => clockGrowFactor(1.0, ref.read(planningModeProvider));

  bool _hasConflict(int start, int end, List<Activity> activities, {int? excludeId, required bool is24h}) {
    for (final a in activities) {
      if (excludeId != null && a.id == excludeId) continue;
      final aStart = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
      final aEnd = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
      if (rangesOverlap(start, end, aStart, aEnd)) return true;
    }
    return false;
  }

  void _exitApp() {
    setState(() {
      _isExiting = true;
    });
    _exitCtrl.forward().then((_) {
      SystemNavigator.pop();
      exit(0);
    });
  }

  ({int start, int end})? _getFreeInterval(int hoverMin, int slotStart, int slotEnd, List<Activity> activities, {required bool is24h}) {
    List<({int start, int end})> freeIntervals = [
      (start: slotStart, end: slotEnd)
    ];
    for (final a in activities) {
      final aStart = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
      final aEnd = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
      
      final nextFree = <({int start, int end})>[];
      for (final f in freeIntervals) {
        if (aStart >= f.end || aEnd <= f.start) {
          nextFree.add(f);
        } else {
          if (aStart > f.start) {
            nextFree.add((start: f.start, end: aStart));
          }
          if (aEnd < f.end) {
            nextFree.add((start: aEnd, end: f.end));
          }
        }
      }
      freeIntervals = nextFree;
    }
    
    for (final f in freeIntervals) {
      if (hoverMin >= f.start && hoverMin < f.end) {
        return f;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final is24h = ref.watch(settingsProvider.select((s) => s.valueOrNull?.is24h ?? false));
    final clockHandsMode = ref.watch(settingsProvider.select((s) => s.valueOrNull?.clockHandsMode ?? 1));
    final clockFaceTheme = ref.watch(settingsProvider.select((s) => s.valueOrNull?.clockFaceTheme ?? 1));
    final activitiesAsync = ref.watch(is24h ? activitiesByDateProvider : activitiesByHalfProvider);
    final tasks = ref.watch(is24h ? tasksByDateProvider : tasksByHalfProvider);
    final half = ref.watch(ampmHalfProvider);
    final nowAsync = ref.watch(currentTimeProvider);
    final now = nowAsync.valueOrNull ?? DateTime.now();
    final date = ref.watch(currentDateProvider);
    final isToday = date == dateOnly(DateTime.now());
    final activities = activitiesAsync.valueOrNull ?? const <Activity>[];
    final schedulingTask = ref.watch(schedulingTaskProvider);
    final isInstant = ref.watch(isInstantModeProvider);

    ref.listen<bool>(precisionModeProvider, (prev, next) {
      if (next != _isPrecisionMode) {
        setState(() {
          _isPrecisionMode = next;
        });
        if (!_isPrecisionMode) {
          _hoverMinuteNotifier.value = null;
        }
      }
    });

    final m = is24h 
        ? (now.hour * 60 + now.minute)
        : ((now.hour % 12) * 60 + now.minute);
        
    final hasCurrent = activities.any((a) {
      final start = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
      final end = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
      return m >= start && m < end;
    });
    if (hasCurrent && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat();
    } else if (!hasCurrent && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }

    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (context, child) {
        if (!_isExiting) return child!;
        final val = _exitCtrl.value;
        final double heightScale = val < 0.5 ? (1.0 - (val * 2.0)) : 0.005;
        final double widthScale = val < 0.5 ? 1.0 : (1.0 - ((val - 0.5) * 2.0));
        return Center(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(widthScale, heightScale, 1.0),
            child: Container(color: Colors.white, child: child!),
          ),
        );
      },
      child: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, c) => Stack(
                      children: [
                        Positioned.fill(
                          child: DragTarget<Preset>(
                            onAcceptWithDetails: (details) =>
                                _onPresetDropped(details.data),
                            builder: (ctx, candidate, rejected) {
                              return MouseRegion(
                                onHover: (e) {
                                  final centered = _toCenter(e.localPosition, c.biggest);
                                  final rDist = centered.distance;
                                  final r = c.biggest.shortestSide / 2 * _grow;
                                  final outer = r * 0.95 * 1.15;
                                  
                                  if (rDist <= outer) {
                                    _revealCtrl.forward();
                                    final newMinute = offsetToMinute(centered, is24h: is24h);
                                    if (_hoverMinuteNotifier.value != newMinute) {
                                      _hoverMinuteNotifier.value = newMinute;
                                    }

                                    if (isInstant) {
                                      final interval = ref.read(instantIntervalProvider);
                                      final slotStart = (newMinute ~/ interval) * interval;
                                      final slotEnd = slotStart + interval;
                                      
                                      final freeSeg = _getFreeInterval(newMinute, slotStart, slotEnd, activities, is24h: is24h);
                                      if (freeSeg != null) {
                                        _dragStartNotifier.value = freeSeg.start;
                                        _dragEndNotifier.value = freeSeg.end;
                                      } else {
                                        _dragStartNotifier.value = null;
                                        _dragEndNotifier.value = null;
                                      }
                                    }
                                  } else {
                                    _revealCtrl.reverse();
                                    if (_hoverMinuteNotifier.value != null) {
                                      _hoverMinuteNotifier.value = null;
                                    }
                                    if (isInstant) {
                                      _dragStartNotifier.value = null;
                                      _dragEndNotifier.value = null;
                                    }
                                  }
                                },
                                onExit: (_) {
                                  _revealCtrl.reverse();
                                  if (_hoverMinuteNotifier.value != null) {
                                    _hoverMinuteNotifier.value = null;
                                  }
                                  if (isInstant) {
                                    _dragStartNotifier.value = null;
                                    _dragEndNotifier.value = null;
                                  }
                                },
                                child: Listener(
                                  onPointerDown: (_) {
                                    ref.read(isClockDraggingProvider.notifier).state = true;
                                  },
                                  onPointerUp: (_) {
                                    ref.read(isClockDraggingProvider.notifier).state = false;
                                  },
                                  onPointerCancel: (_) {
                                    ref.read(isClockDraggingProvider.notifier).state = false;
                                  },
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onSecondaryTap: () {
                                      ref.read(precisionModeProvider.notifier).state = !_isPrecisionMode;
                                    },
                                    onTapUp: (e) {
                                      if (isInstant) {
                                        final Color themeAccentColor;
                                        if (clockFaceTheme == 2) {
                                          themeAccentColor = Colors.white;
                                        } else if (clockFaceTheme == 3) {
                                          themeAccentColor = const Color(0xFF3399FF);
                                        } else if (clockFaceTheme == 4) {
                                          themeAccentColor = const Color(0xFFBB86FC);
                                        } else if (clockFaceTheme == 5 || clockFaceTheme == 6) {
                                          themeAccentColor = const Color(0xFFFFD54F);
                                        } else {
                                          themeAccentColor = AppPalette.accent;
                                        }
                                        _onInstantModeTap(date, themeAccentColor);
                                      } else {
                                        final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
                                        _onTapUp(e.localPosition, c.biggest, activities, lead);
                                      }
                                    },
                                    onDoubleTapDown: (e) {
                                      final instantMode = ref.read(isInstantModeProvider);
                                      ref.read(isInstantModeProvider.notifier).state = !instantMode;
                                      HapticFeedback.mediumImpact();
                                    },
                                    onLongPressStart: (e) {
                                      if (!isInstant) {
                                        _onLongPressStart(e.localPosition, c.biggest, activities);
                                      }
                                    },
                                    onLongPressMoveUpdate: (e) {
                                      if (!isInstant) {
                                        _onLongPressMove(e.localPosition, c.biggest, activities);
                                      }
                                    },
                                    onLongPressEnd: (_) {
                                      if (!isInstant) {
                                        final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
                                        _onLongPressEnd(lead);
                                      }
                                    },
                                    onPanStart: (e) {
                                      if (!isInstant) {
                                        _onPanStart(e.localPosition, c.biggest);
                                      }
                                    },
                                    onPanUpdate: (e) {
                                      if (!isInstant) {
                                        _onPanUpdate(e.localPosition, c.biggest, activities);
                                      }
                                    },
                                    onPanEnd: (_) {
                                      if (!isInstant) {
                                        _onPanEnd();
                                      }
                                    },
                                    child: RepaintBoundary(
                                      child: AnimatedBuilder(
                                        animation: Listenable.merge([
                                          _pulseCtrl,
                                          _revealCtrl,
                                          _hoverMinuteNotifier,
                                          _dragStartNotifier,
                                          _dragEndNotifier,
                                          _dragConflictNotifier,
                                        ]),
                                        builder: (context, child) => AnalogClockFace(
                                          now: now,
                                          activities: activities,
                                          tasks: tasks,
                                          viewHalf: half,
                                          previewStartMinute: _dragStartNotifier.value,
                                          previewEndMinute: _dragEndNotifier.value,
                                          previewColor: candidate.isNotEmpty
                                              ? Color(candidate.first!.colorValue)
                                              : (isInstant ? const Color(0xFFFFEE99).withOpacity(0.27) : null),
                                          previewConflict: _dragConflictNotifier.value,
                                          pulse: _pulseCtrl.value,
                                          clockHandsMode: clockHandsMode,
                                          is24h: is24h,
                                          isToday: isToday,
                                          hoverMinute: _hoverMinuteNotifier.value,
                                          isPrecisionMode: _isPrecisionMode,
                                          outerReveal: 1.0 + (_revealCtrl.value * 0.04),
                                          clockFaceTheme: clockFaceTheme,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (schedulingTask != null)
                          Positioned(
                            top: 10,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppPalette.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppPalette.accent.withValues(alpha: 0.6)),
                                boxShadow: [
                                  BoxShadow(color: AppPalette.accent.withValues(alpha: 0.2), blurRadius: 12),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 20, color: AppPalette.accent),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Tap an activity to schedule "${schedulingTask.title}"',
                                      style: const TextStyle(fontSize: 13, color: AppPalette.accent, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: AppPalette.textDim),
                                    onPressed: () => ref.read(schedulingTaskProvider.notifier).state = null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
  
            Positioned(
              top: 10,
              left: 14,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _exitApp();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppPalette.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPalette.stroke),
                  ),
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    size: 16,
                    color: AppPalette.danger,
                  ),
                ),
              ),
            ),
  
            Positioned(
              top: 10,
              right: 14,
              child: Text(
                formatTimeOfDay(now, is24h: is24h),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.accent,
                  letterSpacing: 0.5,
                ),
              ),
            ),
  
            Positioned(
              right: 14,
              bottom: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final isPlanning = ref.watch(planningModeProvider);
                      if (isPlanning) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: ref.read(currentDateProvider),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null && context.mounted) {
                                  ref.read(currentDateProvider.notifier).state = dateOnly(date);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppPalette.card,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppPalette.stroke),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppPalette.accent),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${ref.read(currentDateProvider).day}/${ref.read(currentDateProvider).month}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                ref.read(planningModeProvider.notifier).state = false;
                                ref.read(currentDateProvider.notifier).state = dateOnly(DateTime.now());
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppPalette.card,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppPalette.stroke),
                                ),
                                child: const Icon(
                                  Icons.exit_to_app_rounded,
                                  size: 16,
                                  color: AppPalette.danger,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      return GestureDetector(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          final RenderBox button = context.findRenderObject() as RenderBox;
                          final Offset offset = button.localToGlobal(Offset.zero);
                          final result = await showMenu<String>(
                            context: context,
                            position: RelativeRect.fromLTRB(offset.dx, offset.dy - 120, offset.dx + button.size.width, offset.dy),
                            color: AppPalette.card,
                            items: [
                              const PopupMenuItem(value: 'today', child: Text('Today')),
                              const PopupMenuItem(value: 'tomorrow', child: Text('Tomorrow')),
                              const PopupMenuItem(value: 'pick', child: Text('Pick Date...')),
                              const PopupMenuItem(value: 'copy', child: Text('Copy Day Schedule...')),
                            ],
                          );
                          if (result == null) return;
                          if (result == 'copy') {
                            if (context.mounted) {
                              final date = ref.read(currentDateProvider);
                              await _showCopyScheduleDialog(context, date);
                            }
                            return;
                          }
                          ref.read(planningModeProvider.notifier).state = true;
                          if (result == 'today') {
                            ref.read(currentDateProvider.notifier).state = dateOnly(DateTime.now());
                          } else if (result == 'tomorrow') {
                            ref.read(currentDateProvider.notifier).state = dateOnly(DateTime.now().add(const Duration(days: 1)));
                          } else if (result == 'pick') {
                            if (!context.mounted) return;
                            final date = await showDatePicker(
                              context: context,
                              initialDate: ref.read(currentDateProvider),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null && context.mounted) {
                              ref.read(currentDateProvider.notifier).state = dateOnly(date);
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppPalette.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppPalette.stroke),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin, size: 14, color: AppPalette.textDim),
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                  if (!is24h) ...[
                    _AmPmMini(
                      half: half,
                      onChanged: (h) {
                        HapticFeedback.selectionClick();
                        ref.read(ampmHalfProvider.notifier).state = h;
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(precisionModeProvider.notifier).state = !_isPrecisionMode;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppPalette.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _isPrecisionMode ? AppPalette.accent : AppPalette.stroke),
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        size: 16,
                        color: _isPrecisionMode ? AppPalette.accent : AppPalette.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Offset _toCenter(Offset local, Size size) => local - size.center(Offset.zero);

  bool get _is24h => ref.read(settingsProvider).valueOrNull?.is24h ?? false;

  int? _hitActivity(Offset local, Size size, List<Activity> activities) {
    final centered = _toCenter(local, size);
    final r = centered.distance;
    final outer = size.shortestSide / 2 * 0.85 * _grow;
    final inner = size.shortestSide / 2 * 0.55 * _grow;
    if (r < inner || r > outer) return null;
    final is24h = _is24h;
    final minute = offsetToMinute(centered, is24h: is24h);
    for (final a in activities) {
      final start = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
      final end = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
      if (minute >= start && minute < end) return a.id;
    }
    return null;
  }

  void _onInstantModeTap(DateTime date, Color accentColor) async {
    final start = _dragStartNotifier.value;
    final end = _dragEndNotifier.value;
    if (start == null || end == null) return;
    
    _dragStartNotifier.value = null;
    _dragEndNotifier.value = null;
    _hoverMinuteNotifier.value = null;
    
    final is24h = _is24h;
    final half = ref.read(ampmHalfProvider);
    final start24 = is24h ? start : (start + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? end : (end + (half == AmPmHalf.pm ? 720 : 0));
    
    final dbStart = toDbMinute(start24);
    final dbEnd = toDbMinute(end24);
    final dbHalf = toDbHalf(start24);
    
    final activity = Activity()
      ..title = ''
      ..startMinute = dbStart
      ..endMinute = dbEnd
      ..ampmHalf = dbHalf
      ..date = date
      ..colorValue = accentColor.toARGB32()
      ..description = ''
      ..recurrence = 'none'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    HapticFeedback.lightImpact();
    await showActivityDetailSheet(context, activity: activity, mode: DetailMode.create);
  }

  void _onPanStart(Offset p, Size size) {
    if (_draggingActivity != null) return;
    final centered = _toCenter(p, size);
    final rDist = centered.distance;
    final outer = size.shortestSide / 2 * 0.95 * _grow;
    if (rDist > outer) return;
    
    ref.read(isClockDraggingProvider.notifier).state = true;
    _hasDragged = false;
    final is24h = _is24h;
    final clickMin = _snap(offsetToMinute(centered, is24h: is24h));
    _dragClickMinute = clickMin;
    _dragStartNotifier.value = clickMin;
    _dragEndNotifier.value = clickMin;
    _lastPanMinute = offsetToMinute(centered, is24h: is24h);
    _crossedHalf = false;
    _dragConflictNotifier.value = false;
  }

  void _onPanUpdate(Offset p, Size size, List<Activity> activities) {
    if (_dragClickMinute == null) return;
    _hasDragged = true;
    final centered = _toCenter(p, size);
    final is24h = _is24h;
    final raw = offsetToMinute(centered, is24h: is24h);
    final currentMin = _snap(raw);
    final clickMin = _dragClickMinute!;
    final prevEnd = _dragEndNotifier.value;

    final last = _lastPanMinute ?? raw;
    final limitMax = is24h ? 1080 : 540;
    final limitMin = is24h ? 360 : 180;
    final scale = is24h ? 1440 : 720;
    if (!_crossedHalf && last > limitMax && raw < limitMin) {
      _crossedHalf = true;
    } else if (_crossedHalf && last < limitMin && raw > limitMax) {
      _crossedHalf = false;
    }
    _lastPanMinute = raw;

    int start;
    int end;
    if (_crossedHalf) {
      if (currentMin >= clickMin) {
        start = clickMin;
        end = scale + currentMin;
      } else {
        start = currentMin;
        end = scale + clickMin;
      }
    } else {
      if (currentMin >= clickMin) {
        start = clickMin;
        end = currentMin;
      } else {
        start = currentMin;
        end = clickMin;
      }
    }

    if (end - start < 5) {
      end = start + 5;
    }

    _dragStartNotifier.value = start;
    _dragEndNotifier.value = end;
    _dragConflictNotifier.value = _hasConflict(start, end.clamp(0, scale), activities, is24h: is24h);
    _hoverMinuteNotifier.value = raw;

    if (_isPrecisionMode && !_aimLockCtrl.isAnimating) {
      _aimLockCtrl.forward(from: 0.0);
    }

    if (end != prevEnd) HapticFeedback.selectionClick();
  }

  Future<void> _onPanEnd() async {
    ref.read(isClockDraggingProvider.notifier).state = false;
    if (!_hasDragged) {
      _dragStartNotifier.value = null;
      _dragEndNotifier.value = null;
      _dragConflictNotifier.value = false;
      _hoverMinuteNotifier.value = null;
      _dragClickMinute = null;
      return;
    }
    if (_dragStartNotifier.value == null || _dragEndNotifier.value == null) return;
    final start = _dragStartNotifier.value!;
    final endVal = _dragEndNotifier.value!;
    final end = (endVal - start) < 5 ? start + 5 : endVal;
    final date = ref.read(currentDateProvider);
    final now = DateTime.now();

    _dragStartNotifier.value = null;
    _dragEndNotifier.value = null;
    _dragConflictNotifier.value = false;
    _hoverMinuteNotifier.value = null;
    _dragClickMinute = null;
    _crossedHalf = false;
    _lastPanMinute = null;

    HapticFeedback.lightImpact();
    if (!mounted) return;

    final result = await _showPresetPicker(context);
    if (result == null || !mounted) return;

    final is24h = _is24h;
    final half = ref.read(ampmHalfProvider);
    final start24 = is24h ? start : (start + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? end : (end + (half == AmPmHalf.pm ? 720 : 0));

    final dbStart = toDbMinute(start24);
    final dbEnd = toDbMinute(end24);
    final dbHalf = toDbHalf(start24);

    if (result is Preset) {
      final activity = await activityFromPreset(
        preset: result,
        date: date,
        half: dbHalf,
        startMinute: dbStart,
        endMinute: dbEnd,
      );
      if (!mounted) return;
      final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
      
      final startDt = date.add(Duration(minutes: start24));
      final endDt = date.add(Duration(minutes: end24));
      final segments = splitSpan(startDt, endDt);
      final repo = ref.read(activityRepoProvider);

      if (segments.length == 1) {
        await repo.upsert(activity, notifLeadMinutes: lead);
      } else {
        final groupId = const Uuid().v4();
        await repo.replaceSpan(
          original: activity,
          segments: [
            for (final s in segments)
              Activity()
                ..title = activity.title
                ..iconKey = activity.iconKey
                ..description = activity.description
                ..date = s.date
                ..ampmHalf = s.half
                ..startMinute = s.start
                ..endMinute = s.end
                ..colorValue = activity.colorValue
                ..groupId = groupId
                ..recurrence = activity.recurrence
                ..createdAt = activity.createdAt
                ..updatedAt = activity.updatedAt
          ],
          notifLeadMinutes: lead,
        );
      }
      return;
    }

    final activity = Activity()
      ..title = ''
      ..startMinute = dbStart
      ..endMinute = dbEnd
      ..ampmHalf = dbHalf
      ..date = date
      ..colorValue = AppPalette.accent.toARGB32()
      ..description = ''
      ..recurrence = 'none'
      ..createdAt = now
      ..updatedAt = now;

    if (!mounted) return;
    await showActivityDetailSheet(context, activity: activity, mode: DetailMode.create);
  }

  Future<void> _onTapUp(Offset p, Size size, List<Activity> activities, int leadMinutes) async {
    if (_draggingActivity != null) return;
    final hit = _hitActivity(p, size, activities);
    if (hit == null) return;

    final a = activities.firstWhere((x) => x.id == hit);

    final schedulingTask = ref.read(schedulingTaskProvider);
    if (schedulingTask != null) {
      schedulingTask.activityId = a.id;
      schedulingTask.startMinute = a.startMinute;
      schedulingTask.endMinute = a.endMinute;
      schedulingTask.ampmHalf = a.ampmHalf;
      await ref.read(taskRepoProvider).update(schedulingTask);
      ref.read(schedulingTaskProvider.notifier).state = null;
      HapticFeedback.lightImpact();
      return;
    }

    await showActivityDetailSheet(context, activity: a, mode: DetailMode.view);
  }

  void _onLongPressStart(Offset p, Size size, List<Activity> activities) {
    final hit = _hitActivity(p, size, activities);
    if (hit == null) return;
    final a = activities.firstWhere((x) => x.id == hit);
    HapticFeedback.mediumImpact();
    
    ref.read(isClockDraggingProvider.notifier).state = true;
    _draggingActivity = a;
    
    final is24h = _is24h;
    final start = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
    final end = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
    _dragStartNotifier.value = start;
    _dragEndNotifier.value = end;
    _dragConflictNotifier.value = _hasConflict(start, end, activities, excludeId: a.id, is24h: is24h);
  }

  void _onLongPressMove(Offset p, Size size, List<Activity> activities) {
    if (_draggingActivity == null) return;
    final centered = _toCenter(p, size);
    final is24h = _is24h;
    final newStart = _snap(offsetToMinute(centered, is24h: is24h));
    final duration = toUiMinute(_draggingActivity!.endMinute, _draggingActivity!.ampmHalf, is24h: is24h) -
                     toUiMinute(_draggingActivity!.startMinute, _draggingActivity!.ampmHalf, is24h: is24h);
    if (newStart == _dragStartNotifier.value) return;
    HapticFeedback.selectionClick();

    final limitMax = is24h ? 1440 : 720;
    final newEnd = (newStart + duration).clamp(0, limitMax);
    _dragStartNotifier.value = newStart;
    _dragEndNotifier.value = newEnd;
    _hoverMinuteNotifier.value = offsetToMinute(centered, is24h: is24h);
    _dragConflictNotifier.value = _hasConflict(newStart, newEnd, activities, excludeId: _draggingActivity!.id, is24h: is24h);

    if (_isPrecisionMode && !_aimLockCtrl.isAnimating) {
      _aimLockCtrl.forward(from: 0.0);
    }
  }

  Future<void> _onLongPressEnd(int leadMinutes) async {
    ref.read(isClockDraggingProvider.notifier).state = false;
    if (_draggingActivity == null) return;
    
    final start = _dragStartNotifier.value!;
    final end = _dragEndNotifier.value!;
    final is24h = _is24h;
    final half = ref.read(ampmHalfProvider);

    final start24 = is24h ? start : (start + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? end : (end + (half == AmPmHalf.pm ? 720 : 0));
    
    _draggingActivity!.startMinute = toDbMinute(start24);
    _draggingActivity!.endMinute = toDbMinute(end24);
    _draggingActivity!.ampmHalf = toDbHalf(start24);

    await ref
        .read(activityRepoProvider)
        .upsert(_draggingActivity!, notifLeadMinutes: leadMinutes);

    final tasks = ref.read(eisenhowerTasksProvider).valueOrNull ?? const [];
    final childTasks = tasks.where((t) => t.activityId == _draggingActivity!.id).toList();
    for (final t in childTasks) {
      bool changed = false;
      final uiActStart = start;
      final uiActEnd = end;
      final tStart = toUiMinute(t.startMinute!, t.ampmHalf, is24h: is24h);
      final tEnd = toUiMinute(t.endMinute!, t.ampmHalf, is24h: is24h);
      
      var newTStart = tStart;
      var newTEnd = tEnd;
      
      if (tStart < uiActStart) {
        newTStart = uiActStart;
        changed = true;
      }
      if (tEnd > uiActEnd) {
        newTEnd = uiActEnd;
        changed = true;
      }
      if (changed) {
        final newTStart24 = is24h ? newTStart : (newTStart + (half == AmPmHalf.pm ? 720 : 0));
        final newTEnd24 = is24h ? newTEnd : (newTEnd + (half == AmPmHalf.pm ? 720 : 0));
        t.startMinute = toDbMinute(newTStart24);
        t.endMinute = toDbMinute(newTEnd24);
        t.ampmHalf = toDbHalf(newTStart24);
        await ref.read(taskRepoProvider).update(t);
      }
    }

    HapticFeedback.lightImpact();
    _draggingActivity = null;
    _dragStartNotifier.value = null;
    _dragEndNotifier.value = null;
    _dragConflictNotifier.value = false;
    _hoverMinuteNotifier.value = null;
  }

  Future<void> _onPresetDropped(Preset p) async {
    final now = DateTime.now();
    final date = ref.read(currentDateProvider);
    final is24h = _is24h;
    final half = ref.read(ampmHalfProvider);
    final start = snap5(now.hour * 60 + now.minute);
    final end = (start + 60).clamp(0, 1440);
    
    final start24 = is24h ? start : (start + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? end : (end + (half == AmPmHalf.pm ? 720 : 0));

    final dbStart = toDbMinute(start24);
    final dbEnd = toDbMinute(end24);
    final dbHalf = toDbHalf(start24);

    final a = await activityFromPreset(
      preset: p,
      date: date,
      half: dbHalf,
      startMinute: dbStart,
      endMinute: dbEnd,
    );
    if (!mounted) return;
    await showActivityDetailSheet(context, activity: a, mode: DetailMode.create);
  }

  Future<void> _copyScheduleToDates(BuildContext context, DateTime sourceDate, List<DateTime> targetDates) async {
    final activityRepo = ref.read(activityRepoProvider);
    final sourceActivities = await activityRepo.getByDate(sourceDate);
    if (sourceActivities.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No activities on this day to copy.')),
        );
      }
      return;
    }
    
    final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
    for (final targetDate in targetDates) {
      final targetActivities = await activityRepo.getByDate(targetDate);
      for (final a in targetActivities) {
        await activityRepo.delete(a.id);
      }
      for (final sa in sourceActivities) {
        final cloned = Activity()
          ..presetId = sa.presetId
          ..iconKey = sa.iconKey
          ..title = sa.title
          ..startMinute = sa.startMinute
          ..endMinute = sa.endMinute
          ..ampmHalf = sa.ampmHalf
          ..date = targetDate
          ..description = sa.description
          ..colorValue = sa.colorValue
          ..recurrence = 'none'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await activityRepo.upsert(cloned, notifLeadMinutes: lead);
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied schedule to ${targetDates.length} day(s).')),
      );
    }
  }

  Future<void> _showCopyScheduleDialog(BuildContext context, DateTime sourceDate) async {
    final result = await showDialog<List<DateTime>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.card,
        title: const Text('Copy Day Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Copy this day\'s activities to other dates. Existing activities on those target dates will be overwritten.',
              style: TextStyle(fontSize: 12, color: AppPalette.textDim),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                foregroundColor: AppPalette.accent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.next_plan_outlined, size: 18),
              label: const Text('Tomorrow'),
              onPressed: () {
                Navigator.pop(ctx, [sourceDate.add(const Duration(days: 1))]);
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                foregroundColor: AppPalette.accent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: const Text('Next 3 Days'),
              onPressed: () {
                Navigator.pop(ctx, [
                  sourceDate.add(const Duration(days: 1)),
                  sourceDate.add(const Duration(days: 2)),
                  sourceDate.add(const Duration(days: 3)),
                ]);
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                foregroundColor: AppPalette.accent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.date_range, size: 18),
              label: const Text('Next 7 Days'),
              onPressed: () {
                Navigator.pop(ctx, List.generate(7, (i) => sourceDate.add(Duration(days: i + 1))));
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
                foregroundColor: AppPalette.accent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Pick Specific Date...'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: sourceDate.add(const Duration(days: 1)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && ctx.mounted) {
                  Navigator.pop(ctx, [dateOnly(picked)]);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppPalette.textDim)),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await _copyScheduleToDates(context, sourceDate, result);
    }
  }
}

class _AmPmMini extends StatelessWidget {
  const _AmPmMini({required this.half, required this.onChanged});
  final AmPmHalf half;
  final ValueChanged<AmPmHalf> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(AmPmHalf.am),
          const SizedBox(width: 2),
          _seg(AmPmHalf.pm),
        ],
      ),
    );
  }

  Widget _seg(AmPmHalf value) {
    final active = half == value;
    return GestureDetector(
      onTap: active ? null : () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppPalette.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : AppPalette.textDim,
          ),
        ),
      ),
    );
  }
}
