import 'package:web/web.dart' as web;
import 'dart:convert';

void clearWebLaunchUrlQuery() {
  final location = web.window.location;
  web.window.history.replaceState(
    null,
    '',
    '${location.pathname}${location.hash}',
  );
}

void returnToSadar(String callbackUrl) {
  web.window.location.replace(callbackUrl);
}

String? readWebFocusSessionState(String sessionId) =>
    _readStoredSession(sessionId);

String? _readStoredSession(String sessionId) {
  try {
    return web.window.sessionStorage.getItem('focus-clock:$sessionId');
  } catch (_) {
    return null;
  }
}

void writeWebFocusSessionState(String sessionId, String state) {
  try {
    web.window.sessionStorage.setItem('focus-clock:$sessionId', state);
  } catch (_) {
    // Some embedded browsers disable Web Storage; the URL remains a fallback.
  }

  final current = Uri.parse(web.window.location.href);
  if (current.queryParameters['sessionId'] != sessionId) return;
  final progress = jsonDecode(state) as Map<String, dynamic>;
  final next = current.replace(
    queryParameters: {
      ...current.queryParameters,
      'startedAt': progress['startedAt'].toString(),
      'remaining': progress['remainingSeconds'].toString(),
      'paused': progress['isPaused'].toString(),
    },
  );
  web.window.history.replaceState(null, '', _relativeUrl(next));
}

void clearWebFocusSessionState(String sessionId) {
  try {
    web.window.sessionStorage.removeItem('focus-clock:$sessionId');
  } catch (_) {
    // URL state is still cleared below.
  }

  final current = Uri.parse(web.window.location.href);
  if (current.queryParameters['sessionId'] != sessionId) return;
  final params = {...current.queryParameters}
    ..remove('startedAt')
    ..remove('remaining')
    ..remove('paused');
  web.window.history.replaceState(
    null,
    '',
    _relativeUrl(current.replace(queryParameters: params)),
  );
}

String _relativeUrl(Uri uri) =>
    '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}${uri.hasFragment ? '#${uri.fragment}' : ''}';
