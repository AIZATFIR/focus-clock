import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppPalette — Obsidian Warm Bookpaper Aesthetic Design System
class AppPalette {
  // Dark Obsidian & Warm Bookpaper Tones
  static const bg = Color(0xFF18181F);
  static const card = Color(0xFF23222B);
  static const accent = Color(0xFFF0C987); // Warm Bookpaper Amber Gold
  static const text = Color(0xFFF5EBE6); // Warm Cream Text
  static const textDim = Color(0xFFA69F95); // Muted Warm Slate
  static const stroke = Color(0xFF363340); // Soft Obsidian Border
  static const danger = Color(0xFFE5484D); // Conflict / Destructive

  // Bookpaper Journaling Environment Tokens
  static const bookpaperFieldBg = Color(0xFF2B2933);
  static const bookpaperBorder = Color(0xFF403C4B);
  static const bookpaperText = Color(0xFFF4E8D1);

  // Glassmorphism & Gemini design tokens
  static const glassSurface = Color(0xF21C1B24); // Frosted Warm Slate
  static const geminiGlassBg = Color(0xE6201F29); // Frosted Obsidian Container
  static const geminiGlassBorder = Color(0x33F0C987); // Soft Gold Frosted Stroke
  static const geminiGlow = Color(0x40F0C987); // Ambient warm gold glow

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  // True black (AMOLED)
  static const blackBg = Color(0xFF0C0C0F);
  static const blackCard = Color(0xFF16151A);

  // Light equivalents
  static const lightBg = Color(0xFFF7F3EB); // Soft Sepia Cream Paper
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF2B2823);
  static const lightTextDim = Color(0xFF7A746B);
  static const lightStroke = Color(0xFFE6DFC9);
  static const lightAccent = Color(0xFFD49A35);
}

class GeminiMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  static const Curve springCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
}

ThemeData buildDarkTheme([String palette = 'executive']) {
  // Default to Obsidian Warm Bookpaper Theme
  Color bg = AppPalette.bg;
  Color card = AppPalette.card;
  Color accent = AppPalette.accent;
  Color stroke = AppPalette.stroke;

  if (palette == 'sage') {
    bg = const Color(0xFF131A17);
    card = const Color(0xFF1C2723);
    accent = const Color(0xFF4EAA86);
    stroke = const Color(0xFF273831);
  } else if (palette == 'sepia' || palette == 'bookpaper') {
    bg = const Color(0xFF181714);
    card = const Color(0xFF25211C);
    accent = const Color(0xFFF0C987);
    stroke = const Color(0xFF383127);
  } else if (palette == 'cream') {
    bg = const Color(0xFF17181F);
    card = const Color(0xFF222430);
    accent = const Color(0xFF8C9EFF);
    stroke = const Color(0xFF2E3244);
  }

  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    scaffoldBackgroundColor: bg,
    colorScheme: base.colorScheme.copyWith(
      surface: bg,
      primary: accent,
      secondary: accent,
      onSurface: AppPalette.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: AppPalette.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: card,
    dividerColor: stroke,
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: AppPalette.text,
      displayColor: AppPalette.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.bookpaperFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.bookpaperBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.bookpaperBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppPalette.textDim, fontSize: 14),
      labelStyle: const TextStyle(color: AppPalette.textDim, fontSize: 13),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: accent,
      unselectedItemColor: AppPalette.textDim,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: card,
      contentTextStyle: const TextStyle(color: AppPalette.text),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: accent.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? accent
              : AppPalette.textDim,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? accent
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
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.lightStroke),
      ),
      labelStyle: const TextStyle(color: AppPalette.lightTextDim),
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
  0xFFF44336, // Red
  0xFFE64A19, // Deep Orange
  0xFFFF9800, // Orange
  0xFFFFC107, // Amber
  0xFFFFEB3B, // Yellow
  0xFFCDDC39, // Lime
  0xFF8BC34A, // Light Green
  0xFF4CAF50, // Green
  0xFF009688, // Teal
  0xFF00BCD4, // Cyan
  0xFF03A9F4, // Light Blue
  0xFF2196F3, // Blue
  0xFF3F51B5, // Indigo
  0xFF673AB7, // Deep Purple
  0xFF9C27B0, // Purple
  0xFFE91E63, // Pink
  0xFF795548, // Brown
];

const presetIcons = <String>[
  '🏃', '💻', '😴', '🍽️', '📚',
  '🏋️', '🎮', '🎵', '🏠', '💆',
  '✍️', '🚗', '🤝', '📞', '🧘',
  '🎨', '🛒', '☕', '🧹', '🎯',
];
