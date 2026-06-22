import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../models/task.dart';

class AnalogClockFace extends StatelessWidget {
  const AnalogClockFace({
    super.key,
    required this.now,
    required this.activities,
    this.tasks = const [],
    required this.viewHalf,
    this.previewStartMinute,
    this.previewEndMinute,
    this.previewColor,
    this.previewConflict = false,
    this.pulse = 0,
    this.clockHandsMode = 1,
    this.is24h = false,
    this.isToday = true,
    this.hoverMinute,
    this.outerReveal = 0,
    this.isPrecisionMode = false,
    this.aimLockProgress = 1.0,
    this.isPlanning = false,
    this.hoveredCompassIndex,
    this.activeCompassIndex,
    this.clockFaceTheme = 1,
  });

  final DateTime now;
  final List<Activity> activities;
  final List<Task> tasks;
  final AmPmHalf viewHalf;
  final int? previewStartMinute;
  final int? previewEndMinute;
  final Color? previewColor;

  /// Preview arc overlaps an existing activity — render it red.
  final bool previewConflict;

  /// 0..1 phase for the "now" pulse ring around the current activity.
  final double pulse;

  final int clockHandsMode;

  /// 24h dial: PM half shows 13–23 (12 at top), AM shows 0–11.
  final bool is24h;

  final bool isToday;

  /// 0..1 — clock grows and the outer minute ring (5,10…60) fades in.
  /// Toggled by tapping the rim.
  final double outerReveal;

  final int? hoveredCompassIndex;
  final int? activeCompassIndex;
  final int? hoverMinute;
  final bool isPrecisionMode;
  final double aimLockProgress;
  final bool isPlanning;
  final int clockFaceTheme;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _ClockPainter(
          now: now,
          activities: activities,
          viewHalf: viewHalf,
          previewStart: previewStartMinute,
          previewEnd: previewEndMinute,
          previewColor: previewColor,
          previewConflict: previewConflict,
          pulse: pulse,
          clockHandsMode: clockHandsMode,
          is24h: is24h,
          isToday: isToday,
          outerReveal: outerReveal,
          tasks: tasks,
          hoverMinute: hoverMinute,
          isPrecisionMode: isPrecisionMode,
          aimLockProgress: aimLockProgress,
          isPlanning: isPlanning,
          clockFaceTheme: clockFaceTheme,
        ),
      );
}

