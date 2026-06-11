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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        _header(),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: [
                _Quadrant(
                  index: 0,
                  title: 'DO',
                  subtitle: 'Urgent + Important',
                  color: const Color(0xFFE5484D),
                  activities: q[0],
                  ref: ref,
                ),
                const SizedBox(height: 8),
                _Quadrant(
                  index: 2,
                  title: 'DELEGATE',
                  subtitle: 'Urgent + Not Important',
                  color: const Color(0xFFE6B800),
                  activities: q[2],
                  ref: ref,
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(children: [
                _Quadrant(
                  index: 1,
                  title: 'SCHEDULE',
                  subtitle: 'Not Urgent + Important',
                  color: AppPalette.accent,
                  activities: q[1],
                  ref: ref,
                ),
                const SizedBox(height: 8),
                _Quadrant(
                  index: 3,
                  title: 'ELIMINATE',
                  subtitle: 'Not Urgent + Not Important',
                  color: AppPalette.textDim,
                  activities: q[3],
                  ref: ref,
                ),
              ]),
            ),
          ],
        ),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 16),
          _completedSection(context, completed, ref),
        ],
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Text('Eisenhower Matrix',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Tooltip(
          message:
              'Classify tasks by urgency & importance.\nSet deadline → auto-urgent if ≤ 3 days.\nSet importance via AI or long-press.',
          child: const Icon(Icons.info_outline,
              size: 16, color: AppPalette.textDim),
        ),
      ],
    );
  }

  Widget _completedSection(
      BuildContext context, List<Activity> done, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Completed',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppPalette.textDim)),
        const SizedBox(height: 6),
        ...done.map((a) => _ActivityTile(activity: a, ref: ref, dimmed: true)),
      ],
    );
  }
}

// ── Quadrant card ─────────────────────────────────────────────────────────────

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
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: 0.8)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 9, color: AppPalette.textDim)),
                    ],
                  ),
                ),
                if (activities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${activities.length}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
              ],
            ),
          ),
          // Activities
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text('—',
                  style: const TextStyle(
                      color: AppPalette.textDim, fontSize: 12)),
            )
          else
            ...activities
                .map((a) => _ActivityTile(activity: a, ref: ref)),
        ],
      ),
    );
  }
}

// ── Activity tile ─────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(
      {required this.activity, required this.ref, this.dimmed = false});
  final Activity activity;
  final WidgetRef ref;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final deadlineStr = a.deadline != null
        ? _deadlineLabel(a.deadline!)
        : null;

    return InkWell(
      onTap: () => showActivityDetailSheet(context, activity: a),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        child: Row(
          children: [
            // Color dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color(a.colorValue).withValues(alpha: dimmed ? 0.4 : 1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            // Title + deadline
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: dimmed
                          ? AppPalette.textDim
                          : AppPalette.text,
                      decoration: dimmed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        _timeLabel(a),
                        style: const TextStyle(
                            fontSize: 10, color: AppPalette.textDim),
                      ),
                      if (deadlineStr != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: a.isUrgent
                                ? AppPalette.danger.withValues(alpha: 0.2)
                                : AppPalette.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            deadlineStr,
                            style: TextStyle(
                                fontSize: 9,
                                color: a.isUrgent
                                    ? AppPalette.danger
                                    : AppPalette.accent,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Importance toggle
            GestureDetector(
              onTap: () => ref
                  .read(activityRepoProvider)
                  .setImportance(a.id, a.importance == 1 ? 0 : 1),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  a.importance >= 1 ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16,
                  color: a.importance >= 1
                      ? AppPalette.accent
                      : AppPalette.textDim,
                ),
              ),
            ),
            // Complete toggle
            GestureDetector(
              onTap: () => ref
                  .read(activityRepoProvider)
                  .markComplete(a.id, !a.isCompleted),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  a.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: a.isCompleted
                      ? Colors.greenAccent.shade400
                      : AppPalette.textDim,
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
    return '${h.toString().padLeft(2, '0')}:$m $suffix '
        '${_dateShort(a.date)}';
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
