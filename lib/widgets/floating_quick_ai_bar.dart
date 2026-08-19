import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../services/voice_assistant_service.dart';

class FloatingQuickAiBar extends ConsumerStatefulWidget {
  const FloatingQuickAiBar({super.key});

  @override
  ConsumerState<FloatingQuickAiBar> createState() => _FloatingQuickAiBarState();
}

class _FloatingQuickAiBarState extends ConsumerState<FloatingQuickAiBar> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _isExpanded = false;
  bool _isProcessing = false;
  String? _statusText;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitCommand([String? overrideText]) async {
    final text = (overrideText ?? _textCtrl.text).trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _statusText = 'AI sedang memproses: "$text"...';
    });

    try {
      final voiceService = ref.read(voiceAssistantServiceProvider);
      final response = await voiceService.processVoiceCommand(text);

      setState(() {
        _statusText = response;
      });

      // Auto clear status after 6 seconds
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) {
          setState(() {
            _statusText = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _statusText = 'Gagal: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Status Badge (if AI replied)
        if (_statusText != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: AppPalette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.accent.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppPalette.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusText!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14, color: AppPalette.textDim),
                  onPressed: () => setState(() => _statusText = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

        // Quick Floating Action Pill / Gemini Prompt Ambient Bar
        AnimatedContainer(
          duration: GeminiMotion.medium,
          curve: GeminiMotion.springCurve,
          width: _isExpanded ? 440 : 210,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isExpanded
                  ? AppPalette.accent.withValues(alpha: 0.8)
                  : AppPalette.accent.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.accent.withValues(alpha: 0.20),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Collapsed Toggle / Preset Pill
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPalette.accent,
                            AppPalette.accent.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            _isExpanded ? 'Tutup Prompt' : 'Gemini AI Focus',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isExpanded) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        autofocus: true,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        onSubmitted: (val) => _submitCommand(val),
                        decoration: const InputDecoration(
                          hintText: 'Tulis prompt... e.g. Fokus 25m nulis',
                          hintStyle: TextStyle(color: AppPalette.textDim, fontSize: 11),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic_rounded, size: 18, color: AppPalette.accent),
                      tooltip: 'Suara Input',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final voiceService = ref.read(voiceAssistantServiceProvider);
                        voiceService.startListening();
                      },
                    ),
                    IconButton(
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.accent),
                            )
                          : const Icon(Icons.send_rounded, size: 16, color: AppPalette.accent),
                      onPressed: _isProcessing ? null : () => _submitCommand(),
                    ),
                  ],
                ],
              ),

              // Quick Chips when expanded
              if (_isExpanded) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickChip(
                        label: '⚡ Fokus 25 m',
                        onTap: () => _submitCommand('Buatkan blok fokus 25 menit sekarang'),
                      ),
                      const SizedBox(width: 6),
                      _QuickChip(
                        label: '📅 Rapikan Agenda',
                        onTap: () => _submitCommand('Rapikan jadwal dan hindari konflik waktu'),
                      ),
                      const SizedBox(width: 6),
                      _QuickChip(
                        label: '📊 Insight Hari Ini',
                        onTap: () => _submitCommand('Beri ringkasan produktivitas saya hari ini'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppPalette.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.stroke),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppPalette.textDim, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
