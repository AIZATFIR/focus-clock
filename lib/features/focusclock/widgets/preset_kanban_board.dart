import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../models/preset.dart';
import '../../providers/providers.dart';
import '../../services/firebase_sync_service.dart';
import '../presets/preset_form_sheet.dart';

/// Kanban Preset Board — bar kartu preset horizontal yang dipasang di bawah / samping
/// analog clockface. Tap satu kartu = preset langsung SNAP masuk ke clockface sebagai
/// time-block aktif, siap digeser handle waktunya di busur jam.
class PresetKanbanBoard extends ConsumerWidget {
  const PresetKanbanBoard({super.key});

  /// Durasi default time-block ketika preset disentap (menit).
  static const int _defaultDurationMinutes = 60;
  static const double _boardHeight = 116;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetsProvider).valueOrNull ?? <Preset>[];

    return SizedBox(
      height: _boardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: presets.length + 1, // +1 tombol tambah preset
        itemBuilder: (context, i) {
          if (i == presets.length) {
            return const _AddPresetButton();
          }
          final p = presets[i];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _PresetSnapChip(preset: p),
          );
        },
      ),
    );
  }
}

class _PresetSnapChip extends ConsumerWidget {
  const _PresetSnapChip({required this.preset});
  final Preset preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(preset.colorValue);
    final hasIcon = preset.iconKey != null && preset.iconKey!.isNotEmpty;

    return ApplePressable(
      onTap: () => _snapPresetToClock(ref, context, preset),
      child: Container(
        width: 210,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasIcon) ...[
                  Text(preset.iconKey!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 12, color: AppPalette.textDim),
                const SizedBox(width: 4),
                Text(
                  'Tap untuk menempel ke jam • ${PresetKanbanBoard._defaultDurationMinutes}m',
                  style: TextStyle(
                      fontSize: 10, color: AppPalette.textDim, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _snapPresetToClock(WidgetRef ref, BuildContext context, Preset p) async {
    final is24h = ref.read(settingsProvider).valueOrNull?.is24hDial ?? false;
    final half = ref.read(ampmHalfProvider);
    final now = ref.read(currentTimeProvider).valueOrNull ?? DateTime.now();
    final date = ref.read(currentDateProvider);

    // Mulai dari waktu sekarang, dicapai ke kelipatan 5 menit.
    int start = is24h ? (now.hour * 60 + now.minute) : minuteOfHalf(now);
    start = snap5(start);
    int end = (start + _defaultDurationMinutes).clamp(0, is24h ? 1440 : 720);

    final start24 = is24h ? start : (start + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? end : (end + (half == AmPmHalf.pm ? 720 : 0));

    final dbStart = toDbMinute(start24);
    final dbHalf = toDbHalf(start24);
    final dbEnd = toDbEndMinute(end24, dbHalf);

    final activity = Activity()
      ..presetId = p.id
      ..title = p.name
      ..iconKey = p.iconKey
      ..startMinute = dbStart
      ..endMinute = dbEnd
      ..ampmHalf = dbHalf
      ..date = dateOnly(date)
      ..colorValue = p.colorValue
      ..description = ''
      ..recurrence = 'none'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
    await ref.read(activityRepoProvider).upsert(activity, notifLeadMinutes: lead);
    try {
      ref.read(firebaseSyncServiceProvider).syncActivity(activity);
    } catch (_) {}

    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(p.iconKey ?? '🎯', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${p.name}" diletakkan di jam. Geser handle waktu di busur jam untuk menyesuaikan.',
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AddPresetButton extends ConsumerWidget {
  const _AddPresetButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ApplePressable(
      onTap: () => showPresetFormSheet(context),
      child: Container(
        width: 210,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppPalette.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.accent.withValues(alpha: 0.5), width: 0.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 18, color: AppPalette.accent),
            SizedBox(width: 8),
            Text(
              'Tambah Preset',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.accent),
            ),
          ],
        ),
      ),
    );
  }
}
