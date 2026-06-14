import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../providers/providers.dart';
import '../activity_detail/activity_detail_sheet.dart';

class EisenhowerTab extends ConsumerWidget {
  const EisenhowerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eisenhowerActivitiesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (activities) => _MatrixView(activities: activities),
    );
  }
}

class _MatrixView extends ConsumerWidget {
  const _MatrixView({required this.activities});
  final List<Activity> activities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = activities.where((a) => !a.isCompleted).toList();

    // Classify into quadrants
    final q = List.generate(4, (_) => <Activity>[]);
    for (final a in pending) {
      q[a.eisenhowerQuadrant].add(a);
    }

    final completed = activities.where((a) => a.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _header(),
        const SizedBox(height: 16),
        _Quadrant(
          index: 0,
          title: 'DO FIRST',
          subtitle: 'Urgent + Important',
          color: const Color(0xFFE5484D),
          activities: q[0],
          ref: ref,
        ),
        const SizedBox(height: 16),
        _Quadrant(
          index: 1,
          title: 'SCHEDULE',
          subtitle: 'Not Urgent + Important',
          color: AppPalette.accent,
          activities: q[1],
          ref: ref,
        ),
        const SizedBox(height: 16),
        _Quadrant(
          index: 2,
          title: 'DELEGATE',
          subtitle: 'Urgent + Not Important',
          color: const Color(0xFFE6B800),
          activities: q[2],
          ref: ref,
        ),
        const SizedBox(height: 16),
        _Quadrant(
          index: 3,
          title: 'ELIMINATE',
          subtitle: 'Not Urgent + Not Important',
          color: AppPalette.textDim,
          activities: q[3],
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

  Widget _completedSection(BuildContext context, List<Activity> done, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Completed',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppPalette.textDim)),
        const SizedBox(height: 12),
        ...done.map((a) => _ActivityTile(activity: a, ref: ref, dimmed: true)),
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
    required this.activities,
    required this.ref,
  });
  
  final int index;
  final String title;
  final String subtitle;
  final Color color;
  final List<Activity> activities;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Activity>(
      onWillAcceptWithDetails: (details) => details.data.eisenhowerQuadrant != index,
      onAcceptWithDetails: (details) async {
        final a = details.data;
        final isImportant = index == 0 || index == 1;
        final isUrgent = index == 0 || index == 2;

        final repo = ref.read(activityRepoProvider);
        await repo.setImportance(a.id, isImportant ? 1 : 0);
        
        if (isUrgent && !a.isUrgent) {
          await repo.setDeadline(a.id, dateOnly(DateTime.now())); // make urgent
        } else if (!isUrgent && a.isUrgent) {
          await repo.setDeadline(a.id, null); // remove urgency
        }
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
                    if (activities.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${activities.length}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                      ),
                  ],
                ),
              ),
              // Activities
              if (activities.isEmpty)
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
                    children: activities.map((a) => _DraggableActivityTile(activity: a, ref: ref)).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Draggable Activity tile ─────────────────────────────────────────────────────────────

class _DraggableActivityTile extends StatelessWidget {
  const _DraggableActivityTile({required this.activity, required this.ref});
  
  final Activity activity;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final tile = _ActivityTile(activity: activity, ref: ref);
    
    return LongPressDraggable<Activity>(
      data: activity,
      hapticFeedbackOnStart: true,
      delay: const Duration(milliseconds: 200),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - 32, // Match list width minus padding
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


class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.ref, this.dimmed = false});
  
  final Activity activity;
  final WidgetRef ref;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final deadlineStr = a.deadline != null ? _deadlineLabel(a.deadline!) : null;

    return InkWell(
      onTap: () => showActivityDetailSheet(context, activity: a),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Color dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(a.colorValue).withValues(alpha: dimmed ? 0.4 : 1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Title + deadline
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dimmed ? AppPalette.textDim : AppPalette.text,
                      decoration: dimmed ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _timeLabel(a),
                        style: const TextStyle(fontSize: 11, color: AppPalette.textDim, fontWeight: FontWeight.w500),
                      ),
                      if (deadlineStr != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: a.isUrgent
                                ? AppPalette.danger.withValues(alpha: 0.15)
                                : AppPalette.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deadlineStr,
                            style: TextStyle(
                                fontSize: 10,
                                color: a.isUrgent ? AppPalette.danger : AppPalette.accent,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Complete toggle
            GestureDetector(
              onTap: () => ref.read(activityRepoProvider).markComplete(a.id, !a.isCompleted),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.transparent,
                child: Icon(
                  a.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: a.isCompleted ? Colors.greenAccent.shade400 : AppPalette.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(Activity a) {
    final h = (a.ampmHalf == AmPmHalf.pm ? 12 : 0) + a.startMinute ~/ 60;
    final m = (a.startMinute % 60).toString().padLeft(2, '0');
    final suffix = a.ampmHalf == AmPmHalf.pm ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$m $suffix ${_dateShort(a.date)}';
  }

  String _dateShort(DateTime d) {
    final now = dateOnly(DateTime.now());
    if (d == now) return '· Today';
    if (d == now.add(const Duration(days: 1))) return '· Tomorrow';
    return '· ${d.day}/${d.month}';
  }

  String _deadlineLabel(DateTime dl) {
    final diff = dl.difference(dateOnly(DateTime.now())).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }
}
