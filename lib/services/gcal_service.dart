import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

import '../core/time_math.dart';
import '../models/activity.dart';

/// Whether GCal sign-in is supported on this platform.
bool get gcalSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

class GCalService {
  static final GCalService _instance = GCalService._();
  factory GCalService() => _instance;
  GCalService._();

  final GoogleSignIn _signIn = GoogleSignIn(
    scopes: [gcal.CalendarApi.calendarScope],
  );

  GoogleSignInAccount? _account;

  bool get isSignedIn => _account != null;

  Future<bool> signIn() async {
    if (!gcalSupported) return false;
    try {
      _account = await _signIn.signIn();
      return _account != null;
    } catch (e) {
      debugPrint('GCal signIn error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    if (!gcalSupported) return;
    await _signIn.signOut();
    _account = null;
  }

  Future<void> restoreSilent() async {
    if (!gcalSupported) return;
    try {
      _account = await _signIn.signInSilently();
    } catch (_) {}
  }

  /// Push a single Activity to Google Calendar primary.
  /// Returns the created event id, or null on failure.
  Future<String?> pushActivity(Activity a) async {
    if (!gcalSupported || _account == null) return null;
    try {
      final headers = await _account!.authHeaders;
      final client = _AuthClient(headers);
      final api = gcal.CalendarApi(client);

      final startDt = toDateTime(a.date, a.ampmHalf, a.startMinute);
      final endDt = toDateTime(a.date, a.ampmHalf, a.endMinute);

      final event = gcal.Event(
        summary: a.title,
        description: a.description.isEmpty ? null : a.description,
        start: gcal.EventDateTime(
          dateTime: startDt,
          timeZone: DateTime.now().timeZoneName,
        ),
        end: gcal.EventDateTime(
          dateTime: endDt,
          timeZone: DateTime.now().timeZoneName,
        ),
      );

      final created =
          await api.events.insert(event, 'primary');
      client.close();
      return created.id;
    } catch (e) {
      debugPrint('GCal pushActivity error: $e');
      return null;
    }
  }

  /// Delete a GCal event by id.
  Future<void> deleteEvent(String eventId) async {
    if (!gcalSupported || _account == null) return;
    try {
      final headers = await _account!.authHeaders;
      final client = _AuthClient(headers);
      final api = gcal.CalendarApi(client);
      await api.events.delete('primary', eventId);
      client.close();
    } catch (e) {
      debugPrint('GCal deleteEvent error: $e');
    }
  }

  /// Pull today's events from GCal primary and return as raw maps.
  Future<List<gcal.Event>> fetchToday() async {
    if (!gcalSupported || _account == null) return [];
    try {
      final headers = await _account!.authHeaders;
      final client = _AuthClient(headers);
      final api = gcal.CalendarApi(client);
      final today = dateOnly(DateTime.now());
      final tomorrow = today.add(const Duration(days: 1));
      final list = await api.events.list(
        'primary',
        timeMin: today,
        timeMax: tomorrow,
        singleEvents: true,
        orderBy: 'startTime',
      );
      client.close();
      return list.items ?? [];
    } catch (e) {
      debugPrint('GCal fetchToday error: $e');
      return [];
    }
  }
}

/// Minimal http.BaseClient that injects Google auth headers.
class _AuthClient extends http.BaseClient {
  _AuthClient(this._headers);
  final Map<String, String> _headers;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
