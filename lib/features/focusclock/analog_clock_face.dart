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
    this.hoverMinute,
    this.outerReveal = 0,
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

  /// 0..1 — clock grows and the outer minute ring (5,10…60) fades in.
  /// Toggled by tapping the rim.
  final double outerReveal;

  final int? hoverMinute;

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
          outerReveal: outerReveal,
          tasks: tasks,
          hoverMinute: hoverMinute,
        ),
      );
}

/// Geometry scale shared with hit-testing: clock occupies 92% at rest,
/// grows to 98% when the minute ring is revealed.
double clockGrowFactor(double outerReveal) => 0.87 + 0.13 * outerReveal;

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
    this.outerReveal = 0,
    this.tasks = const [],
    this.hoverMinute,
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
  final int? hoverMinute;
  final double outerReveal;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rBase = math.min(size.width, size.height) / 2;
    final r = rBase * clockGrowFactor(outerReveal);
    final outerRadius = r * 0.95;
    final arcInner = r * 0.55;
    final arcOuter = r * 0.85;

    // Aura — soft glow when clock is in normal (non-expanded) state
    final aura = (1.0 - outerReveal).clamp(0.0, 1.0);
    if (aura > 0.01) {
      canvas.drawCircle(
        center,
        outerRadius + 14,
        Paint()
          ..color = AppPalette.accent.withValues(alpha: 0.06 * aura)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 22 * aura),
      );
      canvas.drawCircle(
        center,
        outerRadius + 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * aura
          ..color = AppPalette.accent.withValues(alpha: 0.09 * aura)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * aura),
      );
    }

    // Face Drop shadow
    canvas.drawCircle(
      center,
      outerRadius - 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    // Face
    canvas.drawCircle(
        center, outerRadius, Paint()..color = AppPalette.card.withValues(alpha: 0.75));

    // 5-min grid lines in arc band
    _drawGridLines(canvas, center, arcInner, arcOuter);

    // Activity arcs
    for (final a in activities) {
      _drawArc(canvas, center, arcInner, arcOuter, a.startMinute, a.endMinute,
          Color(a.colorValue),
          label: a.title, icon: a.iconKey);
    }
    
    // Task arcs (inside activities)
    final taskInner = r * 0.42;
    final taskOuter = r * 0.52;
    for (final t in tasks) {
      if (t.startMinute != null && t.endMinute != null) {
        final pCv = activities.where((a) => a.id == t.activityId).firstOrNull?.colorValue;
        final pC = pCv != null ? Color(pCv) : AppPalette.accent;
        _drawArc(canvas, center, taskInner, taskOuter, t.startMinute!, t.endMinute!,
            pC.withValues(alpha: 0.95),
            label: t.title);
      }
    }

    // Ghost Line & Knob
    if (hoverMinute != null) {
      final angle = (hoverMinute! / 720) * 2 * math.pi - math.pi / 2;
      final knobRadius = r * 1.08;
      
      // Draw ghost line
      canvas.drawLine(
        center, 
        Offset(center.dx + math.cos(angle) * outerRadius, center.dy + math.sin(angle) * outerRadius),
        Paint()
          ..color = AppPalette.accent.withValues(alpha: 0.6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
      );

      // Draw knob outside the clock
      final knobCenter = Offset(center.dx + math.cos(angle) * knobRadius, center.dy + math.sin(angle) * knobRadius);
      canvas.drawCircle(knobCenter, 10, Paint()..color = AppPalette.accent);
      canvas.drawCircle(knobCenter, 4, Paint()..color = AppPalette.bg);
    }

    // Pulse ring on the activity happening right now
    if (halfOfNow(now) == viewHalf) {
      final m = minuteOfHalf(now);
      for (final a in activities) {
        if (m >= a.startMinute && m < a.endMinute) {
          _drawPulseRing(canvas, center, arcOuter, a);
          break;
        }
      }
    }

    if (previewStart != null && previewEnd != null) {
      final base = previewConflict
          ? AppPalette.danger
          : (previewColor ?? AppPalette.accent);
      final endInHalf = math.min(previewEnd!, 720);
      _drawArc(canvas, center, arcInner, arcOuter, previewStart!, endInHalf,
          base.withValues(alpha: 0.55),
          dashed: true);
      // Span continues past 12 into the next half — hint it dimmer
      if (previewEnd! > 720) {
        _drawArc(canvas, center, arcInner, arcOuter, 0, previewEnd! - 720,
            base.withValues(alpha: 0.28),
            dashed: true);
      }
    }

    // Tick marks — every 5 minutes (144 ticks for 720-min clock)
    // Refined for Apple-like seamless aesthetic
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (int m = 0; m < 720; m += 5) {
      final angle = (m / 720) * 2 * math.pi - math.pi / 2;
      final isHour = m % 60 == 0;
      final is30 = m % 30 == 0;
      final is15 = m % 15 == 0;
      
      final tickLen = isHour ? 14.0 : is30 ? 10.0 : is15 ? 7.0 : 4.0;
      final sw = isHour ? 2.5 : is30 ? 1.8 : is15 ? 1.2 : 0.8;
      final opacity = isHour ? 0.9 : is30 ? 0.6 : is15 ? 0.4 : 0.25;
      
      final s = Offset(
        center.dx + math.cos(angle) * (outerRadius - 2 - tickLen),
        center.dy + math.sin(angle) * (outerRadius - 2 - tickLen),
      );
      final e = Offset(
        center.dx + math.cos(angle) * (outerRadius - 2),
        center.dy + math.sin(angle) * (outerRadius - 2),
      );
      canvas.drawLine(s, e,
          tickPaint
            ..color = AppPalette.text.withValues(alpha: opacity)
            ..strokeWidth = sw);
    }

    // Hour numbers — 24h dial shows 13–23 on PM half, 0–11 on AM
    for (int h = 1; h <= 12; h++) {
      final angle = (h / 12) * 2 * math.pi - math.pi / 2;
      final pos = Offset(
        center.dx + math.cos(angle) * (outerRadius - 38),
        center.dy + math.sin(angle) * (outerRadius - 38),
      );
      final String label;
      if (is24h && viewHalf == AmPmHalf.pm) {
        label = h == 12 ? '12' : '${h + 12}';
      } else if (is24h && viewHalf == AmPmHalf.am) {
        label = h == 12 ? '0' : '$h';
      } else {
        label = '$h';
      }
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
              color: AppPalette.text, 
              fontSize: 19, 
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Outer minute ring (5, 10... 55) shown OUTSIDE the dial.
    // 60 minutes = 360 degrees.
    if (outerReveal > 0.01) {
      final ringR = r * 1.045; // slightly outside the dial
      for (int m = 5; m <= 60; m += 5) {
        if (m == 60) continue; // Skip 60/12 top to avoid clash with pulse
        final angle = (m / 60) * 2 * math.pi - math.pi / 2;
        final pos = Offset(
          center.dx + math.cos(angle) * ringR,
          center.dy + math.sin(angle) * ringR,
        );
        final isQuarter = m % 15 == 0;
        final tp = TextPainter(
          text: TextSpan(
            text: '$m',
            style: TextStyle(
              color: AppPalette.accent.withValues(
                  alpha: outerReveal * (isQuarter ? 0.95 : 0.55)),
              fontSize: isQuarter ? 10.0 : 8.0,
              fontWeight: isQuarter ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Hands only if viewing current half
    if (halfOfNow(now) == viewHalf) {
      _drawHands(canvas, center, r);
    }

    // Elegant center pin
    canvas.drawCircle(center, 6.5, Paint()..color = AppPalette.text);
    canvas.drawCircle(center, 2.5, Paint()..color = AppPalette.accent);
  }

  /// Soft breathing glow just outside the current activity's arc.
  void _drawPulseRing(
      Canvas canvas, Offset center, double arcOuter, Activity a) {
    // Smooth in-out wave from linear 0..1 phase
    final wave = 0.5 - 0.5 * math.cos(pulse * 2 * math.pi);
    final startAngle = (a.startMinute / 720) * 2 * math.pi - math.pi / 2;
    final sweep = ((a.endMinute - a.startMinute) / 720) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcOuter + 4),
      startAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 + 1.5 * wave
        ..strokeCap = StrokeCap.round
        ..color = Color(a.colorValue).withValues(alpha: 0.30 + 0.45 * wave),
    );
  }

  void _drawGridLines(Canvas canvas, Offset center, double inner, double outer) {
    final paint = Paint()
      ..color = AppPalette.stroke.withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 144; i++) {
      if (i % 12 == 0) continue; // hour marks already have tick
      final angle = (i / 144) * 2 * math.pi - math.pi / 2;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * inner,
            center.dy + math.sin(angle) * inner),
        Offset(center.dx + math.cos(angle) * outer,
            center.dy + math.sin(angle) * outer),
        paint,
      );
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
    final startAngle = (startMin / 720) * 2 * math.pi - math.pi / 2;
    final sweep = ((endMin - startMin) / 720) * 2 * math.pi;
    final path = Path()
      ..arcTo(Rect.fromCircle(center: center, radius: outer), startAngle, sweep, true)
      ..arcTo(Rect.fromCircle(center: center, radius: inner), startAngle + sweep,
          -sweep, false)
      ..close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dashed ? 2 : 1
        ..color = Colors.black.withValues(alpha: 0.25),
    );

    if (sweep > 0.18) {
      final midAngle = startAngle + sweep / 2;
      final midR = (inner + outer) / 2;
      final pos = Offset(
        center.dx + math.cos(midAngle) * midR,
        center.dy + math.sin(midAngle) * midR,
      );

      if (icon != null && icon.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(text: icon, style: TextStyle(fontSize: sweep > 0.5 ? 16 : 11)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
        if (label != null && label.isNotEmpty && sweep > 0.45) {
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
      } else if (label != null && label.isNotEmpty && sweep > 0.25) {
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

  void _drawHands(Canvas canvas, Offset center, double r) {
    switch (clockHandsMode) {
      case 1:
        // Single precision: 1 full revolution per 12h
        final angle = (minuteOfHalf(now) / 720) * 2 * math.pi - math.pi / 2;
        _hand(canvas, center, angle, r * 0.72, 3, AppPalette.accent);
      case 2:
        final hAngle =
            ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2;
        final mAngle = (now.minute / 60) * 2 * math.pi - math.pi / 2;
        _hand(canvas, center, hAngle, r * 0.45, 6, AppPalette.text);
        _hand(canvas, center, mAngle, r * 0.65, 4, AppPalette.text);
      default: // 3
        final hAngle =
            ((now.hour % 12 + now.minute / 60) / 12) * 2 * math.pi - math.pi / 2;
        final mAngle = (now.minute / 60) * 2 * math.pi - math.pi / 2;
        final sAngle = (now.second / 60) * 2 * math.pi - math.pi / 2;
        _hand(canvas, center, hAngle, r * 0.45, 6, AppPalette.text);
        _hand(canvas, center, mAngle, r * 0.65, 4, AppPalette.text);
        _hand(canvas, center, sAngle, r * 0.75, 2, AppPalette.accent);
    }
  }

  void _hand(Canvas canvas, Offset center, double angle, double len,
      double width, Color color) {
    final end = Offset(center.dx + math.cos(angle) * len, center.dy + math.sin(angle) * len);
    
    // Hand drop shadow
    canvas.drawLine(
      center,
      Offset(end.dx + 1.5, end.dy + 3),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Elegant gradient hand
    final paint = Paint()
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        center,
        end,
        [color.withValues(alpha: 0.5), color],
        [0.0, 1.0],
      );
    canvas.drawLine(center, end, paint);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.now != now ||
      old.activities != activities ||
      old.viewHalf != viewHalf ||
      old.previewStart != previewStart ||
      old.previewEnd != previewEnd ||
      old.previewConflict != previewConflict ||
      old.pulse != pulse ||
      old.clockHandsMode != clockHandsMode ||
      old.is24h != is24h ||
      old.outerReveal != outerReveal;
}
