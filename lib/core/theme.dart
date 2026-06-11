import 'package:flutter/material.dart';

class AppPalette {
  // Dark
  static const bg = Color(0xFF1E1E1E);
  static const card = Color(0xFF2D2D2D);
  static const accent = Color(0xFFFFD700);
  static const text = Color(0xFFE0E0E0);
  static const textDim = Color(0xFF9A9A9A);
  static const stroke = Color(0xFF3A3A3A);

  // Light equivalents (used inline in buildLightTheme)
  static const lightBg = Color(0xFFF5F5F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF1A1A1A);
  static const lightTextDim = Color(0xFF757575);
  static const lightStroke = Color(0xFFDDDDDD);
  static const lightAccent = Color(0xFFD4A800); // darker gold for light bg
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.bg,
    colorScheme: base.colorScheme.copyWith(
      surface: AppPalette.bg,
      primary: AppPalette.accent,
      secondary: AppPalette.accent,
      onSurface: AppPalette.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.bg,
      foregroundColor: AppPalette.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: AppPalette.card,
    dividerColor: AppPalette.stroke,
    textTheme: base.textTheme.apply(
      bodyColor: AppPalette.text,
      displayColor: AppPalette.text,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppPalette.card,
      selectedItemColor: AppPalette.accent,
      unselectedItemColor: AppPalette.textDim,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppPalette.card,
      contentTextStyle: TextStyle(color: AppPalette.text),
    ),
  );
}

ThemeData buildLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.lightBg,
    colorScheme: base.colorScheme.copyWith(
      surface: AppPalette.lightBg,
      primary: AppPalette.lightAccent,
      secondary: AppPalette.lightAccent,
      onSurface: AppPalette.lightText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.lightBg,
      foregroundColor: AppPalette.lightText,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: AppPalette.lightCard,
    dividerColor: AppPalette.lightStroke,
    textTheme: base.textTheme.apply(
      bodyColor: AppPalette.lightText,
      displayColor: AppPalette.lightText,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppPalette.lightCard,
      selectedItemColor: AppPalette.lightAccent,
      unselectedItemColor: AppPalette.lightTextDim,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppPalette.lightCard,
      contentTextStyle: const TextStyle(color: AppPalette.lightText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppPalette.lightStroke),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      labelStyle: TextStyle(color: AppPalette.lightTextDim),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppPalette.lightAccent
              : AppPalette.lightCard,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppPalette.lightText,
        ),
      ),
    ),
  );
}

const presetColors = <int>[
  0xFF4FC3F7,
  0xFF66BB6A,
  0xFFFFB74D,
  0xFFBA68C8,
  0xFFFFD54F,
  0xFFE57373,
  0xFF4DB6AC,
  0xFFFF8A65,
  0xFF7986CB,
  0xFF81C784,
];

const presetIcons = <String>[
  '🏃', '💻', '😴', '🍽️', '📚',
  '🏋️', '🎮', '🎵', '🏠', '💆',
  '✍️', '🚗', '🤝', '📞', '🧘',
  '🎨', '🛒', '☕', '🧹', '🎯',
];
