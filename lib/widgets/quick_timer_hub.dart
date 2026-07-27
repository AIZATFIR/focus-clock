import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/time_math.dart';
import '../models/activity.dart';
import '../providers/providers.dart';

class QuickTimerHub extends ConsumerStatefulWidget {
  const QuickTimerHub({super.key});

  @override
  ConsumerState<QuickTimerHub> createState() => _QuickTimerHubState();
}

class _QuickTimerHubState extends ConsumerState<QuickTimerHub> {
  final TextEditingController _titleCtrl = TextEditingController();
  int _selectedDuration = 30; // default 30 min
  static const List<int> _durations = [15, 30, 45, 60];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _startTimer(int minutes, {String? customTitle}) async {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final date = dateOnly(now);
    final is24h = ref.read(settingsProvider).valueOrNull?.is24hDial ?? false;
    final half = halfOfNow(now);

    final startMinute = now.hour * 60 + now.minute;
    final endMinute = (startMinute + minutes).clamp(0, 1440);

    final start24 = is24h ? startMinute : (startMinute + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? endMinute : (endMinute + (half == AmPmHalf.pm ? 720 : 0));

    final dbHalf = toDbHalf(start24);
    final dbStart = toDbMinute(start24);
    final dbEnd = toDbEndMinute(end24, dbHalf);

    final rawTitle = customTitle?.trim();
    final title = (rawTitle != null && rawTitle.isNotEmpty)
        ? rawTitle
        : '$minutes Min Focused Work';

    final activity = Activity()
      ..title = title
      ..iconKey = '🎯'
      ..startMinute = dbStart
      ..endMinute = dbEnd
      ..ampmHalf = dbHalf
      ..date = date
      ..colorValue = AppPalette.accent.toARGB32()
      ..description = 'Quick Focus Session created via Quick Input.'
      ..recurrence = 'none'
      ..createdAt = now
      ..updatedAt = now;

    final repo = ref.read(activityRepoProvider);
    await repo.upsert(activity);

    ref.read(activeTimerTitleProvider.notifier).state = title;
    ref.read(activeTimerTotalSecondsProvider.notifier).state = minutes * 60;
    ref.read(activeTimerIsPausedProvider.notifier).state = false;
    ref.read(activeTimerEndTimeProvider.notifier).state = now.add(Duration(minutes: minutes));

    _titleCtrl.clear();
  }

  void _stopTimer() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    ref.read(activeTimerEndTimeProvider.notifier).state = null;
    ref.read(activeTimerIsPausedProvider.notifier).state = false;
  }

  void _rescheduleTimer(int shiftMinutes) {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
    final currentEnd = ref.read(activeTimerEndTimeProvider);
    if (currentEnd != null) {
      ref.read(activeTimerEndTimeProvider.notifier).state = currentEnd.add(Duration(minutes: shiftMinutes));
      ref.read(activeTimerTotalSecondsProvider.notifier).update((total) => total + (shiftMinutes * 60));
    }
  }

  void _showRescheduleDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule_rounded, color: AppPalette.accent, size: 20),
                  SizedBox(width: 8),
                  Text('Reschedule Aktivitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Geser atau tambahkan durasi fokus saat ini:', style: TextStyle(fontSize: 12, color: AppPalette.textDim)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.bg,
                      foregroundColor: AppPalette.accent,
                      side: const BorderSide(color: AppPalette.stroke),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+15 Menit'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _rescheduleTimer(15);
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.bg,
                      foregroundColor: AppPalette.accent,
                      side: const BorderSide(color: AppPalette.stroke),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+30 Menit'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _rescheduleTimer(30);
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.bg,
                      foregroundColor: AppPalette.accent,
                      side: const BorderSide(color: AppPalette.stroke),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+60 Menit'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _rescheduleTimer(60);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeEndTime = ref.watch(activeTimerEndTimeProvider);
    final title = ref.watch(activeTimerTitleProvider);
    final totalSecs = ref.watch(activeTimerTotalSecondsProvider);
    final isPaused = ref.watch(activeTimerIsPausedProvider);
    final nowTime = ref.watch(currentTimeProvider).valueOrNull ?? DateTime.now();

    // ACTIVE ONGOING TIMER STATE
    if (activeEndTime != null) {
      final remainingSecs = isPaused
          ? (activeEndTime.difference(nowTime).inSeconds).clamp(0, totalSecs)
          : activeEndTime.difference(nowTime).inSeconds;

      if (remainingSecs <= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _stopTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.emoji_events, color: AppPalette.accent),
                  SizedBox(width: 8),
                  Text('🎉 Sesi fokus selesai! Pekerjaan bermakna terwujud.'),
                ],
              ),
            ),
          );
        });
      }

      final mins = (remainingSecs.clamp(0, 86400) ~/ 60).toString().padLeft(2, '0');
      final secs = (remainingSecs.clamp(0, 86400) % 60).toString().padLeft(2, '0');
      final progress = totalSecs > 0 ? (1.0 - (remainingSecs / totalSecs)).clamp(0.0, 1.0) : 0.0;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.accent.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppPalette.accent.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Active Progress Indicator
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3.5,
                    backgroundColor: AppPalette.accent.withValues(alpha: 0.2),
                    color: AppPalette.accent,
                  ),
                  const Center(
                    child: Icon(Icons.flash_on_rounded, size: 18, color: AppPalette.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppPalette.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SEDANG BERLANGSUNG',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppPalette.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$mins:$secs tersisa',
                    style: const TextStyle(
                      color: AppPalette.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Reschedule Button
            IconButton(
              icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: AppPalette.accent),
              tooltip: 'Reschedule',
              onPressed: _showRescheduleDialog,
            ),
            // Pause / Resume
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20),
              tooltip: isPaused ? 'Lanjutkan' : 'Jeda',
              onPressed: () {
                ref.read(activeTimerIsPausedProvider.notifier).state = !isPaused;
              },
            ),
            // Stop Button
            IconButton(
              icon: const Icon(Icons.stop_rounded, size: 20, color: AppPalette.danger),
              tooltip: 'Stop / Selesai',
              onPressed: _stopTimer,
            ),
          ],
        ),
      );
    }

    // INACTIVE QUICK INPUT UI (ENERGY & DECISION OPTIMIZED)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 14, color: AppPalette.accent),
              const SizedBox(width: 4),
              const Text(
                'QUICK INPUT — START FOCUS NOW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textDim,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              // Duration Choice Chips
              Row(
                children: _durations.map((m) {
                  final isSelected = _selectedDuration == m;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDuration = m);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? AppPalette.accent : AppPalette.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppPalette.accent : AppPalette.stroke,
                        ),
                      ),
                      child: Text(
                        '${m}m',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : AppPalette.textDim,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title Input & Instant Start Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleCtrl,
                  onSubmitted: (val) => _startTimer(_selectedDuration, customTitle: val),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ngapain persis? (misal: Coding fitur A)',
                    hintStyle: const TextStyle(color: AppPalette.textDim, fontSize: 12),
                    filled: true,
                    fillColor: AppPalette.bg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _startTimer(_selectedDuration, customTitle: _titleCtrl.text),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  'Mulai ${_selectedDuration}m',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
