import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../models/task.dart';

import '../../providers/providers.dart';

class LeftPanel extends ConsumerWidget {
  const LeftPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current focus could be derived from currently running activity
    final activities = ref.watch(activitiesByDateProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final currentMinute = now.hour * 60 + now.minute;
    
    final currentActivity = activities.where((a) {
      final start = a.startMinute + (a.ampmHalf == AmPmHalf.pm ? 720 : 0);
      final end = a.endMinute + (a.ampmHalf == AmPmHalf.pm ? 720 : 0);
      return currentMinute >= start && currentMinute < end;
    }).firstOrNull;

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppPalette.stroke)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Focus Header
          DragTarget<Task>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) async {
              final task = details.data;
              if (currentActivity != null) {
                final t = task..activityId = currentActivity.id;
                await ref.read(taskRepoProvider).update(t);
              } else {
                final half = now.hour >= 12 ? AmPmHalf.pm : AmPmHalf.am;
                final h = now.hour % 12;
                final startM = h * 60 + now.minute;
                final endM = startM + 30;
                final a = Activity()
                  ..date = DateTime(now.year, now.month, now.day)
                  ..ampmHalf = half
                  ..startMinute = startM
                  ..endMinute = endM
                  ..title = 'Focus Block'
                  ..colorValue = AppPalette.accent.toARGB32()
                  ..iconKey = 'star';
                final id = await ref.read(activityRepoProvider).upsert(a);
                final t = task..activityId = id;
                await ref.read(taskRepoProvider).update(t);
              }
              HapticFeedback.heavyImpact();
            },
            builder: (context, candidate, rejected) {
              final isHover = candidate.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: const Border(bottom: BorderSide(color: AppPalette.stroke)),
                  color: isHover ? AppPalette.accent.withValues(alpha: 0.15) : AppPalette.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isHover ? Icons.download_rounded : Icons.center_focus_strong, size: 18, color: AppPalette.accent),
                        const SizedBox(width: 8),
                        Text(isHover ? 'Drop to Focus Now' : 'Current Focus', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (currentActivity != null) ...[
                      Text(currentActivity.title, 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPalette.accent)),
                      const SizedBox(height: 4),
                      Text('Focus until ${currentActivity.endMinute ~/ 60}:${(currentActivity.endMinute % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 13, color: AppPalette.textDim)),
                    ] else ...[
                      const Text('No active block right now.', 
                        style: TextStyle(color: AppPalette.textDim)),
                      const SizedBox(height: 4),
                      const Text('Take a break or schedule something!',
                        style: TextStyle(fontSize: 12, color: AppPalette.textDim)),
                    ],
                  ],
                ),
              );
            },
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
}
