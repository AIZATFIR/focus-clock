import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/time_math.dart';
import '../../models/activity.dart';
import '../../providers/providers.dart';

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
  late int _start;
  late int _end;
  late int _color;
  late AmPmHalf _half;
  late String _recurrence;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _titleCtrl = TextEditingController(text: widget.initial.title);
    _descCtrl = TextEditingController(text: widget.initial.description);
    _start = widget.initial.startMinute;
    _end = widget.initial.endMinute;
    _color = widget.initial.colorValue;
    _half = widget.initial.ampmHalf;
    _recurrence = widget.initial.recurrence;
    // Request focus so keyboard shortcuts work immediately
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
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

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final is24h = settings?.is24h ?? false;
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
                  minute: _start,
                  half: _half,
                  is24h: is24h,
                  readOnly: readOnly,
                  onChanged: (m) => setState(() => _start = m),
                ),
              ),
              const SizedBox(width: 8),
              const Text('→', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: _TimeBlock(
                  label: 'End',
                  minute: _end,
                  half: _half,
                  is24h: is24h,
                  readOnly: readOnly,
                  onChanged: (m) => setState(() => _end = m),
                ),
              ),
            ],
          ),
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
              labelText: 'Description / reason',
              hintText: 'Why this activity?',
              border: OutlineInputBorder(),
            ),
          ),
          if (!readOnly) ...[
            const SizedBox(height: 12),
            const Text('Repeat', style: TextStyle(color: AppPalette.textDim, fontSize: 13)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'none', label: Text('Once')),
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
              ],
              selected: {_recurrence},
              onSelectionChanged: (s) =>
                  setState(() => _recurrence = s.first),
            ),
          ] else if (_recurrence != 'none') ...[
            const SizedBox(height: 8),
            _RecurrenceInfo(_recurrence),
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

  Future<void> _save() async {
    if (_end <= _start) _end = _start + 5;
    if (_end > 720) _end = 720;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity name required')),
      );
      return;
    }
    final a = widget.initial;

    // Conflict check before committing
    final repo = ref.read(activityRepoProvider);
    final dayActivities = await repo.getByDate(widget.initial.date);
    final clash = dayActivities
        .where((x) =>
            x.id != a.id &&
            x.ampmHalf == _half &&
            rangesOverlap(_start, _end, x.startMinute, x.endMinute))
        .firstOrNull;
    if (clash != null && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Time conflict'),
          content: Text(
              'Overlaps with "${clash.title}" '
              '(${formatMinuteOfHalf(clash.startMinute, _half, is24h: false)}–'
              '${formatMinuteOfHalf(clash.endMinute, _half, is24h: false)}).'),
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

    a.title = title;
    a.description = _descCtrl.text.trim();
    a.startMinute = _start;
    a.endMinute = _end;
    a.ampmHalf = _half;
    a.colorValue = _color;
    a.recurrence = _recurrence;
    final lead =
        ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
    await repo.upsert(a, notifLeadMinutes: lead);
    HapticFeedback.lightImpact();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(activityRepoProvider).delete(widget.initial.id);
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
    required this.minute,
    required this.half,
    required this.is24h,
    required this.readOnly,
    required this.onChanged,
  });
  final String label;
  final int minute;
  final AmPmHalf half;
  final bool is24h;
  final bool readOnly;
  final ValueChanged<int> onChanged;

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
            Text(
              formatMinuteOfHalf(minute, half, is24h: is24h),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final h12 = (minute ~/ 60) % 12;
    final m = minute % 60;
    final hour24 = (half == AmPmHalf.pm ? 12 : 0) + h12;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour24, minute: m),
    );
    if (picked == null) return;
    final pickedHour12 = picked.hour % 12;
    onChanged(pickedHour12 * 60 + picked.minute);
  }
}
