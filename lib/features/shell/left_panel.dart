import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/task.dart';
import '../../models/activity.dart';
import '../../providers/providers.dart';
import '../activity_detail/activity_detail_sheet.dart';
import 'task_detail_sheet.dart';

class LeftPanel extends ConsumerStatefulWidget {
  const LeftPanel({super.key, this.onClose});
  final VoidCallback? onClose;

  @override
  ConsumerState<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends ConsumerState<LeftPanel> {
  final _quickAddCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _dragTargetKey = GlobalKey();

  bool _isTaskMode = false;
  double? _createTaskDragStart;
  double? _createTaskDragCurrent;

  // Local drag & resize tracking variables (to prevent database-bound lag)
  int? _draggedTaskId;
  double? _draggedTaskStart;
  double? _draggedTaskEnd;

  int? _draggedActivityId;
  double? _draggedActivityStart;
  double? _draggedActivityEnd;

  // Drag base offsets to prevent snapping jumps
  double? _draggedStartBase;
  double? _draggedEndBase;
  double _accumulatedDelta = 0.0;

  @override
  void dispose() {
    _quickAddCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Add a task to the Inbox (unscheduled)
  Future<void> _addInboxTask(String title) async {
    final text = title.trim();
    if (text.isEmpty) return;
    final task = Task()
      ..title = text
      ..createdAt = DateTime.now();
    await ref.read(taskRepoProvider).add(task);
    _quickAddCtrl.clear();
  }

  // Quickly create a task scheduled at a specific minute
  Future<void> _createTaskAt(int minute, DateTime date) async {
    final start = snap5(minute);
    final end = (start + 30).clamp(0, 1440);

    final titleCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.card,
        title: const Text('New Timeline Task', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Enter task title...',
            isDense: true,
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppPalette.textDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppPalette.accent, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, titleCtrl.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    final task = Task()
      ..title = result.trim()
      ..date = date
      ..ampmHalf = toDbHalf(start)
      ..startMinute = toDbMinute(start)
      ..endMinute = toDbMinute(end)
      ..createdAt = DateTime.now();

    await ref.read(taskRepoProvider).add(task);
  }

  // Quickly create a task scheduled at a specific range of minutes
  Future<void> _createTaskAtRange(int start, int end, DateTime date) async {
    final titleCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.card,
        title: const Text('New Timeline Task', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Enter task title...',
            isDense: true,
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppPalette.textDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppPalette.accent, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, titleCtrl.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    final task = Task()
      ..title = result.trim()
      ..date = date
      ..ampmHalf = toDbHalf(start)
      ..startMinute = toDbMinute(start)
      ..endMinute = toDbMinute(end)
      ..createdAt = DateTime.now();

    await ref.read(taskRepoProvider).add(task);
  }

  Widget _modeButton(bool targetTaskMode, IconData icon, String label) {
    final active = _isTaskMode == targetTaskMode;
    return GestureDetector(
      onTap: active ? null : () {
        setState(() {
          _isTaskMode = targetTaskMode;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppPalette.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? Colors.black : AppPalette.textDim,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active ? Colors.black : AppPalette.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(currentDateProvider);

    // List of tasks scheduled for this day (entire 24h)
    final scheduledTasks = ref.watch(tasksByDateProvider);
    
    // List of activities scheduled for this day (entire 24h)
    final activitiesAsync = ref.watch(activitiesByDateProvider);
    final activities = activitiesAsync.valueOrNull ?? const <Activity>[];

    // Unscheduled tasks (Inbox)
    final unscheduledTasks = ref.watch(unscheduledTasksProvider);

    // Format header date label
    final isToday = date == dateOnly(DateTime.now());
    final isTomorrow = date == dateOnly(DateTime.now().add(const Duration(days: 1)));
    final dateString = isToday
        ? 'Today'
        : isTomorrow
            ? 'Tomorrow'
            : DateFormat('EEE, MMM d').format(date);

    const double timelineHeight = 1920.0; // 80dp per hour * 24 hours

    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.bg,
        border: Border(right: BorderSide(color: AppPalette.stroke)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER: Date Navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppPalette.textDim),
                  onPressed: () {
                    ref.read(currentDateProvider.notifier).state = date.subtract(const Duration(days: 1));
                    HapticFeedback.lightImpact();
                  },
                ),
                Expanded(
                  child: Center(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          ref.read(currentDateProvider.notifier).state = dateOnly(picked);
                        }
                      },
                      child: Text(
                        dateString.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppPalette.text, letterSpacing: 1.2),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppPalette.textDim),
                  onPressed: () {
                    ref.read(currentDateProvider.notifier).state = date.add(const Duration(days: 1));
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),

          // 2. HEADER: Mode Selector Row (Activity / Task Mode Switcher)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppPalette.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.stroke),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _modeButton(false, Icons.directions_run_rounded, 'Activity'),
                  ),
                  Expanded(
                    child: _modeButton(true, Icons.task_alt_rounded, 'Task'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 3. MAIN: Scrollable Timeline Agenda (24-Hour continuous grid)
          Expanded(
            child: DragTarget<Task>(
              key: _dragTargetKey,
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) async {
                // Drop unscheduled task onto the timeline
                final task = details.data;
                final renderBox = _dragTargetKey.currentContext?.findRenderObject() as RenderBox?;
                if (renderBox == null) return;
                final localOffset = renderBox.globalToLocal(details.offset);
                
                final double relativeY = localOffset.dy + _scrollCtrl.offset;
                final clickMin = (relativeY / timelineHeight) * 1440.0;
                final start = snap5(clickMin.toInt()).clamp(0, 1440 - 30);

                final updated = task
                  ..date = date
                  ..ampmHalf = toDbHalf(start)
                  ..startMinute = toDbMinute(start)
                  ..endMinute = toDbMinute(start + 30);

                await ref.read(taskRepoProvider).update(updated);
                HapticFeedback.heavyImpact();
              },
              builder: (ctx, candidateData, rejectedData) {
                final isOver = candidateData.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: isOver ? AppPalette.accent.withValues(alpha: 0.03) : Colors.transparent,
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    child: Stack(
                      children: [
                        // A. Timeline Grid Background
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTapDown: (details) {
                            if (!_isTaskMode) {
                              _createTaskAt((details.localPosition.dy / timelineHeight * 1440).toInt(), date);
                            }
                          },
                          onVerticalDragStart: _isTaskMode
                              ? (details) {
                                  ref.read(isClockDraggingProvider.notifier).state = true;
                                  setState(() {
                                    _createTaskDragStart = details.localPosition.dy;
                                    _createTaskDragCurrent = details.localPosition.dy;
                                  });
                                }
                              : null,
                          onVerticalDragUpdate: _isTaskMode
                              ? (details) {
                                  setState(() {
                                    _createTaskDragCurrent = details.localPosition.dy;
                                  });
                                }
                              : null,
                          onVerticalDragEnd: _isTaskMode
                              ? (details) async {
                                  ref.read(isClockDraggingProvider.notifier).state = false;
                                  if (_createTaskDragStart != null && _createTaskDragCurrent != null) {
                                    final startY = _createTaskDragStart!;
                                    final endY = _createTaskDragCurrent!;
                                    
                                    final min1 = (startY / timelineHeight) * 1440.0;
                                    final min2 = (endY / timelineHeight) * 1440.0;
                                    
                                    final double rawStart = min1 < min2 ? min1 : min2;
                                    final double rawEnd = min1 < min2 ? min2 : min1;
                                    
                                    final int finalStart = snap5(rawStart.round()).clamp(0, 1435);
                                    final int finalEnd = snap5(rawEnd.round()).clamp(finalStart + 5, 1440);
                                    
                                    setState(() {
                                      _createTaskDragStart = null;
                                      _createTaskDragCurrent = null;
                                    });
                                    
                                    await _createTaskAtRange(finalStart, finalEnd, date);
                                  }
                                }
                              : null,
                          onVerticalDragCancel: _isTaskMode
                              ? () {
                                  ref.read(isClockDraggingProvider.notifier).state = false;
                                  setState(() {
                                    _createTaskDragStart = null;
                                    _createTaskDragCurrent = null;
                                  });
                                }
                              : null,
                          child: SizedBox(
                            height: timelineHeight,
                            child: Column(
                              children: List.generate(24, (index) {
                                final timeStr = '${index.toString().padLeft(2, '0')}:00';
                                return Container(
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppPalette.stroke, width: 0.5)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 55,
                                        padding: const EdgeInsets.only(top: 4, left: 8),
                                        child: Text(
                                          timeStr,
                                          style: const TextStyle(fontSize: 10, color: AppPalette.textDim, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.only(top: 40),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: AppPalette.stroke.withValues(alpha: 0.3),
                                                width: 0.5,
                                                style: BorderStyle.solid,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                        // Drag-to-create Task Preview
                        if (_isTaskMode && _createTaskDragStart != null && _createTaskDragCurrent != null)
                          Builder(
                            builder: (context) {
                              final startY = _createTaskDragStart!;
                              final endY = _createTaskDragCurrent!;
                              final double top = startY < endY ? startY : endY;
                              final double height = (startY - endY).abs();
                              
                              final min1 = (startY / timelineHeight) * 1440.0;
                              final min2 = (endY / timelineHeight) * 1440.0;
                              final int startMin = snap5(min1 < min2 ? min1.round() : min2.round()).clamp(0, 1435);
                              final int endMin = snap5(min1 < min2 ? min2.round() : min1.round()).clamp(startMin + 5, 1440);
                              
                              final uiHalf = startMin < 720 ? AmPmHalf.am : AmPmHalf.pm;
                              final uiStartMin = startMin % 720;
                              final uiEndMin = endMin % 720;
                              final timeStr = '${formatMinuteOfHalf(uiStartMin, uiHalf, is24h: true)} – ${formatMinuteOfHalf(uiEndMin, uiHalf, is24h: true)}';

                              return Positioned(
                                top: top,
                                left: 60,
                                right: 12,
                                height: height.clamp(12.0, timelineHeight),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppPalette.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppPalette.accent.withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Create Task ($timeStr)',
                                    style: const TextStyle(
                                      color: AppPalette.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        // B. Scheduled Activity Cards (Wider, acting as background platform)
                        ...activities.map((a) {
                          final bool isThisDragging = _draggedActivityId == a.id;
                          final double start = isThisDragging ? _draggedActivityStart! : toUiMinute(a.startMinute, a.ampmHalf).toDouble();
                          final double end = isThisDragging ? _draggedActivityEnd! : toUiMinute(a.endMinute, a.ampmHalf).toDouble();

                          final top = (start / 1440.0) * timelineHeight;
                          final cardHeight = ((end - start) / 1440.0) * timelineHeight;

                          Widget card = _ActivityTimelineCard(
                            activity: a,
                            isDragging: isThisDragging,
                            is24h: true,
                            onTap: () => showActivityDetailSheet(context, activity: a, mode: DetailMode.view),
                            onCompleteToggle: () async {
                              HapticFeedback.selectionClick();
                              await ref.read(activityRepoProvider).markComplete(a, !a.isCompleted);
                            },
                            onPanStart: () {
                              ref.read(isClockDraggingProvider.notifier).state = true;
                              final startVal = toUiMinute(a.startMinute, a.ampmHalf).toDouble();
                              final endVal = toUiMinute(a.endMinute, a.ampmHalf).toDouble();
                              setState(() {
                                _draggedActivityId = a.id;
                                _draggedActivityStart = startVal;
                                _draggedActivityEnd = endVal;
                                _draggedStartBase = startVal;
                                _draggedEndBase = endVal;
                                _accumulatedDelta = 0.0;
                              });
                            },
                            onPanUpdate: (dy) {
                              final deltaMin = (dy / timelineHeight) * 1440.0;
                              final dur = toUiMinute(a.endMinute, a.ampmHalf) - toUiMinute(a.startMinute, a.ampmHalf);
                              setState(() {
                                _accumulatedDelta += deltaMin;
                                final target = _draggedStartBase! + _accumulatedDelta;
                                _draggedActivityStart = snap5(target.round()).toDouble().clamp(0.0, 1440.0 - dur);
                                _draggedActivityEnd = _draggedActivityStart! + dur;
                              });
                            },
                            onPanEnd: () async {
                              ref.read(isClockDraggingProvider.notifier).state = false;
                              final finalStart = _draggedActivityStart!.round();
                              final dur = toUiMinute(a.endMinute, a.ampmHalf) - toUiMinute(a.startMinute, a.ampmHalf);
                              final finalEnd = (finalStart + dur).clamp(0, 1440);
                              
                              final updated = a
                                ..startMinute = toDbMinute(finalStart)
                                ..endMinute = toDbMinute(finalEnd)
                                ..ampmHalf = toDbHalf(finalStart);
                                
                              final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
                              await ref.read(activityRepoProvider).upsert(updated, notifLeadMinutes: lead);
                              setState(() {
                                _draggedActivityId = null;
                                _draggedStartBase = null;
                                _draggedEndBase = null;
                              });
                              HapticFeedback.lightImpact();
                            },
                            onResizeTopStart: () {
                              ref.read(isClockDraggingProvider.notifier).state = true;
                              final startVal = toUiMinute(a.startMinute, a.ampmHalf).toDouble();
                              final endVal = toUiMinute(a.endMinute, a.ampmHalf).toDouble();
                              setState(() {
                                _draggedActivityId = a.id;
                                _draggedActivityStart = startVal;
                                _draggedActivityEnd = endVal;
                                _draggedStartBase = startVal;
                                _draggedEndBase = endVal;
                                _accumulatedDelta = 0.0;
                              });
                            },
                            onResizeTopUpdate: (dy) {
                              final deltaMin = (dy / timelineHeight) * 1440.0;
                              setState(() {
                                _accumulatedDelta += deltaMin;
                                final target = _draggedStartBase! + _accumulatedDelta;
                                _draggedActivityStart = snap5(target.round()).toDouble().clamp(0.0, _draggedActivityEnd! - 5.0);
                              });
                            },
                            onResizeTopEnd: () async {
                              ref.read(isClockDraggingProvider.notifier).state = false;
                              final finalStart = _draggedActivityStart!.round();
                              
                              final updated = a
                                ..startMinute = toDbMinute(finalStart)
                                ..ampmHalf = toDbHalf(finalStart);
                                
                              final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
                              await ref.read(activityRepoProvider).upsert(updated, notifLeadMinutes: lead);
                              setState(() {
                                _draggedActivityId = null;
                                _draggedStartBase = null;
                                _draggedEndBase = null;
                              });
                              HapticFeedback.lightImpact();
                            },
                            onResizeBottomStart: () {
                              ref.read(isClockDraggingProvider.notifier).state = true;
                              final startVal = toUiMinute(a.startMinute, a.ampmHalf).toDouble();
                              final endVal = toUiMinute(a.endMinute, a.ampmHalf).toDouble();
                              setState(() {
                                _draggedActivityId = a.id;
                                _draggedActivityStart = startVal;
                                _draggedActivityEnd = endVal;
                                _draggedStartBase = startVal;
                                _draggedEndBase = endVal;
                                _accumulatedDelta = 0.0;
                              });
                            },
                            onResizeBottomUpdate: (dy) {
                              final deltaMin = (dy / timelineHeight) * 1440.0;
                              setState(() {
                                _accumulatedDelta += deltaMin;
                                final target = _draggedEndBase! + _accumulatedDelta;
                                _draggedActivityEnd = snap5(target.round()).toDouble().clamp(_draggedActivityStart! + 5.0, 1440.0);
                              });
                            },
                            onResizeBottomEnd: () async {
                              ref.read(isClockDraggingProvider.notifier).state = false;
                              final finalEnd = _draggedActivityEnd!.round();
                              
                              final updated = a..endMinute = toDbMinute(finalEnd);
                              
                              final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
                              await ref.read(activityRepoProvider).upsert(updated, notifLeadMinutes: lead);
                              setState(() {
                                _draggedActivityId = null;
                                _draggedStartBase = null;
                                _draggedEndBase = null;
                              });
                              HapticFeedback.lightImpact();
                            },
                          );

                          if (_isTaskMode) {
                            card = IgnorePointer(
                              child: Opacity(
                                opacity: 0.35,
                                child: card,
                              ),
                            );
                          }

                          return Positioned(
                            key: ValueKey('activity_${a.id}'),
                            top: top,
                            left: 60,
                            right: 12, // covers the full timeline area width
                            height: cardHeight.clamp(24.0, timelineHeight),
                            child: card,
                          );
                        }),

                        // C. Scheduled Task Cards (Nested inside the activity platforms)
                        ...scheduledTasks.map((task) {
                          final bool isThisDragging = _draggedTaskId == task.id;
                          final double start = isThisDragging ? _draggedTaskStart! : toUiMinute(task.startMinute!, task.ampmHalf).toDouble();
                          final double end = isThisDragging ? _draggedTaskEnd! : toUiMinute(task.endMinute!, task.ampmHalf).toDouble();

                          final top = (start / 1440.0) * timelineHeight;
                          final cardHeight = ((end - start) / 1440.0) * timelineHeight;

                          return Positioned(
                            key: ValueKey('task_${task.id}'),
                            top: top,
                            left: 80, // slightly indented so it sits nicely inside the activity background
                            right: 24, // slightly inset from the right edge
                            height: cardHeight.clamp(24.0, timelineHeight),
                            child: _TaskTimelineCard(
                              task: task,
                              isDragging: isThisDragging,
                              onTap: () => showTaskDetailSheet(context, task),
                              onCheckboxChanged: (val) async {
                                if (val != null) {
                                  await ref.read(taskRepoProvider).toggleCompletion(task.id);
                                }
                              },
                              onSubtaskToggle: (idx) async {
                                final list = task.subtaskList;
                                list[idx].isCompleted = !list[idx].isCompleted;
                                final updated = task..subtaskList = list;
                                await ref.read(taskRepoProvider).update(updated);
                                HapticFeedback.selectionClick();
                              },
                              onPanStart: () {
                                ref.read(isClockDraggingProvider.notifier).state = true;
                                final startVal = toUiMinute(task.startMinute!, task.ampmHalf).toDouble();
                                final endVal = toUiMinute(task.endMinute!, task.ampmHalf).toDouble();
                                setState(() {
                                  _draggedTaskId = task.id;
                                  _draggedTaskStart = startVal;
                                  _draggedTaskEnd = endVal;
                                  _draggedStartBase = startVal;
                                  _draggedEndBase = endVal;
                                  _accumulatedDelta = 0.0;
                                });
                              },
                              onPanUpdate: (dy) {
                                final deltaMin = (dy / timelineHeight) * 1440.0;
                                final dur = toUiMinute(task.endMinute!, task.ampmHalf) - toUiMinute(task.startMinute!, task.ampmHalf);
                                setState(() {
                                  _accumulatedDelta += deltaMin;
                                  final target = _draggedStartBase! + _accumulatedDelta;
                                  _draggedTaskStart = snap5(target.round()).toDouble().clamp(0.0, 1440.0 - dur);
                                  _draggedTaskEnd = _draggedTaskStart! + dur;
                                });
                              },
                              onPanEnd: () async {
                                ref.read(isClockDraggingProvider.notifier).state = false;
                                final finalStart = _draggedTaskStart!.round();
                                final dur = toUiMinute(task.endMinute!, task.ampmHalf) - toUiMinute(task.startMinute!, task.ampmHalf);
                                final finalEnd = (finalStart + dur).clamp(0, 1440);
                                
                                final updated = task
                                  ..startMinute = toDbMinute(finalStart)
                                  ..endMinute = toDbMinute(finalEnd)
                                  ..ampmHalf = toDbHalf(finalStart);
                                  
                                await ref.read(taskRepoProvider).update(updated);
                                setState(() {
                                  _draggedTaskId = null;
                                  _draggedStartBase = null;
                                  _draggedEndBase = null;
                                });
                                HapticFeedback.lightImpact();
                              },
                              onResizeTopStart: () {
                                ref.read(isClockDraggingProvider.notifier).state = true;
                                final startVal = toUiMinute(task.startMinute!, task.ampmHalf).toDouble();
                                final endVal = toUiMinute(task.endMinute!, task.ampmHalf).toDouble();
                                setState(() {
                                  _draggedTaskId = task.id;
                                  _draggedTaskStart = startVal;
                                  _draggedTaskEnd = endVal;
                                  _draggedStartBase = startVal;
                                  _draggedEndBase = endVal;
                                  _accumulatedDelta = 0.0;
                                });
                              },
                              onResizeTopUpdate: (dy) {
                                final deltaMin = (dy / timelineHeight) * 1440.0;
                                setState(() {
                                  _accumulatedDelta += deltaMin;
                                  final target = _draggedStartBase! + _accumulatedDelta;
                                  _draggedTaskStart = snap5(target.round()).toDouble().clamp(0.0, _draggedTaskEnd! - 5.0);
                                });
                              },
                              onResizeTopEnd: () async {
                                ref.read(isClockDraggingProvider.notifier).state = false;
                                final finalStart = _draggedTaskStart!.round();
                                
                                final updated = task
                                  ..startMinute = toDbMinute(finalStart)
                                  ..ampmHalf = toDbHalf(finalStart);
                                  
                                await ref.read(taskRepoProvider).update(updated);
                                setState(() {
                                  _draggedTaskId = null;
                                  _draggedStartBase = null;
                                  _draggedEndBase = null;
                                });
                                HapticFeedback.lightImpact();
                              },
                              onResizeBottomStart: () {
                                ref.read(isClockDraggingProvider.notifier).state = true;
                                final startVal = toUiMinute(task.startMinute!, task.ampmHalf).toDouble();
                                final endVal = toUiMinute(task.endMinute!, task.ampmHalf).toDouble();
                                setState(() {
                                  _draggedTaskId = task.id;
                                  _draggedTaskStart = startVal;
                                  _draggedTaskEnd = endVal;
                                  _draggedStartBase = startVal;
                                  _draggedEndBase = endVal;
                                  _accumulatedDelta = 0.0;
                                });
                              },
                              onResizeBottomUpdate: (dy) {
                                final deltaMin = (dy / timelineHeight) * 1440.0;
                                setState(() {
                                  _accumulatedDelta += deltaMin;
                                  final target = _draggedEndBase! + _accumulatedDelta;
                                  _draggedTaskEnd = snap5(target.round()).toDouble().clamp(_draggedTaskStart! + 5.0, 1440.0);
                                });
                              },
                              onResizeBottomEnd: () async {
                                ref.read(isClockDraggingProvider.notifier).state = false;
                                final finalEnd = _draggedTaskEnd!.round();
                                
                                final updated = task..endMinute = toDbMinute(finalEnd);
                                
                                await ref.read(taskRepoProvider).update(updated);
                                setState(() {
                                  _draggedTaskId = null;
                                  _draggedStartBase = null;
                                  _draggedEndBase = null;
                                });
                                HapticFeedback.lightImpact();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppPalette.stroke),

          // 4. BOTTOM PANEL: Unscheduled Inbox
          Container(
            height: 200,
            color: AppPalette.card.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 16, color: AppPalette.accent),
                      const SizedBox(width: 8),
                      const Text(
                        'Inbox / Unscheduled',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppPalette.textDim, letterSpacing: 0.8),
                      ),
                      const Spacer(),
                      Text(
                        '${unscheduledTasks.length} tasks',
                        style: const TextStyle(fontSize: 10, color: AppPalette.textDim),
                      ),
                    ],
                  ),
                ),
                
                // Unscheduled Tasks list
                Expanded(
                  child: unscheduledTasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No unscheduled tasks',
                            style: TextStyle(color: AppPalette.textDim, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.builder(
                          itemCount: unscheduledTasks.length,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          itemBuilder: (context, index) {
                            final task = unscheduledTasks[index];
                            final subCount = task.subtaskList.length;
                            final subDone = task.subtaskList.where((s) => s.isCompleted).length;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Draggable<Task>(
                                data: task,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: 250,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppPalette.accent.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      task.title,
                                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.4,
                                  child: _inboxTile(task, subDone, subCount),
                                ),
                                child: _inboxTile(task, subDone, subCount),
                              ),
                            );
                          },
                        ),
                ),

                // Quick add task textfield
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _quickAddCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add an unscheduled task...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppPalette.textDim),
                      prefixIcon: const Icon(Icons.add, size: 16, color: AppPalette.textDim),
                      filled: true,
                      fillColor: AppPalette.bg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _addInboxTask,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inboxTile(Task task, int subDone, int subCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 12,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? AppPalette.textDim : AppPalette.text,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subCount > 0
            ? Text(
                '$subDone/$subCount subtasks',
                style: const TextStyle(fontSize: 9, color: AppPalette.textDim),
              )
            : null,
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: task.isCompleted,
            activeColor: AppPalette.accent,
            checkColor: Colors.black,
            onChanged: (val) async {
              if (val != null) {
                await ref.read(taskRepoProvider).toggleCompletion(task.id);
              }
            },
          ),
        ),
        onTap: () => showTaskDetailSheet(context, task),
      ),
    );
  }}

// ── CUSTOM TIMELINE TASK CARD WITH MOVE/RESIZE HANDLES ──────────────────────────

class _TaskTimelineCard extends StatelessWidget {
  const _TaskTimelineCard({
    required this.task,
    required this.isDragging,
    required this.onTap,
    required this.onCheckboxChanged,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onResizeTopStart,
    required this.onResizeTopUpdate,
    required this.onResizeTopEnd,
    required this.onResizeBottomStart,
    required this.onResizeBottomUpdate,
    required this.onResizeBottomEnd,
    required this.onSubtaskToggle,
  });

  final Task task;
  final bool isDragging;
  final VoidCallback onTap;
  final ValueChanged<bool?> onCheckboxChanged;

  final VoidCallback onPanStart;
  final ValueChanged<double> onPanUpdate;
  final VoidCallback onPanEnd;

  final VoidCallback onResizeTopStart;
  final ValueChanged<double> onResizeTopUpdate;
  final VoidCallback onResizeTopEnd;

  final VoidCallback onResizeBottomStart;
  final ValueChanged<double> onResizeBottomUpdate;
  final VoidCallback onResizeBottomEnd;

  final ValueChanged<int> onSubtaskToggle;

  @override
  Widget build(BuildContext context) {
    final subCount = task.subtaskList.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSubtasks = constraints.maxHeight >= 64.0;
        
        return Container(
          decoration: BoxDecoration(
            color: AppPalette.card.withValues(alpha: isDragging ? 0.95 : 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDragging ? AppPalette.accent : AppPalette.stroke,
              width: isDragging ? 1.5 : 1.0,
            ),
            boxShadow: isDragging
                ? [BoxShadow(color: AppPalette.accent.withValues(alpha: 0.3), blurRadius: 10)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Left color accent bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    color: task.isCompleted ? AppPalette.textDim : AppPalette.accent,
                  ),
                ),

                // Draggable Card Body
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    onVerticalDragStart: (_) => onPanStart(),
                    onVerticalDragUpdate: (details) => onPanUpdate(details.delta.dy),
                    onVerticalDragEnd: (_) => onPanEnd(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted ? AppPalette.textDim : AppPalette.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (showSubtasks && subCount > 0) ...[
                                  const SizedBox(height: 4),
                                  ...task.subtaskList.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final s = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => onSubtaskToggle(idx),
                                            behavior: HitTestBehavior.opaque,
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 4),
                                              child: Icon(
                                                s.isCompleted
                                                    ? Icons.check_box_outlined
                                                    : Icons.check_box_outline_blank_rounded,
                                                size: 11,
                                                color: s.isCompleted ? AppPalette.accent : AppPalette.textDim,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              s.title,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                color: s.isCompleted ? AppPalette.textDim : AppPalette.text,
                                                decoration: s.isCompleted ? TextDecoration.lineThrough : null,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ]
                              ],
                            ),
                          ),
                          
                          // Checkbox
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: task.isCompleted,
                              activeColor: AppPalette.accent,
                              checkColor: Colors.black,
                              onChanged: onCheckboxChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top boundary resize handle
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  height: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (_) => onResizeTopStart(),
                    onVerticalDragUpdate: (details) => onResizeTopUpdate(details.delta.dy),
                    onVerticalDragEnd: (_) => onResizeTopEnd(),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom boundary resize handle
                Positioned(
                  bottom: 0,
                  left: 10,
                  right: 10,
                  height: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (_) => onResizeBottomStart(),
                    onVerticalDragUpdate: (details) => onResizeBottomUpdate(details.delta.dy),
                    onVerticalDragEnd: (_) => onResizeBottomEnd(),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityTimelineCard extends StatelessWidget {
  const _ActivityTimelineCard({
    required this.activity,
    required this.isDragging,
    required this.onTap,
    required this.onCompleteToggle,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onResizeTopStart,
    required this.onResizeTopUpdate,
    required this.onResizeTopEnd,
    required this.onResizeBottomStart,
    required this.onResizeBottomUpdate,
    required this.onResizeBottomEnd,
    required this.is24h,
  });

  final Activity activity;
  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onCompleteToggle;

  final VoidCallback onPanStart;
  final ValueChanged<double> onPanUpdate;
  final VoidCallback onPanEnd;

  final VoidCallback onResizeTopStart;
  final ValueChanged<double> onResizeTopUpdate;
  final VoidCallback onResizeTopEnd;

  final VoidCallback onResizeBottomStart;
  final ValueChanged<double> onResizeBottomUpdate;
  final VoidCallback onResizeBottomEnd;
  
  final bool is24h;

  @override
  Widget build(BuildContext context) {
    final color = Color(activity.colorValue);
    final fg = color.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
    final timeStr = '${formatMinuteOfHalf(activity.startMinute, activity.ampmHalf, is24h: is24h)} – ${formatMinuteOfHalf(activity.endMinute, activity.ampmHalf, is24h: is24h)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final showTime = constraints.maxHeight >= 40.0;

        return Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDragging ? 0.95 : 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDragging ? AppPalette.accent : color.withValues(alpha: 0.5),
              width: isDragging ? 1.5 : 1.0,
            ),
            boxShadow: isDragging
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Left color accent bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    color: color,
                  ),
                ),

                // Draggable Card Body
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    onVerticalDragStart: (_) => onPanStart(),
                    onVerticalDragUpdate: (details) => onPanUpdate(details.delta.dy),
                    onVerticalDragEnd: (_) => onPanEnd(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                      child: Row(
                        children: [
                          if (activity.iconKey != null && activity.iconKey!.isNotEmpty) ...[
                            Text(activity.iconKey!, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  activity.title.isEmpty ? '(no title)' : activity.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    decoration: activity.isCompleted ? TextDecoration.lineThrough : null,
                                    color: fg,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (showTime) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    timeStr,
                                    style: TextStyle(fontSize: 9, color: fg.withValues(alpha: 0.75)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Checkbox/Complete Icon
                          GestureDetector(
                            onTap: onCompleteToggle,
                            child: Icon(
                              activity.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: fg.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top boundary resize handle
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  height: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (_) => onResizeTopStart(),
                    onVerticalDragUpdate: (details) => onResizeTopUpdate(details.delta.dy),
                    onVerticalDragEnd: (_) => onResizeTopEnd(),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 2,
                          decoration: BoxDecoration(
                            color: fg.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom boundary resize handle
                Positioned(
                  bottom: 0,
                  left: 10,
                  right: 10,
                  height: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (_) => onResizeBottomStart(),
                    onVerticalDragUpdate: (details) => onResizeBottomUpdate(details.delta.dy),
                    onVerticalDragEnd: (_) => onResizeBottomEnd(),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 2,
                          decoration: BoxDecoration(
                            color: fg.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
