import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../models/preset.dart';
import '../../providers/providers.dart';
import 'blueprint_editor_sheet.dart';
import 'preset_form_sheet.dart';
import 'widgets/blueprint_card.dart';

class PresetsTab extends ConsumerStatefulWidget {
  const PresetsTab({super.key});

  @override
  ConsumerState<PresetsTab> createState() => _PresetsTabState();
}

class _PresetsTabState extends ConsumerState<PresetsTab> {
  int _selectedSegment = 0; // 0 = Routine Blueprints, 1 = Category Tags

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Segmented Switcher
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedSegment = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedSegment == 0
                            ? const Color(0xFFEAB308).withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedSegment == 0
                              ? const Color(0xFFEAB308).withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 16,
                            color: _selectedSegment == 0
                                ? const Color(0xFFEAB308)
                                : Colors.white60,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Routine Blueprints',
                            style: TextStyle(
                              color: _selectedSegment == 0
                                  ? Colors.white
                                  : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedSegment = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedSegment == 1
                            ? const Color(0xFFEAB308).withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedSegment == 1
                              ? const Color(0xFFEAB308).withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.label_outline_rounded,
                            size: 16,
                            color: _selectedSegment == 1
                                ? const Color(0xFFEAB308)
                                : Colors.white60,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Category Tags',
                            style: TextStyle(
                              color: _selectedSegment == 1
                                  ? Colors.white
                                  : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content Area
        Expanded(
          child: _selectedSegment == 0
              ? _buildBlueprintsView()
              : _buildCategoryTagsView(),
        ),
      ],
    );
  }

  Widget _buildBlueprintsView() {
    final blueprintsAsync = ref.watch(blueprintsProvider);

    return Stack(
      children: [
        blueprintsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (list) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFEAB308), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'OFFICIAL DEV BLUEPRINTS (LIFE RECIPES)',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...list.where((b) => b.author == 'Official Dev').map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: BlueprintCard(
                        blueprint: b,
                        onCustomize: () =>
                            BlueprintEditorSheet.show(context, blueprint: b),
                      ),
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.palette_outlined,
                        color: Color(0xFF06B6D4), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'MY CUSTOM & COMMUNITY BLUEPRINTS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (list.where((b) => b.author != 'Official Dev').isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        style: BorderStyle.solid,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.auto_stories_outlined,
                            color: Colors.white30, size: 36),
                        const SizedBox(height: 10),
                        const Text(
                          'Belum ada Blueprint Kustom',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buat pola rutinitas harian Anda sendiri dengan menekan tombol "+ Buat Blueprint".',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...list.where((b) => b.author != 'Official Dev').map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: BlueprintCard(
                          blueprint: b,
                          onCustomize: () =>
                              BlueprintEditorSheet.show(context, blueprint: b),
                        ),
                      )),
              ],
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFFEAB308),
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Buat Blueprint',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => BlueprintEditorSheet.show(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTagsView() {
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
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
            color: color.withOpacity(0.92),
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
