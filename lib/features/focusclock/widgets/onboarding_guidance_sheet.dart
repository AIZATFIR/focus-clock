import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/app_settings.dart';
import '../../models/preset.dart';
import '../../providers/providers.dart';
import '../presets/preset_form_sheet.dart';

/// Guidance Awal (Onboarding Preset Aktivitas).
///
/// Ditampilkan saat user pertama kali buka Focus Clock (belum ada preset & belum
/// menyelesaikan onboarding), atau melalui tombol "Setup Rutinitas". User menambahkan
/// preset aktivitas dengan cepat dengan warna & ikon default. Setelah selesai, preset
/// siap digunakan di Kanban Preset Board di samping/bawah analog clockface.
class OnboardingGuidanceSheet extends ConsumerStatefulWidget {
  const OnboardingGuidanceSheet({super.key});

  static const _storageKey = 'focus_clock_onboarding_completed';

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const OnboardingGuidanceSheet(),
      );

  @override
  ConsumerState<OnboardingGuidanceSheet> createState() =>
      _OnboardingGuidanceSheetState();
}

class _PresetDraft {
  const _PresetDraft(this.name, this.iconKey, this.colorValue);
  final String name;
  final String iconKey;
  final int colorValue;
}

class _OnboardingGuidanceSheetState extends ConsumerState<OnboardingGuidanceSheet> {
  final Set<String> _created = <String>{};
  bool _saving = false;

  static const List<_PresetDraft> _defaults = <_PresetDraft>[
    _PresetDraft('Sholat', '🕌', 0xFF3F51B5),
    _PresetDraft('Deep Work / Coding', '💻', 0xFF2196F3),
    _PresetDraft('Belajar', '📖', 0xFF009688),
    _PresetDraft('Istirahat', '🧘', 0xFF9C27B0),
    _PresetDraft('Olahraga', '🏃', 0xFF4CAF50),
  ];

  Future<void> _createPreset(_PresetDraft d, List<Preset> existing) async {
    if (_created.contains(d.name) || existing.any((e) => e.name == d.name)) {
      setState(() => _created.add(d.name));
      return;
    }
    setState(() => _saving = true);
    try {
      final p = Preset()
        ..name = d.name
        ..iconKey = d.iconKey
        ..colorValue = d.colorValue
        ..createdAt = DateTime.now();
      await ref.read(presetRepoProvider).upsert(p);
      if (mounted) setState(() => _created.add(d.name));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finish() async {
    final current = ref.read(settingsProvider).valueOrNull;
    final toSave = current ?? AppSettings();
    toSave.hasCompletedOnboarding = true;
    await ref.read(settingsRepoProvider).update(toSave);
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rutinitas siap. Tap kartu preset di samping jam untuk langsung menempelkan aktivitas.'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(presetsProvider).valueOrNull ?? <Preset>[];
    final done = _created.length >= _defaults.length && presets.isNotEmpty;

    return AppleGlassSurface(
      borderRadius: 24,
      borderWidth: 0.5,
      backgroundColor: AppPalette.card,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.tips_and_updates_rounded, size: 32, color: AppPalette.accent),
            ),
          ),
          const Text(
            'Aktivitas apa saja yang kamu miliki sehari-hari?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          ),
          const SizedBox(height: 4),
          const Text(
            'Buat preset aktivitas dengan warna & ikon. Nanti, tap kartu preset untuk langsung '
            'menempelkannya ke jam sebagai time-block.',
            style: TextStyle(fontSize: 13, color: AppPalette.textDim, letterSpacing: -0.1),
          ),
          const SizedBox(height: 18),
          if (presets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Belum ada preset. Buat beberapa di bawah ini.',
                  style: TextStyle(color: AppPalette.textDim, fontSize: 12)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '${presets.length} preset siap: ${presets.map((p) => p.name).take(3).join(', ')}${presets.length > 3 ? '...' : ''}',
                style: TextStyle(fontSize: 12, color: AppPalette.textDim, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 10),
          ..._defaults.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ApplePressable(
                  onTap: _saving ? null : () => _createPreset(d, presets),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Color(d.colorValue).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Color(d.colorValue).withValues(alpha: 0.45), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(d.iconKey, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(d.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: -0.2)),
                        const Spacer(),
                        if (_created.contains(d.name))
                          const Icon(Icons.check_rounded, size: 18, color: AppPalette.accent)
                        else if (_saving)
                          const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          const Icon(Icons.add_circle_outline, size: 18, color: AppPalette.textDim),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ApplePressable(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showPresetFormSheet(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppPalette.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppPalette.accent.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: const Text(
                    'Tambah Kustom',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.accent),
                  ),
                ),
              ),
              ApplePressable(
                onTap: done ? _finish : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: done ? AppPalette.accent : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: done ? Colors.black : AppPalette.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
