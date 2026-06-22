import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../agenda/agenda_tab.dart';
import '../ai_chat/ai_chat_sheet.dart';
import '../focusclock/focusclock_tab.dart';
import '../presets/presets_tab.dart';
import '../settings/settings_screen.dart';
import 'left_panel.dart';
import 'right_panel.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with TickerProviderStateMixin {
  late final PageController _pc;
  late final TabController _tc;
  bool _showAi = false;
  bool _leftExpanded = true;
  bool _rightExpanded = true;

  late final AnimationController _aiAnim;
  late final FocusNode _shellFocusNode;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(tabIndexProvider).clamp(0, 2);
    _pc = PageController(initialPage: initial);
    _tc = TabController(length: 3, vsync: this, initialIndex: initial);
    _aiAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shellFocusNode = FocusNode(debugLabel: 'HomeShellFocusNode');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _shellFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _shellFocusNode.dispose();
    _aiAnim.dispose();
    _pc.dispose();
    _tc.dispose();
    super.dispose();
  }

  void _openAi() {
    setState(() => _showAi = true);
    _aiAnim.forward();
  }

  void _closeAi() async {
    await _aiAnim.reverse();
    if (mounted) setState(() => _showAi = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(tabIndexProvider, (_, next) {
      final i = next.clamp(0, 2);
      if (_pc.hasClients && _pc.page?.round() != i) {
        _pc.animateToPage(
          i,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
        );
      }
      if (_tc.index != i) _tc.animateTo(i);
    });

    final isPlanning = ref.watch(planningModeProvider);
    final isClockDragging = ref.watch(isClockDraggingProvider);

    final enableAi = isPlanning ? false : ref.watch(settingsProvider.select((s) => s.valueOrNull?.enableAiAssistant ?? true));
    final enableLeft = ref.watch(settingsProvider.select((s) => s.valueOrNull?.enableLeftPanel ?? true));
    final enableRight = isPlanning ? false : ref.watch(settingsProvider.select((s) => s.valueOrNull?.enableRightPanel ?? true));

    final settings = ref.watch(settingsProvider).valueOrNull;
    final keyLeftPanel = settings?.keyLeftPanel ?? 'B';
    final keyRightPanel = settings?.keyRightPanel ?? 'E';
    final keyAiChat = settings?.keyAiChat ?? 'A';
    final keyPrecisionMode = settings?.keyPrecisionMode ?? 'P';
    final keyPlanningMode = settings?.keyPlanningMode ?? 'J';

    const leftWidth = 380.0;
    const rightWidth = 360.0;

    Widget mainContent;
    if (isPlanning) {
      mainContent = const Scaffold(
        backgroundColor: AppPalette.bg,
        body: FocusClockTab(),
      );
    } else {
      mainContent = Scaffold(
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
            ],
          ),
        ),
        body: Stack(
          children: [
            // Middle Row layout containing Left Panel, PageView, Right Panel
            Positioned.fill(
              child: Row(
                children: [
                  // Left Panel
                  if (MediaQuery.of(context).size.width >= 900 && enableLeft)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        width: _leftExpanded ? leftWidth : 0,
                        child: _leftExpanded
                            ? Container(
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(2, 0)),
                                  ],
                                ),
                                child: LeftPanel(onClose: () => setState(() => _leftExpanded = false)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  
                  // Central PageView
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _pc,
                            physics: isClockDragging
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            onPageChanged: (i) =>
                                ref.read(tabIndexProvider.notifier).state = i,
                            children: const [
                              PresetsTab(),
                              FocusClockTab(),
                              AgendaTab(),
                            ],
                          ),
                        ),
                        if (enableAi)
                          _HoverEdgeButton(
                            isVertical: false,
                            alignment: Alignment.center,
                            isExpanded: _showAi,
                            onTap: () {
                              if (_showAi) {
                                _closeAi();
                              } else {
                                _openAi();
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  // Right Panel
                  if (MediaQuery.of(context).size.width >= 900 && enableRight)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        width: _rightExpanded ? rightWidth : 0,
                        child: _rightExpanded
                            ? Container(
                                decoration: const BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(-2, 0)),
                                  ],
                                ),
                                child: RightPanel(onClose: () => setState(() => _rightExpanded = false)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
            
            // Left Panel Toggle
            if (MediaQuery.of(context).size.width >= 900 && enableLeft)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _leftExpanded ? leftWidth : 0,
                top: 0,
                bottom: 0,
                width: 24,
                child: _HoverEdgeButton(
                  isVertical: true,
                  alignment: Alignment.center,
                  isExpanded: _leftExpanded,
                  onTap: () => setState(() => _leftExpanded = !_leftExpanded),
                ),
              ),
            
            // Right Panel Toggle
            if (MediaQuery.of(context).size.width >= 900 && enableRight)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                right: _rightExpanded ? rightWidth : 0,
                top: 0,
                bottom: 0,
                width: 24,
                child: _HoverEdgeButton(
                  isVertical: true,
                  alignment: Alignment.center,
                  isExpanded: _rightExpanded,
                  onTap: () => setState(() => _rightExpanded = !_rightExpanded),
                ),
              ),
            
            if (_showAi || _aiAnim.isAnimating)
              AnimatedBuilder(
                animation: _aiAnim,
                builder: (context, child) {
                  return FractionalTranslation(
                    translation: Offset(0, 1.0 - _aiAnim.value),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: AppPalette.accent.withValues(alpha: 0.3), width: 1.5)),
                        ),
                        child: _AiPage(onClose: _closeAi),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    return Focus(
      focusNode: _shellFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isControlPressed = HardwareKeyboard.instance.isControlPressed;
          final isAltPressed = HardwareKeyboard.instance.isAltPressed;
          
          final String pressedKey = event.logicalKey.keyLabel.toUpperCase();
          
          if (isControlPressed) {
            if (pressedKey == keyLeftPanel.toUpperCase() || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (enableLeft) {
                setState(() => _leftExpanded = !_leftExpanded);
                HapticFeedback.lightImpact();
                return KeyEventResult.handled;
              }
            } else if (pressedKey == keyRightPanel.toUpperCase() || event.logicalKey == LogicalKeyboardKey.arrowRight) {
              if (enableRight) {
                setState(() => _rightExpanded = !_rightExpanded);
                HapticFeedback.lightImpact();
                return KeyEventResult.handled;
              }
            } else if (pressedKey == keyAiChat.toUpperCase() || event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (enableAi) {
                if (_showAi) {
                  _closeAi();
                } else {
                  _openAi();
                }
                HapticFeedback.lightImpact();
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (enableAi && _showAi) {
                _closeAi();
                HapticFeedback.lightImpact();
                return KeyEventResult.handled;
              }
            } else if (pressedKey == keyPrecisionMode.toUpperCase()) {
              ref.read(precisionModeProvider.notifier).update((state) => !state);
              HapticFeedback.lightImpact();
              return KeyEventResult.handled;
            } else if (pressedKey == keyPlanningMode.toUpperCase()) {
              ref.read(planningModeProvider.notifier).update((state) => !state);
              HapticFeedback.lightImpact();
              return KeyEventResult.handled;
            }
          } else if (isAltPressed) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              final cur = ref.read(tabIndexProvider);
              if (cur > 0) {
                ref.read(tabIndexProvider.notifier).state = cur - 1;
                HapticFeedback.lightImpact();
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              final cur = ref.read(tabIndexProvider);
              if (cur < 2) {
                ref.read(tabIndexProvider.notifier).state = cur + 1;
                HapticFeedback.lightImpact();
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              // Cycle interval down (15 -> 30 -> 60 -> 120 -> 180)
              final list = const [15, 30, 60, 120, 180];
              final cur = ref.read(instantIntervalProvider);
              final idx = list.indexOf(cur);
              if (idx != -1) {
                final nextIdx = (idx + 1) % list.length;
                ref.read(instantIntervalProvider.notifier).state = list[nextIdx];
                HapticFeedback.lightImpact();
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              // Cycle interval up (180 -> 120 -> 60 -> 30 -> 15)
              final list = const [15, 30, 60, 120, 180];
              final cur = ref.read(instantIntervalProvider);
              final idx = list.indexOf(cur);
              if (idx != -1) {
                final nextIdx = (idx - 1 + list.length) % list.length;
                ref.read(instantIntervalProvider.notifier).state = list[nextIdx];
                HapticFeedback.lightImpact();
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit1) {
              ref.read(instantIntervalProvider.notifier).state = 15;
              HapticFeedback.lightImpact();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
              ref.read(instantIntervalProvider.notifier).state = 30;
              HapticFeedback.lightImpact();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
              ref.read(instantIntervalProvider.notifier).state = 60;
              HapticFeedback.lightImpact();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
              ref.read(instantIntervalProvider.notifier).state = 120;
              HapticFeedback.lightImpact();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
              ref.read(instantIntervalProvider.notifier).state = 180;
              HapticFeedback.lightImpact();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          if (!_shellFocusNode.hasFocus) {
            _shellFocusNode.requestFocus();
          }
        },
        child: mainContent,
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
      backgroundColor: AppPalette.bg,
      body: Column(
        children: [
          GestureDetector(
            onTap: onClose,
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 3) onClose();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 32, bottom: 12),
              color: AppPalette.card,
              child: Column(
                children: [
                  const Icon(Icons.drag_handle_rounded, color: AppPalette.textDim, size: 28),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppPalette.accent),
                      const SizedBox(width: 8),
                      const Text('AI Assistant',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: AiChatPanel()),
        ],
      ),
    );
  }
}

class _HoverEdgeButton extends StatefulWidget {
  const _HoverEdgeButton({
    required this.isVertical,
    required this.alignment,
    required this.onTap,
    required this.isExpanded,
  });

  final bool isVertical;
  final Alignment alignment;
  final VoidCallback onTap;
  final bool isExpanded;

  @override
  State<_HoverEdgeButton> createState() => _HoverEdgeButtonState();
}

class _HoverEdgeButtonState extends State<_HoverEdgeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isVertical ? 24 : double.infinity,
          height: widget.isVertical ? double.infinity : 24,
          alignment: widget.alignment,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            width: widget.isVertical
                ? (_isHovered ? 8 : 4)
                : (_isHovered ? 80 : 60),
            height: widget.isVertical
                ? (_isHovered ? 80 : 60)
                : (_isHovered ? 8 : 4),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppPalette.accent.withValues(alpha: 0.75)
                  : AppPalette.stroke.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(4),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppPalette.accent.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                widget.isVertical
                    ? (widget.isExpanded ? Icons.chevron_left : Icons.chevron_right)
                    : (widget.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                size: 8,
                color: _isHovered ? Colors.black : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

