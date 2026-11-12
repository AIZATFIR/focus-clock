/// Focus Session Contract (v1)
/// As specified in PRD 3 Section 2, Section 35, and Section 84.
///
/// Provides a versioned, decoupled integration boundary between
/// Sadar and Focus Clock without circular or tightly coupled imports.
library;

class FocusSessionRequest {
  final int habitId;
  final String title;
  final int targetMinutes;
  final DateTime requestedAt;
  final String? callbackUrl;
  final String? sourceHabitKey;
  final String? sourceSessionId;
  final int? sourceRemainingSeconds;
  final DateTime? sourceRemainingAt;
  final DateTime? sourceStartedAt;
  final bool? sourcePaused;

  const FocusSessionRequest({
    required this.habitId,
    required this.title,
    required this.targetMinutes,
    required this.requestedAt,
    this.callbackUrl,
    this.sourceHabitKey,
    this.sourceSessionId,
    this.sourceRemainingSeconds,
    this.sourceRemainingAt,
    this.sourceStartedAt,
    this.sourcePaused,
  });

  Map<String, dynamic> toJson() => {
    'version': FocusSessionContract.version,
    'habitId': habitId,
    'title': title,
    'targetMinutes': targetMinutes,
    'requestedAt': requestedAt.toIso8601String(),
    'callbackUrl': callbackUrl,
    'sourceHabitKey': sourceHabitKey,
    'sourceSessionId': sourceSessionId,
    'sourceRemainingSeconds': sourceRemainingSeconds,
    'sourceRemainingAt': sourceRemainingAt?.toIso8601String(),
    'sourceStartedAt': sourceStartedAt?.toIso8601String(),
    'sourcePaused': sourcePaused,
  };

  factory FocusSessionRequest.fromJson(Map<String, dynamic> json) {
    return FocusSessionRequest(
      habitId: json['habitId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      targetMinutes: json['targetMinutes'] as int? ?? 20,
      requestedAt:
          DateTime.tryParse(json['requestedAt'] as String? ?? '') ??
          DateTime.now(),
      callbackUrl: json['callbackUrl'] as String?,
      sourceHabitKey: json['sourceHabitKey'] as String?,
      sourceSessionId: json['sourceSessionId'] as String?,
      sourceRemainingSeconds: json['sourceRemainingSeconds'] as int?,
      sourceRemainingAt: DateTime.tryParse(
        json['sourceRemainingAt'] as String? ?? '',
      ),
      sourceStartedAt: DateTime.tryParse(
        json['sourceStartedAt'] as String? ?? '',
      ),
      sourcePaused: json['sourcePaused'] as bool?,
    );
  }
}

class FocusSessionResult {
  final String sessionId;
  final int habitId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int actualDurationMinutes;
  final String status; // 'completed', 'cancelled', 'interrupted'

  const FocusSessionResult({
    required this.sessionId,
    required this.habitId,
    required this.startedAt,
    required this.endedAt,
    required this.actualDurationMinutes,
    required this.status,
  });

  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toJson() => {
    'version': FocusSessionContract.version,
    'sessionId': sessionId,
    'habitId': habitId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'actualDurationMinutes': actualDurationMinutes,
    'status': status,
  };

  factory FocusSessionResult.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return FocusSessionResult(
      sessionId: json['sessionId'] as String? ?? '',
      habitId: json['habitId'] as int? ?? 0,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? now,
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? '') ?? now,
      actualDurationMinutes: json['actualDurationMinutes'] as int? ?? 0,
      status: json['status'] as String? ?? 'completed',
    );
  }
}

class FocusSessionContract {
  static const String version = 'v1';
  static const String schemeFocusClock = 'focusclock';
  static const String schemeSadar = 'sadar';

  static int restoreRemainingSeconds({
    required int remainingSeconds,
    required DateTime savedAt,
    required DateTime now,
    required int maxSeconds,
    required bool isPaused,
  }) {
    if (isPaused) return remainingSeconds.clamp(0, maxSeconds);
    final elapsed = now.difference(savedAt).inSeconds.clamp(0, maxSeconds);
    return (remainingSeconds - elapsed).clamp(0, maxSeconds);
  }

