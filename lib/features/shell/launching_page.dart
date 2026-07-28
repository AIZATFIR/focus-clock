import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';

class LaunchingPage extends ConsumerStatefulWidget {
  const LaunchingPage({super.key});

  @override
  ConsumerState<LaunchingPage> createState() => _LaunchingPageState();
}

class _LaunchingPageState extends ConsumerState<LaunchingPage> {
  int _quoteIndex = 0;
  late Timer _timer;

  static const List<String> _affirmations = [
    '✨ Beri makna pada setiap detikan energimu.',
    '🌿 Salurkan kreativitasmu, lindungi kedamaian pikiranmu.',
    '🌟 Setiap langkah kecil hari ini adalah karya emas hidupmu.',
    '⚡ Hadir sepenuhnya. Seize the day & fulfill your life.',
    '🛡️ Kamu memegang kendali penuh atas waktumu.',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _affirmations.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _selectMode(String mode) {
    HapticFeedback.mediumImpact();
    ref.read(selectedAppModeProvider.notifier).state = mode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Row: Google Sync Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final gcalSigned = ref.watch(gcalSignedInProvider);
                          return InkWell(
                            onTap: () async {
                              SystemSound.play(SystemSoundType.click);
                              HapticFeedback.selectionClick();
                              final svc = ref.read(gcalServiceProvider);
                              if (gcalSigned) {
                                await svc.signOut();
                                ref.read(gcalSignedInProvider.notifier).state = false;
                              } else {
                                final ok = await svc.signIn();
                                ref.read(gcalSignedInProvider.notifier).state = ok;
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: gcalSigned ? AppPalette.accent.withValues(alpha: 0.15) : AppPalette.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: gcalSigned ? AppPalette.accent : AppPalette.stroke),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('📅', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Text(
                                    gcalSigned ? 'Google Sync: Terhubung' : 'Sinkronkan Akun Google',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: gcalSigned ? AppPalette.accent : AppPalette.textDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Logo Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.accent.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.schedule_rounded, size: 52, color: AppPalette.accent),
                  ),
                  const SizedBox(height: 20),

                  // Title & Tagline
                  const Text(
                    'FOCUS CLOCK',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your private time secretary to help you seize the day & fulfill your life.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPalette.textDim,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rolling Subconscious Kind Affirmation Banner
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      key: ValueKey<int>(_quoteIndex),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppPalette.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppPalette.accent.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        _affirmations[_quoteIndex],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 2 PRIMARY HERO CARDS (Simple Mode vs Overview Mode)
                  Row(
                    children: [
                      // HERO CARD 1: SIMPLE MODE
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectMode('simple'),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppPalette.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppPalette.accent, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppPalette.accent.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppPalette.accent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.bolt_rounded, size: 22, color: Colors.black),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward_rounded, color: AppPalette.accent, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  '⚡ SIMPLE MODE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppPalette.accent,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Quick Input & Asisten Instant (Hemat Energi)',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '1-tap quick focus input, preset 15m/30m/45m/60m, kontrol Stop & Reschedule, serta asisten suara.',
                                  style: TextStyle(fontSize: 11, color: AppPalette.textDim, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // HERO CARD 2: OVERVIEW MODE
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectMode('overview'),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppPalette.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppPalette.stroke, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppPalette.bg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppPalette.stroke),
                                      ),
                                      child: const Icon(Icons.pie_chart_rounded, size: 22, color: AppPalette.text),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward_rounded, color: AppPalette.textDim, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  '📊 OVERVIEW MODE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppPalette.text,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Sadar Hari & Visual Clock Face Dial Drag',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tarik dial jam untuk buat/geser aktivitas 24 jam, lihat linimasa visual, & Eisenhower matrix.',
                                  style: TextStyle(fontSize: 11, color: AppPalette.textDim, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
