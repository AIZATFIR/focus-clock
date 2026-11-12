import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../core/time_math.dart';
import '../../../models/activity.dart';
import '../../../providers/providers.dart';
import '../../../services/pip_timer_bridge.dart';
import '../../../services/focus_session_contract.dart';
import '../../../services/web_launch_url_stub.dart'
    if (dart.library.js_interop) '../../../services/web_launch_url_web.dart'
    as web_launch_url;

class FocusSessionView extends ConsumerStatefulWidget {
  const FocusSessionView({
    super.key,
    required this.activity,
    required this.onClose,
    this.externalRequest,
  });

  final Activity activity;
  final VoidCallback onClose;
  final FocusSessionRequest? externalRequest;

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
  late final DateTime _sessionStartedAt;
  DateTime? _runningUntil;
  bool _externalResultSent = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    final durationMinutes =
        widget.externalRequest?.targetMinutes ??
        (widget.activity.endMinute - widget.activity.startMinute).clamp(1, 720);
    _totalSeconds = durationMinutes * 60;
    final restored = _readWebSessionState();
    _sessionStartedAt = restored == null
        ? widget.externalRequest?.sourceStartedAt ?? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(restored['startedAt'] as int);

    final now = DateTime.now();
    final nowMinOfHalf = minuteOfHalf(now);
    if (restored != null) {
      _remainingSeconds = (restored['remainingSeconds'] as int).clamp(
        0,
        _totalSeconds,
      );
      _isPaused = restored['isPaused'] as bool;
    } else if (widget.externalRequest != null) {
      _remainingSeconds = _totalSeconds;
    } else if (widget.activity.ampmHalf == halfOfNow(now) &&
        nowMinOfHalf >= widget.activity.startMinute &&
        nowMinOfHalf < widget.activity.endMinute) {
      final elapsed =
          (nowMinOfHalf - widget.activity.startMinute) * 60 + now.second;
      _remainingSeconds = (_totalSeconds - elapsed).clamp(0, _totalSeconds);
    } else {
      _remainingSeconds = _totalSeconds;
    }

    if (!_isPaused && _remainingSeconds > 0) {
      _runningUntil = now.add(Duration(seconds: _remainingSeconds));
    }
    if (_remainingSeconds == 0 && !_isPaused) {
      _isCompleted = true;
    }