  /// Generates URI for launching a Focus Clock session from Sadar
  static Uri buildFocusClockUri(FocusSessionRequest request) {
    return Uri(
      scheme: schemeFocusClock,
      host: 'timer',
      queryParameters: {
        'version': version,
        'habitId': request.habitId.toString(),
        'title': request.title,
        'minutes': request.targetMinutes.toString(),
        'timestamp': request.requestedAt.millisecondsSinceEpoch.toString(),
        'callback': request.callbackUrl ?? 'sadar://completed',
      },
    );
  }

  /// Parses an incoming Focus Clock URI
  static FocusSessionRequest? parseFocusClockUri(Uri uri) {
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return _parseWebFocusClockUri(uri);
    }
    if (uri.scheme != schemeFocusClock || uri.host != 'timer') return null;
    if (uri.queryParameters['version'] != version) return null;
    final habitId = int.tryParse(uri.queryParameters['habitId'] ?? '');
    final title = uri.queryParameters['title'] ?? '';
    final minutes = int.tryParse(
      uri.queryParameters['minutes'] ?? uri.queryParameters['duration'] ?? '',
    );
    final ts = int.tryParse(uri.queryParameters['timestamp'] ?? '');
    final callback = uri.queryParameters['callback'];
    final callbackUri = callback == null ? null : Uri.tryParse(callback);

    if (habitId == null || habitId <= 0 || title.trim().isEmpty) {
      return null;
    }
    if (minutes == null || minutes < 1 || minutes > 720 || ts == null) {
      return null;
    }
    if (callbackUri == null ||
        callbackUri.scheme != schemeSadar ||
        callbackUri.host != 'completed') {
      return null;
    }

