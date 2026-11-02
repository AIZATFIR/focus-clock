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
              child: ApplePressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onClose();
                },
                child: AppleGlassSurface(
                  borderRadius: 20,
                  borderWidth: 0.5,
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close_rounded, color: AppPalette.textDim, size: 20),
                ),
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
        AppleGlassSurface(
          borderRadius: 20,
          borderWidth: 0.5,
          borderColor: color.withValues(alpha: 0.4),
          backgroundColor: color.withValues(alpha: 0.14),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 38),

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
                        valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.06)),
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
                            fontSize: 54,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -1.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: (_isPaused ? AppPalette.textDim : color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (_isPaused ? AppPalette.textDim : color).withValues(alpha: 0.35),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _isPaused ? 'JEDA' : 'FOKUS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: _isPaused ? AppPalette.textDim : color,
                            ),
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
            ApplePressable(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isPaused = !_isPaused);
              },
              child: AppleGlassSurface(
                borderRadius: 18,
                borderWidth: 0.5,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20, color: AppPalette.text),
                    const SizedBox(width: 8),
                    Text(
                      _isPaused ? 'Lanjutkan' : 'Jeda',
                      style: const TextStyle(color: AppPalette.text, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Finish Early
            ApplePressable(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _isCompleted = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReflectionCard(Color color) {
    return AppleGlassSurface(
      borderRadius: 24,
      borderWidth: 0.5,
      padding: const EdgeInsets.all(28),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Icon(Icons.spa_rounded, color: color, size: 26),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sesi Selesai',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.6),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.activity.title} telah selesai. Bagaimana sesinya terasa?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppPalette.textDim, height: 1.4, letterSpacing: -0.1),
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
          ApplePressable(
            onTap: () {
              ref.read(activityRepoProvider).markComplete(widget.activity, true);
              widget.onClose();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Tutup',
                style: TextStyle(color: AppPalette.textDim, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reflectionOption(String label, String value) {
    final selected = _selectedReflection == value;
    return ApplePressable(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedReflection = value);
        ref.read(activityRepoProvider).markComplete(widget.activity, true);
        Future.delayed(const Duration(milliseconds: 300), widget.onClose);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppPalette.accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppPalette.accent : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            letterSpacing: -0.1,
            color: selected ? AppPalette.accent : AppPalette.text,
          ),
        ),
      ),
    );
  }
}
