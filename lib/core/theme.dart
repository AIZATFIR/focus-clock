import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  // Dark
  static const bg = Color(0xFF1E1E1E);
  static const card = Color(0xFF2D2D2D);
  static const accent = Color(0xFFE6B800); // muted gold
  static const text = Color(0xFFE0E0E0);
  static const textDim = Color(0xFF9A9A9A);
  static const stroke = Color(0xFF2A2A2A);
  static const danger = Color(0xFFE5484D); // conflict / destructive
  static const glassSurface = Color(0xD91A1A1A); // 85% opacity, frosted sheets

  // True black (AMOLED)
  static const blackBg = Color(0xFF000000);
  static const blackCard = Color(0xFF141414);

  // Light equivalents (used inline in buildLightTheme)
  static const lightBg = Color(0xFFF5F5F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF1A1A1A);
  static const lightTextDim = Color(0xFF757575);
  static const lightStroke = Color(0xFFE8E8E8);
  static const lightAccent = Color(0xFFD4A800); // darker gold for light bg
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
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
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppPalette.card,
      indicatorColor: AppPalette.accent.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? AppPalette.accent
              : AppPalette.textDim,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppPalette.accent
              : AppPalette.textDim,
        ),
      ),
    ),
  );
}

/// AMOLED variant: true black background, deep cards.
ThemeData buildBlackTheme() {
  final base = buildDarkTheme();
  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.blackBg,
    colorScheme: base.colorScheme.copyWith(surface: AppPalette.blackBg),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: AppPalette.blackBg,
    ),
    cardColor: AppPalette.blackCard,
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: AppPalette.blackCard,
    ),
  );
}

ThemeData buildLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
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
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppPalette.lightCard,
      indicatorColor: AppPalette.lightAccent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? AppPalette.lightAccent
              : AppPalette.lightTextDim,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppPalette.lightAccent
              : AppPalette.lightTextDim,
        ),
      ),
    ),
  );
}

const presetColors = <int>[
  // Reds
  0xFFFFCDD2, 0xFFE57373, 0xFFF44336, 0xFFD32F2F, 0xFFB71C1C,
  // Pinks
  0xFFF8BBD0, 0xFFF06292, 0xFFE91E63, 0xFFC2185B, 0xFF880E4F,
  // Purples
  0xFFE1BEE7, 0xFFBA68C8, 0xFF9C27B0, 0xFF7B1FA2, 0xFF4A148C,
  // Deep Purples
  0xFFD1C4E9, 0xFF9575CD, 0xFF673AB7, 0xFF512DA8, 0xFF311B92,
  // Indigos
  0xFFC5CAE9, 0xFF7986CB, 0xFF3F51B5, 0xFF303F9F, 0xFF1A237E,
  // Blues
  0xFFBBDEFB, 0xFF64B5F6, 0xFF2196F3, 0xFF1976D2, 0xFF0D47A1,
  // Light Blues
  0xFFB3E5FC, 0xFF4FC3F7, 0xFF03A9F4, 0xFF0288D1, 0xFF01579B,
  // Cyans
  0xFFB2EBF2, 0xFF4DD0E1, 0xFF00BCD4, 0xFF0097A7, 0xFF006064,
  // Teals
  0xFFB2DFDB, 0xFF4DB6AC, 0xFF009688, 0xFF00796B, 0xFF004D40,
  // Greens
  0xFFC8E6C9, 0xFF81C784, 0xFF4CAF50, 0xFF388E3C, 0xFF1B5E20,
  // Light Greens
  0xFFDCEDC8, 0xFFAED581, 0xFF8BC34A, 0xFF689F38, 0xFF33691E,
  // Limes
  0xFFF0F4C3, 0xFFDCE775, 0xFFCDDC39, 0xFFAFB42B, 0xFF827717,
  // Yellows
  0xFFFFF9C4, 0xFFFFF176, 0xFFFFEB3B, 0xFFFBC02D, 0xFFF57F17,
  // Ambers
  0xFFFFECB3, 0xFFFFD54F, 0xFFFFC107, 0xFFFFA000, 0xFFFF6F00,
  // Oranges
  0xFFFFE0B2, 0xFFFFB74D, 0xFFFF9800, 0xFFF57C00, 0xFFE65100,
  // Deep Oranges
  0xFFFFCCBC, 0xFFFF8A65, 0xFFFF5722, 0xFFE64A19, 0xFFBF360C,
  // Browns
  0xFFD7CCC8, 0xFFA1887F, 0xFF795548, 0xFF5D4037, 0xFF3E2723,
  // Blue Greys
  0xFFCFD8DC, 0xFF90A4AE, 0xFF607D8B, 0xFF455A64, 0xFF263238,
];

const presetIcons = <String>[
  '🏃', '💻', '😴', '🍽️', '📚',
  '🏋️', '🎮', '🎵', '🏠', '💆',
  '✍️', '🚗', '🤝', '📞', '🧘',
  '🎨', '🛒', '☕', '🧹', '🎯',
];