    PipTimerBridge.setTimerActive(true);
    _syncNotification();
    _startCountdown();
  }

  void _syncNotification() {
    PipTimerBridge.updateLiveNotification(
      title: widget.activity.title.isNotEmpty ? widget.activity.title : 'Fokus',
      timeStr: _formatTimer(_remainingSeconds),
      details: _isPaused ? 'Dijeda' : 'Tetap tenang & sadar',
    );
  }

  void _startCountdown() {
    _timer?.cancel();
    _persistWebSessionState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isCompleted && mounted) {
        final secondsLeft = _runningUntil == null
            ? 0
            : _runningUntil!.difference(DateTime.now()).inSeconds;
        setState(() {
          if (secondsLeft > 0) {
            _remainingSeconds = secondsLeft;
            _syncNotification();
          } else {
            _remainingSeconds = 0;
            _timer?.cancel();
            _isCompleted = true;
            _runningUntil = null;
            PipTimerBridge.setTimerActive(false);
            PipTimerBridge.cancelLiveNotification();
            HapticFeedback.heavyImpact();
          }
        });
        _persistWebSessionState();
        if (_isCompleted) unawaited(_sendExternalResult());
      }
    });
  }

  Map<String, dynamic>? _readWebSessionState() {
    final request = widget.externalRequest;
    final sessionId = request?.sourceSessionId;
    if (!kIsWeb || request == null || sessionId == null) return null;
    try {
      final encoded = web_launch_url.readWebFocusSessionState(sessionId);
      if (encoded != null) {
        final state = jsonDecode(encoded) as Map<String, dynamic>;
        final startedAt = state['startedAt'];
        final savedAt = state['savedAt'];
        final remainingSeconds = state['remainingSeconds'];
        if (state['totalSeconds'] != _totalSeconds ||
            startedAt is! int ||
            startedAt <= 0 ||
            startedAt > DateTime.now().millisecondsSinceEpoch ||
            (savedAt != null &&
                (savedAt is! int ||
                    savedAt <= 0 ||
                    savedAt >
                        DateTime.now()
                            .add(const Duration(minutes: 5))
                            .millisecondsSinceEpoch)) ||
            remainingSeconds is! int ||
            remainingSeconds < 0 ||
            remainingSeconds > _totalSeconds ||
            state['isPaused'] is! bool) {
          throw const FormatException('Invalid saved focus session.');
        }
        final remainingNow = savedAt == null
            ? remainingSeconds
            : FocusSessionContract.restoreRemainingSeconds(
                remainingSeconds: remainingSeconds,
                savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt as int),
                now: DateTime.now(),
                maxSeconds: _totalSeconds,
                isPaused: state['isPaused'] as bool,
              );
        return {...state, 'remainingSeconds': remainingNow};
      }
    } catch (error) {
      _clearWebSessionState();
      debugPrint('Discarding invalid saved focus session: $error');
    }

    final remainingSeconds = request.sourceRemainingSeconds;
    final sourceStartedAt = request.sourceStartedAt;
    if (remainingSeconds == null &&
        request.sourcePaused == null &&
        request.sourceStartedAt == null) {
      return null;
    }
    return {
      'startedAt':
          sourceStartedAt?.millisecondsSinceEpoch ??
          request.requestedAt.millisecondsSinceEpoch,
      'remainingSeconds': remainingSeconds == null
          ? _totalSeconds
          : (request.sourceRemainingAt == null
                ? remainingSeconds
                : FocusSessionContract.restoreRemainingSeconds(
                    remainingSeconds: remainingSeconds,
                    savedAt: request.sourceRemainingAt!,
                    now: DateTime.now(),
                    maxSeconds: _totalSeconds,
                    isPaused: request.sourcePaused ?? false,
                  )),
      'totalSeconds': _totalSeconds,
      'isPaused': request.sourcePaused ?? false,
    };
  }

  void _persistWebSessionState() {
    final sessionId = widget.externalRequest?.sourceSessionId;
    if (!kIsWeb || sessionId == null) return;
    try {
      web_launch_url.writeWebFocusSessionState(
        sessionId,
        jsonEncode({
          'startedAt': _sessionStartedAt.millisecondsSinceEpoch,
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'remainingSeconds': _remainingSeconds,
          'totalSeconds': _totalSeconds,
          'isPaused': _isPaused,
        }),
      );
    } catch (error) {
      debugPrint('Could not persist web focus session: $error');
    }
  }

  void _finishSession() {
    if (_isCompleted) return;
    _timer?.cancel();
    _remainingSeconds = _remainingNow;
    _isCompleted = true;
    setState(() {
      _isPaused = true;
      _runningUntil = null;
    });
    PipTimerBridge.setTimerActive(false);
    PipTimerBridge.cancelLiveNotification();
    _persistWebSessionState();
  }

  int get _remainingNow {
    if (_isPaused || _runningUntil == null) return _remainingSeconds;
    return _runningUntil!
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, _totalSeconds);
  }

  void _clearWebSessionState() {
    final sessionId = widget.externalRequest?.sourceSessionId;
    if (!kIsWeb || sessionId == null) return;
    try {
      web_launch_url.clearWebFocusSessionState(sessionId);
    } catch (error) {
      debugPrint('Could not clear web focus session: $error');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    PipTimerBridge.setTimerActive(false);
    PipTimerBridge.cancelLiveNotification();
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

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(_sendExternalResult());
      },
      child: Scaffold(
        backgroundColor: AppPalette.bg,
        body: SafeArea(
          child: Stack(
            children: [
              // Top minimal exit button
              Positioned(
                top: 16,
                left: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppPalette.textDim,
                    size: 24,
                  ),
                  tooltip: 'Tutup Fokus',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _closeSession();
                  },
                ),
              ),

              // Top Picture-in-Picture floating button
              Positioned(
                top: 16,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.picture_in_picture_alt_rounded,
                    color: AppPalette.accent,
                    size: 22,
                  ),
                  tooltip: 'Picture-in-Picture (Melayang)',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    PipTimerBridge.enterPip();
                  },
                ),
              ),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isCompleted
                      ? _buildReflectionCard(color)
                      : _buildActiveTimer(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeSession() {
    unawaited(_sendExternalResult());
    if (!_hasSadarWebCallback) widget.onClose();
  }

  bool get _hasSadarWebCallback {
    final request = widget.externalRequest;
    final callback = request?.callbackUrl;
    return kIsWeb &&
        (request?.sourceHabitKey != null || (request?.habitId ?? 0) > 0) &&
        callback != null &&
        FocusSessionContract.isAllowedSadarWebCallback(
          Uri.tryParse(callback) ?? Uri(),
        );
  }

  Future<void> _sendExternalResult() async {
    final request = widget.externalRequest;
    if (request == null || request.callbackUrl == null || _externalResultSent) {
      return;
    }
    final webCallback = _hasSadarWebCallback;
    if (!webCallback && request.habitId <= 0) return;
    _externalResultSent = true;
    _clearWebSessionState();

    final endedAt = DateTime.now();
    final elapsedMinutes =
        ((_totalSeconds - _remainingSeconds).clamp(0, _totalSeconds)) ~/ 60;
    final result = FocusSessionResult(
      sessionId: request.sourceSessionId ?? const Uuid().v4(),
      habitId: request.habitId,
      startedAt: _sessionStartedAt,
      endedAt: endedAt,
      actualDurationMinutes: elapsedMinutes,
      status: _isCompleted ? 'completed' : 'cancelled',
    );
    final callback = Uri.parse(request.callbackUrl!);
    try {
      if (webCallback) {
        final returnUri = FocusSessionContract.buildSadarWebCompletedUri(
          callbackUrl: request.callbackUrl!,
          habitKey: request.sourceHabitKey ?? request.habitId.toString(),
          result: result,
        );
        web_launch_url.returnToSadar(returnUri.toString());
        return;
      }
      final resultUri = FocusSessionContract.buildSadarCompletedUri(result);
      await launchUrl(
        callback.replace(queryParameters: resultUri.queryParameters),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      debugPrint('Could not return focus result to Sadar: $error');
    }
  }

  Widget _buildActiveTimer(Color color) {
    final progress = _totalSeconds > 0
        ? (1.0 - (_remainingSeconds / _totalSeconds)).clamp(0.0, 1.0)
        : 0.0;

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
                widget.activity.iconKey?.isNotEmpty == true
                    ? widget.activity.iconKey!
                    : '🎯',
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
                        valueColor: AlwaysStoppedAnimation(
                          AppPalette.stroke.withValues(alpha: 0.3),
                        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                side: const BorderSide(color: AppPalette.stroke),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 20,
                color: AppPalette.text,
              ),
              label: Text(
                _isPaused ? 'Lanjutkan' : 'Jeda',
                style: const TextStyle(color: AppPalette.text),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (_isPaused) {
                    _isPaused = false;
                    _runningUntil = DateTime.now().add(
                      Duration(seconds: _remainingSeconds),
                    );
                  } else {
                    _remainingSeconds = _remainingNow;
                    _isPaused = true;
                    _runningUntil = null;
                  }
                });
                if (_remainingSeconds == 0 && !_isPaused) {
                  _finishSession();
                }
                _persistWebSessionState();
              },
            ),
            const SizedBox(width: 16),
            // Finish Early
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.2),
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text(
                'Selesai',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                _finishSession();
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.activity.title} telah selesai. Bagaimana sesinya terasa?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppPalette.textDim,
              height: 1.4,
            ),
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
              if (widget.externalRequest == null) {
                ref
                    .read(activityRepoProvider)
                    .markComplete(widget.activity, true);
              }
              _closeSession();
            },
            child: const Text(
              'Tutup',
              style: TextStyle(color: AppPalette.textDim),
            ),
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
        if (widget.externalRequest == null) {
          ref.read(activityRepoProvider).markComplete(widget.activity, true);
        }
        Future.delayed(const Duration(milliseconds: 300), _closeSession);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppPalette.accent.withValues(alpha: 0.2)
              : AppPalette.bg,
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
