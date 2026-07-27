import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/floating_quick_ai_bar.dart';
import '../../widgets/quick_timer_hub.dart';
import '../ai_chat/storytelling_sheet.dart';

class SimpleModeView extends ConsumerWidget {
  const SimpleModeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        'Pusat Fokus Instant',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pilih durasi fokus atau tanya asisten AI tanpa distraksi visual.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppPalette.textDim,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Timer Hub (Hero 1-Tap 15m/30m/45m/60m + Stop/Reschedule)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppPalette.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppPalette.accent.withValues(alpha: 0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.accent.withValues(alpha: 0.1),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const QuickTimerHub(),
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
