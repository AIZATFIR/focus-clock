import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 12-hour half. DB partition key.
/// Ordinal serialization for Isar: AM=0, PM=1.
enum AmPmHalf { am, pm }

extension AmPmHalfX on AmPmHalf {
  String get label => this == AmPmHalf.am ? 'AM' : 'PM';
}

AmPmHalf halfOfNow([DateTime? now]) =>
    (now ?? DateTime.now()).hour < 12 ? AmPmHalf.am : AmPmHalf.pm;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int minuteOfHalf(DateTime d) {
  final h12 = d.hour % 12;
  return h12 * 60 + d.minute;
}

/// Snap absolute minute [0..720]: prefer nearest hour (within 8 min), else nearest 5.
int snap5(int m) {
  final nearestHour = ((m + 30) ~/ 60) * 60;
  if ((m - nearestHour).abs() <= 8) return nearestHour.clamp(0, 720);
  return ((m + 2) ~/ 5) * 5 % 720;
}

/// Snap a drag delta (any int): nearest 5, prefer 0 or multiples of 60 (within 8).
int snapDelta(int delta) {
  if (delta == 0) return 0;
  final sign = delta < 0 ? -1 : 1;
  final abs = delta.abs();
  final nearestHour = ((abs + 30) ~/ 60) * 60;
  if ((abs - nearestHour).abs() <= 8) return sign * nearestHour;
  return sign * ((abs + 2) ~/ 5) * 5;
}

String formatMinuteOfHalf(int minute, AmPmHalf half, {required bool is24h}) {
  final h12 = (minute ~/ 60) % 12;
  final m = minute % 60;
  if (is24h) {
    final h24 = (half == AmPmHalf.pm ? 12 : 0) + h12;
    return '${h24.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
  final h = h12 == 0 ? 12 : h12;
  return '$h:${m.toString().padLeft(2, '0')} ${half.label}';
}

String formatTimeOfDay(DateTime d, {required bool is24h}) {
  if (is24h) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  final h12 = d.hour % 12;
  final h = h12 == 0 ? 12 : h12;
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '$h:${d.minute.toString().padLeft(2, '0')} $ampm';
}

/// Convert (dx, dy) from clock center to minute-of-half [0..720).
/// 12 o'clock = top = minute 0. Clockwise.
int offsetToMinute(Offset offset) {
  final theta = math.atan2(offset.dx, -offset.dy);
  var norm = theta < 0 ? theta + 2 * math.pi : theta;
  final minute = (norm / (2 * math.pi) * 720).round() % 720;
  return minute;
}

double minuteToAngle(int minute) => (minute / 720.0) * 2 * math.pi;

/// True if [aStart, aEnd) overlaps [bStart, bEnd).
bool rangesOverlap(int aStart, int aEnd, int bStart, int bEnd) =>
    aStart < bEnd && bStart < aEnd;

/// Combine date + half + minute to a real DateTime (for scheduling).
DateTime toDateTime(DateTime date, AmPmHalf half, int minute) {
  final h12 = minute ~/ 60;
  final mm = minute % 60;
  final hour = (half == AmPmHalf.pm ? 12 : 0) + h12;
  return DateTime(date.year, date.month, date.day, hour, mm);
}
