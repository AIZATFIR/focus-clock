import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/time_math.dart';
import '../../../models/activity.dart';
import '../../../providers/providers.dart';
import '../../../services/natural_intent_parser.dart';
import '../../../services/firebase_sync_service.dart';
import '../../ai_chat/voice_assistant_sheet.dart';
import 'focus_session_view.dart';

class NowNextCard extends ConsumerStatefulWidget {
  const NowNextCard({
    super.key,
    required this.activities,
    required this.now,
    required this.date,
  });

  final List<Activity> activities;
  final DateTime now;
  final DateTime date;

  @override
  ConsumerState<NowNextCard> createState() => _NowNextCardState();
}

class _NowNextCardState extends ConsumerState<NowNextCard> {
  final TextEditingController _intentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isInputActive = false;

  @override
  void dispose() {
    _intentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitIntent(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final parsed = NaturalIntentParser.parse(trimmed, referenceTime: widget.now, targetDate: widget.date);
    final activity = parsed.toActivity();

    final lead = ref.read(settingsProvider).valueOrNull?.notifLeadMinutes ?? 1;
    await ref.read(activityRepoProvider).upsert(activity, notifLeadMinutes: lead);

    try {
      ref.read(firebaseSyncServiceProvider).syncActivity(activity);
    } catch (_) {}

    _intentCtrl.clear();
    setState(() => _isInputActive = false);
    HapticFeedback.mediumImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(activity.iconKey ?? '🎯', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Jadwal "${activity.title}" (${activity.startMinute ~/ 60}:${(activity.startMinute % 60).toString().padLeft(2, '0')}) ditambahkan.'),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final is24h = ref.watch(settingsProvider.select((s) => s.valueOrNull?.is24hTime ?? false));
    final half = halfOfNow(widget.now);
    final nowMinOfHalf = minuteOfHalf(widget.now);
    final isToday = dateOnly(widget.date) == dateOnly(widget.now);

    Activity? currentActivity;
    Activity? nextActivity;

    if (isToday) {
      for (final a in widget.activities) {
        if (a.ampmHalf == half && nowMinOfHalf >= a.startMinute && nowMinOfHalf < a.endMinute) {
          currentActivity = a;
          break;
        }
      }

      final upcoming = widget.activities.where((a) {
        if (a.ampmHalf == half) {
          return a.startMinute > nowMinOfHalf;
        }
        return half == AmPmHalf.am && a.ampmHalf == AmPmHalf.pm;
      }).toList();

      upcoming.sort((a, b) {
        final hc = a.ampmHalf.index.compareTo(b.ampmHalf.index);
        return hc != 0 ? hc : a.startMinute.compareTo(b.startMinute);
      });

      if (upcoming.isNotEmpty) {
        nextActivity = upcoming.first;
      }
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 620),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.stroke.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Current Focus & Next Item
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Current State
              Expanded(
                child: currentActivity != null
                    ? _buildCurrentFocusPill(currentActivity, nowMinOfHalf)
                    : _buildFreeTimePill(nextActivity),
              ),

              const SizedBox(width: 12),

              // Action: Focus Button (if current active) or Natural Mic
              if (currentActivity != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(currentActivity.colorValue).withValues(alpha: 0.2),
                    foregroundColor: Color(currentActivity.colorValue),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Color(currentActivity.colorValue).withValues(alpha: 0.5)),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                  label: const Text('Mulai Fokus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => FocusSessionView(
                          activity: currentActivity!,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                      ),
                    );
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.mic_rounded, color: AppPalette.accent, size: 22),
                  tooltip: 'Ucapkan Niat',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const VoiceAssistantSheet(),
                    );
                  },
                ),
            ],
          ),

          // Row 2: What's Next (Subtle indicator)
          if (nextActivity != null && currentActivity != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.arrow_forward_rounded, size: 12, color: AppPalette.textDim),
                const SizedBox(width: 6),
                Text(
                  'Berikutnya: ${nextActivity.iconKey ?? ''} ${nextActivity.title} (${formatMinuteOfHalf(nextActivity.startMinute, nextActivity.ampmHalf, is24h: is24h)})',
                  style: const TextStyle(fontSize: 11, color: AppPalette.textDim, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppPalette.stroke),
          const SizedBox(height: 12),

          // Row 3: Frictionless Natural Intent Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _intentCtrl,
                  focusNode: _focusNode,
                  style: const TextStyle(fontSize: 13, color: AppPalette.text),
                  onSubmitted: _submitIntent,
                  decoration: InputDecoration(
                    hintText: 'Tulis niat (misal: "Belajar coding 1 jam jam 8 malam")',
                    hintStyle: const TextStyle(fontSize: 12, color: AppPalette.textDim),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: AppPalette.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppPalette.stroke),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppPalette.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppPalette.accent),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppPalette.accent),
                      onPressed: () => _submitIntent(_intentCtrl.text),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Row 4: Quick Intent Chips (Intelligent Suggestions)
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _suggestionChip('💻 Deep Work 45m', 'Deep Work 45m'),
                const SizedBox(width: 6),
                _suggestionChip('📖 Belajar 30m', 'Belajar 30m'),
                const SizedBox(width: 6),
                _suggestionChip('🧘 Istirahat 15m', 'Istirahat 15m'),
                const SizedBox(width: 6),
                _suggestionChip('🏃 Olahraga 30m', 'Olahraga 30m'),
                const SizedBox(width: 6),
                _suggestionChip('✍️ Menulis 30m', 'Menulis 30m'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentFocusPill(Activity a, int nowMin) {
    final remainingMins = (a.endMinute - nowMin).clamp(0, 720);
    final color = Color(a.colorValue);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.center,
          child: Text(a.iconKey?.isNotEmpty == true ? a.iconKey! : '🎯', style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                a.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppPalette.text),
              ),
              const SizedBox(height: 2),
              Text(
                'Fokus Sekarang • ${remainingMins}m tersisa',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFreeTimePill(Activity? next) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppPalette.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.accent.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.wb_sunny_outlined, size: 18, color: AppPalette.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Waktu Luang',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppPalette.text),
              ),
              const SizedBox(height: 2),
              Text(
                next != null ? 'Berikutnya: ${next.title}' : 'Tidak ada jadwal tersisa',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppPalette.textDim),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _suggestionChip(String label, String intent) {
    return InkWell(
      onTap: () => _submitIntent(intent),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppPalette.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppPalette.stroke),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppPalette.textDim, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
