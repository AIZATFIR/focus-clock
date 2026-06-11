import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/app_settings.dart';
import '../../providers/providers.dart';
import '../../services/gcal_service.dart';

// Provider presets
const _providerPresets = [
  ('OpenRouter', 'https://openrouter.ai/api/v1'),
  ('Groq', 'https://api.groq.com/openai/v1'),
  ('OpenAI', 'https://api.openai.com/v1'),
  ('Gemini (OpenAI compat)', 'https://generativelanguage.googleapis.com/v1beta/openai'),
  ('Ollama (local)', 'http://localhost:11434/v1'),
  ('Custom', ''),
];

const _modelSuggestions = [
  // OpenRouter (free, recommended)
  'google/gemini-2.0-flash-exp:free',
  'google/gemini-2.5-flash-preview:free',
  'meta-llama/llama-3.3-70b-instruct:free',
  'mistralai/mistral-7b-instruct:free',
  // Groq (fastest free — sub-second latency)
  'llama-3.3-70b-versatile',
  'llama-3.1-70b-versatile',
  'llama-3.2-3b-preview',
  // OpenAI
  'gpt-4o-mini',
  // Anthropic (via OpenRouter)
  'claude-haiku-4-5-20251001',
  // Local (Ollama)
  'llama3.2:latest',
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) => ListView(
          children: [
            // ── Time ────────────────────────────────────────────────────────
            const _Section(title: 'Time'),
            SwitchListTile(
              title: const Text('24-hour format'),
              subtitle: Text(s.is24h ? 'Shows 13:45' : 'Shows 1:45 PM'),
              value: s.is24h,
              activeColor: AppPalette.accent,
              onChanged: (v) => _save(ref, s, is24h: v),
            ),

            // ── Clock Hands ─────────────────────────────────────────────────
            const Divider(),
            const _Section(title: 'Clock Hands'),
            RadioListTile(
              title: const Text('1 hand — precision'),
              subtitle: const Text('Single hand, 1 revolution per 12h'),
              value: 1,
              groupValue: s.clockHandsMode,
              activeColor: AppPalette.accent,
              onChanged: (v) => _save(ref, s, clockHandsMode: v as int),
            ),
            RadioListTile(
              title: const Text('2 hands — hour + minute'),
              value: 2,
              groupValue: s.clockHandsMode,
              activeColor: AppPalette.accent,
              onChanged: (v) => _save(ref, s, clockHandsMode: v as int),
            ),
            RadioListTile(
              title: const Text('3 hands — hour + minute + second'),
              value: 3,
              groupValue: s.clockHandsMode,
              activeColor: AppPalette.accent,
              onChanged: (v) => _save(ref, s, clockHandsMode: v as int),
            ),

            // ── Clock Display ───────────────────────────────────────────────
            const Divider(),
            const _Section(title: 'Clock Display'),
            SwitchListTile(
              title: const Text('Minute labels'),
              subtitle: const Text('Show 5, 10, 15… on clock ring'),
              value: s.showMinuteLabels,
              activeColor: AppPalette.accent,
              onChanged: (v) => _save(ref, s, showMinuteLabels: v),
            ),

            // ── Theme ───────────────────────────────────────────────────────
            const Divider(),
            const _Section(title: 'Theme'),
            RadioListTile(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: s.themeMode,
              activeColor: AppPalette.accent,
              onChanged: (v) => _save(ref, s, themeMode: v as String),
            ),
            RadioListTile(
              title: const Text('Light'),
              value: 'light',
              groupValue: s.themeMode,
              activeColor: AppPalette.accent,
              onChanged: (v) => _save(ref, s, themeMode: v as String),
            ),
            RadioListTile(
              title: const Text('System'),
              value: 'system',
              groupValue: s.themeMode,
              activeColor: AppPalette.accent,
              onChanged: (v) => _save(ref, s, themeMode: v as String),
            ),
            SwitchListTile(
              title: const Text('True black (AMOLED)'),
              subtitle: const Text('Pure black background in dark theme'),
              value: s.trueBlack,
              activeColor: AppPalette.accent,
              onChanged: (v) => _save(ref, s, trueBlack: v),
            ),

            // ── Notifications ───────────────────────────────────────────────
            const Divider(),
            const _Section(title: 'Notifications'),
            ListTile(
              title: const Text('Lead time'),
              subtitle: Text('${s.notifLeadMinutes} minute(s) before'),
              trailing: DropdownButton<int>(
                value: s.notifLeadMinutes,
                items: const [1, 5, 10, 15]
                    .map((v) =>
                        DropdownMenuItem(value: v, child: Text('$v min')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _save(ref, s, notifLeadMinutes: v);
                },
              ),
            ),

            // ── AI Assistant ─────────────────────────────────────────────────
            const Divider(),
            const _Section(title: 'AI Assistant'),
            _AiConfigTile(s: s, onSave: (baseUrl, apiKey, model) {
              _save(ref, s,
                  aiBaseUrl: baseUrl, aiApiKey: apiKey, aiModel: model);
            }),

            // ── Google Calendar ─────────────────────────────────────────────
            const Divider(),
            const _Section(title: 'Google Calendar'),
            _GCalTile(),

            // ── About ───────────────────────────────────────────────────────
            const Divider(),
            const _Section(title: 'About'),
            const ListTile(
              title: Text('Focus Clock'),
              subtitle: Text('v0.2.0'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _save(
    WidgetRef ref,
    AppSettings s, {
    bool? is24h,
    int? clockHandsMode,
    String? themeMode,
    bool? trueBlack,
    int? notifLeadMinutes,
    bool? showMinuteLabels,
    String? aiBaseUrl,
    String? aiApiKey,
    String? aiModel,
  }) {
    final next = AppSettings()
      ..is24h = is24h ?? s.is24h
      ..clockHandsMode = clockHandsMode ?? s.clockHandsMode
      ..themeMode = themeMode ?? s.themeMode
      ..trueBlack = trueBlack ?? s.trueBlack
      ..notifLeadMinutes = notifLeadMinutes ?? s.notifLeadMinutes
      ..showMinuteLabels = showMinuteLabels ?? s.showMinuteLabels
      ..aiBaseUrl = aiBaseUrl ?? s.aiBaseUrl
      ..aiApiKey = aiApiKey ?? s.aiApiKey
      ..aiModel = aiModel ?? s.aiModel;
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
  String _selectedPreset = 'OpenRouter';

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

  void _pickPreset(String name) {
    final preset = _providerPresets.firstWhere((p) => p.$1 == name);
    setState(() {
      _selectedPreset = name;
      if (preset.$2.isNotEmpty) _urlCtrl.text = preset.$2;
    });
  }

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
            const Text('💡 Groq = fastest free',
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
            fieldViewBuilder:
                (ctx, ctrl, focusNode, onSubmit) => TextField(
              controller: ctrl,
              focusNode: focusNode,
              onChanged: (v) => _modelCtrl.text = v,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'google/gemini-2.0-flash-exp:free',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
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
