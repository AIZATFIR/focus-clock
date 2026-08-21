import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/time_math.dart';
import '../../../models/routine_blueprint.dart';

class BlueprintClockPreview extends StatelessWidget {
  final List<BlueprintBlock> blocks;
  final double size;
  final AmPmHalf? filterHalf;

  const BlueprintClockPreview({
    super.key,
    required this.blocks,
    this.size = 120,
    this.filterHalf,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BlueprintClockPainter(
          blocks: blocks,
          filterHalf: filterHalf,
        ),
      ),
    );
  }
}

class _BlueprintClockPainter extends CustomPainter {
  final List<BlueprintBlock> blocks;
  final AmPmHalf? filterHalf;

  _BlueprintClockPainter({
    required this.blocks,
    this.filterHalf,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF1E1E2E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Subtle outer border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 1, borderPaint);

    // Inner dial track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.45;
    canvas.drawCircle(center, radius * 0.65, trackPaint);

    // Render Blocks
    final visibleBlocks = filterHalf == null
        ? blocks
        : blocks.where((b) => b.ampmHalf == filterHalf).toList();

    for (final b in visibleBlocks) {
      final startAngle = (b.startMinute / 720.0) * 2 * math.pi - math.pi / 2;
      var durationMinutes = b.endMinute - b.startMinute;
      if (durationMinutes <= 0) durationMinutes += 720;
      final sweepAngle = (durationMinutes / 720.0) * 2 * math.pi;

      final blockPaint = Paint()
        ..color = Color(b.colorValue).withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.40
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius * 0.65);
      canvas.drawArc(rect, startAngle, sweepAngle, false, blockPaint);
    }

    // Center pivot dot
    final pivotPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.12, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant _BlueprintClockPainter oldDelegate) {
    return oldDelegate.blocks != blocks || oldDelegate.filterHalf != filterHalf;
  }
}
