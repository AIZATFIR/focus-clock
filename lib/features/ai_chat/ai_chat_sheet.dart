import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../services/ai_service.dart';

/// Embeddable chat panel — lives in the pull-up sheet under the Clock tab.
/// Transcript is provider-backed: conversation continues across open/close.
class AiChatPanel extends ConsumerStatefulWidget {
  const AiChatPanel({super.key, this.scrollController});
  final ScrollController? scrollController;

  @override
  ConsumerState<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends ConsumerState<AiChatPanel> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _append(ChatMessage m) {
    ref.read(aiTranscriptProvider.notifier).state = [
      ...ref.read(aiTranscriptProvider),
      m,
    ];
  }

  void _replaceLast(ChatMessage m) {
    final list = [...ref.read(aiTranscriptProvider)];
    if (list.isNotEmpty) list.removeLast();
    list.add(m);
    ref.read(aiTranscriptProvider.notifier).state = list;
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    final settings = ref.read(settingsProvider).valueOrNull;
    final apiKey = settings?.aiApiKey ?? '';
    if (apiKey.isEmpty) {
      _append(ChatMessage(
        role: 'model',
        text:
            '⚠️ API key belum diset. Buka Settings → AI Assistant → masukkan API key.',
      ));
      return;
    }

    _ctrl.clear();
    _append(ChatMessage(role: 'user', text: text));
    _append(ChatMessage(role: 'model', text: '', isLoading: true));
    setState(() => _sending = true);
    _scrollToBottom();

    try {
      final ai = ref.read(aiServiceProvider);
      final reply = await ai.send(text);
      _replaceLast(ChatMessage(role: 'model', text: reply));
    } catch (e) {
      _replaceLast(
          ChatMessage(role: 'model', text: '❌ Error: ${e.toString()}'));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
      _focus.requestFocus();
    }
  }

  void _newChat() {
    ref.read(aiServiceProvider).reset();
    ref.read(aiTranscriptProvider.notifier).state = <ChatMessage>[];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = widget.scrollController;
      if (s != null && s.hasClients) {
        s.animateTo(
          s.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    final messages = ref.watch(aiTranscriptProvider);

    return Column(
      children: [
        // Panel header: title + new session
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Row(
            children: [
              const Text('✨ ', style: TextStyle(fontSize: 16)),
              const Text(
                'AI Assistant',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: messages.isEmpty ? null : _newChat,
                icon: const Icon(Icons.add_comment_outlined, size: 15),
                label: const Text('New chat', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppPalette.textDim,
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: messages.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _Bubble(msg: messages[i]),
                ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + pad),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppPalette.stroke)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Tambah gym jam 7 pagi...',
                    hintStyle: const TextStyle(
                        color: AppPalette.textDim, fontSize: 14),
                    filled: true,
                    fillColor: AppPalette.bg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: _sending
                    ? const SizedBox(
                        width: 44,
                        height: 44,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppPalette.accent),
                        ),
                      )
                    : IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppPalette.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(10),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 20),
                        onPressed: _send,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bubble ─────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppPalette.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 14))),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppPalette.accent.withValues(alpha: 0.15)
                    : AppPalette.bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppPalette.accent.withValues(alpha: 0.3)
                      : AppPalette.stroke,
                  width: 1,
                ),
              ),
              child: msg.isLoading
                  ? const SizedBox(
                      width: 40,
                      height: 16,
                      child: _ThreeDots(),
                    )
                  : Text(
                      msg.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppPalette.text,
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 34),
        ],
      ),
    );
  }
}

// ── Typing indicator ───────────────────────────────────────────────────────

class _ThreeDots extends StatefulWidget {
  const _ThreeDots();

  @override
  State<_ThreeDots> createState() => _ThreeDotsState();
}

class _ThreeDotsState extends State<_ThreeDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_c.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2)
                .clamp(0.3, 1.0);
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppPalette.accent.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text(
              'AI Schedule Assistant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contoh perintah:',
              style: TextStyle(color: AppPalette.textDim, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...const [
              '"Tambah gym jam 6 pagi besok"',
              '"Pindahkan meeting ke jam 3 sore"',
              '"Hapus semua kegiatan hari ini"',
              '"Apa saja jadwal saya hari ini?"',
            ].map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    s,
                    style: const TextStyle(
                        color: AppPalette.accent,
                        fontSize: 13,
                        fontStyle: FontStyle.italic),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
