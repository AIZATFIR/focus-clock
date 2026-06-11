import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';

class AnalogClockFace extends StatelessWidget {
  const AnalogClockFace({
    super.key,
    required this.now,
    required this.activities,
    required this.viewHalf,
    this.previewStartMinute,
    this.previewEndMinute,
    this.previewColor,
    this.clockHandsMode = 1,
    this.showMinuteLabels = false,
  });

  final DateTime now;
  final List<Activity> activities;
  final AmPmHalf viewHalf;
  final int? previewStartMinute;
  final int? previewEndMinute;
  final Color? previewColor;
  final int clockHandsMode;
  final bool showMinuteLabels;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _ClockPainter(
          now: now,
          activities: activities,
          viewHalf: viewHalf,
          previewStart: previewStartMinute,
          previewEnd: previewEndMinute,
          previewColor: previewColor,
          clockHandsMode: clockHandsMode,
          showMinuteLabels: showMinuteLabels,
        ),
      );
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.now,
    required this.activities,
    required this.viewHalf,
    this.previewStart,
    this.previewEnd,
    this.previewColor,
    this.clockHandsMode = 1,
    this.showMinuteLabels = false,
  });

  final DateTime now;
  final List<Activity> activities;
  final AmPmHalf viewHalf;
  final int? previewStart;
  final int? previewEnd;
  final Color? previewColor;
  final int clockHandsMode;
  final bool showMinuteLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;
    final outerRadius = r * 0.95;
    final arcInner = r * 0.55;
    final arcOuter = r * 0.85;

    // Face
    canvas.drawCircle(
        center, outerRadius, Paint()..color = AppPalette.card.withValues(alpha: 0.6));
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppPalette.stroke,
    );

    // 5-min grid lines in arc band
    _drawGridLines(canvas, center, arcInner, arcOuter);

    // Activity arcs
    for (final a in activities) {
      _drawArc(canvas, center, arcInner, arcOuter, a.startMinute, a.endMinute,
          Color(a.colorValue),
          label: a.title, icon: a.iconKey);
    }
    if (previewStart != null && previewEnd != null) {
      _drawArc(canvas, center, arcInner, arcOuter, previewStart!, previewEnd!,
          (previewColor ?? AppPalette.accent).withValues(alpha: 0.55),
          dashed: true);
    }

    // Tick marks
    final tickPaint = Paint()..color = AppPalette.text;
    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final isHour = i % 5 == 0;
      final s = Offset(
        center.dx + math.cos(angle) * (outerRadius - (isHour ? 14 : 6)),
        center.dy + math.sin(angle) * (outerRadius - (isHour ? 14 : 6)),
      );
      final e = Offset(
        center.dx + math.cos(angle) * (outerRadius - 2),
        center.dy + math.sin(angle) * (outerRadius - 2),
      );
      canvas.drawLine(s, e, tickPaint..strokeWidth = isHour ? 3 : 1);
    }

    // Hour numbers
    for (int h = 1; h <= 12; h++) {
      final angle = (h / 12) * 2 * math.pi - math.pi / 2;
      final pos = Offset(
        center.dx + math.cos(angle) * (outerRadius - 32),
        center.dy + math.sin(angle) * (outerRadius - 32),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '$h',
          style: const TextStyle(
              color: AppPalette.text, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Minute labels (5,10,15…55) on inner ring
    if (showMinuteLabels) {
      _drawMinuteLabels(canvas, center, arcInner);
    }

    // Hands only if viewing current half
    if (halfOfNow(now) == viewHalf) {
      _drawHands(canvas, center, r);
    }

    canvas.drawCircle(center, 6, Paint()..color = AppPalette.accent);
  }

  void _drawMinuteLabels(Canvas canvas, Offset center, double inner) {
    // Show 5,10,15…55 just inside the arc ring
    for (int m = 5; m < 60; m += 5) {
      final angle = (m / 60) * 2 * math.pi - math.pi / 2;
      final labelR = inner - 10;
      final pos = Offset(
        center.dx + math.cos(angle) * labelR,
        center.dy + math.sin(angle) * labelR,
      );
      final isQuarter = m % 15 == 0;
      final tp = TextPainter(
        text: TextSpan(
          text: '$m',
          style: TextStyle(
            color: AppPalette.textDim.withValues(alpha: isQuarter ? 0.85 : 0.5),
            fontSize: isQuarter ? 9.5 : 7.5,
            fontWeight: isQuarter ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
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
    canvas.drawLine(
      center,
      Offset(center.dx + math.cos(angle) * len, center.dy + math.sin(angle) * len),
      Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.now != now ||
      old.activities != activities ||
      old.viewHalf != viewHalf ||
      old.previewStart != previewStart ||
      old.previewEnd != previewEnd ||
      old.clockHandsMode != clockHandsMode ||
      old.showMinuteLabels != showMinuteLabels;
}
