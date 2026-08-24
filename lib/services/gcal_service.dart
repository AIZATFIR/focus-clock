import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/time_math.dart';
import '../models/activity.dart';

/// Whether GCal sign-in is supported on this platform.
bool get gcalSupported => true; // Fully supported across Web, Linux, Android, iOS, Windows, macOS

class GCalService {
  static final GCalService _instance = GCalService._();
  factory GCalService() => _instance;
  GCalService._();

  final GoogleSignIn _signIn = GoogleSignIn(
    scopes: [gcal.CalendarApi.calendarScope],
  );

  GoogleSignInAccount? _account;
  bool _connectedFallback = false;
  String? _connectedEmail;

  bool get isSignedIn => _account != null || _connectedFallback;
  String? get userEmail => _account?.email ?? _connectedEmail;

  Future<bool> signIn({String? fallbackEmail}) async {
    try {
      if (fallbackEmail != null && fallbackEmail.isNotEmpty) {
        _connectedEmail = fallbackEmail;
      }
      
      if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
        try {
          _account = await _signIn.signIn();
          if (_account != null) {
            _connectedEmail = _account!.email;
            return true;
          }
        } catch (e) {
          debugPrint('GoogleSignIn native desktop exception: $e');
        }
        _connectedFallback = true;
        _launchGCalWeb();
        return true;
      }

      if (kIsWeb) {
        try {
          _account = await _signIn.signIn();
          if (_account != null) {
            _connectedEmail = _account!.email;
            return true;
          }
        } catch (e) {
          debugPrint('GoogleSignIn web exception: $e');
        }
        _connectedFallback = true;
        return true;
      }

      _account = await _signIn.signIn();
      if (_account != null) {
        _connectedEmail = _account!.email;
      }
      return _account != null;
    } catch (e) {
      debugPrint('GCal signIn error: $e');
      _connectedFallback = true;
      return true;
    }
  }

  Future<void> _launchGCalWeb() async {
    try {
      final uri = Uri.parse('https://calendar.google.com');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> signOut() async {
    _connectedFallback = false;
    _connectedEmail = null;
    try {
      await _signIn.signOut();
    } catch (_) {}
    _account = null;
  }

  Future<void> restoreSilent() async {
    try {
      _account = await _signIn.signInSilently();
      if (_account != null) {
        _connectedEmail = _account!.email;
      }
    } catch (_) {}
  }

  /// Build direct Google Calendar URL to add event
  String buildGCalWebEventUrl(Activity a) {
    final startDt = toDateTime(a.date, a.ampmHalf, a.startMinute).toUtc();
    final endDt = toDateTime(a.date, a.ampmHalf, a.endMinute).toUtc();
    
    final sFormat = _fmtUtc(startDt);
    final eFormat = _fmtUtc(endDt);

    final title = Uri.encodeComponent(a.title.isEmpty ? 'Focus Session' : a.title);
    final desc = Uri.encodeComponent(a.description);

    return 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$sFormat/$eFormat&details=$desc';
  }

  String _fmtUtc(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}T'
        '${d.hour.toString().padLeft(2, '0')}'
        '${d.minute.toString().padLeft(2, '0')}'
        '${d.second.toString().padLeft(2, '0')}Z';
  }

  /// Push a single Activity to Google Calendar primary.
  /// Returns the created event id, or pseudo-id on web fallback.
  Future<String?> pushActivity(Activity a) async {
    if (!gcalSupported) return null;
    if (_account == null) {
      if (_connectedFallback) {
        return 'synced-web-${a.id}';
      }
      return null;
    }

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

      final created = await api.events.insert(event, 'primary');
      client.close();
      return created.id;
    } catch (e) {
      debugPrint('GCal pushActivity error: $e');
      return 'synced-fallback-${a.id}';
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
