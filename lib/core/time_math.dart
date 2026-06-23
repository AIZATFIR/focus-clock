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

int toDbMinute(int uiMinute) => uiMinute % 720;
AmPmHalf toDbHalf(int uiMinute) => uiMinute < 720 ? AmPmHalf.am : AmPmHalf.pm;
int toUiMinute(int dbMinute, AmPmHalf half, {bool is24h = true}) =>
    is24h ? (dbMinute + (half == AmPmHalf.pm ? 720 : 0)) : dbMinute;

/// Snap absolute minute [0..1440]: nearest 5 minutes.
int snap5(int m) {
  return (((m + 2.5) ~/ 5) * 5).clamp(0, 1440);
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
  } else {
    final h12 = d.hour % 12;
    final hour = h12 == 0 ? 12 : h12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}

String formatCurrentTime(DateTime d, {required bool is24h, required String format}) {
  if (format == 'seconds') {
    if (is24h) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    } else {
      final h12 = d.hour % 12;
      final hour = h12 == 0 ? 12 : h12;
      final ampm = d.hour < 12 ? 'AM' : 'PM';
      return '${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')} $ampm';
    }
  } else if (format == 'detailed') {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdayStr = days[d.weekday == 7 ? 0 : d.weekday];
    final monthStr = months[d.month - 1];
    final timePart = formatTimeOfDay(d, is24h: is24h);
    return '$weekdayStr, ${d.day} $monthStr $timePart';
  } else {
    return formatTimeOfDay(d, is24h: is24h);
  }
}

/// Convert (dx, dy) from clock center to minute-of-day [0..1440) or [0..720).
/// 12 o'clock = top = minute 0. Clockwise.
int offsetToMinute(Offset offset, {required bool is24h}) {
  final theta = math.atan2(offset.dx, -offset.dy);
  var norm = theta < 0 ? theta + 2 * math.pi : theta;
  final scale = is24h ? 1440.0 : 720.0;
  final minute = (norm / (2 * math.pi) * scale).round() % scale.toInt();
  return minute;
}

double minuteToAngle(int minute, {required bool is24h}) {
  final scale = is24h ? 1440.0 : 720.0;
  return (minute / scale) * 2 * math.pi;
}

/// True if [aStart, aEnd) overlaps [bStart, bEnd).
bool rangesOverlap(int aStart, int aEnd, int bStart, int bEnd) =>
    aStart < bEnd && bStart < aEnd;

/// One piece of a (possibly cross-midnight) span, confined to a single half.
typedef SpanSegment = ({DateTime date, AmPmHalf half, int start, int end});

/// Split an absolute datetime range into per-half segments.
/// Sleep 22:00→05:00 becomes [PM 600-720 today, AM 0-300 tomorrow].
List<SpanSegment> splitSpan(DateTime startDt, DateTime endDt) {
  assert(endDt.isAfter(startDt));
  final segments = <SpanSegment>[];
  var date = dateOnly(startDt);
  var half = halfOfNow(startDt);
  var minute = minuteOfHalf(startDt);
  var remaining = endDt.difference(startDt).inMinutes;
  while (remaining > 0) {
    final segEnd = math.min(720, minute + remaining);
    segments.add((date: date, half: half, start: minute, end: segEnd));
    remaining -= segEnd - minute;
    minute = 0;
    if (half == AmPmHalf.am) {
      half = AmPmHalf.pm;
    } else {
      half = AmPmHalf.am;
      date = date.add(const Duration(days: 1));
    }
  }
  return segments;
}

/// Combine date + half + minute to a real DateTime (for scheduling).
DateTime toDateTime(DateTime date, AmPmHalf half, int minute) {
  final h12 = minute ~/ 60;
  final mm = minute % 60;
  final hour = (half == AmPmHalf.pm ? 12 : 0) + h12;
  return DateTime(date.year, date.month, date.day, hour, mm);
}
