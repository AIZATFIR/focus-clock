import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/voice_assistant_service.dart';

class VoiceAssistantSheet extends ConsumerStatefulWidget {
  const VoiceAssistantSheet({super.key});

  @override
  ConsumerState<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends ConsumerState<VoiceAssistantSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;
  final TextEditingController _voiceInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _voiceInputCtrl.dispose();
    super.dispose();
  }

  void _submitVoiceCommand(String text) async {
    if (text.trim().isEmpty) return;
    _voiceInputCtrl.clear();
    final service = ref.read(voiceAssistantServiceProvider);
    await service.processVoiceCommand(text);
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(voiceAssistantServiceProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPalette.stroke,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq_rounded, color: AppPalette.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Sekretaris Suara (Presidential Desk)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: service.statusMessage,
            builder: (context, msg, _) {
              return Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppPalette.textDim),
              );
            },
          ),
          const SizedBox(height: 20),

          // Animated Audio Waveform Visualizer
          ValueListenableBuilder<bool>(
            valueListenable: service.isListening,
            builder: (context, listening, _) {
              return GestureDetector(
                onTap: () {
                  if (listening) {
                    service.stopListening();
                  } else {
                    service.startListening();
                  }
                },
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: listening
                        ? AppPalette.accent.withValues(alpha: 0.2)
                        : AppPalette.bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: listening ? AppPalette.accent : AppPalette.stroke,
                      width: 2,
                    ),
                    boxShadow: listening
                        ? [
                            BoxShadow(
                              color: AppPalette.accent.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            )
                          ]
                        : null,
                  ),
                  child: AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (context, child) {
                      final scale = listening ? (1.0 + 0.15 * math.sin(_waveCtrl.value * math.pi)) : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Icon(
                          listening ? Icons.mic : Icons.mic_none_rounded,
                          size: 38,
                          color: listening ? AppPalette.accent : AppPalette.textDim,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Tekan mikrofon di atas atau ketik perintah suara:',
            style: TextStyle(fontSize: 11, color: AppPalette.textDim),
          ),
          const SizedBox(height: 12),

          // Voice Dictation / Command Text Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voiceInputCtrl,
                  onSubmitted: _submitVoiceCommand,
                  decoration: InputDecoration(
                    hintText: 'Contoh: "Timer 15 menit fokus"',
                    hintStyle: const TextStyle(color: AppPalette.textDim, fontSize: 13),
                    filled: true,
                    fillColor: AppPalette.bg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: () => _submitVoiceCommand(_voiceInputCtrl.text),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Presets voice shortcuts
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('⏱️ Timer 15m', style: TextStyle(fontSize: 11)),
                onPressed: () => _submitVoiceCommand('Timer 15 menit'),
              ),
              ActionChip(
                label: const Text('⚡ Timer 30m', style: TextStyle(fontSize: 11)),
                onPressed: () => _submitVoiceCommand('Timer 30 menit'),
              ),
              ActionChip(
                label: const Text('📅 Cek Jadwal', style: TextStyle(fontSize: 11)),
                onPressed: () => _submitVoiceCommand('Apa jadwal saya hari ini?'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
