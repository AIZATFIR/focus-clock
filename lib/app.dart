import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/shell/home_shell.dart';
import 'providers/providers.dart';

class FocusClockApp extends ConsumerWidget {
  const FocusClockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.valueOrNull?.themeMode ?? 'dark'));
    final trueBlack = ref.watch(settingsProvider.select((s) => s.valueOrNull?.trueBlack ?? false));
    final hasSettings = ref.watch(settingsProvider.select((s) => s.hasValue));

    final mode = switch (themeMode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    return MaterialApp(
      title: 'Focus Clock',
      theme: buildLightTheme(),
      darkTheme: trueBlack ? buildBlackTheme() : buildDarkTheme(),
      themeMode: mode,
      home: hasSettings
          ? const HomeShell()
          : const Scaffold(
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
      debugShowCheckedModeBanner: false,
    );
  }
}
