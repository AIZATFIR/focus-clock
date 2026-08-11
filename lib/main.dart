import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

import 'app.dart';
import 'data/isar_service.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Desktop Window Manager
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 700),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Color(0xFF0F0F1A),
      title: 'Focus Clock',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      try {
        await windowManager.setPreventClose(true);
      } catch (_) {}
    });
  }

  late final IsarService isarService;
  try {
    isarService = await IsarService.open();
  } catch (e) {
    debugPrint('IsarService initialization error: $e');
    isarService = IsarService.fallback();
  }

  final notifier = NotificationService();
  try {
    await notifier.init();
  } catch (e) {
    debugPrint('NotificationService initialization error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isarService.isar),
        notificationServiceProvider.overrideWithValue(notifier),
      ],
      child: const FocusClockDesktopWrapper(child: FocusClockApp()),
    ),
  );
}

class FocusClockDesktopWrapper extends ConsumerStatefulWidget {
  const FocusClockDesktopWrapper({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<FocusClockDesktopWrapper> createState() => _FocusClockDesktopWrapperState();
}

class _FocusClockDesktopWrapperState extends ConsumerState<FocusClockDesktopWrapper> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      _initTray();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
    );

    _updateTrayMenu();
  }

  Future<void> _updateTrayMenu() async {
    final title = ref.read(activeTimerTitleProvider);
    final endTime = ref.read(activeTimerEndTimeProvider);
    final hasActive = endTime != null;

    final items = <MenuItem>[
      if (hasActive) ...[
        MenuItem(
          key: 'status',
          label: '📍 BERLANGSUNG: $title',
          disabled: true,
        ),
        MenuItem(
          key: 'stop_timer',
          label: '⏹️ Stop / Selesai Sesi Ini',
        ),
        MenuItem(
          key: 'reschedule_15',
          label: '⏩ Reschedule (+15 Menit)',
        ),
        MenuItem.separator(),
      ],
      MenuItem(
        key: 'show_window',
        label: 'Tampilkan Focus Clock',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: 'Keluar',
      ),
    ];

    await trayManager.setContextMenu(Menu(items: items));
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'stop_timer') {
      ref.read(activeTimerEndTimeProvider.notifier).state = null;
      ref.read(activeTimerIsPausedProvider.notifier).state = false;
      _updateTrayMenu();
    } else if (menuItem.key == 'reschedule_15') {
      final cur = ref.read(activeTimerEndTimeProvider);
      if (cur != null) {
        ref.read(activeTimerEndTimeProvider.notifier).state = cur.add(const Duration(minutes: 15));
        ref.read(activeTimerTotalSecondsProvider.notifier).update((t) => t + 900);
      }
      _updateTrayMenu();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
