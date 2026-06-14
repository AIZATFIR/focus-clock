import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../models/preset.dart';
import '../../providers/providers.dart';
import 'preset_form_sheet.dart';

class PresetsTab extends ConsumerWidget {
  const PresetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetsProvider);
    return Stack(
      children: [
        presets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                child: Text(
                  'No presets yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.textDim),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text(
                    'LONG-PRESS TO DRAG ONTO CLOCK',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: AppPalette.textDim),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _PresetCard(preset: list[i]),
                  ),
                ),
              ],
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: AppPalette.accent,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text('Preset'),
            onPressed: () => showPresetFormSheet(context),
          ),
        ),
      ],
    );
  }
}

class _PresetCard extends ConsumerWidget {
  const _PresetCard({required this.preset});
  final Preset preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(preset.colorValue);
    final hasIcon = preset.iconKey != null && preset.iconKey!.isNotEmpty;

    return LongPressDraggable<Preset>(
      data: preset,
      delay: const Duration(milliseconds: 200),
      onDragStarted: () =>
          ref.read(tabIndexProvider.notifier).state = 1, // jump to clock
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black54)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasIcon) ...[
                Text(preset.iconKey!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Text(
                preset.name,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: _row(color, hasIcon)),
      child: InkWell(
        onTap: () => showPresetFormSheet(context, existing: preset),
        borderRadius: BorderRadius.circular(12),
        child: _row(color, hasIcon),
      ),
    );
  }

  Widget _row(Color color, bool hasIcon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (hasIcon)
              Text(preset.iconKey!, style: const TextStyle(fontSize: 22))
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                preset.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.drag_indicator, color: AppPalette.textDim),
          ],
        ),
      );
}

/// Helper to build an Activity from a dragged Preset.
Future<Activity> activityFromPreset({
  required Preset preset,
  required DateTime date,
  required AmPmHalf half,
  required int startMinute,
  required int endMinute,
}) async {
  final now = DateTime.now();
  return Activity()
    ..presetId = preset.id
    ..title = preset.name
    ..iconKey = preset.iconKey
    ..startMinute = startMinute
    ..endMinute = endMinute
    ..ampmHalf = half
    ..date = date
    ..colorValue = preset.colorValue
    ..description = ''
    ..recurrence = 'none'
    ..createdAt = now
    ..updatedAt = now;
}
