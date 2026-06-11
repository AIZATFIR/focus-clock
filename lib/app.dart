import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
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
    return MaterialApp(
      title: 'Focus Clock',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      home: const HomeShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
