import 'dart:async' show unawaited;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../providers/providers.dart';
import '../../widgets/color_swatch_picker.dart';

enum DetailMode { view, edit, create }

Future<void> showActivityDetailSheet(
  BuildContext context, {
  required Activity activity,
  DetailMode mode = DetailMode.view,
}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppPalette.glassSurface,
            child: _DetailSheet(initial: activity, initialMode: mode),
          ),
        ),
      ),
    );

class _DetailSheet extends ConsumerStatefulWidget {
  const _DetailSheet({required this.initial, required this.initialMode});
  final Activity initial;
  final DetailMode initialMode;

  @override
  ConsumerState<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends ConsumerState<_DetailSheet> {
  late DetailMode _mode;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  /// Span as absolute datetimes — may cross noon/midnight.
  late DateTime _startDt;
  late DateTime _endDt;

  late int _color;
  late String _recurrence;
  late int _importance;
  DateTime? _deadline;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _titleCtrl = TextEditingController(text: widget.initial.title);
    _descCtrl = TextEditingController(text: widget.initial.description);
    final a = widget.initial;
    _startDt = toDateTime(a.date, a.ampmHalf, a.startMinute);
    // toDateTime normalizes endMinute > 720 into the next half/day
    _endDt = toDateTime(a.date, a.ampmHalf, a.endMinute);
    _color = a.colorValue;
    _recurrence = a.recurrence;
    _importance = a.importance;
    _deadline = a.deadline;
    if (a.groupId != null) _loadGroupSpan(a.groupId!);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  /// Tapped segment is one slice — show the whole block's true span.
  Future<void> _loadGroupSpan(String groupId) async {
    final group = await ref.read(activityRepoProvider).getGroup(groupId);
    if (group.isEmpty || !mounted) return;
    group.sort((a, b) {
      final d = a.date.compareTo(b.date);
      if (d != 0) return d;
      final h = a.ampmHalf.index.compareTo(b.ampmHalf.index);
      return h != 0 ? h : a.startMinute.compareTo(b.startMinute);
    });
    setState(() {
      _startDt =
          toDateTime(group.first.date, group.first.ampmHalf, group.first.startMinute);
      _endDt = toDateTime(group.last.date, group.last.ampmHalf, group.last.endMinute);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_mode == DetailMode.view &&
        event.logicalKey == LogicalKeyboardKey.delete) {
      _delete();
    }
  }

  bool get _overnight => dateOnly(_endDt) != dateOnly(_startDt);


  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    final is24h = ref.watch(settingsProvider.select((s) => s.valueOrNull?.is24h ?? false));
    final readOnly = _mode == DetailMode.view;
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + pad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.initial.iconKey != null &&
                  widget.initial.iconKey!.isNotEmpty)
                Text(widget.initial.iconKey!,
                    style: const TextStyle(fontSize: 20))
              else
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Color(_color),
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                _modeTitle(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_mode == DetailMode.view) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => setState(() => _mode = DetailMode.edit),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  onPressed: _delete,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimeBlock(
                  label: 'Start',
                  value: _startDt,
                  is24h: is24h,
                  readOnly: readOnly,
                  onChanged: (dt) => setState(() {
                    final dur = _endDt.difference(_startDt);
                    _startDt = dt;
                    _endDt = dt.add(dur); // keep duration when start moves
                  }),
                ),
              ),
              const SizedBox(width: 8),
              const Text('→', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: _TimeBlock(
                  label: 'End',
                  value: _endDt,
                  is24h: is24h,
                  nextDay: _overnight,
                  readOnly: readOnly,
                  onChanged: (dt) => setState(() {
                    // End at/before start = user means next day (overnight)
                    var candidate =
                        DateTime(_startDt.year, _startDt.month, _startDt.day,
                            dt.hour, dt.minute);
                    if (!candidate.isAfter(_startDt)) {
                      candidate = candidate.add(const Duration(days: 1));
                    }
                    _endDt = candidate;
                  }),
                ),
              ),
            ],
          ),
          if (_overnight) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.nightlight_round,
                    size: 13, color: AppPalette.accent),
                const SizedBox(width: 6),
                Text(
                  'Overnight — ends next day',
                  style: const TextStyle(
                      color: AppPalette.accent, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            readOnly: readOnly,
            decoration: const InputDecoration(
              labelText: 'Activity',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            readOnly: readOnly,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason / Benefits',
              hintText: 'Why this activity?',
              border: OutlineInputBorder(),
            ),
          ),
          if (!readOnly) ...[
            const SizedBox(height: 12),
            const Text('Color',
                style: TextStyle(color: AppPalette.textDim, fontSize: 13)),
            const SizedBox(height: 6),
            ColorSwatchPicker(
              value: _color,
              onChanged: (c) => setState(() => _color = c),
            ),

            const Text('Repeat', style: TextStyle(color: AppPalette.textDim, fontSize: 13)),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Once'),
                    selected: _recurrence == 'none',
                    onSelected: (b) { if (b) setState(() => _recurrence = 'none'); },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Daily'),
                    selected: _recurrence == 'daily',
                    onSelected: (b) { if (b) setState(() => _recurrence = 'daily'); },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Weekday'),
                    selected: _recurrence == 'weekday',
                    onSelected: (b) { if (b) setState(() => _recurrence = 'weekday'); },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Weekly'),
                    selected: _recurrence == 'weekly',
                    onSelected: (b) { if (b) setState(() => _recurrence = 'weekly'); },
                  ),
                ],
              ),
            ),
          ] else ...[

            if (_recurrence != 'none') ...[
              const SizedBox(height: 8),
              _RecurrenceInfo(_recurrence),
            ],
          ],
          const SizedBox(height: 16),
          if (_mode != DetailMode.view)
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.accent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
        ],
      ),
    )); // closes Padding + KeyboardListener
  }

  String _modeTitle() => switch (_mode) {
        DetailMode.view => widget.initial.title.isEmpty
            ? 'Activity'
            : widget.initial.title,
        DetailMode.edit => 'Edit Activity',
        DetailMode.create => 'New Activity',
      };

  Activity _segmentActivity(SpanSegment seg, String? groupId) {
    final src = widget.initial;
    return Activity()
      ..presetId = src.presetId
      ..iconKey = src.iconKey
      ..title = _titleCtrl.text.trim()
      ..startMinute = seg.start
      ..endMinute = seg.end
      ..ampmHalf = seg.half
      ..date = seg.date
      ..description = _descCtrl.text.trim()
      ..colorValue = _color
      ..recurrence = _recurrence
      ..importance = _importance
      ..deadline = _deadline
      ..groupId = groupId
      ..createdAt = src.createdAt
      ..updatedAt = DateTime.now();
  }

  Future<void> _save() async {
    if (!_endDt.isAfter(_startDt)) {
      _endDt = _startDt.add(const Duration(minutes: 5));
    }
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity name required')),
      );
      return;
    }

    final a = widget.initial;
    final repo = ref.read(activityRepoProvider);
    final segments = splitSpan(_startDt, _endDt);

    // Ids belonging to this block (self or group) are exempt from conflicts
    final selfIds = <int>{a.id};
    if (a.groupId != null) {
      selfIds.addAll((await repo.getGroup(a.groupId!)).map((g) => g.id));
    }

    Activity? clash;
    AmPmHalf clashHalf = AmPmHalf.am;
    for (final seg in segments) {
      final dayActivities = await repo.getByDate(seg.date);
      clash = dayActivities
          .where((x) =>
              !selfIds.contains(x.id) &&
              x.ampmHalf == seg.half &&
              rangesOverlap(seg.start, seg.end, x.startMinute, x.endMinute))
          .firstOrNull;
      if (clash != null) {
        clashHalf = seg.half;
        break;
      }
    }
    if (clash != null && mounted) {
      final c = clash;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Time conflict'),
          content: Text(
              'Overlaps with "${c.title}" '
              '(${formatMinuteOfHalf(c.startMinute, clashHalf, is24h: false)}–'
              '${formatMinuteOfHalf(c.endMinute, clashHalf, is24h: false)}).'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final lead =
        ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;

    if (segments.length == 1 && a.groupId == null) {
      // Plain single-half block — keep the existing record/id
      final seg = segments.first;
      a.title = title;
      a.description = _descCtrl.text.trim();
      a.date = seg.date;
      a.ampmHalf = seg.half;
      a.startMinute = seg.start;
      a.endMinute = seg.end;
      a.colorValue = _color;
      a.recurrence = _recurrence;
      a.importance = _importance;
      a.deadline = _deadline;
      await repo.upsert(a, notifLeadMinutes: lead);
    } else {
      final groupId =
          segments.length > 1 ? (a.groupId ?? const Uuid().v4()) : null;
      await repo.replaceSpan(
        original: a,
        segments: [for (final s in segments) _segmentActivity(s, groupId)],
        notifLeadMinutes: lead,
      );
    }
    HapticFeedback.lightImpact();

    // Push to Google Calendar if signed in (fire-and-forget)
    final gcalSigned = ref.read(gcalSignedInProvider);
    if (gcalSigned) {
      final gcal = ref.read(gcalServiceProvider);
      final pushTarget = segments.length == 1
          ? widget.initial
          : (await repo.getGroup(widget.initial.groupId ?? '')).firstOrNull
              ?? widget.initial;
      unawaited(gcal.pushActivity(pushTarget));
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(activityRepoProvider).deleteGroupOf(widget.initial);
    if (mounted) Navigator.pop(context);
  }
}

class _RecurrenceInfo extends StatelessWidget {
  const _RecurrenceInfo(this.recurrence);
  final String recurrence;

  @override
  Widget build(BuildContext context) {
    final label = recurrence == 'daily' ? '↻ Repeats daily' : '↻ Repeats weekly';
    return Row(
      children: [
        const Icon(Icons.repeat, size: 14, color: AppPalette.accent),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: AppPalette.accent, fontSize: 12)),
      ],
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.label,
    required this.value,
    required this.is24h,
    required this.readOnly,
    required this.onChanged,
    this.nextDay = false,
  });
  final String label;
  final DateTime value;
  final bool is24h;
  final bool readOnly;
  final bool nextDay;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: readOnly ? null : () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppPalette.stroke),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppPalette.textDim)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  formatTimeOfDay(value, is24h: is24h),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                if (nextDay) ...[
                  const SizedBox(width: 5),
                  const Text('+1',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.accent)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value.hour, minute: value.minute),
    );
    if (picked == null) return;
    onChanged(DateTime(
        value.year, value.month, value.day, picked.hour, picked.minute));
  }
}
