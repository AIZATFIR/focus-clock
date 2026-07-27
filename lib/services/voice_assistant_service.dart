import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/time_math.dart';
import '../models/activity.dart';
import '../providers/providers.dart';

final voiceAssistantServiceProvider = Provider<VoiceAssistantService>((ref) {
  return VoiceAssistantService(ref);
});

class VoiceAssistantService {
  VoiceAssistantService(this._ref);
  final Ref _ref;

  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  final ValueNotifier<String> recognizedText = ValueNotifier<String>('');
  final ValueNotifier<String> statusMessage = ValueNotifier<String>('Standard Sekretariat Presiden Ready');

  void startListening() {
    isListening.value = true;
    statusMessage.value = 'Sekretaris mendengarkan... Bicara sekarang.';
    recognizedText.value = '';
  }

  void stopListening() {
    isListening.value = false;
  }

  /// Process natural voice string input into action execution or AI command
  Future<String> processVoiceCommand(String text) async {
    isListening.value = false;
    recognizedText.value = text;
    statusMessage.value = 'Memproses perintah: "$text"...';

    final lower = text.toLowerCase().trim();

    // 1. Voice Command: Quick Timer (e.g. "Timer 15 menit", "Fokus 30 menit")
    final timerMatch = RegExp(r'(?:timer|fokus|set timer|mulai)\s+(\d+)\s*(?:menit|min|m)?').firstMatch(lower);
    if (timerMatch != null) {
      final mins = int.tryParse(timerMatch.group(1) ?? '') ?? 15;
      await _startQuickTimer(mins, lower);
      final response = 'Siap Pak/Bu, timer fokus $mins menit telah berhasil diaktifkan!';
      statusMessage.value = response;
      return response;
    }

    // 2. Voice Command: Agenda inquiry (e.g. "Apa kegiatan hari ini", "Jadwal saya")
    if (lower.contains('jadwal') || lower.contains('kegiatan') || lower.contains('agenda')) {
      final now = DateTime.now();
      final acts = await _ref.read(activityRepoProvider).getByDate(dateOnly(now));
      if (acts.isEmpty) {
        final resp = 'Jadwal hari ini masih kosong, Pak/Bu. Anda dapat meminta saya membuatkan Fitrah Blueprint.';
        statusMessage.value = resp;
        return resp;
      } else {
        final summary = acts.map((a) => '${a.title} (${_fmtTime(a.ampmHalf, a.startMinute)})').join(', ');
        final resp = 'Ada ${acts.length} kegiatan hari ini: $summary.';
        statusMessage.value = resp;
        return resp;
      }
    }

    // 3. Fallback to AI Service for complex voice requests
    try {
      final ai = _ref.read(aiServiceProvider);
      final response = await ai.send(text);
      statusMessage.value = response;
      return response;
    } catch (e) {
      final err = 'Gagal memproses perintah suara: ${e.toString()}';
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

    final start24 = is24h ? startMinute : (startMinute + (half == AmPmHalf.pm ? 720 : 0));
    final end24 = is24h ? endMinute : (endMinute + (half == AmPmHalf.pm ? 720 : 0));

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
      ..description = 'Voice command activity created by Voice Assistant.'
      ..recurrence = 'none'
      ..createdAt = now
      ..updatedAt = now;

    await _ref.read(activityRepoProvider).upsert(activity);

    _ref.read(activeTimerTitleProvider.notifier).state = title;
    _ref.read(activeTimerTotalSecondsProvider.notifier).state = minutes * 60;
    _ref.read(activeTimerIsPausedProvider.notifier).state = false;
    _ref.read(activeTimerEndTimeProvider.notifier).state = now.add(Duration(minutes: minutes));
  }

  String _fmtTime(AmPmHalf half, int relMin) {
    final h = (half == AmPmHalf.pm ? 12 : 0) + relMin ~/ 60;
    final m = relMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
