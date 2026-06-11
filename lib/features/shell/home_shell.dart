import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../agenda/agenda_tab.dart';
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

  @override
  void initState() {
    super.initState();
    final initial = ref.read(tabIndexProvider);
    _pc = PageController(initialPage: initial);
    _tc = TabController(length: 4, vsync: this, initialIndex: initial);
  }

  @override
  void dispose() {
    _pc.dispose();
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(tabIndexProvider, (_, next) {
      if (_pc.hasClients && _pc.page?.round() != next) {
        _pc.animateToPage(
          next,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
      if (_tc.index != next) _tc.animateTo(next);
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
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Weekly Review',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const WeeklyReviewScreen()),
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
      body: PageView(
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
    );
  }
}
