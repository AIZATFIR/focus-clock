import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../agenda/agenda_tab.dart';
import '../ai_chat/ai_chat_sheet.dart';
import '../focusclock/focusclock_tab.dart';
import '../presets/presets_tab.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: ref.read(tabIndexProvider));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(tabIndexProvider);
    ref.listen<int>(tabIndexProvider, (_, next) {
      if (_pc.hasClients && _pc.page?.round() != next) {
        _pc.animateToPage(
          next,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'FOCUS',
                style: TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'CLOCK',
                style: TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.accent,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            color: AppPalette.accent,
            tooltip: 'AI Assistant',
            onPressed: () => showAiChatSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pc,
        onPageChanged: (i) =>
            ref.read(tabIndexProvider.notifier).state = i,
        children: const [
          PresetsTab(),
          FocusClockTab(),
          AgendaTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) =>
            ref.read(tabIndexProvider.notifier).state = i,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            selectedIcon: Icon(Icons.dashboard_customize),
            label: 'Presets',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Clock',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_agenda_outlined),
            selectedIcon: Icon(Icons.view_agenda),
            label: 'Agenda',
          ),
        ],
      ),
    );
  }
}
