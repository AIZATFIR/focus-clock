import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../services/ai_service.dart';
import '../agenda/agenda_tab.dart';
import '../ai_chat/ai_chat_sheet.dart';
import '../eisenhower/eisenhower_tab.dart';
import '../focusclock/focusclock_tab.dart';
import '../presets/presets_tab.dart';
import '../settings/settings_screen.dart';
import '../weekly_review/weekly_review_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin {
  late final PageController _pc;
  late final TabController _tc;
  bool _showAi = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(tabIndexProvider).clamp(0, 3);
    _pc = PageController(initialPage: initial);
    _tc = TabController(length: 4, vsync: this, initialIndex: initial);
  }

  @override
  void dispose() {
    _pc.dispose();
    _tc.dispose();
    super.dispose();
  }

  void _openAi() => setState(() => _showAi = true);
  void _closeAi() => setState(() => _showAi = false);

  @override
  Widget build(BuildContext context) {
    if (_showAi) return _AiPage(onClose: _closeAi);

    ref.listen<int>(tabIndexProvider, (_, next) {
      final i = next.clamp(0, 3);
      if (_pc.hasClients && _pc.page?.round() != i) {
        _pc.animateToPage(
          i,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
        );
      }
      if (_tc.index != i) _tc.animateTo(i);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'FOCUS',
              style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: 'CLOCK',
              style: TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.accent),
            ),
          ]),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: ActionChip(
              avatar: const Icon(Icons.bar_chart_rounded, size: 16),
              label: const Text('Weekly Review', style: TextStyle(fontSize: 12)),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeeklyReviewScreen()),
              ),
              backgroundColor: AppPalette.accent.withValues(alpha: 0.1),
              side: BorderSide(color: AppPalette.accent.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tc,
          onTap: (i) => ref.read(tabIndexProvider.notifier).state = i,
          indicatorColor: AppPalette.accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppPalette.accent,
          unselectedLabelColor: AppPalette.textDim,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize_outlined, size: 20),
                text: 'Presets', height: 52),
            Tab(icon: Icon(Icons.access_time, size: 20),
                text: 'Clock', height: 52),
            Tab(icon: Icon(Icons.view_agenda_outlined, size: 20),
                text: 'Agenda', height: 52),
            Tab(icon: Icon(Icons.grid_view_rounded, size: 20),
                text: 'Matrix', height: 52),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pc,
              onPageChanged: (i) =>
                  ref.read(tabIndexProvider.notifier).state = i,
              children: const [
                PresetsTab(),
                FocusClockTab(),
                AgendaTab(),
                EisenhowerTab(),
              ],
            ),
          ),
          // Wide AI assistant button
          _WideButton(
            onTap: _openAi,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _ClockDotsIcon(size: 16),
                const SizedBox(width: 8),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.accent,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_up_rounded,
                    size: 17, color: AppPalette.textDim),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI full-screen page ───────────────────────────────────────────────────────

class _AiPage extends ConsumerWidget {
  const _AiPage({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          tooltip: 'Back to Clock',
          onPressed: onClose,
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ClockDotsIcon(size: 18),
            SizedBox(width: 8),
            Text('AI Assistant',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add_comment_outlined, size: 15),
            label:
                const Text('New chat', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AppPalette.textDim),
            onPressed: () {
              ref.read(aiServiceProvider).reset();
              ref.read(aiTranscriptProvider.notifier).state =
                  <ChatMessage>[];
            },
          ),
        ],
      ),
      body: const AiChatPanel(),
    );
  }
}

// ── Shared wide bottom button ─────────────────────────────────────────────────

class _WideButton extends StatefulWidget {
  const _WideButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_WideButton> createState() => _WideButtonState();
}

class _WideButtonState extends State<_WideButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 13, 16, 13 + bottom),
        decoration: BoxDecoration(
          color: _pressed
              ? AppPalette.accent.withValues(alpha: 0.06)
              : AppPalette.card,
          border: const Border(top: BorderSide(color: AppPalette.stroke)),
        ),
        child: widget.child,
      ),
    );
  }
}

// ── Clock-dots icon (mimics analog clock face: outer + inner ring) ────────────

class _ClockDotsIcon extends StatelessWidget {
  const _ClockDotsIcon({this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ClockDotsPainter(),
    );
  }
}

class _ClockDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Outer ring
    canvas.drawCircle(c, r - 0.8,
        Paint()
          ..color = AppPalette.accent.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    // Inner ring
    canvas.drawCircle(c, r * 0.52,
        Paint()
          ..color = AppPalette.accent.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);

    // 4 tick dots at 12/3/6/9
    final dotPaint = Paint()
      ..color = AppPalette.accent
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2) - math.pi / 2;
      final dx = c.dx + (r - 2.5) * math.cos(angle);
      final dy = c.dy + (r - 2.5) * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.1, dotPaint);
    }

    // Center dot
    canvas.drawCircle(c, 1.4,
        Paint()
          ..color = AppPalette.accent
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