    return FocusSessionRequest(
      habitId: habitId,
      title: title,
      targetMinutes: minutes,
      requestedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      callbackUrl: callbackUri.toString(),
    );
  }

  static FocusSessionRequest? _parseWebFocusClockUri(Uri uri) {
    if (uri.queryParameters['autoStart'] != 'true') return null;
    final title = (uri.queryParameters['task'] ?? '').trim();
    final minutes = int.tryParse(uri.queryParameters['duration'] ?? '');
    final habitIdValue = uri.queryParameters['habitId'];
    final habitId = habitIdValue == null ? 0 : int.tryParse(habitIdValue);
    final callbackUrl = uri.queryParameters['callback'];
    final sourceHabitKey = uri.queryParameters['habitKey'];
    final sourceSessionId = uri.queryParameters['sessionId'];
    final startedAtValue =
        uri.queryParameters['startedAt'] ?? uri.queryParameters['timestamp'];
    final startedAtTimestamp = int.tryParse(startedAtValue ?? '');
    final remainingValue = uri.queryParameters['remaining'];
    final sourceRemainingSeconds = remainingValue == null
        ? null
        : int.tryParse(remainingValue);
    final remainingAtValue = uri.queryParameters['savedAt'];
    final remainingAtTimestamp = int.tryParse(remainingAtValue ?? '');
    final pausedValue = uri.queryParameters['paused'];
    final sourcePaused = pausedValue == null
        ? null
        : pausedValue == 'true'
        ? true
        : pausedValue == 'false'
        ? false
        : null;

    if (title.isEmpty || minutes == null || minutes < 1 || minutes > 720) {
      return null;
    }
    if (startedAtTimestamp != null &&
        startedAtTimestamp >
            DateTime.now()
                .add(const Duration(minutes: 5))
                .millisecondsSinceEpoch) {
      return null;
    }
    if ((remainingValue != null && sourceRemainingSeconds == null) ||
        (remainingAtValue != null && remainingAtTimestamp == null) ||
        (remainingAtTimestamp != null &&
            remainingAtTimestamp >
                DateTime.now()
                    .add(const Duration(minutes: 5))
                    .millisecondsSinceEpoch) ||
        (sourceRemainingSeconds != null &&
            (sourceRemainingSeconds < 0 ||
                sourceRemainingSeconds > minutes * 60)) ||
        (pausedValue != null && sourcePaused == null)) {
      return null;
    }
    if (habitId == null || habitId < 0) return null;
    if (callbackUrl != null) {
      final callback = Uri.tryParse(callbackUrl);
      final nativeCallback =
          callback?.scheme == schemeSadar && callback?.host == 'completed';
      final webCallback =
          callback != null && isAllowedSadarWebCallback(callback);
      if (!nativeCallback && !webCallback) {
        return null;
      }
      final sourceHabitKeyIsValid =
          sourceHabitKey == null ||
          RegExp(r'^[A-Za-z0-9._:-]{1,160}$').hasMatch(sourceHabitKey);
      final sourceSessionIdIsValid =
          sourceSessionId != null &&
          RegExp(r'^[A-Za-z0-9._:-]{1,128}$').hasMatch(sourceSessionId);
      if (!sourceHabitKeyIsValid ||
          (webCallback &&
              ((sourceHabitKey == null && habitId <= 0) ||
                  !sourceSessionIdIsValid))) {
        return null;
      }
    }

    return FocusSessionRequest(
      habitId: habitId,
      title: title,
      targetMinutes: minutes,
      requestedAt: startedAtTimestamp == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(startedAtTimestamp),
      callbackUrl: callbackUrl,
      sourceHabitKey: sourceHabitKey,
      sourceSessionId: sourceSessionId,
      sourceRemainingSeconds: sourceRemainingSeconds,
      sourceRemainingAt: remainingAtTimestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(remainingAtTimestamp),
      sourceStartedAt: startedAtTimestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startedAtTimestamp),
      sourcePaused: sourcePaused,
    );
  }

  static bool isAllowedSadarWebCallback(Uri uri) {
    final localHost = uri.host == 'localhost' || uri.host == '127.0.0.1';
    final isLocal = localHost && uri.scheme == 'http';
    final isProduction =
        uri.host == 'sadar-web.vercel.app' &&
        uri.scheme == 'https' &&
        uri.port == 443;
    return (isLocal || isProduction) &&
        uri.userInfo.isEmpty &&
        (uri.path.isEmpty || uri.path == '/') &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty;
  }

  static Uri buildSadarWebCompletedUri({
    required String callbackUrl,
    required String habitKey,
    required FocusSessionResult result,
  }) {
    final callback = Uri.parse(callbackUrl);
    if (!isAllowedSadarWebCallback(callback) ||
        !RegExp(r'^[A-Za-z0-9._:-]{1,160}$').hasMatch(habitKey)) {
      throw ArgumentError('Invalid Sadar web callback.');
    }
    return callback.replace(
      queryParameters: {
        'fc_version': '1',
        'fc_session': result.sessionId,
        'fc_habit': habitKey,
        'fc_started': result.startedAt.millisecondsSinceEpoch.toString(),
        'fc_ended': result.endedAt.millisecondsSinceEpoch.toString(),
        'fc_duration': result.actualDurationMinutes.toString(),
        'fc_status': result.status,
      },
    );
  }

  /// Generates URI for returning completed session data from Focus Clock to Sadar
  static Uri buildSadarCompletedUri(FocusSessionResult result) {
    return Uri(
      scheme: schemeSadar,
      host: 'completed',
      queryParameters: {
        'version': version,
        'sessionId': result.sessionId,
        'habitId': result.habitId.toString(),
        'startedAt': result.startedAt.millisecondsSinceEpoch.toString(),
        'endedAt': result.endedAt.millisecondsSinceEpoch.toString(),
        'duration': result.actualDurationMinutes.toString(),
        'status': result.status,
      },
    );
  }

  /// Parses an incoming Sadar completion URI
  static FocusSessionResult? parseSadarCompletedUri(Uri uri) {
    if (uri.scheme != schemeSadar || uri.host != 'completed') return null;
    if (uri.queryParameters['version'] != version) return null;
    final habitId = int.tryParse(uri.queryParameters['habitId'] ?? '');
    final sessionId = uri.queryParameters['sessionId'] ?? '';
    final startTs = int.tryParse(uri.queryParameters['startedAt'] ?? '');
    final endTs = int.tryParse(uri.queryParameters['endedAt'] ?? '');
    final duration = int.tryParse(uri.queryParameters['duration'] ?? '');
    final status = uri.queryParameters['status'];

    if (habitId == null || habitId <= 0 || sessionId.isEmpty) return null;
    if (startTs == null || endTs == null || endTs < startTs) return null;
    if (duration == null || duration < 0 || duration > 720) return null;
    if (status != 'completed' &&
        status != 'cancelled' &&
        status != 'interrupted') {
      return null;
    }

    return FocusSessionResult(
      sessionId: sessionId,
      habitId: habitId,
      startedAt: DateTime.fromMillisecondsSinceEpoch(startTs),
      endedAt: DateTime.fromMillisecondsSinceEpoch(endTs),
      actualDurationMinutes: duration,
      status: status!,
    );
  }
}
