// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/app_settings.dart';
import '../../providers/providers.dart';
import '../../services/gcal_service.dart';

// Provider presets
const _providerPresets = [
  ('Google AI', 'https://generativelanguage.googleapis.com/v1beta/openai'),
  ('Groq', 'https://api.groq.com/openai/v1'),
  ('OpenRouter', 'https://openrouter.ai/api/v1'),
  ('OpenAI', 'https://api.openai.com/v1'),
  ('Ollama (local)', 'http://localhost:11434/v1'),
  ('Custom', ''),
];

const _modelSuggestions = [
  // Google AI Studio (free tier, recommended default)
  'gemini-2.5-flash',
  'gemini-2.5-flash-lite',
  'gemini-2.0-flash',
  // Groq (fastest free — sub-second latency)
  'llama-3.3-70b-versatile',
  'llama-3.1-70b-versatile',
  // OpenRouter (free routes)
  'google/gemini-2.0-flash-exp:free',
  'meta-llama/llama-3.3-70b-instruct:free',
  // OpenAI
  'gpt-4o-mini',
  // Local (Ollama)
  'llama3.2:latest',
];

/// Short in-app guide: how to get an API key, per provider.
const _apiKeyGuides = <String, (String url, List<String> steps)>{
  'Google AI': (
    'aistudio.google.com/apikey',
    [
      'Buka aistudio.google.com/apikey, login akun Google',
      'Klik "Create API key" → pilih project (atau buat baru)',
      'Copy key (mulai dengan "AIza...") → paste di bawah',
      'Gratis: model gemini-2.5-flash, kuota harian cukup besar',
    ],
  ),
  'Groq': (
    'console.groq.com/keys',
    [
      'Buka console.groq.com, daftar gratis (email/Google)',
      'Menu "API Keys" → "Create API Key"',
      'Copy key (mulai dengan "gsk_...") → paste di bawah',
      'Paling cepat: respons < 1 detik, free tier 14.400 req/hari',
    ],
  ),
  'OpenRouter': (
    'openrouter.ai/keys',
    [
      'Buka openrouter.ai, login (Google/GitHub)',
      'Menu "Keys" → "Create Key"',
      'Copy key (mulai dengan "sk-or-...") → paste di bawah',
      'Pilih model berakhiran ":free" supaya gratis',
    ],
  ),
  'OpenAI': (
    'platform.openai.com/api-keys',
    [
      'Buka platform.openai.com, login',
      '"API keys" → "Create new secret key"',
      'Copy key (mulai dengan "sk-...") → paste di bawah',
      'Berbayar — perlu isi billing dulu',
    ],
  ),
  'Ollama (local)': (
    'ollama.com/download',
    [
      'Install Ollama dari ollama.com/download',
      'Jalankan: ollama pull llama3.2',
      'API key tidak perlu — kosongkan saja',
      'Gratis & offline, tapi perlu PC yang kuat',
    ],
  ),
};

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _is24h;
  int? _clockHandsMode;
  bool? _showMinuteLabels;
  bool? _enableAiAssistant;
  bool? _enableLeftPanel;
  bool? _enableRightPanel;
  String? _themeMode;
  bool? _trueBlack;
  int? _clockFaceTheme;
  int? _notifLeadMinutes;
  String? _keyLeftPanel;
  String? _keyRightPanel;
  String? _keyAiChat;
  String? _keyPrecisionMode;
  String? _keyPlanningMode;
  bool? _is24hDial;
  bool? _is24hTime;
  bool? _showCurrentTime;
  String? _currentTimeFormat;
  bool? _floatTimeText;
  String? _glowStyle;

  void _syncLocal(AppSettings s) {
    _is24h = s.is24h;
    _clockHandsMode = s.clockHandsMode;
    _showMinuteLabels = s.showMinuteLabels;
    _enableAiAssistant = s.enableAiAssistant;
    _enableLeftPanel = s.enableLeftPanel;
    _enableRightPanel = s.enableRightPanel;
    _themeMode = s.themeMode;
    _trueBlack = s.trueBlack;
    _clockFaceTheme = s.clockFaceTheme;
    _notifLeadMinutes = s.notifLeadMinutes;
    _keyLeftPanel = s.keyLeftPanel;
    _keyRightPanel = s.keyRightPanel;
    _keyAiChat = s.keyAiChat;
    _keyPrecisionMode = s.keyPrecisionMode;
    _keyPlanningMode = s.keyPlanningMode;
    _is24hDial = s.is24hDial;
    _is24hTime = s.is24hTime;
    _showCurrentTime = s.showCurrentTime;
    _currentTimeFormat = s.currentTimeFormat;
    _floatTimeText = s.floatTimeText;
    _glowStyle = s.glowStyle;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    // Listen to changes in settings provider to sync local state
    ref.listen<AsyncValue<AppSettings>>(settingsProvider, (prev, next) {
      if (next is AsyncData<AppSettings>) {
        setState(() {
          _syncLocal(next.value);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) {
          // Initialize if null
          if (_is24h == null) {
            _syncLocal(s);
          }

          final curClockHandsMode = _clockHandsMode!;
          final curShowMinuteLabels = _showMinuteLabels!;
          final curEnableAiAssistant = _enableAiAssistant!;
          final curEnableLeftPanel = _enableLeftPanel!;
          final curEnableRightPanel = _enableRightPanel!;
          final curThemeMode = _themeMode!;
          final curTrueBlack = _trueBlack!;
          final curClockFaceTheme = _clockFaceTheme!;
          final curNotifLeadMinutes = _notifLeadMinutes!;
          final curKeyLeftPanel = _keyLeftPanel ?? s.keyLeftPanel;
          final curKeyRightPanel = _keyRightPanel ?? s.keyRightPanel;
          final curKeyAiChat = _keyAiChat ?? s.keyAiChat;
          final curKeyPrecisionMode = _keyPrecisionMode ?? s.keyPrecisionMode;
          final curKeyPlanningMode = _keyPlanningMode ?? s.keyPlanningMode;

          return ListView(
            children: [
              // ── Simple Mode ──────────────────────────────────────────────────
              const _Section(title: 'Mode'),
              SwitchListTile(
                title: const Text('Simple Mode'),
                subtitle: const Text('Flat, lightweight UI without glowing effects'),
                value: curClockFaceTheme >= 5,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  setState(() {
                    _clockFaceTheme = v ? 5 : 1;
                    if (v) {
                      // Automatically force 12h in simple mode to match old Linux app layout
                      _is24h = false;
                      _is24hDial = false;
                      _is24hTime = false;
                    }
                  });
                  _save(
                    s,
                    clockFaceTheme: v ? 5 : 1,
                    is24h: v ? false : null,
                    is24hDial: v ? false : null,
                    is24hTime: v ? false : null,
                  );
                },
              ),

              const Divider(),
              // ── Time & Display ──────────────────────────────────────────────
              const _Section(title: 'Time & Display'),
              SwitchListTile(
                title: const Text('24-hour Time Format'),
                subtitle: Text((_is24hTime ?? false) ? 'Digital displays show 13:45' : 'Digital displays show 1:45 PM'),
                value: _is24hTime ?? false,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  setState(() {
                    _is24hTime = v;
                  });
                  _save(s, is24hTime: v);
                },
              ),
              SwitchListTile(
                title: const Text('24-hour Clock Dial'),
                subtitle: Text((_is24hDial ?? false) ? 'Dial shows 0-23 (24h sweep)' : 'Dial shows 1-12 (12h sweep)'),
                value: _is24hDial ?? false,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  setState(() {
                    _is24hDial = v;
                    _is24h = v;
                  });
                  _save(s, is24hDial: v, is24h: v);
                },
              ),
              SwitchListTile(
                title: const Text('Show Current Time Tip'),
                subtitle: const Text('Display time bubble at the tip of the hand'),
                value: _showCurrentTime ?? true,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  setState(() {
                    _showCurrentTime = v;
                  });
                  _save(s, showCurrentTime: v);
                },
              ),
              if (_showCurrentTime ?? true) ...[
                ListTile(
                  title: const Text('Current Time Format'),
                  subtitle: const Text('Choose how detailed the time bubble is'),
                  trailing: DropdownButton<String>(
                    value: _currentTimeFormat ?? 'short',
                    dropdownColor: const Color(0xFF1E1F24),
                    items: const [
                      DropdownMenuItem(value: 'short', child: Text('Hours & Minutes')),
                      DropdownMenuItem(value: 'seconds', child: Text('Hours, Minutes, Seconds')),
                      DropdownMenuItem(value: 'detailed', child: Text('Detailed (Date + Time)')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _currentTimeFormat = v;
                        });
                        _save(s, currentTimeFormat: v);
                      }
                    },
                  ),
                ),
                SwitchListTile(
                  title: const Text('Floating Time Text'),
                  subtitle: const Text('Remove background capsule to let the text float'),
                  value: _floatTimeText ?? false,
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    setState(() {
                      _floatTimeText = v;
                    });
                    _save(s, floatTimeText: v);
                  },
                ),
              ],

              // ── Clock Hands ─────────────────────────────────────────────────
              const Divider(),
              const _Section(title: 'Clock Hands'),
              RadioListTile(
                title: const Text('1 hand — precision'),
                subtitle: const Text('Single hand, 1 revolution per 12h'),
                value: 1,
                groupValue: curClockHandsMode,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _clockHandsMode = v;
                    });
                    _save(s, clockHandsMode: v);
                  }
                },
              ),
              RadioListTile(
                title: const Text('2 hands — hour + minute'),
                value: 2,
                groupValue: curClockHandsMode,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _clockHandsMode = v;
                    });
                    _save(s, clockHandsMode: v);
                  }
                },
              ),
              RadioListTile(
                title: const Text('3 hands — hour + minute + second'),
                value: 3,
                groupValue: curClockHandsMode,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _clockHandsMode = v;
                    });
                    _save(s, clockHandsMode: v);
                  }
                },
              ),

              // ── Clock Display ───────────────────────────────────────────────
              const Divider(),
              const _Section(title: 'Clock Display'),
              SwitchListTile(
                title: const Text('Minute labels'),
                subtitle: const Text('Show 5, 10, 15… on clock ring'),
                value: curShowMinuteLabels,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  setState(() {
                    _showMinuteLabels = v;
                  });
                  _save(s, showMinuteLabels: v);
                },
              ),

              // ── UI Panels ───────────────────────────────────────────────
              const Divider(),
              const _Section(title: 'UI Layout'),
              SwitchListTile(
                title: const Text('AI Assistant'),
                subtitle: const Text('Show bottom AI trigger button'),
                value: curEnableAiAssistant,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  setState(() {
                    _enableAiAssistant = v;
                  });
                  _save(s, enableAiAssistant: v);
                },
              ),
              SwitchListTile(
                title: const Text('Left Panel (Current Focus)'),
                subtitle: const Text('Show left sidebar on wide screens'),
                value: curEnableLeftPanel,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  setState(() {
                    _enableLeftPanel = v;
                  });
                  _save(s, enableLeftPanel: v);
                },
              ),
              SwitchListTile(
                title: const Text('Right Panel (Timeline)'),
                subtitle: const Text('Show right sidebar on wide screens'),
                value: curEnableRightPanel,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  setState(() {
                    _enableRightPanel = v;
                  });
                  _save(s, enableRightPanel: v);
                },
              ),

              // ── Theme ───────────────────────────────────────────────────────
              const Divider(),
              const _Section(title: 'Theme'),
              RadioListTile(
                title: const Text('Dark'),
                value: 'dark',
                groupValue: curThemeMode,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _themeMode = v;
                    });
                    _save(s, themeMode: v);
                  }
                },
              ),
              RadioListTile(
                title: const Text('Light'),
                value: 'light',
                groupValue: curThemeMode,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _themeMode = v;
                    });
                    _save(s, themeMode: v);
                  }
                },
              ),
              RadioListTile(
                title: const Text('System'),
                value: 'system',
                groupValue: curThemeMode,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _themeMode = v;
                    });
                    _save(s, themeMode: v);
                  }
                },
              ),
              SwitchListTile(
                title: const Text('True black (AMOLED)'),
                subtitle: const Text('Pure black background in dark theme'),
                value: curTrueBlack,
                activeColor: AppPalette.accent,
                onChanged: (v) {
                  setState(() {
                    _trueBlack = v;
                  });
                  _save(s, trueBlack: v);
                },
              ),

              // ── Clock Face Theme ─────────────────────────────────────────────
              if (curClockFaceTheme < 5) ...[
                const Divider(),
                const _Section(title: 'Clock Face Theme'),
                RadioListTile<int>(
                  title: const Text('Default (Yellow-Black)'),
                  value: 1,
                  groupValue: curClockFaceTheme,
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _clockFaceTheme = v;
                      });
                      _save(s, clockFaceTheme: v);
                    }
                  },
                ),
                RadioListTile<int>(
                  title: const Text('Elegance (White-Glow)'),
                  value: 2,
                  groupValue: curClockFaceTheme,
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _clockFaceTheme = v;
                      });
                      _save(s, clockFaceTheme: v);
                    }
                  },
                ),
                RadioListTile<int>(
                  title: const Text('Blue-Glow'),
                  value: 3,
                  groupValue: curClockFaceTheme,
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _clockFaceTheme = v;
                      });
                      _save(s, clockFaceTheme: v);
                    }
                  },
                ),
                RadioListTile<int>(
                  title: const Text('Purple-Glow'),
                  value: 4,
                  groupValue: curClockFaceTheme,
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _clockFaceTheme = v;
                      });
                      _save(s, clockFaceTheme: v);
                    }
                  },
                ),
                const Divider(),
                const _Section(title: 'Glow Style'),
                RadioListTile<String>(
                  title: const Text('Default Glow'),
                  subtitle: const Text('Full glowing aura with background capsule'),
                  value: 'default',
                  groupValue: _glowStyle ?? 'default',
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _glowStyle = v;
                      });
                      _save(s, glowStyle: v);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Floating Text (No Background)'),
                  subtitle: const Text('Vibrant floating text with no capsule background'),
                  value: 'floating',
                  groupValue: _glowStyle ?? 'default',
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _glowStyle = v;
                      });
                      _save(s, glowStyle: v);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Subtle Glow'),
                  subtitle: const Text('Minimal accent glow with background capsule'),
                  value: 'subtle',
                  groupValue: _glowStyle ?? 'default',
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _glowStyle = v;
                      });
                      _save(s, glowStyle: v);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Disable Glow'),
                  subtitle: const Text('Flat hands and markings with no glowing effects'),
                  value: 'off',
                  groupValue: _glowStyle ?? 'default',
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _glowStyle = v;
                      });
                      _save(s, glowStyle: v);
                    }
                  },
                ),
              ] else ...[
                const Divider(),
                const _Section(title: 'Simple Clock Style'),
                RadioListTile<int>(
                  title: const Text('Simple Flat'),
                  value: 5,
                  groupValue: curClockFaceTheme,
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _clockFaceTheme = v;
                      });
                      _save(s, clockFaceTheme: v);
                    }
                  },
                ),
                RadioListTile<int>(
                  title: const Text('Simple Mode Classic'),
                  value: 6,
                  groupValue: curClockFaceTheme,
                  activeColor: AppPalette.accent,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _clockFaceTheme = v;
                      });
                      _save(s, clockFaceTheme: v);
                    }
                  },
                ),
              ],

              // ── Notifications ───────────────────────────────────────────────
              const Divider(),
              const _Section(title: 'Notifications'),
              ListTile(
                title: const Text('Lead time'),
                subtitle: Text('$curNotifLeadMinutes minute(s) before'),
                trailing: DropdownButton<int>(
                  value: curNotifLeadMinutes,
                  items: const [1, 5, 10, 15]
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text('$v min')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _notifLeadMinutes = v;
                      });
                      _save(s, notifLeadMinutes: v);
                    }
                  },
                ),
              ),

              // ── AI Assistant ─────────────────────────────────────────────────
              const Divider(),
              const _Section(title: 'AI Assistant'),
              _AiConfigTile(s: s, onSave: (baseUrl, apiKey, model) {
                _save(s,
                    aiBaseUrl: baseUrl, aiApiKey: apiKey, aiModel: model);
              }),

              // ── Google Calendar ─────────────────────────────────────────────
              const Divider(),
              const _Section(title: 'Google Calendar'),
              _GCalTile(),

              // ── Keyboard Shortcuts ──────────────────────────────────────────
              const Divider(),
              const _Section(title: 'Keyboard Shortcuts'),
              ListTile(
                title: const Text('Toggle Left Panel'),
                subtitle: Text('Current shortcut: Ctrl + $curKeyLeftPanel'),
                trailing: TextButton(
                  onPressed: () {
                    _recordKeybind('Toggle Left Panel', curKeyLeftPanel, (newKey) {
                      setState(() {
                        _keyLeftPanel = newKey;
                      });
                      _save(s, keyLeftPanel: newKey);
                    });
                  },
                  child: const Text('Change'),
                ),
              ),
              ListTile(
                title: const Text('Toggle Right Panel'),
                subtitle: Text('Current shortcut: Ctrl + $curKeyRightPanel'),
                trailing: TextButton(
                  onPressed: () {
                    _recordKeybind('Toggle Right Panel', curKeyRightPanel, (newKey) {
                      setState(() {
                        _keyRightPanel = newKey;
                      });
                      _save(s, keyRightPanel: newKey);
                    });
                  },
                  child: const Text('Change'),
                ),
              ),
              ListTile(
                title: const Text('Toggle AI Chat'),
                subtitle: Text('Current shortcut: Ctrl + $curKeyAiChat'),
                trailing: TextButton(
                  onPressed: () {
                    _recordKeybind('Toggle AI Chat', curKeyAiChat, (newKey) {
                      setState(() {
                        _keyAiChat = newKey;
                      });
                      _save(s, keyAiChat: newKey);
                    });
                  },
                  child: const Text('Change'),
                ),
              ),
              ListTile(
                title: const Text('Toggle Precision Mode'),
                subtitle: Text('Current shortcut: Ctrl + $curKeyPrecisionMode'),
                trailing: TextButton(
                  onPressed: () {
                    _recordKeybind('Toggle Precision Mode', curKeyPrecisionMode, (newKey) {
                      setState(() {
                        _keyPrecisionMode = newKey;
                      });
                      _save(s, keyPrecisionMode: newKey);
                    });
                  },
                  child: const Text('Change'),
                ),
              ),
              ListTile(
                title: const Text('Toggle Planning Mode'),
                subtitle: Text('Current shortcut: Ctrl + $curKeyPlanningMode'),
                trailing: TextButton(
                  onPressed: () {
                    _recordKeybind('Toggle Planning Mode', curKeyPlanningMode, (newKey) {
                      setState(() {
                        _keyPlanningMode = newKey;
                      });
                      _save(s, keyPlanningMode: newKey);
                    });
                  },
                  child: const Text('Change'),
                ),
              ),

              // ── About ───────────────────────────────────────────────────────
              const Divider(),
              const _Section(title: 'About'),
              const ListTile(
                title: Text('Focus Clock'),
                subtitle: Text('v0.3.0'),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _recordKeybind(String label, String currentKey, Function(String newKey) onSaved) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final keyLabel = event.logicalKey.keyLabel;
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop();
                return KeyEventResult.handled;
              }
              if (keyLabel.isNotEmpty) {
                onSaved(keyLabel);
                Navigator.of(context).pop();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1F24),
            title: Text('Assign Key for $label', style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Press any key to assign it as the new shortcut.\nKey combinations will use Ctrl + [Key].',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppPalette.accent.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Current: Ctrl + $currentKey',
                    style: TextStyle(
                      color: AppPalette.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Press Esc to cancel',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _save(
    AppSettings s, {
    bool? is24h,
    int? clockHandsMode,
    String? themeMode,
    bool? trueBlack,
    int? notifLeadMinutes,
    bool? showMinuteLabels,
    int? clockFaceTheme,
    String? aiBaseUrl,
    String? aiApiKey,
    String? aiModel,
    bool? enableAiAssistant,
    bool? enableLeftPanel,
    bool? enableRightPanel,
    String? keyLeftPanel,
    String? keyRightPanel,
    String? keyAiChat,
    String? keyPrecisionMode,
    String? keyPlanningMode,
    bool? is24hDial,
    bool? is24hTime,
    bool? showCurrentTime,
    String? currentTimeFormat,
    bool? floatTimeText,
    String? glowStyle,
  }) {
    final next = AppSettings()
      ..id = s.id
      ..is24h = is24h ?? s.is24h
      ..clockHandsMode = clockHandsMode ?? s.clockHandsMode
      ..themeMode = themeMode ?? s.themeMode
      ..trueBlack = trueBlack ?? s.trueBlack
      ..notifLeadMinutes = notifLeadMinutes ?? s.notifLeadMinutes
      ..showMinuteLabels = showMinuteLabels ?? s.showMinuteLabels
      ..clockFaceTheme = clockFaceTheme ?? s.clockFaceTheme
      ..aiBaseUrl = aiBaseUrl ?? s.aiBaseUrl
      ..aiApiKey = aiApiKey ?? s.aiApiKey
      ..aiModel = aiModel ?? s.aiModel
      ..enableAiAssistant = enableAiAssistant ?? s.enableAiAssistant
      ..enableLeftPanel = enableLeftPanel ?? s.enableLeftPanel
      ..enableRightPanel = enableRightPanel ?? s.enableRightPanel
      ..keyLeftPanel = keyLeftPanel ?? s.keyLeftPanel
      ..keyRightPanel = keyRightPanel ?? s.keyRightPanel
      ..keyAiChat = keyAiChat ?? s.keyAiChat
      ..keyPrecisionMode = keyPrecisionMode ?? s.keyPrecisionMode
      ..keyPlanningMode = keyPlanningMode ?? s.keyPlanningMode
      ..is24hDial = is24hDial ?? s.is24hDial
      ..is24hTime = is24hTime ?? s.is24hTime
      ..showCurrentTime = showCurrentTime ?? s.showCurrentTime
      ..currentTimeFormat = currentTimeFormat ?? s.currentTimeFormat
      ..floatTimeText = floatTimeText ?? s.floatTimeText
      ..glowStyle = glowStyle ?? s.glowStyle;
    ref.read(settingsRepoProvider).update(next);
  }
}