/// Geometry scale shared with hit-testing: clock occupies more space in planning mode.
double clockGrowFactor(double outerReveal, bool isPlanning) =>
    isPlanning ? (0.92 + 0.06 * outerReveal) : (0.88 + 0.08 * outerReveal);

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.now,
    required this.activities,
    required this.viewHalf,
    this.previewStart,
    this.previewEnd,
    this.previewColor,
    this.previewConflict = false,
    this.pulse = 0,
    this.clockHandsMode = 1,
    this.is24h = false,
    this.isToday = true,
    this.outerReveal = 0,
    this.tasks = const [],
    this.hoverMinute,
    this.isPrecisionMode = false,
    this.aimLockProgress = 1.0,
    this.isPlanning = false,
    this.clockFaceTheme = 1,
  });

  final DateTime now;
  final List<Activity> activities;
  final List<Task> tasks;
  final AmPmHalf viewHalf;
  final int? previewStart;
  final int? previewEnd;
  final Color? previewColor;
  final bool previewConflict;
  final double pulse;
  final int clockHandsMode;
  final bool is24h;
  final bool isToday;
  final int? hoverMinute;
  final double outerReveal;
  final bool isPrecisionMode;
  final double aimLockProgress;
  final bool isPlanning;
  final int clockFaceTheme;

  static final Map<String, TextPainter> _tpCache = {};

  TextPainter _getPainter(String text, double fontSize, FontWeight weight, Color color, {double? letterSpacing}) {
    final key = '${text}_${fontSize}_${weight.value}_${color.toARGB32()}_$letterSpacing';
    if (_tpCache.containsKey(key)) {
      return _tpCache[key]!;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _tpCache[key] = tp;
    return tp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rBase = math.min(size.width, size.height) / 2;
    final r = rBase * clockGrowFactor(outerReveal, isPlanning);
    final outerRadius = r * 0.96;
    final arcOuter = r * 0.86;
    final taskInner = r * 0.32;
    final taskOuter = r * 0.42;

    // Theme Color Configurations
    final int theme = clockFaceTheme;
    final Color themeAccentColor;
    final bool enableGlows = theme <= 4;

    switch (theme) {
      case 2: // Elegance (White-Glow)
        themeAccentColor = Colors.white;
        break;
      case 3: // Blue-Glow
        themeAccentColor = const Color(0xFF3399FF);
        break;
      case 4: // Purple-Glow
        themeAccentColor = const Color(0xFFBB86FC);
        break;
      case 5: // Simple Flat
        themeAccentColor = const Color(0xFFFFD54F);
        break;
      case 6: // Simple Classic
        themeAccentColor = const Color(0xFFFFD54F);
        break;
      case 1:
      default: // Default Yellow-Black
        themeAccentColor = AppPalette.accent; // Color(0xFFFFEE99)
        break;
    }

    // 1. Dual-layer soft shadow & glowing aura (disabled in Simple theme)
    if (enableGlows) {
      canvas.drawCircle(
        center,
        outerRadius + 22,
        Paint()
          ..color = themeAccentColor.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );

      canvas.drawCircle(
        center,
        outerRadius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    // 2. Bezel (Embossed 3D border - flatter in simple theme)
    if (enableGlows) {
      final bezelPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(center.dx - outerRadius, center.dy - outerRadius),
          Offset(center.dx + outerRadius, center.dy + outerRadius),
          [
            Colors.white.withValues(alpha: 0.20), // Light highlight top-left
            Colors.white.withValues(alpha: 0.02),
            Colors.black.withValues(alpha: 0.50), // Shadow bottom-right
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawCircle(center, outerRadius + 2, bezelPaint);
    } else {
      final double borderWidth = theme == 6 ? 2.0 : 1.5;
      final Color borderColor = theme == 6 ? AppPalette.stroke : AppPalette.stroke.withOpacity(0.5);
      canvas.drawCircle(
        center,
        outerRadius + (borderWidth / 2),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }

    // 3. Face with radial gradient (Obsidian look) or Flat color for Simple
    final Paint facePaint;
    if (enableGlows) {
      facePaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          outerRadius,
          [
            const Color(0xFF23252F), // Lighter center
            const Color(0xFF14151B), // Darker edge
          ],
          [0.0, 1.0],
        );
    } else {
      facePaint = Paint()..color = theme == 6 ? const Color(0xFF222222) : const Color(0xFF16171C);
    }
    canvas.drawCircle(center, outerRadius, facePaint);

    // 4. Inner bezel shadow (sunken / inset clock look)
    if (enableGlows) {
      canvas.drawCircle(
        center,
        outerRadius - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.black.withValues(alpha: 0.45),
      );
    }

    // 10-min grid lines in arc band (72 or 144 grid lines)
    _drawGridLines(canvas, center, taskInner, arcOuter);

    // Activity arcs
    for (final a in activities) {
      final start = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
      final end = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
      _drawArc(canvas, center, taskInner, arcOuter, start, end,
          Color(a.colorValue),
          label: a.title, icon: a.iconKey);
    }
    
    // Task arcs
    for (final t in tasks) {
      if (t.startMinute != null && t.endMinute != null) {
        final start = toUiMinute(t.startMinute!, t.ampmHalf, is24h: is24h);
        final end = toUiMinute(t.endMinute!, t.ampmHalf, is24h: is24h);
        final pCv = activities.where((a) => a.id == t.activityId).firstOrNull?.colorValue;
        final pC = pCv != null ? Color(pCv) : themeAccentColor;
        final taskColor = Color.lerp(pC, Colors.white, 0.45)!;
        _drawArc(canvas, center, taskInner, taskOuter, start, end,
            taskColor.withValues(alpha: 0.95),
            label: t.title);
      }
    }

    // Ghost Line
    if (hoverMinute != null && isPrecisionMode && theme <= 4) {
      final scale = is24h ? 1440 : 720;
      final angle = (hoverMinute! / scale) * 2 * math.pi - math.pi / 2;
      
      // Draw ghost line
      canvas.drawLine(
        center, 
        Offset(center.dx + math.cos(angle) * outerRadius, center.dy + math.sin(angle) * outerRadius),
        Paint()
          ..color = themeAccentColor.withValues(alpha: 0.25)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
      );
    }

    // Pulse ring on the activity happening right now
    if (isToday) {
      final m = is24h 
          ? (now.hour * 60 + now.minute)
          : ((now.hour % 12) * 60 + now.minute);
      for (final a in activities) {
        final start = toUiMinute(a.startMinute, a.ampmHalf, is24h: is24h);
        final end = toUiMinute(a.endMinute, a.ampmHalf, is24h: is24h);
        if (m >= start && m < end) {
          _drawPulseRing(canvas, center, arcOuter, start, end, Color(a.colorValue));
          break;
        }
      }
    }

    if (previewStart != null && previewEnd != null) {
      final base = previewConflict
          ? AppPalette.danger
          : (previewColor ?? themeAccentColor);
      final scale = is24h ? 1440 : 720;
      final endInClock = math.min(previewEnd!, scale);
      _drawArc(canvas, center, taskInner, arcOuter, previewStart!, endInClock,
          base.withValues(alpha: 0.55),
          dashed: true);
      // Span continues past midnight
      if (previewEnd! > scale) {
        _drawArc(canvas, center, taskInner, arcOuter, 0, previewEnd! - scale,
            base.withValues(alpha: 0.28),
            dashed: true);
      }
    }

    // Tick marks — every 5 minutes (for 12h) or 10 minutes (for 24h)
    final limit = is24h ? 1440 : 720;
    final step = is24h ? 10 : 5;
    for (int m = 0; m < limit; m += step) {
      final angle = (m / limit) * 2 * math.pi - math.pi / 2;
      final isHour = m % 60 == 0;
      final is30 = m % 30 == 0;
      final is15 = m % 15 == 0;
      
      final double tickLen;
      final double sw;
      final double opacity;
      if (is24h) {
        tickLen = isHour ? 15.0 : is30 ? 10.0 : 6.0;
        sw = isHour ? 3.0 : is30 ? 1.8 : 1.0;
        opacity = isHour ? 0.90 : is30 ? 0.65 : 0.35;
      } else {
        tickLen = isHour ? 14.0 : is30 ? 10.0 : is15 ? 7.0 : 4.0;
        sw = isHour ? 2.5 : is30 ? 1.8 : is15 ? 1.2 : 0.8;
        opacity = isHour ? 0.90 : is30 ? 0.60 : is15 ? 0.40 : 0.25;
      }
      
      final s = Offset(
        center.dx + math.cos(angle) * (outerRadius - tickLen),
        center.dy + math.sin(angle) * (outerRadius - tickLen),
      );
      final e = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );
      
      canvas.drawLine(
        s,
        e,
        Paint()
          ..color = AppPalette.text.withValues(alpha: opacity)
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }

    // Draw static 5-minute labels around the clock face
    final bool showHoverEffects = (hoverMinute != null && theme <= 4);
    for (int m = 5; m <= 60; m += 5) {
      final minVal = m == 60 ? 0 : m;
      
      bool isHovered = false;
      if (showHoverEffects) {
        final hoverMinVal = hoverMinute! % 60;
        if ((hoverMinVal - minVal).abs() <= 1 || (hoverMinVal - minVal).abs() >= 59) {
          isHovered = true;
        }
      }
      
      if (!isHovered) {
        final angle = (m / 60) * 2 * math.pi - math.pi / 2;
        final textRadius = outerRadius + 14;
        final pos = Offset(
          center.dx + math.cos(angle) * textRadius,
          center.dy + math.sin(angle) * textRadius,
        );
        
        final label = minVal.toString().padLeft(2, '0');
        final tp = _getPainter(
          label,
          9.0,
          FontWeight.w600,
          (theme >= 5) ? themeAccentColor.withOpacity(0.85) : Colors.white.withValues(alpha: 0.12),
        );
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Draw 1 precise minute label inside a premium glassmorphic capsule chip
    if (showHoverEffects) {
      final m = hoverMinute! % 60;
      final h = hoverMinute! ~/ 60;
      final String txt;
      if (is24h) {
        txt = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      } else {
        final displayHour = h == 0 ? 12 : h;
        final suffix = viewHalf == AmPmHalf.pm ? ' PM' : ' AM';
        txt = '${displayHour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}$suffix';
      }
      final angle = (hoverMinute! / (is24h ? 1440 : 720)) * 2 * math.pi - math.pi / 2;
      
      final textRadius = outerRadius + 22;
      final txtCenter = Offset(
        center.dx + math.cos(angle) * textRadius,
        center.dy + math.sin(angle) * textRadius,
      );
      
      // Spotlight glow behind the precision time
      if (enableGlows) {
        canvas.drawCircle(
          txtCenter,
          24,
          Paint()
            ..color = themeAccentColor.withValues(alpha: 0.27)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      
      final tp = _getPainter(txt, 11, FontWeight.w800, theme >= 5 ? Colors.black : Colors.white);
      final chipRect = Rect.fromCenter(center: txtCenter, width: tp.width + 14, height: tp.height + 8);
      final chipRRect = RRect.fromRectAndRadius(chipRect, const Radius.circular(8));
      
      // Paint capsule background
      canvas.drawRRect(
        chipRRect,
        Paint()..color = theme >= 5 ? themeAccentColor : Colors.black.withOpacity(0.80),
      );
      if (theme < 5) {
        canvas.drawRRect(
          chipRRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..color = themeAccentColor.withOpacity(0.35),
        );
      }
      
      tp.paint(canvas, Offset(txtCenter.dx - tp.width / 2, txtCenter.dy - tp.height / 2));
    }

    // Hour numbers — 12h dial shows 1..12 (or 0..11 if theme >= 5), 24h dial shows 0..23
    if (is24h) {
      for (int h = 0; h < 24; h++) {
        final angle = (h / 24) * 2 * math.pi - math.pi / 2;
        final pos = Offset(
          center.dx + math.cos(angle) * (outerRadius - 38),
          center.dy + math.sin(angle) * (outerRadius - 38),
        );
        final label = '$h';
        final tp = _getPainter(label, 11, FontWeight.w600, AppPalette.text, letterSpacing: -0.5);
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    } else {
      final bool useZeroToEleven = (theme == 5 || theme == 6);
      for (int h = 1; h <= 12; h++) {
        final angle = (h / 12) * 2 * math.pi - math.pi / 2;
        final pos = Offset(
          center.dx + math.cos(angle) * (outerRadius - 38),
          center.dy + math.sin(angle) * (outerRadius - 38),
        );
        final label = useZeroToEleven ? (h == 12 ? '0' : '$h') : '$h';
        final tp = _getPainter(label, 14, FontWeight.w600, AppPalette.text, letterSpacing: -0.5);
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Hands sweep only if today and viewed half matches actual time (or in 24h)
    if (isToday && (is24h || halfOfNow(now) == viewHalf)) {
      _drawHands(canvas, center, r, outerRadius, themeAccentColor, enableGlows);
    }

    // Elegant center pin
    if (theme == 6) {
      canvas.drawCircle(center, 6.5, Paint()..color = themeAccentColor);
      canvas.drawCircle(center, 4.5, Paint()..color = Colors.white);
    } else {
      canvas.drawCircle(center, 6.5, Paint()..color = AppPalette.text);
      canvas.drawCircle(center, 2.5, Paint()..color = themeAccentColor);
    }
  }

  /// Soft breathing glow just outside the current activity's arc.
  void _drawPulseRing(
      Canvas canvas, Offset center, double arcOuter, int startMin, int endMin, Color color) {
    final wave = 0.5 - 0.5 * math.cos(pulse * 2 * math.pi);
    final scale = is24h ? 1440 : 720;
    final startAngle = (startMin / scale) * 2 * math.pi - math.pi / 2;
    final sweep = ((endMin - startMin) / scale) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcOuter + 4),
      startAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 + 1.5 * wave
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.30 + 0.45 * wave),
    );
  }

  void _drawGridLines(Canvas canvas, Offset center, double inner, double outer) {
    final scale = is24h ? 1440 : 720;
    final paint = Paint()
      ..color = AppPalette.stroke.withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    for (int i = 0; i < scale / 10; i++) {
      final angle = (i / (scale / 10)) * 2 * math.pi - math.pi / 2;
      final s = Offset(
        center.dx + math.cos(angle) * inner,
        center.dy + math.sin(angle) * inner,
      );
      final e = Offset(
        center.dx + math.cos(angle) * outer,
        center.dy + math.sin(angle) * outer,
      );
      canvas.drawLine(s, e, paint);
    }
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    double inner,
    double outer,
    int startMin,
    int endMin,
    Color color, {
    String? label,
    String? icon,
    bool dashed = false,
  }) {
    if (endMin <= startMin) return;
    final scale = is24h ? 1440 : 720;
    final startAngle = (startMin / scale) * 2 * math.pi - math.pi / 2;
    final sweep = ((endMin - startMin) / scale) * 2 * math.pi;
    final path = Path()
      ..arcTo(Rect.fromCircle(center: center, radius: outer), startAngle, sweep, true)
      ..arcTo(Rect.fromCircle(center: center, radius: inner), startAngle + sweep,
          -sweep, false)
      ..close();

    final Paint paint;
    if (clockFaceTheme >= 5) {
      paint = Paint()..color = color..style = PaintingStyle.fill;
    } else {
      paint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          outer,
          [
            color,
            Color.lerp(color, Colors.black, 0.24)!,
          ],
          [inner / outer, 1.0],
        );
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dashed ? 2 : 1
        ..color = Colors.black.withValues(alpha: 0.35),
    );
    if (clockFaceTheme < 5) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = Colors.white.withValues(alpha: 0.15),
      );
    }

    if (sweep > 0.09) {
      final midAngle = startAngle + sweep / 2;
      double midR = (inner + outer) / 2;
      if (icon != null) {
        final r = outer / 0.86;
        final arcInner = r * 0.44;
        midR = (arcInner + outer) / 2;
      }
      final pos = Offset(
        center.dx + math.cos(midAngle) * midR,
        center.dy + math.sin(midAngle) * midR,
      );

      if (icon != null && icon.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(text: icon, style: TextStyle(fontSize: sweep > 0.25 ? 16 : 11)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
        if (label != null && label.isNotEmpty && sweep > 0.22) {
          final lp = TextPainter(
            text: TextSpan(
                text: label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: outer - inner - 4);
          lp.paint(canvas, Offset(pos.dx - lp.width / 2, pos.dy + tp.height / 2));
        }
      } else if (label != null && label.isNotEmpty && sweep > 0.12) {
        final tp = TextPainter(
          text: TextSpan(
              text: label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: outer - inner - 8);
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  void _drawHands(Canvas canvas, Offset center, double r, double outerRadius, Color accentColor, bool enableGlows) {
    final scale = is24h ? 1440.0 : 720.0;
    final totalMins = is24h 
        ? (now.hour * 60 + now.minute + now.second / 60.0)
        : ((now.hour % 12) * 60 + now.minute + now.second / 60.0);
    final pAngle = (totalMins / scale) * 2 * math.pi - math.pi / 2;

    final double precisionWidth = clockFaceTheme == 6 ? 2.0 : 3.5;
    final double hourWidth = clockFaceTheme == 6 ? 4.0 : 7.5;
    final double minuteWidth = clockFaceTheme == 6 ? 2.5 : 4.5;
    final bool showTooltip = clockFaceTheme != 6;

    switch (clockHandsMode) {
      case 1:
        // Single precision hand only
        _hand(canvas, center, pAngle, outerRadius, precisionWidth, accentColor, enableGlows);
        if (showTooltip) {
          _drawTimeTip(canvas, center, pAngle, outerRadius, accentColor, enableGlows);
        }
        break;
      case 2:
        // Hour + Minute hands, plus yellow/accent precision hand
        final hAngle = pAngle;
        final mAngle = ((now.minute + now.second / 60.0) / 60) * 2 * math.pi - math.pi / 2;
        _hand(canvas, center, hAngle, r * 0.50, hourWidth, AppPalette.text, enableGlows);
        _hand(canvas, center, mAngle, r * 0.75, minuteWidth, AppPalette.text, enableGlows);
        _hand(canvas, center, pAngle, outerRadius, precisionWidth, accentColor, enableGlows);
        if (showTooltip) {
          _drawTimeTip(canvas, center, pAngle, outerRadius, accentColor, enableGlows);
        }
        break;
      default: // 3
        // Hour + Minute + Second hands, plus yellow/accent precision hand
        final hAngle = pAngle;
        final mAngle = ((now.minute + now.second / 60.0) / 60) * 2 * math.pi - math.pi / 2;
        final sAngle = (now.second / 60.0) * 2 * math.pi - math.pi / 2;
        _hand(canvas, center, hAngle, r * 0.50, hourWidth, AppPalette.text, enableGlows);
        _hand(canvas, center, mAngle, r * 0.75, minuteWidth, AppPalette.text, enableGlows);
        _hand(canvas, center, sAngle, r * 0.82, 1.2, AppPalette.text.withValues(alpha: 0.5), enableGlows);
        
        // Draw the yellow/accent precision hand with the tooltip
        _hand(canvas, center, pAngle, outerRadius, precisionWidth, accentColor, enableGlows);
        if (showTooltip) {
          _drawTimeTip(canvas, center, pAngle, outerRadius, accentColor, enableGlows);
        }
        break;
    }
  }

  void _drawTimeTip(Canvas canvas, Offset center, double angle, double handLen, Color accentColor, bool enableGlows) {
    final tipOffset = Offset(
      center.dx + math.cos(angle) * (handLen + 28),
      center.dy + math.sin(angle) * (handLen + 28),
    );
    final String txt;
    if (is24h) {
      final hourStr = now.hour.toString().padLeft(2, '0');
      final minStr = now.minute.toString().padLeft(2, '0');
      final secStr = now.second.toString().padLeft(2, '0');
      txt = '$hourStr:$minStr:$secStr';
    } else {
      final h12 = now.hour % 12;
      final displayHour = h12 == 0 ? 12 : h12;
      final hourStr = displayHour.toString().padLeft(2, '0');
      final minStr = now.minute.toString().padLeft(2, '0');
      final secStr = now.second.toString().padLeft(2, '0');
      final suffix = now.hour < 12 ? ' AM' : ' PM';
      txt = '$hourStr:$minStr:$secStr$suffix';
    }
    
    // Spotlight glow behind the current time (further outside the dial)
    if (enableGlows) {
      canvas.drawCircle(
        tipOffset,
        24,
        Paint()
          ..color = accentColor.withValues(alpha: 0.27)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    
    final tp = _getPainter(txt, 11, FontWeight.w800, clockFaceTheme >= 5 ? Colors.black : Colors.white);
    final chipRect = Rect.fromCenter(center: tipOffset, width: tp.width + 16, height: tp.height + 8);
    final chipRRect = RRect.fromRectAndRadius(chipRect, const Radius.circular(8));
    
    // Paint capsule background
    canvas.drawRRect(
      chipRRect,
      Paint()..color = clockFaceTheme >= 5 ? accentColor : Colors.black.withOpacity(0.80),
    );
    if (clockFaceTheme < 5) {
      canvas.drawRRect(
        chipRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = accentColor.withOpacity(0.35),
      );
    }
    
    tp.paint(canvas, Offset(tipOffset.dx - tp.width / 2, tipOffset.dy - tp.height / 2));
  }

  void _hand(Canvas canvas, Offset center, double angle, double len,
      double width, Color color, bool enableGlows) {
    final end = Offset(center.dx + math.cos(angle) * len, center.dy + math.sin(angle) * len);
    
    // Hand drop shadow
    if (enableGlows) {
      canvas.drawLine(
        center,
        Offset(end.dx + 1.5, end.dy + 3),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Elegant hand paint
    final Paint paint;
    if (enableGlows) {
      paint = Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          center,
          end,
          [color.withValues(alpha: 0.5), color],
          [0.0, 1.0],
        );
    } else {
      paint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
    }
    canvas.drawLine(center, end, paint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.now != now ||
      old.activities != activities ||
      old.tasks != tasks ||
      old.viewHalf != viewHalf ||
      old.previewStart != previewStart ||
      old.previewEnd != previewEnd ||
      old.previewConflict != previewConflict ||
      old.pulse != pulse ||
      old.clockHandsMode != clockHandsMode ||
      old.is24h != is24h ||
      old.outerReveal != outerReveal ||
      old.hoverMinute != hoverMinute ||
      old.clockFaceTheme != clockFaceTheme ||
      old.isPrecisionMode != isPrecisionMode;
}
