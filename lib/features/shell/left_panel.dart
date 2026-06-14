import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';

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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppPalette.stroke)),
              color: AppPalette.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.center_focus_strong, size: 18, color: AppPalette.accent),
                    SizedBox(width: 8),
                    Text('Current Focus', style: TextStyle(fontWeight: FontWeight.w600)),
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
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
}
