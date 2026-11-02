import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/sadar_providers.dart';
import '../../../services/deep_link_service.dart';
import 'sadar_timer_view.dart';

class QuickActionSheet extends ConsumerStatefulWidget {
  const QuickActionSheet({
    super.key,
    required this.habit,
    required this.date,
    this.existingEntry,
    required this.onClose,
  });

  final Habit habit;
  final DateTime date;
  final HabitEntry? existingEntry;
  final VoidCallback onClose;

  @override
  ConsumerState<QuickActionSheet> createState() => _QuickActionSheetState();
}

class _QuickActionSheetState extends ConsumerState<QuickActionSheet> {
  late TextEditingController _noteCtrl;
  bool _isEditingNote = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.existingEntry?.note ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _dateStr {
    final y = widget.date.year.toString().padLeft(4, '0');
    final m = widget.date.month.toString().padLeft(2, '0');
    final d = widget.date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _updateStatus(HabitStatus status) async {
    HapticFeedback.mediumImpact();
    await ref.read(sadarRepoProvider).recordEntryStatus(
      habitId: widget.habit.id,
      dateString: _dateStr,
      status: status,
      valueCompleted: status == HabitStatus.yes ? widget.habit.target : 0,
      note: widget.existingEntry?.note,
    );
    ref.invalidate(dailyFulfillmentProvider);
    ref.invalidate(whatIRepeatProvider);
    ref.invalidate(awarenessStatsProvider);
    widget.onClose();
  }

  Future<void> _saveNote() async {
    HapticFeedback.lightImpact();
    final text = _noteCtrl.text.trim();
    await ref.read(sadarRepoProvider).recordEntryStatus(
      habitId: widget.habit.id,
      dateString: _dateStr,
      status: widget.existingEntry?.status ?? HabitStatus.unmarked,
      note: text.isEmpty ? null : text,
    );
    setState(() => _isEditingNote = false);
  }

  void _startTimer() async {
    HapticFeedback.mediumImpact();
    widget.onClose();

    // Try opening Focus Clock native timer via URL scheme
    final launched = await DeepLinkService.launchFocusClockTimer(
      TimerLaunchParams(
        habitId: widget.habit.id,
        title: widget.habit.name,
        durationMinutes: widget.habit.target,
        iconKey: widget.habit.iconKey,
        colorValue: widget.habit.colorValue,
        callbackUrl: 'sadar://completed',
      ),
    );

    // Fallback to internal Sadar timer if Focus Clock scheme not available or on desktop/web
    if (!launched && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => SadarTimerView(
            habit: widget.habit,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(widget.habit.colorValue);
    final dateFormatted = DateFormat('EEEE, d MMMM y').format(widget.date);
    final currentStatus = widget.existingEntry?.status ?? HabitStatus.unmarked;
    final hasNote = widget.existingEntry?.note?.isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppPalette.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: habitColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: habitColor.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.habit.iconKey.isNotEmpty ? widget.habit.iconKey : '🎯',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateFormatted · Target ${widget.habit.target} ${_formatUnit(widget.habit.unit)}',
                      style: const TextStyle(fontSize: 12, color: AppPalette.textDim),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppPalette.textDim, size: 22),
                onPressed: widget.onClose,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Timer Start Hero Button (if timed)
          if (widget.habit.timerEnabled) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                'Mulai Fokus (${widget.habit.target} min)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              onPressed: _startTimer,
            ),
            const SizedBox(height: 16),
          ],

          // 4 Action Buttons (Note, Yes, No, Skip)
          Row(
            children: [
              // 1. Note
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_note_rounded,
                  label: hasNote ? 'Catatan ✓' : 'Catatan',
                  color: hasNote ? const Color(0xFFEAB308) : AppPalette.textDim,
                  bgColor: hasNote ? const Color(0xFFEAB308).withValues(alpha: 0.15) : AppPalette.bg,
                  isSelected: hasNote,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isEditingNote = !_isEditingNote);
                  },
                ),
              ),
              const SizedBox(width: 10),

              // 2. Yes
              Expanded(
                child: _buildActionButton(
                  icon: Icons.check_circle_rounded,
                  label: 'Ya',
                  color: const Color(0xFF22C55E),
                  bgColor: currentStatus == HabitStatus.yes
                      ? const Color(0xFF22C55E).withValues(alpha: 0.25)
                      : AppPalette.bg,
                  isSelected: currentStatus == HabitStatus.yes,
                  onTap: () => _updateStatus(HabitStatus.yes),
                ),
              ),
              const SizedBox(width: 10),

              // 3. No
              Expanded(
                child: _buildActionButton(
                  icon: Icons.cancel_rounded,
                  label: 'Tidak',
                  color: const Color(0xFFEF4444),
                  bgColor: currentStatus == HabitStatus.no
                      ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                      : AppPalette.bg,
                  isSelected: currentStatus == HabitStatus.no,
                  onTap: () => _updateStatus(HabitStatus.no),
                ),
              ),
              const SizedBox(width: 10),

              // 4. Skip
              Expanded(
                child: _buildActionButton(
                  icon: Icons.redo_rounded,
                  label: 'Lewati',
                  color: const Color(0xFF64748B),
                  bgColor: currentStatus == HabitStatus.skip
                      ? const Color(0xFF64748B).withValues(alpha: 0.25)
                      : AppPalette.bg,
                  isSelected: currentStatus == HabitStatus.skip,
                  onTap: () => _updateStatus(HabitStatus.skip),
                ),
              ),
            ],
          ),

          // Note Editor Drawer
          if (_isEditingNote || hasNote) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _noteCtrl,
                    style: const TextStyle(fontSize: 13, color: AppPalette.text),
                    decoration: const InputDecoration(
                      hintText: 'Tulis refleksi singkat untuk hari ini...',
                      hintStyle: TextStyle(color: AppPalette.textDim, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _noteCtrl.clear();
                          _saveNote();
                        },
                        child: const Text('Hapus', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          backgroundColor: AppPalette.accent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _saveNote,
                        child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (currentStatus != HabitStatus.unmarked) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _updateStatus(HabitStatus.unmarked),
                child: const Text(
                  'Hapus Status Hari Ini',
                  style: TextStyle(color: AppPalette.textDim, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppPalette.stroke,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : AppPalette.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatUnit(HabitUnit unit) {
    switch (unit) {
      case HabitUnit.min:
        return 'menit';
      case HabitUnit.count:
        return 'kali';
      case HabitUnit.binary:
        return 'sesi';
    }
  }
}
