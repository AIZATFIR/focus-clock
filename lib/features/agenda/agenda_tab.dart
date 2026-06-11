import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../providers/providers.dart';
import '../activity_detail/activity_detail_sheet.dart';

class AgendaTab extends ConsumerWidget {
  const AgendaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(currentDateProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final is24h = settings?.is24h ?? false;
    return Column(
      children: [
        _WeekStrip(selectedDate: selectedDate),
        Expanded(child: _TimelineView(date: selectedDate, is24h: is24h)),
      ],
    );
  }
}

// ── Week strip — exactly 7 days, Sun-Sat of current week ─────────────────────

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.selectedDate});
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dateOnly(DateTime.now());
    // Week containing today, Sun=0
    final sun = today.subtract(Duration(days: today.weekday % 7));
    final days = List.generate(7, (i) => sun.add(Duration(days: i)));

    return Container(
      height: 64,
      color: AppPalette.card,
      child: Row(
        children: days.map((day) {
          final isSelected = day == selectedDate;
          final isToday = day == today;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(currentDateProvider.notifier).state = day;
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).substring(0, 1),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.black
                          : isToday
                              ? AppPalette.accent
                              : AppPalette.textDim,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected ? AppPalette.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: AppPalette.accent, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.black
                            : isToday
                                ? AppPalette.accent
                                : AppPalette.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _TimelineView extends ConsumerStatefulWidget {
  const _TimelineView({required this.date, required this.is24h});
  final DateTime date;
  final bool is24h;

  @override
  ConsumerState<_TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<_TimelineView> {
  final _scroll = ScrollController();

  static const double _hourH = 64.0;
  static const double _labelW = 52.0;
  static const double _totalH = _hourH * 24;

  // block drag state
  int? _draggingId;
  double _dragDeltaY = 0;

  // create-by-drag state
  int? _createStartMin; // absolute minute of day
  int? _createEndMin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hour = DateTime.now().hour;
      final target = ((hour - 1.5) * _hourH).clamp(0.0, _totalH);
      if (_scroll.hasClients) {
        _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesByDateProvider);
    final activities = activitiesAsync.valueOrNull ?? const <Activity>[];

    return Stack(
      children: [
        GestureDetector(
          // drag on empty area = create new activity
          onVerticalDragStart: (d) => _onCreateDragStart(d, context),
          onVerticalDragUpdate: _onCreateDragUpdate,
          onVerticalDragEnd: (_) => _onCreateDragEnd(context),
          child: SingleChildScrollView(
            controller: _scroll,
            physics: _draggingId != null || _createStartMin != null
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            child: SizedBox(
              height: _totalH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _labelW,
                    height: _totalH,
                    child: _buildLabels(),
                  ),
                  Expanded(child: _buildGrid(activities)),
                ],
              ),
            ),
          ),
        ),
        if (dateOnly(widget.date) == dateOnly(DateTime.now()))
          _NowLine(hourH: _hourH, labelW: _labelW, scroll: _scroll),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: AppPalette.accent,
            foregroundColor: Colors.black,
            child: const Icon(Icons.add),
            onPressed: () => _createCustom(context),
          ),
        ),
      ],
    );
  }

  // ── Labels ─────────────────────────────────────────────────────────────────

  Widget _buildLabels() {
    final items = <Widget>[];
    for (int h = 1; h < 24; h++) {
      items.add(Positioned(
        top: h * _hourH - 7,
        left: 0,
        right: 4,
        child: Text(
          _hourLabel(h),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 10, color: AppPalette.textDim),
        ),
      ));
      // :15 :30 :45 sub-labels
      for (final m in [15, 30, 45]) {
        items.add(Positioned(
          top: h * _hourH + m / 60 * _hourH - 5,
          right: 4,
          child: Text(
            ':${m.toString().padLeft(2, '0')}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 8,
              color: AppPalette.textDim.withValues(alpha: m == 30 ? 0.6 : 0.35),
            ),
          ),
        ));
      }
    }
    return Stack(children: items);
  }

  String _hourLabel(int h) {
    if (widget.is24h) return '${h.toString().padLeft(2, '0')}:00';
    if (h == 0) return '';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  // ── Grid ──────────────────────────────────────────────────────────────────

  Widget _buildGrid(List<Activity> activities) {
    // Create-preview overlay
    Widget? createPreview;
    if (_createStartMin != null && _createEndMin != null) {
      final top = _createStartMin! / 60 * _hourH;
      final h = ((_createEndMin! - _createStartMin!) / 60 * _hourH)
          .clamp(20.0, double.infinity);
      createPreview = Positioned(
        top: top,
        left: 2,
        right: 4,
        height: h,
        child: Container(
          decoration: BoxDecoration(
            color: AppPalette.accent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppPalette.accent, width: 1.5),
          ),
        ),
      );
    }

    return Stack(
      children: [
        CustomPaint(
          size: Size(double.infinity, _totalH),
          painter: _GridPainter(hourH: _hourH),
        ),
        ...activities.map((a) => _buildBlock(a)),
        if (createPreview != null) createPreview,
      ],
    );
  }

  Widget _buildBlock(Activity a) {
    final offsetMin = a.ampmHalf == AmPmHalf.am ? 0 : 720;
    final isDragging = _draggingId == a.id;
    final delta = isDragging ? _snappedDeltaMin() : 0;
    final startMin = (offsetMin + a.startMinute + delta).clamp(0, 1440 - 1);
    final endMin =
        (offsetMin + a.endMinute + delta).clamp(startMin + 1, 1440);
    final top = startMin / 60 * _hourH;
    final height = ((endMin - startMin) / 60 * _hourH).clamp(22.0, 1e6);
    final color = Color(a.colorValue);
    final fg = _fg(color);

    return Positioned(
      top: top,
      left: 2,
      right: 4,
      height: height,
      child: GestureDetector(
        onTap: isDragging
            ? null
            : () => showActivityDetailSheet(context,
                activity: a, mode: DetailMode.view),
        onVerticalDragStart: (_) {
          HapticFeedback.mediumImpact();
          setState(() {
            _draggingId = a.id;
            _dragDeltaY = 0;
          });
        },
        onVerticalDragUpdate: (d) =>
            setState(() => _dragDeltaY += d.delta.dy),
        onVerticalDragEnd: (_) => _commitBlockDrag(a),
        child: Opacity(
          opacity: a.isCompleted ? 0.45 : 1.0,
          child: Material(
            elevation: isDragging ? 6 : 0,
            borderRadius: BorderRadius.circular(5),
            shadowColor: color.withValues(alpha: 0.4),
            color: color.withValues(alpha: isDragging ? 0.95 : 0.88),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border(left: BorderSide(color: color, width: 3.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              child: Row(
                children: [
                  if (a.iconKey != null && a.iconKey!.isNotEmpty) ...[
                    Text(a.iconKey!, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.title.isEmpty ? '(no title)' : a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                              color: fg,
                              decoration: a.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null),
                        ),
                        if (height > 40)
                          Text(
                            _timeRange(a),
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                color: fg.withValues(alpha: 0.75)),
                          ),
                      ],
                    ),
                  ),
                  if (a.recurrence != 'none')
                    Icon(Icons.repeat,
                        size: 11, color: fg.withValues(alpha: 0.6)),
                  // Complete toggle
                  if (!isDragging)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(activityRepoProvider).markComplete(
                            a.id, !a.isCompleted);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          a.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: fg.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _snappedDeltaMin() {
    final raw = (_dragDeltaY / _hourH * 60).round();
    return snapDelta(raw);
  }

  Future<void> _commitBlockDrag(Activity a) async {
    if (_draggingId == null) return;
    final delta = _snappedDeltaMin();
    setState(() {
      _draggingId = null;
      _dragDeltaY = 0;
    });
    if (delta == 0) return;
    final dur = a.endMinute - a.startMinute;
    a.startMinute = (a.startMinute + delta).clamp(0, 720 - dur);
    a.endMinute = a.startMinute + dur;
    final lead =
        ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
    await ref.read(activityRepoProvider).upsert(a, notifLeadMinutes: lead);
    HapticFeedback.lightImpact();
  }

  // ── Create by dragging empty area ─────────────────────────────────────────

  void _onCreateDragStart(DragStartDetails d, BuildContext ctx) {
    final scrollOff = _scroll.hasClients ? _scroll.offset : 0.0;
    final box = ctx.findRenderObject() as RenderBox?;
    final topOfWidget = box?.localToGlobal(Offset.zero).dy ?? 0.0;
    final localY = d.globalPosition.dy - topOfWidget;
    final absMin =
        ((localY + scrollOff) / _hourH * 60).round().clamp(0, 1439);
    setState(() {
      _createStartMin = absMin;
      _createEndMin = absMin;
    });
  }

  void _onCreateDragUpdate(DragUpdateDetails d) {
    if (_createStartMin == null) return;
    final scrollOff = _scroll.hasClients ? _scroll.offset : 0.0;
    // accumulate dy from start position
    final newEndMin = (_createStartMin! + d.localPosition.dy / _hourH * 60)
        .round()
        .clamp(_createStartMin! + 5, 1439);
    setState(() => _createEndMin = newEndMin);
  }

  Future<void> _onCreateDragEnd(BuildContext ctx) async {
    if (_createStartMin == null || _createEndMin == null) return;
    final startAbsMin = _createStartMin!;
    final endAbsMin = _createEndMin!;
    setState(() {
      _createStartMin = null;
      _createEndMin = null;
    });

    final half = startAbsMin >= 720 ? AmPmHalf.pm : AmPmHalf.am;
    final startRel = snap5(startAbsMin % 720);
    final endRel = snap5(endAbsMin % 720).clamp(startRel + 5, 720);

    final a = Activity()
      ..title = ''
      ..startMinute = startRel
      ..endMinute = endRel
      ..ampmHalf = half
      ..date = widget.date
      ..colorValue = AppPalette.accent.toARGB32()
      ..description = ''
      ..recurrence = 'none'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    if (!mounted) return;
    await showActivityDetailSheet(ctx, activity: a, mode: DetailMode.create);
  }

  Future<void> _createCustom(BuildContext ctx) async {
    final half = ref.read(ampmHalfProvider);
    final start = snap5(minuteOfHalf(DateTime.now()));
    final a = Activity()
      ..title = ''
      ..startMinute = start
      ..endMinute = (start + 30).clamp(0, 720)
      ..ampmHalf = half
      ..date = widget.date
      ..colorValue = AppPalette.accent.toARGB32()
      ..description = ''
      ..recurrence = 'none'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await showActivityDetailSheet(ctx, activity: a, mode: DetailMode.create);
  }

  String _timeRange(Activity a) {
    final s = formatMinuteOfHalf(a.startMinute, a.ampmHalf, is24h: widget.is24h);
    final e = formatMinuteOfHalf(a.endMinute, a.ampmHalf, is24h: widget.is24h);
    return '$s – $e';
  }

  Color _fg(Color bg) =>
      bg.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
}

// ── Now line ─────────────────────────────────────────────────────────────────

class _NowLine extends StatefulWidget {
  const _NowLine(
      {required this.hourH, required this.labelW, required this.scroll});
  final double hourH;
  final double labelW;
  final ScrollController scroll;

  @override
  State<_NowLine> createState() => _NowLineState();
}

class _NowLineState extends State<_NowLine> {
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    widget.scroll.addListener(_rebuild);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      setState(() => _now = DateTime.now());
      return true;
    });
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.scroll.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInContent =
        (_now.hour * 60 + _now.minute) / 60 * widget.hourH;
    final scrollOff =
        widget.scroll.hasClients ? widget.scroll.offset : 0.0;
    final top = topInContent - scrollOff;

    return Positioned(
      top: top,
      left: widget.labelW,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle)),
            Expanded(
                child: Container(height: 1.5, color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}

// ── Grid painter ──────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.hourH});
  final double hourH;

  @override
  void paint(Canvas canvas, Size size) {
    final hour = Paint()
      ..color = AppPalette.stroke.withValues(alpha: 0.6)
      ..strokeWidth = 0.6;
    final half = Paint()
      ..color = AppPalette.stroke.withValues(alpha: 0.3)
      ..strokeWidth = 0.4;
    final quarter = Paint()
      ..color = AppPalette.stroke.withValues(alpha: 0.15)
      ..strokeWidth = 0.3;

    for (int h = 0; h <= 24; h++) {
      canvas.drawLine(Offset(0, h * hourH), Offset(size.width, h * hourH), hour);
      if (h < 24) {
        canvas.drawLine(
            Offset(0, h * hourH + hourH * 0.25),
            Offset(size.width, h * hourH + hourH * 0.25),
            quarter);
        canvas.drawLine(
            Offset(0, h * hourH + hourH * 0.5),
            Offset(size.width, h * hourH + hourH * 0.5),
            half);
        canvas.drawLine(
            Offset(0, h * hourH + hourH * 0.75),
            Offset(size.width, h * hourH + hourH * 0.75),
            quarter);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.hourH != hourH;
}
