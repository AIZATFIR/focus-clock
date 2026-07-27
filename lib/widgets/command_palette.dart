import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/ai_chat/voice_assistant_sheet.dart';
import '../features/settings/settings_screen.dart';
import '../providers/providers.dart';

class CommandPaletteModal extends ConsumerStatefulWidget {
  const CommandPaletteModal({super.key});

  @override
  ConsumerState<CommandPaletteModal> createState() => _CommandPaletteModalState();
}

class _CommandPaletteModalState extends ConsumerState<CommandPaletteModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedIndex = 0;

  late final List<_CommandItem> _allCommands;

  @override
  void initState() {
    super.initState();
    _allCommands = [
      _CommandItem(
        icon: Icons.flash_on_rounded,
        title: 'Start 5m Focus Timer',
        subtitle: 'Instantly spin up a 5 minute focus timer starting now',
        category: 'Quick Timers',
        onExecute: (context, ref) {
          _triggerTimer(context, ref, 5);
        },
      ),
      _CommandItem(
        icon: Icons.flash_on_rounded,
        title: 'Start 10m Focus Timer',
        subtitle: 'Instantly spin up a 10 minute focus timer starting now',
        category: 'Quick Timers',
        onExecute: (context, ref) {
          _triggerTimer(context, ref, 10);
        },
      ),
      _CommandItem(
        icon: Icons.flash_on_rounded,
        title: 'Start 15m Focus Timer',
        subtitle: 'Instantly spin up a 15 minute focus timer starting now',
        category: 'Quick Timers',
        onExecute: (context, ref) {
          _triggerTimer(context, ref, 15);
        },
      ),
      _CommandItem(
        icon: Icons.flash_on_rounded,
        title: 'Start 30m Focus Timer',
        subtitle: 'Instantly spin up a 30 minute focus timer starting now',
        category: 'Quick Timers',
        onExecute: (context, ref) {
          _triggerTimer(context, ref, 30);
        },
      ),
      _CommandItem(
        icon: Icons.flash_on_rounded,
        title: 'Start 60m Focus Timer',
        subtitle: 'Instantly spin up a 60 minute focus timer starting now',
        category: 'Quick Timers',
        onExecute: (context, ref) {
          _triggerTimer(context, ref, 60);
        },
      ),
      _CommandItem(
        icon: Icons.mic_rounded,
        title: 'Open Voice Assistant (Sekretaris Suara)',
        subtitle: 'Bicara langsung dengan asisten pribadi',
        category: 'Assistant',
        onExecute: (context, ref) {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => const VoiceAssistantSheet(),
          );
        },
      ),
      _CommandItem(
        icon: Icons.palette_outlined,
        title: 'Eye-Friendly Theme: OLED Executive Gold',
        subtitle: 'Muted Gold & Obsidian Midnight',
        category: 'Appearance',
        onExecute: (context, ref) => _setPalette(context, ref, 'executive'),
      ),
      _CommandItem(
        icon: Icons.palette_outlined,
        title: 'Eye-Friendly Theme: Soft Sage & Emerald',
        subtitle: 'Soothing Green Tones for reduced strain',
        category: 'Appearance',
        onExecute: (context, ref) => _setPalette(context, ref, 'sage'),
      ),
      _CommandItem(
        icon: Icons.palette_outlined,
        title: 'Eye-Friendly Theme: Warm Sunset Sepia',
        subtitle: 'Blue-light reduction warm sepia tones',
        category: 'Appearance',
        onExecute: (context, ref) => _setPalette(context, ref, 'sepia'),
      ),
      _CommandItem(
        icon: Icons.palette_outlined,
        title: 'Eye-Friendly Theme: Soft Cream Dark',
        subtitle: 'Gentle Indigo & Soft Cream Slate',
        category: 'Appearance',
        onExecute: (context, ref) => _setPalette(context, ref, 'cream'),
      ),
      _CommandItem(
        icon: Icons.my_location_rounded,
        title: 'Toggle Precision Mode (1-min Snap)',
        subtitle: 'Switch between 1-minute and 5-minute clock snapping',
        category: 'Clock Controls',
        onExecute: (context, ref) {
          ref.read(precisionModeProvider.notifier).update((s) => !s);
          Navigator.pop(context);
        },
      ),
      _CommandItem(
        icon: Icons.fullscreen_rounded,
        title: 'Toggle Planning Mode (Fullscreen Clock)',
        subtitle: 'Focus strictly on the analog clock dial canvas',
        category: 'Clock Controls',
        onExecute: (context, ref) {
          ref.read(planningModeProvider.notifier).update((s) => !s);
          Navigator.pop(context);
        },
      ),
      _CommandItem(
        icon: Icons.settings_outlined,
        title: 'Open App Settings',
        subtitle: 'Configure AI keys, 24h dial, keybinds, and defaults',
        category: 'System',
        onExecute: (context, ref) {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
    ];
  }

  void _triggerTimer(BuildContext context, WidgetRef ref, int minutes) async {
    Navigator.pop(context);
    final now = DateTime.now();
    ref.read(activeTimerTitleProvider.notifier).state = '$minutes Min Focus Session';
    ref.read(activeTimerTotalSecondsProvider.notifier).state = minutes * 60;
    ref.read(activeTimerIsPausedProvider.notifier).state = false;
    ref.read(activeTimerEndTimeProvider.notifier).state = now.add(Duration(minutes: minutes));
    HapticFeedback.mediumImpact();
  }

  void _setPalette(BuildContext context, WidgetRef ref, String palette) async {
    Navigator.pop(context);
    final repo = ref.read(settingsRepoProvider);
    final current = await repo.get();
    current.themePalette = palette;
    await repo.update(current);
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_CommandItem> _getFiltered() {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _allCommands;
    return _allCommands.where((c) {
      return c.title.toLowerCase().contains(q) ||
          c.subtitle.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFiltered();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPalette.accent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                onChanged: (_) => setState(() => _selectedIndex = 0),
                decoration: InputDecoration(
                  hintText: 'Ketik perintah atau cari senjata (Ctrl+K)...',
                  hintStyle: const TextStyle(color: AppPalette.textDim, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppPalette.accent),
                  suffixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppPalette.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppPalette.stroke),
                    ),
                    child: const Text('ESC', style: TextStyle(fontSize: 10, color: AppPalette.textDim)),
                  ),
                  filled: true,
                  fillColor: AppPalette.bg,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppPalette.stroke),

            // Command Items List
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Tidak ada perintah yang cocok', style: TextStyle(color: AppPalette.textDim)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isSelected = idx == _selectedIndex;

                        return InkWell(
                          onTap: () => item.onExecute(context, ref),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppPalette.accent.withValues(alpha: 0.18) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppPalette.accent.withValues(alpha: 0.4) : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(item.icon, size: 20, color: isSelected ? AppPalette.accent : AppPalette.textDim),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? AppPalette.accent : AppPalette.text,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        style: const TextStyle(fontSize: 11, color: AppPalette.textDim),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppPalette.bg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(fontSize: 9, color: AppPalette.textDim, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
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

class _CommandItem {
  _CommandItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.onExecute,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String category;
  final void Function(BuildContext context, WidgetRef ref) onExecute;
}
