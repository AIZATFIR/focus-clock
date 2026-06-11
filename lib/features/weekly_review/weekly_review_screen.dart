import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../providers/providers.dart';

class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  ConsumerState<WeeklyReviewScreen> createState() =>
      _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  bool _aiLoading = false;
  String? _aiReview;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(weekActivitiesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Review'),
        actions: [
          IconButton(
            tooltip: 'AI Consultation',
            icon: const Text('✨', style: TextStyle(fontSize: 18)),
            onPressed: async.valueOrNull == null || _aiLoading
                ? null
                : () => _requestAiReview(async.valueOrNull!),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (activities) => _Body(
          activities: activities,
          aiLoading: _aiLoading,
          aiReview: _aiReview,
        ),
      ),
    );
  }

  Future<void> _requestAiReview(List<Activity> activities) async {
    setState(() {
      _aiLoading = true;
      _aiReview = null;
    });

    final stats = _computeStats(activities);
    final prompt = _buildReviewPrompt(stats, activities);

    try {
      final ai = ref.read(aiServiceProvider);
      final reply = await ai.send(prompt);
      setState(() => _aiReview = reply);
    } catch (e) {
      setState(() => _aiReview = '❌ Error: $e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  _WeekStats _computeStats(List<Activity> activities) {
    final today = dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final byDay = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final dayActs = activities.where((a) => dateOnly(a.date) == day).toList();
      final total = dayActs.length;
      final done = dayActs.where((a) => a.isCompleted).length;
      return _DayStat(day: day, total: total, done: done);
    });

    final total = activities.length;
    final done = activities.where((a) => a.isCompleted).length;
    final deepWorkMinutes = activities
        .where((a) =>
            a.isCompleted &&
            (a.title.contains('Deep Work') || a.title.contains('🎯')))
        .fold<int>(0, (sum, a) => sum + (a.endMinute - a.startMinute));
    final importantDone = activities
        .where((a) => a.importance >= 1 && a.isCompleted)
        .length;
    final importantTotal =
        activities.where((a) => a.importance >= 1).length;

    return _WeekStats(
      byDay: byDay,
      total: total,
      done: done,
      deepWorkMinutes: deepWorkMinutes,
      importantDone: importantDone,
      importantTotal: importantTotal,
    );
  }

  String _buildReviewPrompt(_WeekStats s, List<Activity> activities) {
    final rate =
        s.total > 0 ? (s.done / s.total * 100).toStringAsFixed(0) : '0';
    final dayLines = s.byDay
        .map((d) =>
            '  ${_dayName(d.day)}: ${d.done}/${d.total} completed')
        .join('\n');
    final titles = activities
        .take(20)
        .map((a) =>
            '  - [${a.isCompleted ? "✓" : " "}] ${a.title} (${a.importance >= 1 ? "important" : "low"})')
        .join('\n');

    return '''Weekly review analysis. Respond in the same language I usually use.

Stats this week:
- Overall: $rate% completion (${s.done}/${s.total} activities)
- Important tasks: ${s.importantDone}/${s.importantTotal} done
- Deep Work minutes completed: ${s.deepWorkMinutes}
- Day breakdown:
$dayLines

Activities:
$titles

Please:
1. Analyze patterns (which days were most productive, what types of tasks were skipped)
2. Identify 1-2 root causes of incomplete tasks
3. Give 3 specific, actionable improvements for next week
4. One motivational insight based on the Fitrah philosophy (balance of Work, Rest, Social)

Be concise and direct. Max 200 words.''';
  }

  String _dayName(DateTime d) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.activities,
    required this.aiLoading,
    required this.aiReview,
  });
  final List<Activity> activities;
  final bool aiLoading;
  final String? aiReview;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final total = activities.length;
    final done = activities.where((a) => a.isCompleted).length;
    final rate = total > 0 ? done / total : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Week label
        Text(
          'Week of ${monday.day}/${monday.month}',
          style: const TextStyle(
              fontSize: 13, color: AppPalette.textDim),
        ),
        const SizedBox(height: 12),

        // Big completion ring
        _CompletionRing(rate: rate, done: done, total: total),
        const SizedBox(height: 16),

        // Day bars
        ...List.generate(7, (i) {
          final day = monday.add(Duration(days: i));
          final dayActs =
              activities.where((a) => dateOnly(a.date) == day).toList();
          final dayDone = dayActs.where((a) => a.isCompleted).length;
          final dayTotal = dayActs.length;
          final isToday = day == today;
          return _DayBar(
            day: day,
            done: dayDone,
            total: dayTotal,
            isToday: isToday,
          );
        }),

        const SizedBox(height: 16),

        // Stats row
        _StatsRow(activities: activities),

        const SizedBox(height: 20),

        // AI Review panel
        if (aiLoading)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: AppPalette.accent),
                SizedBox(height: 10),
                Text('AI analyzing your week…',
                    style: TextStyle(
                        color: AppPalette.textDim, fontSize: 13)),
              ],
            ),
          )
        else if (aiReview != null)
          _AiReviewCard(review: aiReview!)
        else
          Center(
            child: Column(
              children: [
                const Text('✨', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                const Text('Tap ✨ above for AI review',
                    style: TextStyle(
                        color: AppPalette.textDim, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Completion ring ───────────────────────────────────────────────────────────

class _CompletionRing extends StatelessWidget {
  const _CompletionRing(
      {required this.rate, required this.done, required this.total});
  final double rate;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: rate,
              strokeWidth: 10,
              backgroundColor: AppPalette.stroke,
              color: rate >= 0.8
                  ? Colors.greenAccent.shade400
                  : rate >= 0.5
                      ? AppPalette.accent
                      : AppPalette.danger,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(rate * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700),
                ),
                Text(
                  '$done/$total',
                  style: const TextStyle(
                      fontSize: 12, color: AppPalette.textDim),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day bar ───────────────────────────────────────────────────────────────────

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.day,
    required this.done,
    required this.total,
    required this.isToday,
  });
  final DateTime day;
  final int done;
  final int total;
  final bool isToday;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final rate = total > 0 ? done / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              _days[day.weekday - 1],
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday ? AppPalette.accent : AppPalette.textDim,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: total > 0 ? rate : 0,
                minHeight: 8,
                backgroundColor: AppPalette.stroke,
                color: total == 0
                    ? AppPalette.stroke
                    : rate >= 0.8
                        ? Colors.greenAccent.shade400
                        : rate >= 0.5
                            ? AppPalette.accent
                            : AppPalette.danger,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              total == 0 ? '—' : '$done/$total',
              style: const TextStyle(
                  fontSize: 11, color: AppPalette.textDim),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.activities});
  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    final deepWork = activities
        .where((a) =>
            a.isCompleted &&
            (a.title.contains('Deep Work') || a.title.contains('🎯')))
        .fold<int>(0, (s, a) => s + (a.endMinute - a.startMinute));
    final importantDone =
        activities.where((a) => a.importance >= 1 && a.isCompleted).length;
    final importantTotal =
        activities.where((a) => a.importance >= 1).length;

    return Row(
      children: [
        _StatChip(
          icon: '🎯',
          label: 'Deep Work',
          value: '${deepWork ~/ 60}h ${deepWork % 60}m',
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: '⭐',
          label: 'Important',
          value: '$importantDone/$importantTotal',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.icon, required this.label, required this.value});
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppPalette.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$icon $label',
                style: const TextStyle(
                    fontSize: 11, color: AppPalette.textDim)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── AI Review card ────────────────────────────────────────────────────────────

class _AiReviewCard extends StatelessWidget {
  const _AiReviewCard({required this.review});
  final String review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppPalette.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('✨ ', style: TextStyle(fontSize: 16)),
            const Text('AI Weekly Review',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          Text(review,
              style: const TextStyle(
                  fontSize: 13, height: 1.55, color: AppPalette.text)),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _WeekStats {
  const _WeekStats({
    required this.byDay,
    required this.total,
    required this.done,
    required this.deepWorkMinutes,
    required this.importantDone,
    required this.importantTotal,
  });
  final List<_DayStat> byDay;
  final int total;
  final int done;
  final int deepWorkMinutes;
  final int importantDone;
  final int importantTotal;
}

class _DayStat {
  const _DayStat(
      {required this.day, required this.total, required this.done});
  final DateTime day;
  final int total;
  final int done;
}
