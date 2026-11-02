import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppPalette — Obsidian Warm Bookpaper & Apple Design System
class AppPalette {
  // Dark Obsidian & Warm Bookpaper Tones
  static const bg = Color(0xFF18181F);
  static const card = Color(0xFF202028);
  static const accent = Color(0xFFF0C987); // Warm Bookpaper Amber Gold
  static const text = Color(0xFFF5EBE6); // Warm Cream Text
  static const textDim = Color(0xFFA69F95); // Muted Warm Slate
  static const stroke = Color(0xFF32303C); // Soft Obsidian Border
  static const danger = Color(0xFFE5484D); // Conflict / Destructive

  // Bookpaper Journaling Environment Tokens
  static const bookpaperFieldBg = Color(0xFF2B2933);
  static const bookpaperBorder = Color(0xFF403C4B);
  static const bookpaperText = Color(0xFFF4E8D1);

  // Apple Frosted Glass Tokens
  static const appleGlassSurface = Color(0xD91C1C24); // Frosted Dark Glass Surface
  static const appleGlassBg = Color(0xB3181820); // Translucent Dark Container
  static const appleGlassBorder = Color(0x1FFFFFFF); // 0.5px Delicate Light Stroke
  static const appleGlassBorderSubtle = Color(0x0FFFFFFF); // 0.5px Extra Subtle Stroke
  static const double appleGlassBlur = 20.0;
  static const double appleSquircleRadius = 22.0;

  // Glassmorphism & Gemini design tokens (backward compatibility)
  static const glassSurface = Color(0xD91C1C24); // Frosted Slate
  static const geminiGlassBg = Color(0xB3181820); // Frosted Obsidian Container
  static const geminiGlassBorder = Color(0x1FFFFFFF); // Soft Frosted Stroke
  static const geminiGlow = Color(0x33F0C987); // Ambient warm gold glow

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  // True black (AMOLED)
  static const blackBg = Color(0xFF0C0C0F);
  static const blackCard = Color(0xFF141418);

  // Light equivalents
  static const lightBg = Color(0xFFF7F3EB); // Soft Sepia Cream Paper
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF2B2823);
  static const lightTextDim = Color(0xFF7A746B);
  static const lightStroke = Color(0xFFE6DFC9);
  static const lightAccent = Color(0xFFD49A35);
}

class GeminiMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve springCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
}

/// Apple-grade frosted glass container with BackdropFilter and ultra-delicate 0.5px border
class AppleGlassSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blur;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const AppleGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = AppPalette.appleSquircleRadius,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.5,
    this.blur = AppPalette.appleGlassBlur,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppPalette.appleGlassSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppPalette.appleGlassBorder,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (shadows != null && shadows!.isNotEmpty) {
      content = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
        ),
        child: content,
      );
    } else if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return ApplePressable(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Instant touch feedback with tactile haptics & fluid spring physics
class ApplePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;
  final HitTestBehavior behavior;

  const ApplePressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 140),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<ApplePressable> createState() => _ApplePressableState();
}

