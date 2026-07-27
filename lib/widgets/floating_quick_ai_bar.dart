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

        // Quick Floating Action Pill / Input Bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _isExpanded ? 380 : 160,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPalette.accent.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppPalette.accent.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Collapsed Toggle / Preset Pill
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isExpanded = !_isExpanded);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppPalette.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.black),
                      const SizedBox(width: 6),
                      Text(
                        _isExpanded ? 'Tutup' : 'P info...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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
                    style: const TextStyle(fontSize: 12),
                    onSubmitted: (val) => _submitCommand(val),
                    decoration: const InputDecoration(
                      hintText: 'misal: lanjut ngoding, jam 4 baca buku',
                      hintStyle: TextStyle(color: AppPalette.textDim, fontSize: 11),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic_rounded, size: 18, color: AppPalette.accent),
                  tooltip: 'Voice Input',
                  onPressed: () {
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
        ),
      ],
    );
  }
}
