import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/time_math.dart';
import '../models/activity.dart';
import '../providers/providers.dart';
import 'secure_storage_service.dart';

final voiceAssistantServiceProvider = Provider<VoiceAssistantService>((ref) {
  return VoiceAssistantService(ref);
});

class VoiceAssistantService {
  VoiceAssistantService(this._ref) {
    _initTts();
  }

  final Ref _ref;

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  final ValueNotifier<String> recognizedText = ValueNotifier<String>('');
  final ValueNotifier<String> statusMessage =
      ValueNotifier<String>('Sekretaris Waktu Aura Siap Mendampingi');

  bool _speechInitialized = false;

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.1); // Warm, friendly pitch for Aura
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        isSpeaking.value = true;
      });

      _tts.setCompletionHandler(() {
        isSpeaking.value = false;
      });

      _tts.setErrorHandler((msg) {
        isSpeaking.value = false;
      });
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  /// Speak response text using Aura's voice
  Future<void> speak(String text) async {
    final enabled = await _ref.read(secureStorageServiceProvider).isVoiceEnabled();
    if (!enabled || text.trim().isEmpty) return;

    try {
      await _tts.stop();
      // Clean markdown tags for cleaner speech
      final cleanText = text
          .replaceAll(RegExp(r'[*#_~`]'), '')
          .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '')
          .trim();
      if (cleanText.isNotEmpty) {
        await _tts.speak(cleanText);
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Stop current TTS speech output
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      isSpeaking.value = false;
    } catch (_) {}
  }

  /// Start microphone listening (Speech-to-Text)
  Future<void> startListening({Function(String text)? onResult}) async {
    if (isListening.value) return;

    try {
      if (!_speechInitialized) {
        _speechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              isListening.value = false;
            }
          },
          onError: (errorNotification) {
            isListening.value = false;
            statusMessage.value = 'Mikrofon: ${errorNotification.errorMsg}';
          },
        );
      }

      if (_speechInitialized) {
        isListening.value = true;
        recognizedText.value = '';
        statusMessage.value = 'Aura mendengarkan... Bicara sekarang.';

        await _speech.listen(
          onResult: (result) {
            recognizedText.value = result.recognizedWords;
            if (onResult != null) {
              onResult(result.recognizedWords);
            }
          },
          listenOptions: stt.SpeechListenOptions(localeId: 'id_ID'),
        );
      } else {
        statusMessage.value = 'Perangkat mikrofon tidak tersedia. Silakan ketik perintah.';
        isListening.value = false;
      }
    } catch (e) {
      isListening.value = false;
      statusMessage.value = 'Gagal membuka mikrofon: ${e.toString()}';
    }
  }

  /// Stop microphone listening
  Future<void> stopListening() async {
    if (!isListening.value) return;
    try {
      await _speech.stop();
    } catch (_) {}
    isListening.value = false;
  }

  /// Process natural voice string input into action execution or AI command
  Future<String> processVoiceCommand(String text) async {
    await stopListening();
    await stopSpeaking();

    recognizedText.value = text;
    statusMessage.value = 'Aura memproses: "$text"...';

    final lower = text.toLowerCase().trim();

    // 1. Voice Command: Quick Timer (e.g. "Timer 15 menit", "Fokus 30 menit")
    final timerMatch =
        RegExp(r'(?:timer|fokus|set timer|mulai)\s+(\d+)\s*(?:menit|min|m)?')
            .firstMatch(lower);
    if (timerMatch != null) {
      final mins = int.tryParse(timerMatch.group(1) ?? '') ?? 15;
      await _startQuickTimer(mins, lower);
      final response =
          'Siap Pak/Bu, timer fokus $mins menit telah berhasil diaktifkan!';
      statusMessage.value = response;
      await speak(response);
      return response;
    }

    // 2. Voice Command: Agenda inquiry (e.g. "Apa kegiatan hari ini", "Jadwal saya")
    if (lower.contains('jadwal') ||
        lower.contains('kegiatan') ||
        lower.contains('agenda')) {
      final now = DateTime.now();
      final acts =
          await _ref.read(activityRepoProvider).getByDate(dateOnly(now));
      if (acts.isEmpty) {
        final resp =
            'Jadwal hari ini masih kosong, Pak/Bu. Anda dapat meminta saya membuatkan Fitrah Blueprint.';
        statusMessage.value = resp;
        await speak(resp);
        return resp;
      } else {
        final summary = acts
            .map((a) => '${a.title} (${_fmtTime(a.ampmHalf, a.startMinute)})')
            .join(', ');
        final resp = 'Ada ${acts.length} kegiatan hari ini: $summary.';
        statusMessage.value = resp;
        await speak(resp);
        return resp;
      }
    }

    // 3. Complex voice requests -> AI Service Aura
    try {
      final ai = _ref.read(aiServiceProvider);
      final response = await ai.send(text);
      statusMessage.value = response;
      await speak(response);
      return response;
    } catch (e) {
      final err = 'Aura mengalami masalah: ${e.toString()}';
      statusMessage.value = err;
      return err;
    }
  }

  Future<void> _startQuickTimer(int minutes, String rawInput) async {
    final now = DateTime.now();
    final date = dateOnly(now);
    final is24h = _ref.read(settingsProvider).valueOrNull?.is24hDial ?? false;
    final half = halfOfNow(now);

    final startMinute = now.hour * 60 + now.minute;
    final endMinute = (startMinute + minutes).clamp(0, 1440);

    final start24 =
        is24h ? startMinute : (startMinute + (half == AmPmHalf.pm ? 720 : 0));
    final end24 =
        is24h ? endMinute : (endMinute + (half == AmPmHalf.pm ? 720 : 0));

    final dbHalf = toDbHalf(start24);
    final dbStart = toDbMinute(start24);
    final dbEnd = toDbEndMinute(end24, dbHalf);

    final title = '$minutes Min Focus ($rawInput)';

    final activity = Activity()
      ..title = title
      ..iconKey = '🎙️'
      ..startMinute = dbStart
      ..endMinute = dbEnd
      ..ampmHalf = dbHalf
      ..date = date
      ..description = 'Voice command activity created by Aura AI Secretary.'
      ..recurrence = 'none'
      ..createdAt = now
      ..updatedAt = now;

    await _ref.read(activityRepoProvider).upsert(activity);

    _ref.read(activeTimerTitleProvider.notifier).state = title;
    _ref.read(activeTimerTotalSecondsProvider.notifier).state = minutes * 60;
    _ref.read(activeTimerIsPausedProvider.notifier).state = false;
    _ref.read(activeTimerEndTimeProvider.notifier).state =
        now.add(Duration(minutes: minutes));
  }

  String _fmtTime(AmPmHalf half, int relMin) {
    final h = (half == AmPmHalf.pm ? 12 : 0) + relMin ~/ 60;
    final m = relMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
