import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/daily_reflection.dart';
import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/sadar_providers.dart';
import 'habit_editor_sheet.dart';
import 'reflection_sheet.dart';
import 'sadar_timer_view.dart';

class TodayView extends ConsumerStatefulWidget {
  const TodayView({super.key});

  @override
  ConsumerState<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends ConsumerState<TodayView> {
  late Timer _clockTimer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _greeting() {
    final hour = _currentTime.hour;
    if (hour < 12) return 'Selamat pagi, Zafir.';
    if (hour < 17) return 'Selamat siang, Zafir.';
    return 'Selamat malam, Zafir.';
  }

  String get _todayStr {
    final y = _currentTime.year.toString().padLeft(4, '0');
    final m = _currentTime.month.toString().padLeft(2, '0');
    final d = _currentTime.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _openHabitEditor([Habit? habit]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HabitEditorSheet(
        habit: habit,
        onSaved: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openReflection(DailyReflection? existingReflection) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReflectionSheet(
        dateString: _todayStr,
        existingReflection: existingReflection,
        onSaved: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _startTimer(Habit habit) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => SadarTimerView(
          habit: habit,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  Future<void> _toggleComplete(Habit habit, HabitStatus currentStatus) async {
    HapticFeedback.mediumImpact();
    final newStatus = currentStatus == HabitStatus.yes ? HabitStatus.unmarked : HabitStatus.yes;
    await ref.read(sadarRepoProvider).recordEntryStatus(
      habitId: habit.id,
      dateString: _todayStr,
      status: newStatus,
      valueCompleted: newStatus == HabitStatus.yes ? habit.target : 0,
    );
    ref.invalidate(dailyFulfillmentProvider);
    ref.invalidate(whatIRepeatProvider);
    ref.invalidate(awarenessStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final rangeQuery = DateRangeQuery(start: _todayStr, end: _todayStr);
    final entriesAsync = ref.watch(habitEntriesStreamProvider(rangeQuery));
    final reflectionAsync = ref.watch(dailyReflectionProvider(_todayStr));

    final entriesMap = <int, HabitEntry>{};
    entriesAsync.whenData((entries) {
      for (final e in entries) {
        entriesMap[e.habitId] = e;
      }
    });

    final timeFormatted = DateFormat('h:mm a').format(_currentTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Salutation & Core Philosophy Prompt
            Text(
              _greeting(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppPalette.text,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'How do you want to live today?',
              style: TextStyle(
                fontSize: 15,
                color: AppPalette.textDim,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 28),

            // 2. TODAY Header Line
            Row(
              children: [
                const Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: AppPalette.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppPalette.stroke,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. List of Things
            habitsAsync.when(
              data: (habits) {
                if (habits.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Text(
                          'No things chosen for today yet.',
                          style: TextStyle(fontSize: 13, color: AppPalette.textDim),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _openHabitEditor(),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Pilih yang Bermakna Hari Ini'),
                        ),
                      ],
                    ),
                  );
                }

                int completedCount = 0;
                for (final h in habits) {
                  final entry = entriesMap[h.id];
                  if (entry?.status == HabitStatus.yes) {
                    completedCount++;
                  }
                }

                return Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: habits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final entry = entriesMap[habit.id];
                        final isDone = entry?.status == HabitStatus.yes;
                        final habitColor = Color(habit.colorValue);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF22C55E).withValues(alpha: 0.08)
                                : AppPalette.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                                  : AppPalette.stroke,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox Button
                              InkWell(
                                onTap: () => _toggleComplete(habit, entry?.status ?? HabitStatus.unmarked),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isDone ? const Color(0xFF22C55E) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDone ? const Color(0xFF22C55E) : AppPalette.stroke,
                                      width: 1.8,
                                    ),
                                  ),
                                  child: isDone
                                      ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Emoji
                              Text(habit.iconKey, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),

                              // Name & Target
                              Expanded(
                                child: Text(
                                  '${habit.name}${habit.unit == HabitUnit.min ? ' — ${habit.target} min' : (habit.target > 1 ? ' — ${habit.target} kali' : '')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                                    color: isDone ? AppPalette.textDim : AppPalette.text,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    decorationColor: AppPalette.textDim,
                                  ),
                                ),
                              ),

                              // Timer Action Button (if timed and not yet done)
                              if (habit.timerEnabled && !isDone) ...[
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    backgroundColor: habitColor.withValues(alpha: 0.15),
                                    foregroundColor: habitColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                  label: const Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () => _startTimer(habit),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // + Add & Progress Line
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _openHabitEditor(),
                          icon: const Icon(Icons.add_rounded, size: 18, color: AppPalette.accent),
                          label: const Text(
                            'Add',
                            style: TextStyle(
                              color: AppPalette.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$completedCount / ${habits.length} done',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.textDim,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Color(0xFFEF4444))),
            ),

            const SizedBox(height: 24),
            const Divider(color: AppPalette.stroke, height: 1),
            const SizedBox(height: 24),

            // 4. Today's Reflection Card
            reflectionAsync.when(
              data: (reflection) {
                final hasReflected = reflection != null &&
                    (reflection.proudOfToday.isNotEmpty || reflection.note.isNotEmpty);

                return InkWell(
                  onTap: () => _openReflection(reflection),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppPalette.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: hasReflected ? AppPalette.accent.withValues(alpha: 0.4) : AppPalette.stroke,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_border_rounded, size: 18, color: AppPalette.accent),
                            const SizedBox(width: 8),
                            const Text(
                              "Today's reflection",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppPalette.text,
                              ),
                            ),
                            const Spacer(),
                            if (hasReflected)
                              Text(
                                _feelingLabel(reflection.feeling),
                                style: const TextStyle(fontSize: 12, color: AppPalette.accent, fontWeight: FontWeight.bold),
                              )
                            else
                              const Text(
                                '[ How did today feel? ]',
                                style: TextStyle(fontSize: 12, color: AppPalette.textDim),
                              ),
                          ],
                        ),
                        if (hasReflected && reflection.proudOfToday.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            '“${reflection.proudOfToday}”',
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppPalette.text,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 48),

            // 5. Calm Clock Display at bottom
            Center(
              child: Text(
                timeFormatted,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  color: AppPalette.textDim,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

  String _feelingLabel(ReflectionFeeling feeling) {
    switch (feeling) {
      case ReflectionFeeling.proud:
        return 'Proud 🌟';
      case ReflectionFeeling.good:
        return 'Good 🌿';
      case ReflectionFeeling.okay:
        return 'Okay ☁️';
      case ReflectionFeeling.notSatisfied:
        return 'Reflecting 🌧️';
    }
  }
}