class _ApplePressableState extends State<ApplePressable> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = true);
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
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
  } else if (palette == 'full_book' || palette == 'bookpaper' || palette == 'sepia') {
    bg = const Color(0xFF1B1916);
    card = const Color(0xFF26231E);
    accent = const Color(0xFFE2BE82);
    stroke = const Color(0xFF3B352D);
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
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: const TextStyle(letterSpacing: -1.0, fontWeight: FontWeight.w700),
      displayMedium: const TextStyle(letterSpacing: -0.8, fontWeight: FontWeight.w700),
      displaySmall: const TextStyle(letterSpacing: -0.6, fontWeight: FontWeight.w600),
      headlineLarge: const TextStyle(letterSpacing: -0.6, fontWeight: FontWeight.w600),
      headlineMedium: const TextStyle(letterSpacing: -0.5, fontWeight: FontWeight.w600),
      headlineSmall: const TextStyle(letterSpacing: -0.4, fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(letterSpacing: -0.3, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(letterSpacing: -0.2, fontWeight: FontWeight.w600),
      titleSmall: const TextStyle(letterSpacing: -0.1, fontWeight: FontWeight.w500),
      bodyLarge: const TextStyle(letterSpacing: -0.15, fontWeight: FontWeight.w400),
      bodyMedium: const TextStyle(letterSpacing: -0.1, fontWeight: FontWeight.w400),
      bodySmall: const TextStyle(letterSpacing: 0.0, fontWeight: FontWeight.w400),
      labelLarge: const TextStyle(letterSpacing: -0.1, fontWeight: FontWeight.w600),
    ).apply(
      bodyColor: AppPalette.text,
      displayColor: AppPalette.text,
    ),
    cardTheme: CardTheme(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppPalette.appleGlassBorder, width: 0.5),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppPalette.appleGlassBorder, width: 0.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.bookpaperFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.appleGlassBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.appleGlassBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.accent, width: 1.2),
      ),
      hintStyle: const TextStyle(color: AppPalette.textDim, fontSize: 13, letterSpacing: -0.1),
      labelStyle: const TextStyle(color: AppPalette.textDim, fontSize: 13, letterSpacing: -0.1),
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
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: const TextStyle(letterSpacing: -1.0, fontWeight: FontWeight.w700),
      displayMedium: const TextStyle(letterSpacing: -0.8, fontWeight: FontWeight.w700),
      displaySmall: const TextStyle(letterSpacing: -0.6, fontWeight: FontWeight.w600),
      headlineLarge: const TextStyle(letterSpacing: -0.6, fontWeight: FontWeight.w600),
      headlineMedium: const TextStyle(letterSpacing: -0.5, fontWeight: FontWeight.w600),
      headlineSmall: const TextStyle(letterSpacing: -0.4, fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(letterSpacing: -0.3, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(letterSpacing: -0.2, fontWeight: FontWeight.w600),
      titleSmall: const TextStyle(letterSpacing: -0.1, fontWeight: FontWeight.w500),
      bodyLarge: const TextStyle(letterSpacing: -0.15, fontWeight: FontWeight.w400),
      bodyMedium: const TextStyle(letterSpacing: -0.1, fontWeight: FontWeight.w400),
      bodySmall: const TextStyle(letterSpacing: 0.0, fontWeight: FontWeight.w400),
      labelLarge: const TextStyle(letterSpacing: -0.1, fontWeight: FontWeight.w600),
    ).apply(
      bodyColor: AppPalette.lightText,
      displayColor: AppPalette.lightText,
    ),
    cardTheme: CardTheme(
      color: AppPalette.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppPalette.lightStroke, width: 0.5),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppPalette.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppPalette.lightStroke, width: 0.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.lightStroke, width: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.lightStroke, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.lightStroke, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.lightAccent, width: 1.2),
      ),
      hintStyle: const TextStyle(color: AppPalette.lightTextDim, fontSize: 13, letterSpacing: -0.1),
      labelStyle: const TextStyle(color: AppPalette.lightTextDim, fontSize: 13, letterSpacing: -0.1),
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

/// Full Book / Warm Journal theme with gentle paper aesthetic
ThemeData buildFullBookTheme() {
  return buildDarkTheme('full_book');
}

/// Pastel Book Palette — Eye-Friendly & Relaxing Muted Tones
const pastelBookColors = <int>[
  0xFF8DA399, // Muted Sage Green
  0xFFC89F98, // Dusty Rose
  0xFF9CAAC6, // Soft Periwinkle
  0xFFD6BE93, // Warm Ochre
  0xFFB2A3C4, // Soft Lavender
  0xFFA8B896, // Matcha Tea
  0xFFCFA085, // Soft Terracotta
  0xFF8DB8B2, // Dusty Teal
  0xFFD4B28C, // Muted Sand
  0xFFA69C90, // Warm Slate
];

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
