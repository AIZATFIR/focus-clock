import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../services/voice_assistant_service.dart';

class StorytellingSheet extends ConsumerStatefulWidget {
  const StorytellingSheet({super.key});

  @override
  ConsumerState<StorytellingSheet> createState() => _StorytellingSheetState();
}

class _StorytellingSheetState extends ConsumerState<StorytellingSheet> {
  final TextEditingController _storyCtrl = TextEditingController();
  bool _isEveningMode = true; // true = Malam (Refleksi), false = Pagi (Niat)
  bool _isProcessing = false;
  String? _aiFeedback;

  @override
  void dispose() {
    _storyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitStory() async {
    final text = _storyCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _aiFeedback = null;
    });

    try {
      final prompt = _isEveningMode
          ? 'Refleksi Malam Hari & Cerita Hari Ini:\n"$text"\n\nMohon berikan refleksi bermakna yang memberikan apresiasi atas energi kreatif yang telah dicurahkan hari ini, serta usulkan 1-3 langkah niat untuk besok.'
          : 'Niat Pagi Hari & Energi Kreatif:\n"$text"\n\nMohon berikan dorongan bermakna untuk mengarahkan energi kreatif hari ini agar tidak terbuang sia-sia, serta bantu buatkan alokasi waktu fokus utamanya.';

      final ai = ref.read(aiServiceProvider);
      final response = await ai.send(prompt);

      setState(() {
        _aiFeedback = response;
      });
      _storyCtrl.clear();
    } catch (e) {
      setState(() {
        _aiFeedback = 'Gagal memproses cerita: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 620),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppPalette.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEveningMode ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  color: AppPalette.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEveningMode ? 'Refleksi Malam: Talking About Your Day' : 'Niat Pagi: Seize The Day',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Salurkan energi kreatifmu & beri makna pada setiap langkah.',
                      style: TextStyle(fontSize: 11, color: AppPalette.textDim),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppPalette.textDim),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mode Selector Switch
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppPalette.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isEveningMode = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isEveningMode ? AppPalette.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          '🌙 Cerita Malam Ini',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isEveningMode ? Colors.black : AppPalette.textDim,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isEveningMode = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isEveningMode ? AppPalette.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          '☀️ Niat Pagi Hari',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !_isEveningMode ? Colors.black : AppPalette.textDim,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Input field for storytelling
          TextField(
            controller: _storyCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: _isEveningMode
                  ? 'Ceritakan tentang harimu... Apa yang sudah kamu capai? Apa yang ingin kamu tuntaskan besok agar pikiranmu tenang?'
                  : 'Apa target utama hari ini? Ke mana kamu ingin menyalurkan energi kreatifmu agar hari ini bermakna?',
              hintStyle: const TextStyle(color: AppPalette.textDim, fontSize: 12),
              filled: true,
              fillColor: AppPalette.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppPalette.stroke),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action Row
          Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppPalette.bg,
                  side: const BorderSide(color: AppPalette.stroke),
                ),
                icon: const Icon(Icons.mic_rounded, color: AppPalette.accent, size: 20),
                tooltip: 'Bicara Langsung',
                onPressed: () {
                  final service = ref.read(voiceAssistantServiceProvider);
                  service.startListening();
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessing ? null : _submitStory,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isProcessing ? 'Merenung...' : 'Kirim & Beri Makna',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          if (_aiFeedback != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppPalette.stroke),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppPalette.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppPalette.accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _aiFeedback!,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
