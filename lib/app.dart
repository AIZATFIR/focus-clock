import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/home_shell.dart';
import 'providers/providers.dart';

class FocusClockApp extends ConsumerWidget {
  const FocusClockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final mode = settingsAsync.maybeWhen(
      data: (s) => switch (s.themeMode) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
      orElse: () => ThemeMode.dark,
    );
    final trueBlack = settingsAsync.valueOrNull?.trueBlack ?? false;
    return MaterialApp(
      title: 'Focus Clock',
      theme: buildLightTheme(),
      darkTheme: trueBlack ? buildBlackTheme() : buildDarkTheme(),
      themeMode: mode,
      home: settingsAsync.when(
        data: (s) => s.hasCompletedOnboarding ? const HomeShell() : const OnboardingScreen(),
        loading: () => const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 72, color: AppPalette.accent),
                SizedBox(height: 24),
                Text('FOCUS CLOCK', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
              ],
            ),
          ),
        ),
        error: (e, st) => Scaffold(body: Center(child: Text('Error loading settings: $e'))),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
