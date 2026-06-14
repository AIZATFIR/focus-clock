import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/task.dart';
import '../../providers/providers.dart';

class EisenhowerTab extends ConsumerStatefulWidget {
  const EisenhowerTab({super.key});

  @override
  ConsumerState<EisenhowerTab> createState() => _EisenhowerTabState();
}

class _EisenhowerTabState extends ConsumerState<EisenhowerTab> {
  final _textCtrl = TextEditingController();

  void _addTask() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final t = Task()..title = text;
    ref.read(taskRepoProvider).add(t);
    _textCtrl.clear();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eisenhowerTasksProvider);
    return Column(
      children: [
        // Quick add task
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  onSubmitted: (_) => _addTask(),
                  decoration: InputDecoration(
                    hintText: 'Add a new task...',
                    filled: true,
                    fillColor: AppPalette.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _addTask,
                elevation: 0,
                mini: true,
                backgroundColor: AppPalette.accent,
                child: const Icon(Icons.add, color: AppPalette.bg),
              ),
            ],
          ),
        ),
        // Matrix
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (tasks) => _MatrixView(tasks: tasks),
          ),
        ),
      ],
    );
  }
}

class _MatrixView extends ConsumerWidget {
  const _MatrixView({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = tasks.where((t) => !t.isCompleted).toList();

    // Classify into quadrants
    final q = List.generate(4, (_) => <Task>[]);
    for (final t in pending) {
      q[t.eisenhowerQuadrant].add(t);
    }

    final completed = tasks.where((t) => t.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _header(),
        const SizedBox(height: 16),
        _Quadrant(
          index: 0,
          title: 'DO FIRST',
          subtitle: 'Urgent + Important',
          color: const Color(0xFFE5484D),
          tasks: q[0],
          ref: ref,
        ),
        const SizedBox(height: 16),
        _Quadrant(
          index: 1,
          title: 'SCHEDULE',
          subtitle: 'Not Urgent + Important',
          color: AppPalette.accent,
          tasks: q[1],
          ref: ref,
        ),
        const SizedBox(height: 16),
        _Quadrant(
          index: 2,
          title: 'DELEGATE',
          subtitle: 'Urgent + Not Important',
          color: const Color(0xFFE6B800),
          tasks: q[2],
          ref: ref,
        ),
        const SizedBox(height: 16),
        _Quadrant(
          index: 3,
          title: 'ELIMINATE',
          subtitle: 'Not Urgent + Not Important',
          color: AppPalette.textDim,
          tasks: q[3],
          ref: ref,
        ),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 32),
          _completedSection(context, completed, ref),
        ],
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Text('Eisenhower Matrix',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Drag and drop tasks between categories to adjust urgency and importance.',
          child: const Icon(Icons.info_outline, size: 18, color: AppPalette.textDim),
        ),
      ],
    );
  }

  Widget _completedSection(BuildContext context, List<Task> done, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Completed',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppPalette.textDim)),
        const SizedBox(height: 12),
        ...done.map((t) => _TaskTile(task: t, ref: ref, dimmed: true)),
      ],
    );
  }
}

// ── Quadrant Drag Target ─────────────────────────────────────────────────────────────

class _Quadrant extends StatelessWidget {
  const _Quadrant({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tasks,
    required this.ref,
  });
  
  final int index;
  final String title;
  final String subtitle;
  final Color color;
  final List<Task> tasks;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.eisenhowerQuadrant != index,
      onAcceptWithDetails: (details) async {
        final t = details.data;
        await ref.read(taskRepoProvider).updateEisenhower(t.id, index);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 110),
          decoration: BoxDecoration(
            color: isHovered ? color.withValues(alpha: 0.1) : AppPalette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? color : color.withValues(alpha: 0.2),
              width: isHovered ? 2 : 1,
            ),
            boxShadow: isHovered
                ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 2)]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: const TextStyle(fontSize: 11, color: AppPalette.textDim, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (tasks.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${tasks.length}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                      ),
                  ],
                ),
              ),
              // Tasks
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('Drag tasks here',
                        style: TextStyle(color: AppPalette.textDim.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: tasks.map((t) => _DraggableTaskTile(task: t, ref: ref)).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Draggable Task tile ─────────────────────────────────────────────────────────────

class _DraggableTaskTile extends StatelessWidget {
  const _DraggableTaskTile({required this.task, required this.ref});
  
  final Task task;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final tile = _TaskTile(task: task, ref: ref);
    
    return LongPressDraggable<Task>(
      data: task,
      hapticFeedbackOnStart: true,
      delay: const Duration(milliseconds: 200),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 4),
            ],
          ),
          child: tile,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: tile,
      ),
      child: tile,
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.ref, this.dimmed = false});
  
  final Task task;
  final WidgetRef ref;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final t = task;
    final deadlineStr = t.deadline != null ? _deadlineLabel(t.deadline!) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Drag handle
          Icon(Icons.drag_indicator, size: 16, color: AppPalette.textDim.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          // Title + deadline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dimmed ? AppPalette.textDim : AppPalette.text,
                    decoration: dimmed ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (deadlineStr != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.isUrgent
                          ? AppPalette.danger.withValues(alpha: 0.15)
                          : AppPalette.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      deadlineStr,
                      style: TextStyle(
                          fontSize: 10,
                          color: t.isUrgent ? AppPalette.danger : AppPalette.accent,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Schedule button
          GestureDetector(
            onTap: () {
              ref.read(schedulingTaskProvider.notifier).state = t;
              Navigator.of(context).pop(); // Close bottom sheet
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.transparent,
              child: Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: AppPalette.accent.withValues(alpha: 0.8),
              ),
            ),
          ),
          // Complete toggle
          GestureDetector(
            onTap: () => ref.read(taskRepoProvider).toggleCompletion(t.id),
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.transparent,
              child: Icon(
                t.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: t.isCompleted ? Colors.greenAccent.shade400 : AppPalette.textDim,
              ),
            ),
          ),
          // Delete task button
          GestureDetector(
            onTap: () => ref.read(taskRepoProvider).delete(t.id),
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.transparent,
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: AppPalette.textDim.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _deadlineLabel(DateTime dl) {
    final diff = dl.difference(dateOnly(DateTime.now())).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }
}
