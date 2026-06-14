import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../providers/providers.dart';

class RightPanel extends ConsumerWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesByDateProvider).valueOrNull ?? <Activity>[];
    
    // Calculate total deep work, rest, etc.
    int deepWorkMins = 0;
    int restMins = 0;
    
    for (final a in activities) {
      final dur = a.endMinute - a.startMinute;
      final title = a.title.toLowerCase();
      if (title.contains('rest') || title.contains('break') || title.contains('bengong') || title.contains('istirahat')) {
        restMins += dur;
      } else if (title.contains('work') || title.contains('study') || title.contains('belajar') || title.contains('focus') || title.contains('deep')) {
        deepWorkMins += dur;
      }
    }

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppPalette.stroke)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppPalette.stroke)),
              color: AppPalette.card,
            ),
            child: const Row(
              children: [
                Icon(Icons.timeline_rounded, size: 18, color: AppPalette.accent),
                SizedBox(width: 8),
                Text('Daily Timeline', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          
          // Fitrah Guide
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_rounded, size: 16, color: AppPalette.accent),
                    SizedBox(width: 6),
                    Text('Fitrah Guide', style: TextStyle(fontWeight: FontWeight.w600, color: AppPalette.accent)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Deep Work: ${deepWorkMins ~/ 60}h ${deepWorkMins % 60}m', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text('Max 90-120m per session to prevent dopamine depletion.', style: TextStyle(fontSize: 12, color: AppPalette.textDim)),
                const SizedBox(height: 8),
                Text('Intentional Rest: ${restMins ~/ 60}h ${restMins % 60}m', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text('Required for Default Mode Network to consolidate memory.', style: TextStyle(fontSize: 12, color: AppPalette.textDim)),
              ],
            ),
          ),

          // Timeline List
          Expanded(
            child: activities.isEmpty
              ? const Center(child: Text('No activities today', style: TextStyle(color: AppPalette.textDim)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activities.length,
                  itemBuilder: (context, i) {
                    final a = activities[i];
                    final startStr = '${a.startMinute ~/ 60}:${(a.startMinute % 60).toString().padLeft(2, '0')} ${a.ampmHalf == AmPmHalf.am ? "AM" : "PM"}';
                    final endStr = '${a.endMinute ~/ 60}:${(a.endMinute % 60).toString().padLeft(2, '0')}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(startStr, style: const TextStyle(fontSize: 12, color: AppPalette.textDim, fontWeight: FontWeight.w500)),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: Color(a.colorValue),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                Text('Until $endStr', style: const TextStyle(fontSize: 12, color: AppPalette.textDim)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
