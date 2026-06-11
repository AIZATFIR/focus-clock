import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../models/preset.dart';
import '../../providers/providers.dart';
import '../activity_detail/activity_detail_sheet.dart';
import '../ai_chat/ai_chat_sheet.dart';
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
  const _PresetPickerSheet({super.key});

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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.accent,
                  side: const BorderSide(color: AppPalette.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Custom activity'),
                onPressed: () => Navigator.pop(context, 'custom'),
              ),
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
  int? _dragStart;
  int? _dragEnd; // may exceed 720 when drag crosses 12 into the next half
  Activity? _draggingActivity;
  bool _dragConflict = false;
  int? _lastPanMinute; // raw minute of previous pan update (crossing detect)
  bool _crossedHalf = false;
  late final AnimationController _pulseCtrl;
  late final AnimationController _revealCtrl;
  final _aiSheet = DraggableScrollableController();

  /// Peek fraction of the AI sheet (shows handle + NOW & AROUND).
  static const _peek = 0.16;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _revealCtrl.dispose();
    _aiSheet.dispose();
    super.dispose();
  }

  double get _reveal =>
      Curves.easeOutCubic.transform(_revealCtrl.value);

  /// Current geometry scale — keeps hit-testing in sync with the painter.
  double get _grow => clockGrowFactor(_reveal);

  void _toggleReveal() {
    final opening = _revealCtrl.value < 0.5;
    if (opening) {
      _revealCtrl.forward();
    } else {
      _revealCtrl.reverse();
    }
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  void _toggleAiSheet() {
    final expanded = _aiSheet.isAttached && _aiSheet.size > 0.5;
    _aiSheet.animateTo(
      expanded ? _peek : 0.85,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    HapticFeedback.selectionClick();
  }

  /// True if [start, end) overlaps any activity (excluding [excludeId]).
  bool _hasConflict(int start, int end, List<Activity> activities,
      {int? excludeId}) {
    for (final a in activities) {
      if (excludeId != null && a.id == excludeId) continue;
      if (rangesOverlap(start, end, a.startMinute, a.endMinute)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesByHalfProvider);
    final half = ref.watch(ampmHalfProvider);
    final nowAsync = ref.watch(currentTimeProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final is24h = settings?.is24h ?? false;
    final clockHandsMode = settings?.clockHandsMode ?? 1;
    final showMinuteLabels = settings?.showMinuteLabels ?? false;
    final now = nowAsync.valueOrNull ?? DateTime.now();
    final activities = activitiesAsync.valueOrNull ?? const <Activity>[];

    // Pulse only while an activity is live in the viewed half — saves battery.
    final m = minuteOfHalf(now);
    final hasCurrent = halfOfNow(now) == half &&
        activities.any((a) => m >= a.startMinute && m < a.endMinute);
    if (hasCurrent && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat();
    } else if (!hasCurrent && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }

    return LayoutBuilder(builder: (context, cons) {
      final peekPx = cons.maxHeight * _peek;
      return Stack(
        children: [
          // Clock area (above the AI sheet peek)
          Positioned.fill(
            bottom: peekPx,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, c) => DragTarget<Preset>(
                      onAcceptWithDetails: (details) =>
                          _onPresetDropped(details.data),
                      builder: (ctx, candidate, rejected) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (e) => _onTapUp(e.localPosition, c.biggest,
                              activities, settings?.notifLeadMinutes ?? 1),
                          onDoubleTapDown: (e) => _onDoubleTap(
                              e.localPosition, c.biggest, activities),
                          onLongPressStart: (e) => _onLongPressStart(
                              e.localPosition, c.biggest, activities),
                          onLongPressMoveUpdate: (e) => _onLongPressMove(
                              e.localPosition, c.biggest, activities),
                          onLongPressEnd: (_) => _onLongPressEnd(
                              settings?.notifLeadMinutes ?? 1),
                          onPanStart: (e) =>
                              _onPanStart(e.localPosition, c.biggest),
                          onPanUpdate: (e) => _onPanUpdate(
                              e.localPosition, c.biggest, activities),
                          onPanEnd: (_) => _onPanEnd(half),
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation:
                                  Listenable.merge([_pulseCtrl, _revealCtrl]),
                              builder: (_, __) => AnalogClockFace(
                                now: now,
                                activities: activities,
                                viewHalf: half,
                                previewStartMinute: _draggingActivity == null
                                    ? _dragStart
                                    : _draggingActivity!.startMinute,
                                previewEndMinute: _draggingActivity == null
                                    ? _dragEnd
                                    : _draggingActivity!.endMinute,
                                previewColor: candidate.isNotEmpty
                                    ? Color(candidate.first!.colorValue)
                                    : null,
                                previewConflict: _dragConflict,
                                pulse: _pulseCtrl.value,
                                clockHandsMode: clockHandsMode,
                                is24h: is24h,
                                // Settings can pin the minute ring on
                                outerReveal:
                                    showMinuteLabels ? 1.0 : _reveal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Current time — quiet chip, top right
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

          // AM/PM — small toggle, bottom right of the clock
          Positioned(
            right: 14,
            bottom: peekPx + 12,
            child: _AmPmMini(
              half: half,
              onChanged: (h) {
                HapticFeedback.selectionClick();
                ref.read(ampmHalfProvider.notifier).state = h;
              },
            ),
          ),

          // AI assistant — pull-up sheet with NOW & AROUND in its header
          DraggableScrollableSheet(
            controller: _aiSheet,
            initialChildSize: _peek,
            minChildSize: _peek,
            maxChildSize: 0.85,
            snap: true,
            builder: (ctx, scrollCtrl) => ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppPalette.card,
                  border:
                      Border(top: BorderSide(color: AppPalette.stroke)),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleAiSheet,
                      child: _SheetHeader(
                        activities: activities,
                        now: now,
                        half: half,
                        is24h: is24h,
                      ),
                    ),
                    Expanded(
                      child: AiChatPanel(scrollController: scrollCtrl),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Offset _toCenter(Offset local, Size size) => local - size.center(Offset.zero);

  int? _hitActivity(Offset local, Size size, List<Activity> activities) {
    final centered = _toCenter(local, size);
    final r = centered.distance;
    final outer = size.shortestSide / 2 * 0.85 * _grow;
    final inner = size.shortestSide / 2 * 0.55 * _grow;
    if (r < inner || r > outer) return null;
    final minute = offsetToMinute(centered);
    for (final a in activities) {
      if (minute >= a.startMinute && minute < a.endMinute) return a.id;
    }
    return null;
  }

  /// Tap landed on the rim band (ticks/numbers) outside the activity arcs.
  bool _hitRim(Offset local, Size size) {
    final r = _toCenter(local, size).distance;
    final half = size.shortestSide / 2;
    return r > half * 0.85 * _grow && r <= half * 1.1;
  }

  // === Pan = drag-create new activity ===
  // Allow from anywhere within outer radius; snap to 5min
  void _onPanStart(Offset p, Size size) {
    if (_draggingActivity != null) return;
    final centered = _toCenter(p, size);
    final rDist = centered.distance;
    final outer = size.shortestSide / 2 * 0.95 * _grow;
    if (rDist > outer) return;
    setState(() {
      _dragStart = snap5(offsetToMinute(centered));
      _dragEnd = _dragStart;
      _lastPanMinute = offsetToMinute(centered);
      _crossedHalf = false;
      _dragConflict = false;
    });
  }

  void _onPanUpdate(Offset p, Size size, List<Activity> activities) {
    if (_dragStart == null) return;
    final centered = _toCenter(p, size);
    final raw = offsetToMinute(centered);
    final m = snap5(raw);
    final prevEnd = _dragEnd;

    // Crossing 12 o'clock: top-of-dial jump between high and low minutes
    final last = _lastPanMinute ?? raw;
    if (!_crossedHalf && last > 540 && raw < 180) {
      _crossedHalf = true; // continued into the next half (overnight feel)
    } else if (_crossedHalf && last < 180 && raw > 540) {
      _crossedHalf = false; // dragged back across 12
    }
    _lastPanMinute = raw;

    setState(() {
      if (_crossedHalf) {
        _dragEnd = 720 + m; // minute within the NEXT half
      } else if (m >= _dragStart!) {
        _dragEnd = m;
      } else {
        // Dragged backward — enforce minimum 5min
        _dragEnd = (_dragStart! + 5).clamp(0, 720);
      }
      // Conflict check covers only this half; sheet validates full span on save
      _dragConflict = _hasConflict(
          _dragStart!, _dragEnd!.clamp(0, 720), activities);
    });
    if (_dragEnd != prevEnd) HapticFeedback.selectionClick();
  }

  Future<void> _onPanEnd(AmPmHalf half) async {
    if (_dragStart == null || _dragEnd == null) return;
    final start = _dragStart!;
    final end = (_dragEnd! - start) < 5 ? start + 5 : _dragEnd!;
    final date = ref.read(currentDateProvider);
    final now = DateTime.now();
    setState(() {
      _dragStart = null;
      _dragEnd = null;
      _crossedHalf = false;
      _lastPanMinute = null;
      _dragConflict = false;
    });
    HapticFeedback.lightImpact();
    if (!mounted) return;

    // Show preset picker first
    final result = await _showPresetPicker(context);
    if (result == null || !mounted) return; // dismissed

    // endMinute > 720 = span continues into next half; sheet normalizes it
    final Activity activity;
    if (result is Preset) {
      activity = await activityFromPreset(
        preset: result,
        date: date,
        half: half,
        startMinute: start,
        endMinute: end,
      );
    } else {
      // 'custom'
      activity = Activity()
        ..title = ''
        ..startMinute = start
        ..endMinute = end
        ..ampmHalf = half
        ..date = date
        ..colorValue = AppPalette.accent.toARGB32()
        ..description = ''
        ..recurrence = 'none'
        ..createdAt = now
        ..updatedAt = now;
    }
    if (!mounted) return;
    await showActivityDetailSheet(context,
        activity: activity, mode: DetailMode.create);
  }

  // === Tap = view detail, or rim tap = reveal minute ring ===
  Future<void> _onTapUp(Offset p, Size size, List<Activity> activities,
      int leadMinutes) async {
    if (_draggingActivity != null) return; // ignore tap during drag
    final hit = _hitActivity(p, size, activities);
    if (hit == null) {
      if (_hitRim(p, size)) _toggleReveal();
      return;
    }
    final a = activities.firstWhere((x) => x.id == hit);
    await showActivityDetailSheet(context, activity: a, mode: DetailMode.view);
  }

  // === Double-tap = enter drag-reschedule mode ===
  void _onDoubleTap(Offset p, Size size, List<Activity> activities) {
    final hit = _hitActivity(p, size, activities);
    if (hit == null) return;
    final a = activities.firstWhere((x) => x.id == hit);
    setState(() => _draggingActivity = Activity()
      ..id = a.id
      ..presetId = a.presetId
      ..iconKey = a.iconKey
      ..title = a.title
      ..startMinute = a.startMinute
      ..endMinute = a.endMinute
      ..ampmHalf = a.ampmHalf
      ..date = a.date
      ..description = a.description
      ..colorValue = a.colorValue
      ..recurrence = a.recurrence
      ..createdAt = a.createdAt
      ..updatedAt = a.updatedAt);
  }

  // === Long-press = drag-reschedule ===
  void _onLongPressStart(Offset p, Size size, List<Activity> activities) {
    final hit = _hitActivity(p, size, activities);
    if (hit == null) return;
    final a = activities.firstWhere((x) => x.id == hit);
    HapticFeedback.mediumImpact();
    setState(() => _draggingActivity = a);
  }

  void _onLongPressMove(Offset p, Size size, List<Activity> activities) {
    if (_draggingActivity == null) return;
    final centered = _toCenter(p, size);
    final newStart = snap5(offsetToMinute(centered));
    final duration = _draggingActivity!.endMinute - _draggingActivity!.startMinute;
    if (newStart == _draggingActivity!.startMinute) return;
    HapticFeedback.selectionClick();
    setState(() {
      _draggingActivity!.startMinute = newStart;
      _draggingActivity!.endMinute = (newStart + duration).clamp(0, 720);
      _dragConflict = _hasConflict(
        _draggingActivity!.startMinute,
        _draggingActivity!.endMinute,
        activities,
        excludeId: _draggingActivity!.id,
      );
    });
  }

  Future<void> _onLongPressEnd(int leadMinutes) async {
    if (_draggingActivity == null) return;
    await ref
        .read(activityRepoProvider)
        .upsert(_draggingActivity!, notifLeadMinutes: leadMinutes);
    HapticFeedback.lightImpact();
    setState(() {
      _draggingActivity = null;
      _dragConflict = false;
    });
  }

  // === Preset dropped from drag ===
  Future<void> _onPresetDropped(Preset p) async {
    final half = ref.read(ampmHalfProvider);
    final date = ref.read(currentDateProvider);
    final start = snap5(minuteOfHalf(DateTime.now()));
    final end = (start + 60).clamp(0, 720);
    final a = await activityFromPreset(
      preset: p,
      date: date,
      half: half,
      startMinute: start,
      endMinute: end,
    );
    if (!mounted) return;
    await showActivityDetailSheet(context, activity: a, mode: DetailMode.create);
  }
}

/// Header of the AI pull-up sheet: drag handle + NOW & AROUND summary.
/// Tap to expand into the AI assistant.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.activities,
    required this.now,
    required this.half,
    required this.is24h,
  });
  final List<Activity> activities;
  final DateTime now;
  final AmPmHalf half;
  final bool is24h;

  @override
  Widget build(BuildContext context) {
    final m = minuteOfHalf(now);
    Activity? current;
    Activity? next;
    for (final a in activities) {
      if (m >= a.startMinute && m < a.endMinute) current = a;
      if (a.startMinute > m &&
          (next == null || a.startMinute < next.startMinute)) {
        next = a;
      }
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppPalette.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Text(
                'NOW & AROUND',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: AppPalette.textDim),
              ),
              const Spacer(),
              Text('✨',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppPalette.accent.withValues(alpha: 0.9))),
              const Icon(Icons.keyboard_arrow_up,
                  size: 16, color: AppPalette.textDim),
            ],
          ),
          const SizedBox(height: 2),
          if (current != null)
            _row(current, label: 'Now', highlight: true)
          else
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('No active block',
                  style: TextStyle(color: AppPalette.textDim, fontSize: 13)),
            ),
          if (next != null) _row(next, label: 'Next'),
        ],
      ),
    );
  }

  Widget _row(Activity a, {required String label, bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          children: [
            if (a.iconKey != null && a.iconKey!.isNotEmpty)
              Text(a.iconKey!, style: const TextStyle(fontSize: 14))
            else
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: Color(a.colorValue), shape: BoxShape.circle),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${a.title.isEmpty ? "(no title)" : a.title}  ·  '
                '${formatMinuteOfHalf(a.startMinute, half, is24h: is24h)}–'
                '${formatMinuteOfHalf(a.endMinute, half, is24h: is24h)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                  color: highlight ? AppPalette.accent : AppPalette.text,
                ),
              ),
            ),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppPalette.textDim)),
          ],
        ),
      );
}

/// Compact AM/PM toggle pinned at the clock's bottom-right corner.
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
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.black : AppPalette.textDim,
          ),
        ),
      ),
    );
  }
}
