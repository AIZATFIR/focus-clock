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

  void _finishOnboarding() {
    final s = ref.read(settingsProvider).valueOrNull;
    if (s == null) return;

    final next = s..hasCompletedOnboarding = true;
    ref.read(settingsRepoProvider).update(next);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule, size: 64, color: AppPalette.accent),
                const SizedBox(height: 24),
                const Text(
                  'Focus Clock',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'AI-powered time management.\nAtur waktumu, kurangi burnout.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppPalette.textDim, height: 1.4),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _finishOnboarding,
                    child: const Text('Mulai Sekarang', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
