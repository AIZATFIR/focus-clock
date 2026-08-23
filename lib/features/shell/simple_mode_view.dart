import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../providers/providers.dart';
import '../../widgets/floating_quick_ai_bar.dart';
import '../../widgets/quick_timer_hub.dart';
import '../activity_detail/activity_detail_sheet.dart';
import '../ai_chat/storytelling_sheet.dart';

class SimpleModeView extends ConsumerWidget {
  const SimpleModeView({super.key});

  void _openCreateSheet(BuildContext context, WidgetRef ref, {int initialMinutes = 30}) {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final date = dateOnly(now);
    final is24h = ref.read(settingsProvider).valueOrNull?.is24hDial ?? false;
    final half = halfOfNow(now);

    final startMinute = now.hour * 60 + now.minute;
    final endMinute = (startMinute + initialMinutes).clamp(0, 1440);

    final start24 = is24h ? startMinute : (startMinute + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? endMinute : (endMinute + (half == AmPmHalf.pm ? 720 : 0));

    final dbHalf = toDbHalf(start24);
    final dbStart = toDbMinute(start24);
    final dbEnd = toDbEndMinute(end24, dbHalf);

    final activity = Activity()
      ..title = '$initialMinutes Min Focused Work'
      ..iconKey = '🎯'
      ..startMinute = dbStart
      ..endMinute = dbEnd
      ..ampmHalf = dbHalf
      ..date = date
      ..colorValue = AppPalette.accent.toARGB32()
      ..description = 'Quick Focus Session created via Simple Mode.'
      ..recurrence = 'none'
      ..createdAt = now
      ..updatedAt = now;

    showActivityDetailSheet(context, activity: activity, mode: DetailMode.create);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEndTime = ref.watch(activeTimerEndTimeProvider);

    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sub-header with Back Button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              SystemSound.play(SystemSoundType.click);
                              HapticFeedback.mediumImpact();
                              ref.read(selectedAppModeProvider.notifier).state = 'launching';
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppPalette.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppPalette.stroke),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_rounded, size: 16, color: AppPalette.accent),
                                  SizedBox(width: 6),
                                  Text(
                                    'Desk',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppPalette.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '⚡ SIMPLE MODE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.accent,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Title & Intro
                      const Text(
                        'Simple Mode',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Aktivitas fokus cepat dan praktis.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppPalette.textDim,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Ongoing Active Timer Display (If timer is running)
                      if (activeEndTime != null) ...[
                        const QuickTimerHub(),
                        const SizedBox(height: 20),
                      ],

                      // Hero Primary Pop-Up Action Button (Memenuhi Layar di Android)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openCreateSheet(context, ref, initialMinutes: 30),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppPalette.accent,
                                  AppPalette.accent.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppPalette.accent.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.bolt_rounded, size: 28, color: Colors.black),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '⚡ BUAT AKTIVITAS FOKUS',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Pop-Up Waktu Lain, Icon, Warna, & Detail',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.open_in_new_rounded, size: 20, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Large Quick Presets Grid (Memenuhi Layar di Android)
                      const Text(
                        'PILIH DURASI / WAKTU LAIN DARI SEKARANG:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.textDim,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _QuickPresetCard(
                            title: '15 Menit',
                            subtitle: 'Quick Focus',
                            icon: '⚡',
                            onTap: () => _openCreateSheet(context, ref, initialMinutes: 15),
                          ),
                          _QuickPresetCard(
                            title: '30 Menit',
                            subtitle: 'Standard Focus',
                            icon: '🎯',
                            onTap: () => _openCreateSheet(context, ref, initialMinutes: 30),
                          ),
                          _QuickPresetCard(
                            title: '45 Menit',
                            subtitle: 'Deep Work',
                            icon: '💻',
                            onTap: () => _openCreateSheet(context, ref, initialMinutes: 45),
                          ),
                          _QuickPresetCard(
                            title: '60 Menit (1j)',
                            subtitle: 'Full Session',
                            icon: '🚀',
                            onTap: () => _openCreateSheet(context, ref, initialMinutes: 60),
                          ),
                          _QuickPresetCard(
                            title: '90 Menit (1.5j)',
                            subtitle: 'Extended Work',
                            icon: '🔥',
                            onTap: () => _openCreateSheet(context, ref, initialMinutes: 90),
                          ),
                          _QuickPresetCard(
                            title: '+ Waktu Lain...',
                            subtitle: 'Custom Detail',
                            icon: '⏱️',
                            highlight: true,
                            onTap: () => _openCreateSheet(context, ref, initialMinutes: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Storytelling Reflection Card ("Talking About Your Day")
                      InkWell(
                        onTap: () {
                          SystemSound.play(SystemSoundType.click);
                          HapticFeedback.mediumImpact();
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => const StorytellingSheet(),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppPalette.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppPalette.stroke),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppPalette.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.auto_stories_rounded, color: AppPalette.accent, size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📖 Talking About Your Day',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppPalette.text,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Refleksi malam & niat hari esok bersama Asisten Sekretaris.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppPalette.textDim,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppPalette.textDim),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // bottom clearance for floating AI bar
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Quick AI Command Bar ("P info...")
          const Positioned(
            bottom: 20,
            right: 16,
            child: FloatingQuickAiBar(),
          ),
        ],
      ),
    );
  }
}

class _QuickPresetCard extends StatelessWidget {
  const _QuickPresetCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: highlight ? AppPalette.accent.withValues(alpha: 0.15) : AppPalette.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight ? AppPalette.accent : AppPalette.stroke,
              width: highlight ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: highlight ? AppPalette.accent : AppPalette.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.textDim,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
