import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/time_math.dart';
import '../../../models/activity.dart';
import '../../../providers/providers.dart';

class FocusSessionView extends ConsumerStatefulWidget {
  const FocusSessionView({
    super.key,
    required this.activity,
    required this.onClose,
  });

  final Activity activity;
  final VoidCallback onClose;

  @override
  ConsumerState<FocusSessionView> createState() => _FocusSessionViewState();
}

class _FocusSessionViewState extends ConsumerState<FocusSessionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _isPaused = false;
  bool _isCompleted = false;
  String? _selectedReflection;

  Timer? _timer;
  late int _remainingSeconds;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    final durationMinutes = (widget.activity.endMinute - widget.activity.startMinute).clamp(1, 720);
    _totalSeconds = durationMinutes * 60;
    
    final now = DateTime.now();
    final nowMinOfHalf = minuteOfHalf(now);
    if (widget.activity.ampmHalf == halfOfNow(now) &&
        nowMinOfHalf >= widget.activity.startMinute &&
        nowMinOfHalf < widget.activity.endMinute) {
      final elapsed = (nowMinOfHalf - widget.activity.startMinute) * 60 + now.second;
      _remainingSeconds = (_totalSeconds - elapsed).clamp(0, _totalSeconds);
    } else {
      _remainingSeconds = _totalSeconds;
    }

    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            _isCompleted = true;
            HapticFeedback.heavyImpact();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.activity.colorValue);

    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Top minimal exit button
            Positioned(
              top: 16,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppPalette.textDim, size: 24),
                tooltip: 'Tutup Fokus',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.onClose();
                },
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isCompleted ? _buildReflectionCard(color) : _buildActiveTimer(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimer(Color color) {
    final progress = _totalSeconds > 0 ? (1.0 - (_remainingSeconds / _totalSeconds)).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Intention Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.activity.iconKey?.isNotEmpty == true ? widget.activity.iconKey! : '🎯',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                widget.activity.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Hero Breathing Timer Circle
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = 1.0 + (_pulseCtrl.value * 0.025);
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background track
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 5,
                        valueColor: AlwaysStoppedAnimation(AppPalette.stroke.withValues(alpha: 0.3)),
                      ),
                    ),
                    // Progress arc
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    // Big Time Digits
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimer(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPaused ? 'JEDA' : 'FOKUS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.0,
                            color: _isPaused ? AppPalette.textDim : color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 48),

        // Minimal Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pause / Resume
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                side: const BorderSide(color: AppPalette.stroke),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20, color: AppPalette.text),
              label: Text(_isPaused ? 'Lanjutkan' : 'Jeda', style: const TextStyle(color: AppPalette.text)),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isPaused = !_isPaused);
              },
            ),
            const SizedBox(width: 16),
            // Finish Early
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.2),
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => _isCompleted = true);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReflectionCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.spa_rounded, color: color, size: 26),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sesi Selesai',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.activity.title} telah selesai. Bagaimana sesinya terasa?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppPalette.textDim, height: 1.4),
          ),
          const SizedBox(height: 24),

          // 3 Quiet Reflection Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _reflectionOption('🌿 Tenang & Lancar', 'smooth'),
              _reflectionOption('⚡ Sangat Fokus', 'deep'),
              _reflectionOption('💨 Terdistraksi', 'distracted'),
            ],
          ),

          const SizedBox(height: 28),
          TextButton(
            onPressed: () {
              ref.read(activityRepoProvider).markComplete(widget.activity, true);
              widget.onClose();
            },
            child: const Text('Tutup', style: TextStyle(color: AppPalette.textDim)),
          ),
        ],
      ),
    );
  }

  Widget _reflectionOption(String label, String value) {
    final selected = _selectedReflection == value;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedReflection = value);
        ref.read(activityRepoProvider).markComplete(widget.activity, true);
        Future.delayed(const Duration(milliseconds: 300), widget.onClose);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppPalette.accent.withValues(alpha: 0.2) : AppPalette.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppPalette.accent : AppPalette.stroke,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? AppPalette.accent : AppPalette.text,
          ),
        ),
      ),
    );
  }
}
