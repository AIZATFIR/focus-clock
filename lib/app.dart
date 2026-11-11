import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'core/time_math.dart';
import 'core/platform_support.dart';
import 'features/focusclock/widgets/focus_session_view.dart';
import 'features/shell/home_shell.dart';
import 'models/activity.dart';
import 'providers/providers.dart';
import 'services/focus_session_contract.dart';

class FocusClockApp extends ConsumerStatefulWidget {
  const FocusClockApp({super.key});

  @override
  ConsumerState<FocusClockApp> createState() => _FocusClockAppState();
}

class _FocusClockAppState extends ConsumerState<FocusClockApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;
  FocusSessionRequest? _pendingRequest;

  @override
  void initState() {
    super.initState();
    if (shouldSubscribeToAppLinks(isWeb: kIsWeb)) {
      _linkSubscription = AppLinks().uriLinkStream.listen(
        _handleIncomingLink,
        onError: (Object error) =>
            debugPrint('Focus Clock deep link error: $error'),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _handleIncomingLink(Uri uri) {
    final request = FocusSessionContract.parseFocusClockUri(uri);
    if (request == null) return;
    _pendingRequest = request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = _pendingRequest;
      final navigator = _navigatorKey.currentState;
      if (pending == null || navigator == null) return;
      _pendingRequest = null;
      navigator.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => FocusSessionView(
            activity: _activityFor(pending),
            externalRequest: pending,
            onClose: () => _navigatorKey.currentState?.pop(),
          ),
        ),
      );
    });
  }

  Activity _activityFor(FocusSessionRequest request) {
    final now = DateTime.now();
    return Activity()
      ..title = request.title
      ..startMinute = 0
      ..endMinute = request.targetMinutes
      ..ampmHalf = AmPmHalf.am
      ..date = dateOnly(now)
      ..colorValue = AppPalette.accent.value
      ..createdAt = now
      ..updatedAt = now;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.themeMode ?? 'dark'),
    );
    final themePalette = ref.watch(
      settingsProvider.select(
        (s) => s.valueOrNull?.themePalette ?? 'executive',
      ),
    );
    final trueBlack = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.trueBlack ?? false),
    );
    final hasSettings = ref.watch(settingsProvider.select((s) => s.hasValue));

    final mode = switch (themeMode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Focus Clock',
      theme: buildLightTheme(),
      darkTheme: trueBlack ? buildBlackTheme() : buildDarkTheme(themePalette),
      themeMode: mode,
      home: hasSettings
          ? const HomeShell()
          : const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 72, color: AppPalette.accent),
                    SizedBox(height: 24),
                    Text(
                      'FOCUS CLOCK',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      debugShowCheckedModeBanner: false,
    );
  }
}
