import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.access_time_filled_rounded,
      'title': 'Jam Analog Interaktif',
      'subtitle': 'Geser jarum jam untuk memblokir waktu fokus secara visual dan presisi tanpa mengetik manual.',
      'badge': 'LANGKAH 1 DARI 3',
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'Gemini AI Assistant',
      'subtitle': 'Ketik prompt natural atau gunakan suara. AI akan merapikan agenda dan mencegah bentrok waktu.',
      'badge': 'LANGKAH 2 DARI 3',
    },
    {
      'icon': Icons.bolt_rounded,
      'title': 'Simple Mode & Command Palette',
      'subtitle': 'Fokus mendalam tanpa distraksi dengan Simple Mode, serta akses kilat via shortcut Ctrl + K.',
      'badge': 'LANGKAH 3 DARI 3',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    final s = ref.read(settingsProvider).valueOrNull;
    if (s == null) return;

    final next = s..hasCompletedOnboarding = true;
    ref.read(settingsRepoProvider).update(next);
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: GeminiMotion.medium,
        curve: GeminiMotion.springCurve,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FOCUS CLOCK',
                    style: TextStyle(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppPalette.accent,
                    ),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Lewati', style: TextStyle(color: AppPalette.textDim)),
                  ),
                ],
              ),
            ),

            // Main PageView Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (ctx, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppPalette.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.accent.withValues(alpha: 0.25),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(slide['icon'] as IconData, size: 72, color: AppPalette.accent),
                        ),
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppPalette.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            slide['badge'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.accent,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppPalette.textDim,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots & Next Button
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (idx) => AnimatedContainer(
                        duration: GeminiMotion.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == idx ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == idx ? AppPalette.accent : AppPalette.stroke,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Mulai Sekarang' : 'Lanjut',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
