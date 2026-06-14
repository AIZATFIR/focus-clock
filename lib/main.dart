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
      backgroundColor: Colors.transparent,
      title: 'Focus Clock',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // Intercept the close button to implement standby (hide instead of close)
      await windowManager.setPreventClose(true);
    });
  }

  final isarService = await IsarService.open();
  final notifier = NotificationService();
  await notifier.init();
  
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

class FocusClockDesktopWrapper extends StatefulWidget {
  const FocusClockDesktopWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<FocusClockDesktopWrapper> createState() => _FocusClockDesktopWrapperState();
}

class _FocusClockDesktopWrapperState extends State<FocusClockDesktopWrapper> with WindowListener, TrayListener {
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
    // Basic tray setup. Note: You should place an icon at linux/tray_icon.png or similar.
    // For now, we will just use a generic or empty string which might show a default icon.
    // In production, configure standard system paths for tray_manager.
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png', // Assuming app_icon exists
    );
    
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Focus Clock',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onWindowClose() {
    // Instead of exiting, we hide the window (standby mode)
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    // Show window when tray icon is clicked
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy(); // Force exit
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
