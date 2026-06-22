import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../services/ai_service.dart';

/// Embeddable chat panel — lives in the pull-up sheet under the Clock tab.
/// Transcript is provider-backed: conversation continues across open/close.
class AiChatPanel extends ConsumerStatefulWidget {
  const AiChatPanel({super.key, this.scrollController, this.onExpandSheet});
  final ScrollController? scrollController;
  final VoidCallback? onExpandSheet;

  @override
  ConsumerState<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends ConsumerState<AiChatPanel> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _listCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _listCtrl.dispose();
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
            'Mode AI sedang offline. Silakan masukkan API Key Google Gemini di menu Settings.',
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

  Future<void> _showBlueprintDialog(BuildContext context) async {
    int wakeH = 6;
    int sleepH = 22;
    final goalCtrl = TextEditingController();
    final now = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🌅 Fitrah Blueprint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Generate a psychologically balanced day:\n'
              'Deep Work → Intentional Rest → Active Rest → Sleep.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(builder: (ctx, setS) => Column(
              children: [
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wake up', style: TextStyle(fontSize: 12)),
                      Slider(
                        value: wakeH.toDouble(),
                        min: 3, max: 10, divisions: 7,
                        label: '${wakeH.toString().padLeft(2, '0')}:00',
                        activeColor: AppPalette.accent,
                        onChanged: (v) => setS(() => wakeH = v.toInt()),
                      ),
                    ],
                  )),
                  Text('${wakeH.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sleep at', style: TextStyle(fontSize: 12)),
                      Slider(
                        value: sleepH.toDouble(),
                        min: 19, max: 26, divisions: 7,
                        label: '${(sleepH % 24).toString().padLeft(2, '0')}:00',
                        activeColor: AppPalette.accent,
                        onChanged: (v) => setS(() => sleepH = v.toInt()),
                      ),
                    ],
                  )),
                  Text('${(sleepH % 24).toString().padLeft(2, '0')}:00',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ],
            )),
            TextField(
              controller: goalCtrl,
              decoration: const InputDecoration(
                labelText: 'Goals (comma separated)',
                hintText: 'e.g. Math study, Gym, Project',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final goals = goalCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final dateStr =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              final goalsStr =
                  goals.isEmpty ? '' : ' Goals: ${goals.join(', ')}.';
              _ctrl.text =
                  'Generate Fitrah Blueprint for today ($dateStr). '
                  'Wake: ${wakeH.toString().padLeft(2, '0')}:00, '
                  'Sleep: ${(sleepH % 24).toString().padLeft(2, '0')}:00.$goalsStr';
              _send();
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    goalCtrl.dispose();
  }

  void _scrollToBottom() {
    // Expand the sheet first so the list has room, then scroll to bottom.
    widget.onExpandSheet?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listCtrl.hasClients) {
        _listCtrl.animateTo(
          _listCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
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
        // Panel header: title + blueprint + new session
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppPalette.accent),
              const SizedBox(width: 8),
              const Text(
                'AI Assistant',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Fitrah Blueprint quick launch
              Tooltip(
                message: 'Generate Fitrah Blueprint',
                child: IconButton(
                  onPressed: () => _showBlueprintDialog(context),
                  icon: const Icon(Icons.psychology, size: 20, color: AppPalette.accent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
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
                  controller: _listCtrl,
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
                  child: Icon(Icons.auto_awesome, size: 14, color: AppPalette.accent)),
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
                  : MarkdownBody(
                      data: msg.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 14, color: AppPalette.text),
                        strong: const TextStyle(fontWeight: FontWeight.w600, color: AppPalette.text),
                        em: const TextStyle(fontStyle: FontStyle.italic, color: AppPalette.text),
                        listBullet: const TextStyle(color: AppPalette.text),
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
      builder: (context, child) {
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
            const Icon(Icons.auto_awesome, size: 48, color: AppPalette.accent),
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
