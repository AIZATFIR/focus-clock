import 'package:flutter/material.dart';
import '../core/theme.dart';

class HotkeysModal extends StatelessWidget {
  const HotkeysModal({super.key});

  @override
  Widget build(BuildContext context) {
    const shortcuts = [
      {'key': 'Ctrl + K', 'desc': 'Open Command Palette (Power Weapons)'},
      {'key': 'Ctrl + B', 'desc': 'Toggle Left Panel (Agenda & Tasks)'},
      {'key': 'Ctrl + E', 'desc': 'Toggle Right Panel (Eisenhower Matrix)'},
      {'key': 'Ctrl + A', 'desc': 'Toggle AI Assistant Sheet'},
      {'key': 'Ctrl + P', 'desc': 'Toggle Precision Mode (1-min Snapping)'},
      {'key': 'Ctrl + J', 'desc': 'Toggle Planning Mode (Fullscreen Dial)'},
      {'key': 'Alt + 1..5', 'desc': 'Quick Set Instant Mode Interval (15, 30, 60, 120, 180m)'},
      {'key': 'Alt + ← / →', 'desc': 'Switch Tabs (Presets, Clock, Agenda)'},
      {'key': 'Double Tap Dial', 'desc': 'Toggle Instant Mode'},
      {'key': 'Secondary Click', 'desc': 'Toggle Precision Snapping'},
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPalette.accent.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.keyboard_rounded, color: AppPalette.accent, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Power User Hotkeys Mastery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppPalette.textDim),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Master these hotkeys to control your Presidential Desk with ultimate speed.',
              style: TextStyle(fontSize: 12, color: AppPalette.textDim),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: shortcuts.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppPalette.stroke),
                itemBuilder: (context, idx) {
                  final s = shortcuts[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppPalette.bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            s['key']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            s['desc']!,
                            style: const TextStyle(fontSize: 13),
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
      ),
    );
  }
}