// ── AI Config tile ────────────────────────────────────────────────────────────

class _AiConfigTile extends StatefulWidget {
  const _AiConfigTile({required this.s, required this.onSave});
  final AppSettings s;
  final void Function(String baseUrl, String apiKey, String model) onSave;

  @override
  State<_AiConfigTile> createState() => _AiConfigTileState();
}

class _AiConfigTileState extends State<_AiConfigTile> {
  late TextEditingController _urlCtrl;
  late TextEditingController _keyCtrl;
  late TextEditingController _modelCtrl;
  bool _obscureKey = true;
  bool _showGuide = false;
  String _selectedPreset = 'Google AI';

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.s.aiBaseUrl);
    _keyCtrl = TextEditingController(text: widget.s.aiApiKey);
    _modelCtrl = TextEditingController(text: widget.s.aiModel);

    // Detect preset from saved URL
    final match = _providerPresets
        .where((p) => p.$2 == widget.s.aiBaseUrl)
        .firstOrNull;
    _selectedPreset = match?.$1 ?? 'Custom';
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  static const _defaultModelFor = {
    'Google AI': 'gemini-2.5-flash',
    'Groq': 'llama-3.3-70b-versatile',
    'OpenRouter': 'google/gemini-2.0-flash-exp:free',
    'OpenAI': 'gpt-4o-mini',
    'Ollama (local)': 'llama3.2:latest',
  };

  void _pickPreset(String name) {
    final preset = _providerPresets.firstWhere((p) => p.$1 == name);
    setState(() {
      _selectedPreset = name;
      if (preset.$2.isNotEmpty) _urlCtrl.text = preset.$2;
      final m = _defaultModelFor[name];
      if (m != null) {
        _modelCtrl.text = m;
        _acFieldCtrl?.text = m;
      }
    });
  }

  TextEditingController? _acFieldCtrl;

  @override
  Widget build(BuildContext context) {
    final saved = widget.s.aiApiKey.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider selector
          const Text('Provider',
              style: TextStyle(fontSize: 13, color: AppPalette.textDim)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _providerPresets.map((p) {
                final selected = _selectedPreset == p.$1;
                return GestureDetector(
                  onTap: () => _pickPreset(p.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppPalette.accent.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppPalette.accent
                            : AppPalette.stroke,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      p.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color:
                            selected ? AppPalette.accent : AppPalette.text,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // How-to-get-API-key guide (per provider)
          if (_apiKeyGuides.containsKey(_selectedPreset)) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showGuide = !_showGuide),
              child: Row(
                children: [
                  Icon(
                    _showGuide
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 16,
                    color: AppPalette.accent,
                  ),
                  const Text(
                    'Cara dapat API key (gratis)',
                    style: TextStyle(fontSize: 12, color: AppPalette.accent),
                  ),
                ],
              ),
            ),
            if (_showGuide)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppPalette.accent.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔗 ${_apiKeyGuides[_selectedPreset]!.$1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.accent),
                    ),
                    const SizedBox(height: 6),
                    ..._apiKeyGuides[_selectedPreset]!.$2.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${e.key + 1}. ${e.value}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: AppPalette.text),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 14),

          // Base URL
          const Text('Base URL',
              style: TextStyle(fontSize: 13, color: AppPalette.textDim)),
          const SizedBox(height: 4),
          TextField(
            controller: _urlCtrl,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'https://openrouter.ai/api/v1',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          const SizedBox(height: 10),

          // API Key
          const Text('API Key',
              style: TextStyle(fontSize: 13, color: AppPalette.textDim)),
          const SizedBox(height: 4),
          TextField(
            controller: _keyCtrl,
            obscureText: _obscureKey,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'sk-or-...',
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Model
          Row(children: [
            const Text('Model',
                style: TextStyle(fontSize: 13, color: AppPalette.textDim)),
            const Spacer(),
            const Text('💡 Google AI = gratis · Groq = tercepat',
                style: TextStyle(fontSize: 11, color: AppPalette.textDim)),
          ]),
          const SizedBox(height: 4),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _modelCtrl.text),
            optionsBuilder: (v) => _modelSuggestions
                .where((m) =>
                    m.toLowerCase().contains(v.text.toLowerCase()))
                .toList(),
            onSelected: (v) => _modelCtrl.text = v,
            fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
              _acFieldCtrl = ctrl;
              return TextField(
                controller: ctrl,
                focusNode: focusNode,
                onChanged: (v) => _modelCtrl.text = v,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'gemini-2.5-flash',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // Save button + status
          Row(
            children: [
              if (saved) ...[
                const Icon(Icons.check_circle,
                    size: 14, color: Colors.green),
                const SizedBox(width: 4),
                const Text('Connected',
                    style: TextStyle(fontSize: 12, color: Colors.green)),
                const Spacer(),
              ] else if (const String.fromEnvironment('DEMO_AI_KEY').isNotEmpty) ...[
                const Icon(Icons.stars,
                    size: 14, color: AppPalette.accent),
                const SizedBox(width: 4),
                const Text('Demo Mode Active',
                    style: TextStyle(fontSize: 12, color: AppPalette.accent)),
                const Spacer(),
              ] else
                const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => widget.onSave(
                  _urlCtrl.text.trim(),
                  _keyCtrl.text.trim(),
                  _modelCtrl.text.trim(),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Google Calendar tile ──────────────────────────────────────────────────────

class _GCalTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GCalTile> createState() => _GCalTileState();
}

class _GCalTileState extends ConsumerState<_GCalTile> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _restoreSilent();
  }

  Future<void> _restoreSilent() async {
    final svc = ref.read(gcalServiceProvider);
    await svc.restoreSilent();
    if (mounted) {
      ref.read(gcalSignedInProvider.notifier).state = svc.isSignedIn;
    }
  }

  Future<void> _toggle() async {
    if (!gcalSupported) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Google Sign-In only available on Android / iOS / macOS'),
      ));
      return;
    }
    setState(() => _loading = true);
    final svc = ref.read(gcalServiceProvider);
    final signedIn = ref.read(gcalSignedInProvider);
    if (signedIn) {
      await svc.signOut();
      ref.read(gcalSignedInProvider.notifier).state = false;
    } else {
      final ok = await svc.signIn();
      ref.read(gcalSignedInProvider.notifier).state = ok;
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in cancelled or failed')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(gcalSignedInProvider);
    return ListTile(
      leading: const Text('📅', style: TextStyle(fontSize: 22)),
      title: Text(signedIn ? 'Connected' : 'Connect Google Calendar'),
      subtitle: Text(
        signedIn
            ? 'Activities sync to your calendar'
            : gcalSupported
                ? 'Tap to sign in with Google'
                : 'Available on Android / iOS',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : signedIn
              ? TextButton(
                  onPressed: _toggle,
                  style: TextButton.styleFrom(
                      foregroundColor: AppPalette.danger),
                  child: const Text('Disconnect'),
                )
              : FilledButton(
                  onPressed: gcalSupported ? _toggle : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.accent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Connect'),
                ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            color: AppPalette.textDim,
          ),
        ),
      );
}
