import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/time_math.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/preset_repository.dart';
import '../models/activity.dart';
import 'goal_schedule_planner.dart';
import 'gemini_tool_adapter.dart';
import 'secure_storage_service.dart';

/// Enum representing the active AI execution mode
enum AiExecutionMode {
  byokGeminiDirect('BYOK (Gemini Direct)'),
  byokOpenAiCompatibleDirect('BYOK (Direct)'),
  serverOpenRouter('Server-Side (OpenRouter)'),
  demoFallback('Demo Mode');

  const AiExecutionMode(this.label);
  final String label;
}

List<Content> openAiMessagesToGeminiHistory(
  Iterable<Map<String, dynamic>> messages,
) {
  return [
    for (final message in messages)
      if ((message['role'] == 'user' || message['role'] == 'assistant') &&
          message['content'] is String &&
          (message['content'] as String).isNotEmpty)
        Content(message['role'] == 'assistant' ? 'model' : 'user', [
          TextPart(message['content'] as String),
        ]),
  ];
}

// ── Tool schemas (OpenAI & Gemini function calling format) ───────────────────

const _tools = [
  {
    'type': 'function',
    'function': {
      'name': 'generate_blueprint',
      'description':
          'Generate a psychologically balanced full-day schedule (Fitrah Blueprint). '
          'Creates Deep Work blocks, Intentional Rest, Active Rest, Wind Down, and Sleep blocks '
          'based on circadian rhythm and ultradian cycle research. '
          'Call this when user asks to generate, plan, or blueprint their day.',
      'parameters': {
        'type': 'object',
        'required': ['date', 'wake_hour', 'sleep_hour'],
        'properties': {
          'date': {'type': 'string', 'description': 'ISO date yyyy-MM-dd'},
          'wake_hour': {
            'type': 'integer',
            'description': 'Wake-up hour (0-23), e.g. 6 for 6am',
          },
          'sleep_hour': {
            'type': 'integer',
            'description': 'Target sleep hour (0-23), e.g. 22 for 10pm',
          },
          'goals': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                'Main goals/tasks for the day, e.g. ["Math study", "Exercise"]',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'set_priority',
      'description':
          'Set importance level and/or deadline for an activity (for Eisenhower Matrix).',
      'parameters': {
        'type': 'object',
        'required': ['id'],
        'properties': {
          'id': {'type': 'integer'},
          'importance': {
            'type': 'integer',
            'description': '0 = low importance, 1 = high importance',
            'enum': [0, 1],
          },
          'deadline': {
            'type': 'string',
            'description': 'ISO date yyyy-MM-dd for deadline. Null to clear.',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'list_activities',
      'description': 'List all activities for a given date.',
      'parameters': {
        'type': 'object',
        'properties': {
          'date': {
            'type': 'string',
            'description': 'ISO date yyyy-MM-dd. Defaults to today if omitted.',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'create_activity',
      'description': 'Create a new time-block activity.',
      'parameters': {
        'type': 'object',
        'required': ['title', 'date', 'start_hour'],
        'properties': {
          'title': {'type': 'string'},
          'date': {'type': 'string', 'description': 'ISO date yyyy-MM-dd'},
          'start_hour': {
            'type': 'integer',
            'description': '0-23 (24h). 7=7am, 14=2pm.',
          },
          'start_minute': {
            'type': 'integer',
            'description': '0-59. Default 0.',
          },
          'duration_minutes': {
            'type': 'integer',
            'description': 'Duration minutes. Default 60.',
          },
          'description': {'type': 'string'},
          'focus_goal_link': {
            'type': 'string',
            'description':
                'Exact current focus goal title, only when the user clearly connects this activity to it.',
          },
          'recurrence': {
            'type': 'string',
            'enum': ['none', 'daily', 'weekly'],
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'update_activity',
      'description':
          'Update an existing activity. Only supply fields to change.',
      'parameters': {
        'type': 'object',
        'required': ['id'],
        'properties': {
          'id': {'type': 'integer'},
          'title': {'type': 'string'},
          'date': {'type': 'string'},
          'start_hour': {'type': 'integer'},
          'start_minute': {'type': 'integer'},
          'duration_minutes': {'type': 'integer'},
          'description': {'type': 'string'},
          'focus_goal_link': {
            'type': 'string',
            'description':
                'Exact current focus goal title to link this activity to; empty string to clear.',
          },
          'recurrence': {
            'type': 'string',
            'enum': ['none', 'daily', 'weekly'],
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'delete_activity',
      'description': 'Delete an activity by ID.',
      'parameters': {
        'type': 'object',
        'required': ['id'],
        'properties': {
          'id': {'type': 'integer'},
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'schedule_adaptive_goal',
      'description':
          'Create a recurring practice block for a long-term goal using schedule details explicitly provided by the user. '
          'Ask for the target date, practice hours, time window, and 5 weekdays or all 7 days. Do not guess missing details.',
      'parameters': {
        'type': 'object',
        'required': [
          'goal_title',
          'target_date',
          'daily_hours',
          'preferred_time',
          'days_per_week',
        ],
        'properties': {
          'goal_title': {
            'type': 'string',
            'description':
                'Title of goal/identity, e.g. "Juara 1 LKS IT Software Solutions"',
          },
          'target_date': {
            'type': 'string',
            'description': 'Target event date ISO yyyy-MM-dd (e.g. 2027-07-15)',
          },
          'daily_hours': {
            'type': 'number',
            'description': 'Practice hours per session, from 0.5 to 4.0.',
          },
          'preferred_time': {
            'type': 'string',
            'enum': ['morning', 'afternoon', 'evening'],
            'description': 'User-selected practice window.',
          },
          'days_per_week': {
            'type': 'integer',
            'enum': [5, 7],
            'description': '5 means weekdays; 7 means every day.',
          },
        },
      },
    },
  },
];

// ── Chat message ──────────────────────────────────────────────────────────────

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.text,
    this.isLoading = false,
    this.modeLabel,
    this.proposalIds = const [],
  });
  final String role; // 'user' | 'model'
  final String text;
  final bool isLoading;
  final String? modeLabel;
  final List<String> proposalIds;
}

enum AiActionProposalStatus { pending, applying, applied, cancelled, failed }

class AiActionProposal {
  AiActionProposal({
    required this.id,
    required this.toolName,
    required this.arguments,
  });

  final String id;
  final String toolName;
  final Map<String, dynamic> arguments;
  String? activityTitle;
  DateTime? activityDate;
  AiActionProposalStatus status = AiActionProposalStatus.pending;
  String? error;

  String get summary {
    final args = arguments;
    return switch (toolName) {
      'create_activity' =>
        'Tambah "${args['title'] ?? 'aktivitas'}" • ${args['date'] ?? 'tanggal belum ada'} • ${_time(args)} • ${args['duration_minutes'] ?? 60} menit',
      'update_activity' =>
        'Ubah "${activityTitle ?? 'aktivitas #${args['id'] ?? '?'}'}"${activityDate == null ? '' : ' • ${_date(activityDate!)}'}: ${args.entries.where((entry) => entry.key != 'id').map((entry) => '${entry.key} → ${entry.value}').join(', ')}',
      'delete_activity' =>
        'Hapus "${activityTitle ?? 'aktivitas #${args['id'] ?? '?'}'}"${activityDate == null ? '' : ' • ${_date(activityDate!)}'}',
      'set_priority' =>
        'Ubah prioritas "${activityTitle ?? 'aktivitas #${args['id'] ?? '?'}'}"${args['importance'] == null ? '' : ' • tingkat ${args['importance']}'}${args['deadline'] == null ? '' : ' • tenggat ${args['deadline']}'}',
      'generate_blueprint' =>
        'Buat blueprint ${args['date'] ?? 'untuk hari yang dipilih'} • bangun ${args['wake_hour'] ?? '?'}:00 • tidur ${args['sleep_hour'] ?? '?'}:00${args['goals'] == null ? '' : ' • ${args['goals']}'}',
      'schedule_adaptive_goal' =>
        'Jadwalkan latihan "${args['goal_title'] ?? 'tujuan'}" • ${args['daily_hours'] ?? '?'} jam per sesi • ${args['preferred_time'] ?? 'waktu belum dipilih'} • ${args['days_per_week'] ?? '?'} hari per minggu • target ${args['target_date'] ?? '?'}',
      _ => 'Tinjau tindakan ${toolName.replaceAll('_', ' ')}',
    };
  }

  static String _time(Map<String, dynamic> args) {
    final hour = args['start_hour'];
    if (hour is! num) return 'waktu belum dipilih';
    final minute = args['start_minute'] is num
        ? (args['start_minute'] as num).toInt()
        : 0;
    return '${hour.toInt().toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// ── AiService ─────────────────────────────────────────────────────────────────

class AiService {
  AiService({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required ActivityRepository activityRepo,
    required PresetRepository presetRepo,
    this.focusGoal = '',
    AiServiceStorage? secureStorage,
    http.Client? httpClient,
  }) : _activityRepo = activityRepo,
       _presetRepo = presetRepo,
       _secureStorage = secureStorage ?? SecureStorageService(),
       _httpClient = httpClient;

  final String baseUrl;
  final String apiKey;
  final String model;
  final String focusGoal;
  final ActivityRepository _activityRepo;
  final PresetRepository _presetRepo;
  final AiServiceStorage _secureStorage;
  final http.Client? _httpClient;

  Future<http.Response> _post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) => _httpClient == null
      ? http.post(uri, headers: headers, body: body)
      : _httpClient.post(uri, headers: headers, body: body);

  // History for OpenAI format requests
  final List<Map<String, dynamic>> _history = [];
  final Map<String, AiActionProposal> _proposals = {};
  final List<String> _lastTurnProposalIds = [];
  bool _initialized = false;
  AiExecutionMode _activeMode = AiExecutionMode.demoFallback;

  AiExecutionMode get activeMode => _activeMode;
  List<AiActionProposal> get pendingProposals => _proposals.values
      .where((proposal) => proposal.status == AiActionProposalStatus.pending)
      .toList(growable: false);
  List<AiActionProposal> get lastTurnProposals => _lastTurnProposalIds
      .map((id) => _proposals[id])
      .whereType<AiActionProposal>()
      .toList(growable: false);
  AiActionProposal? proposalById(String id) => _proposals[id];

  /// Format system prompt for Persona "Aura"
  String _buildAuraSystemPrompt(
    String dateStr,
    String timeStr,
    String timezone,
    String presetList,
    String focusGoal,
  ) {
    return '''Kamu adalah Aura, pendamping tujuan dan waktu yang hangat, jujur, dan tidak menghakimi.

ATURAN PERILAKU:
1. Jika pengguna belum bercerita tentang hal yang penting baginya, mulai dengan bertanya: "Apa yang sedang kamu perjuangkan?"
2. Selalu sadar konteks waktu pengguna saat ini: $dateStr $timeStr (Timezone: $timezone).
3. Dengarkan dulu. Tanyakan satu hal yang paling membantu berikutnya; jangan langsung memberi jadwal penuh.
4. Jangan mengarang tenggat, waktu luang, komitmen, atau target latihan. Tanyakan jika informasi itu dibutuhkan.
5. Bantu pengguna memilih satu langkah nyata hari ini. Hindari rasa bersalah, streak, pujian kosong, dan kepastian palsu.
6. Jawab ringkas dan jelas. Ikuti kerangka nilai pengguna; jangan memaksakan kerangka agama atau psikologi.

ARAH FOCUS CLOCK:
- Tujuan pengguna menjadi acuan. Identitas dibangun lewat keputusan dan tindakan berulang, bukan satu jadwal sempurna.
- Seimbangkan belajar/kerja, istirahat, tidur, ibadah, keluarga, dan tanggung jawab sesuai kondisi serta pilihan pengguna.
- Jam analog adalah visual peta hari; bantu pengguna melihat sekarang, berikutnya, dan ruang yang masih tersedia.
- Presets pengguna saat ini: $presetList.
- Tujuan utama pengguna saat ini: ${focusGoal.isEmpty ? 'belum ditetapkan' : focusGoal}.
- Saat membuat aktivitas yang jelas mendukung tujuan utama, isi `focus_goal_link` dengan judul tujuan di atas. Jangan menautkan aktivitas yang tidak berhubungan atau menebak hubungan.

IDENTITAS & ADAPTIVE GOAL SCHEDULING:
- Jika pengguna menyampaikan tujuan jangka panjang, pahami dulu arti tujuan itu bagi mereka dan apa langkah yang sudah pernah dicoba.
- Sebelum memakai `schedule_adaptive_goal`, pastikan tenggat, jam latihan, rentang waktu, dan pilihan 5 hari kerja atau 7 hari berasal dari pengguna. Jika belum jelas, tanyakan; jangan menebak nilai.
- Sampaikan apa yang akan dijadwalkan dengan bahasa biasa. Jangan mengklaim jadwal berhasil sebelum tool mengonfirmasi.

PANGGILAN TOOL AUTOMATION:
- list_activities: untuk melihat jadwal aktif.
- create_activity: untuk menambah kegiatan/time-block.
- update_activity: untuk menggeser/mengubah jadwal.
- delete_activity: untuk menghapus jadwal.
- set_priority: untuk mengatur Eisenhower Matrix.
- generate_blueprint: untuk membuat rencana Fitrah Blueprint seharian penuh.
- schedule_adaptive_goal: untuk menganalisis & menanamkan blok latihan target jangka panjang (lomba/identitas).
- Semua tool yang mengubah jadwal adalah draf. Jangan pernah mengatakan aktivitas sudah dibuat, diubah, atau dihapus sampai pengguna menekan tombol konfirmasi di aplikasi.
- Setelah tool mengembalikan `awaiting_confirmation`, jelaskan singkat bahwa draf menunggu tinjauan pengguna.
''';
  }

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final now = DateTime.now();
    final timezone = DateTime.now().timeZoneName;
    final presets = await _presetRepo.getAll();
    final presetList = presets.isEmpty
        ? 'tidak ada'
        : presets
              .asMap()
              .entries
              .map((e) => '${e.key + 1}. "${e.value.name}"')
              .join(', ');
    final dateStr = _fmtDate(now);
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final systemPrompt = _buildAuraSystemPrompt(
      dateStr,
      timeStr,
      timezone,
      presetList,
      focusGoal,
    );

    _history.add({'role': 'system', 'content': systemPrompt});
    _initialized = true;
  }

  /// Send message via Hybrid Architecture (BYOK Gemini SDK or Server-Side Fallback)
  Future<String> send(String userMessage) async {
    await _ensureInit();
    _lastTurnProposalIds.clear();
    _history.add({'role': 'user', 'content': userMessage});

    final userGeminiKey = (await _secureStorage.getGeminiApiKey()) ?? apiKey;

    // Determine Mode
    try {
      if (userGeminiKey.isNotEmpty && userGeminiKey.startsWith('AIza')) {
        _activeMode = AiExecutionMode.byokGeminiDirect;
        try {
          return _addDraftNotice(
            await _sendGeminiDirect(userMessage, userGeminiKey),
          );
        } catch (e) {
          // Fallback to server side if BYOK fails
          _activeMode = AiExecutionMode.serverOpenRouter;
          return _addDraftNotice(await _sendServerFallback(userMessage));
        }
      } else if (userGeminiKey.isNotEmpty || _isLoopbackProvider(baseUrl)) {
        _activeMode = AiExecutionMode.byokOpenAiCompatibleDirect;
        return _addDraftNotice(
          await _callOpenAiCompatibleDirect(
            key: userGeminiKey,
            url: baseUrl,
            modelName: model,
          ),
        );
      } else {
        _activeMode = AiExecutionMode.serverOpenRouter;
        return _addDraftNotice(await _sendServerFallback(userMessage));
      }
    } catch (_) {
      if (_lastTurnProposalIds.isNotEmpty) return _addDraftNotice('');
      rethrow;
    }
  }

  String _addDraftNotice(String reply) => _lastTurnProposalIds.isEmpty
      ? reply
      : 'Draf tindakan siap ditinjau. Belum ada perubahan di clock; pilih Terapkan atau Batal di bawah.';

  Future<Map<String, dynamic>> _stageTool(
    String name,
    Map<String, dynamic> args,
  ) async {
    if (!_mutatingTools.contains(name)) return _executeTool(name, args);

    final encodedArgs = jsonEncode(args);
    final existing = _proposals.values.cast<AiActionProposal?>().firstWhere(
      (proposal) =>
          proposal?.status == AiActionProposalStatus.pending &&
          proposal?.toolName == name &&
          jsonEncode(proposal?.arguments) == encodedArgs,
      orElse: () => null,
    );
    final proposal =
        existing ??
        AiActionProposal(
          id: const Uuid().v4(),
          toolName: name,
          arguments: Map<String, dynamic>.from(
            jsonDecode(encodedArgs) as Map<String, dynamic>,
          ),
        );
    final activityId = args['id'];
    if (activityId is num &&
        {'update_activity', 'delete_activity', 'set_priority'}.contains(name)) {
      final activity = await _activityRepo.get(activityId.toInt());
      proposal.activityTitle = activity?.title;
      proposal.activityDate = activity?.date;
    }
    _proposals[proposal.id] = proposal;
    if (!_lastTurnProposalIds.contains(proposal.id)) {
      _lastTurnProposalIds.add(proposal.id);
    }
    return {
      'status': 'awaiting_confirmation',
      'proposal_id': proposal.id,
      'preview': proposal.summary,
    };
  }

  Future<Map<String, dynamic>> confirmProposal(String id) async {
    final proposal = _proposals[id];
    if (proposal == null) return {'error': 'Draft not found.'};
    if (proposal.status != AiActionProposalStatus.pending) {
      return {'error': 'Draft is no longer waiting for confirmation.'};
    }

    proposal.status = AiActionProposalStatus.applying;
    final result = await _executeTool(proposal.toolName, proposal.arguments);
    if (result.containsKey('error') || result['success'] == false) {
      proposal.status = AiActionProposalStatus.failed;
      proposal.error = result['error']?.toString() ?? 'Action failed.';
    } else {
      proposal.status = AiActionProposalStatus.applied;
      _history.add({
        'role': 'assistant',
        'content': 'Pengguna menyetujui dan menerapkan: ${proposal.summary}.',
      });
    }
    return result;
  }

  bool cancelProposal(String id) {
    final proposal = _proposals[id];
    if (proposal == null || proposal.status != AiActionProposalStatus.pending) {
      return false;
    }
    proposal.status = AiActionProposalStatus.cancelled;
    _history.add({
      'role': 'assistant',
      'content': 'Pengguna membatalkan draf: ${proposal.summary}.',
    });
    return true;
  }

  static const _mutatingTools = {
    'create_activity',
    'update_activity',
    'delete_activity',
    'set_priority',
    'generate_blueprint',
    'schedule_adaptive_goal',
  };

  bool _isLoopbackProvider(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'localhost' ||
        host.endsWith('.localhost') ||
        host == '::1' ||
        RegExp(r'^127(?:\.\d{1,3}){3}$').hasMatch(host);
  }

  // ── Mode 1: BYOK Client-Side via Google Generative AI SDK ────────────────
  Future<String> _sendGeminiDirect(String userMessage, String geminiKey) async {
    var toolWasCalled = false;
    try {
      final systemPromptObj =
          _history.firstWhere(
                (m) => m['role'] == 'system',
                orElse: () => {'content': ''},
              )['content']
              as String;
      final directModelName = model.startsWith('gemini-')
          ? model
          : 'gemini-2.5-flash';
      final geminiModel = GenerativeModel(
        model: directModelName,
        apiKey: geminiKey,
        systemInstruction: Content.system(systemPromptObj),
        tools: convertOpenAiToolsToGemini(
          _tools.map((tool) => Map<String, dynamic>.from(tool)),
        ),
      );
      final priorMessages = _history.take(_history.length - 1);
      final chat = geminiModel.startChat(
        history: openAiMessagesToGeminiHistory(priorMessages),
      );
      var response = await chat.sendMessage(Content.text(userMessage));
      for (var loop = 0; loop < 5; loop++) {
        final calls = response.functionCalls.toList();
        if (calls.isEmpty) break;

        final results = <FunctionResponse>[];
        for (final call in calls) {
          toolWasCalled = true;
          final result = await _stageTool(
            call.name,
            Map<String, dynamic>.from(call.args),
          );
          results.add(
            FunctionResponse(call.name, Map<String, Object?>.from(result)),
          );
        }
        response = await chat.sendMessage(Content.functionResponses(results));
      }
      if (response.functionCalls.isNotEmpty) {
        throw StateError('Gemini exceeded the tool-call limit.');
      }
      final reply =
          response.text?.trim() ?? 'Halo, Aura di sini. Ada yang bisa dibantu?';

      _history.add({'role': 'assistant', 'content': reply});
      return reply;
    } catch (_) {
      if (toolWasCalled) {
        const reply =
            'Sambungan terputus setelah Aura meminta tindakan ke Focus Clock. Periksa jadwal sebelum mencoba lagi.';
        _history.add({'role': 'assistant', 'content': reply});
        return reply;
      }
      // Fall back to HTTP endpoint if SDK fails
      return await _sendServerFallback(userMessage);
    }
  }

  // ── Mode 2: Server-Side Fallback via OpenRouter / Backend ─────────────────
  Future<String> _sendServerFallback(String userMessage) async {
    final serverUrl = await _secureStorage.getBackendServerUrl();
    final openRouterKey = await _secureStorage.getOpenRouterKey();

    // 1. Try local/custom server endpoint `/api/chat/secretary`
    try {
      final uri = Uri.parse('$serverUrl/api/chat/secretary');
      final resp = await _post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': _history, 'userMessage': userMessage}),
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final reply =
            (data['reply'] as String?)?.trim() ??
            'Siap, Aura sudah memproses jadwal Anda.';
        _history.add({'role': 'assistant', 'content': reply});
        return reply;
      }
    } catch (_) {
      // Server offline or not reached, try direct OpenRouter HTTP if available
    }

    // 2. Direct OpenRouter HTTP call
    return await _callOpenRouterDirect(openRouterKey);
  }

  Future<String> _callOpenRouterDirect(String? openRouterKey) async {
    const demoUrl = String.fromEnvironment(
      'DEMO_AI_URL',
      defaultValue: 'https://generativelanguage.googleapis.com/v1beta/openai',
    );
    const demoKey = String.fromEnvironment('DEMO_AI_KEY');
    const demoModel = String.fromEnvironment(
      'DEMO_AI_MODEL',
      defaultValue: 'gemini-2.5-flash',
    );

    final effectiveKey = (openRouterKey != null && openRouterKey.isNotEmpty)
        ? openRouterKey
        : (apiKey.isNotEmpty ? apiKey : demoKey);
    final effectiveUrl = (openRouterKey != null && openRouterKey.isNotEmpty)
        ? 'https://openrouter.ai/api/v1'
        : (apiKey.isNotEmpty ? baseUrl : demoUrl);
    final effectiveModel = (openRouterKey != null && openRouterKey.isNotEmpty)
        ? 'google/gemini-2.0-flash-exp:free'
        : (model.isNotEmpty ? model : demoModel);

    if (effectiveKey.isEmpty) {
      return 'Halo! Aura siap membantu. Silakan masukkan GEMINI_API_KEY Anda di Settings untuk mode BYOK, atau nyalakan Server Backend OpenRouter.';
    }

    return _callOpenAiCompatibleDirect(
      key: effectiveKey,
      url: effectiveUrl,
      modelName: effectiveModel,
    );
  }

  Future<String> _callOpenAiCompatibleDirect({
    required String key,
    required String url,
    required String modelName,
  }) async {
    // Agentic loop
    for (int loop = 0; loop < 5; loop++) {
      final response = await _callOpenAiFormatApi(url, key, modelName);
      final choice = response['choices'][0];
      final msg = choice['message'] as Map<String, dynamic>;

      _history.add(msg);

      final toolCalls = msg['tool_calls'] as List?;
      if (toolCalls == null || toolCalls.isEmpty) {
        return (msg['content'] as String?)?.trim() ??
            'Aura siap mendampingi waktu Anda.';
      }

      for (final tc in toolCalls) {
        final name = tc['function']['name'] as String;
        final args =
            jsonDecode(tc['function']['arguments'] as String)
                as Map<String, dynamic>;
        final result = await _stageTool(name, args);
        _history.add({
          'role': 'tool',
          'tool_call_id': tc['id'],
          'content': jsonEncode(result),
        });
      }
    }

    return 'Proses penjadwalan selesais.';
  }

  Future<Map<String, dynamic>> _callOpenAiFormatApi(
    String url,
    String key,
    String modelName,
  ) async {
    final baseUri = Uri.parse(url);
    final uri = baseUri.path.endsWith('/chat/completions')
        ? baseUri
        : baseUri.replace(
            path:
                '${baseUri.path.replaceFirst(RegExp(r'/+$'), '')}/chat/completions',
          );
    final body = jsonEncode({
      'model': modelName,
      'messages': _history,
      'tools': _tools,
      'tool_choice': 'auto',
    });

    final resp = await _post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (key.isNotEmpty) 'Authorization': 'Bearer $key',
        if (url.contains('openrouter'))
          'HTTP-Referer': 'https://focusclock.app',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ── Tool executor ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _executeTool(
    String name,
    Map<String, dynamic> args,
  ) async {
    try {
      return switch (name) {
        'list_activities' => await _listActivities(args),
        'create_activity' => await _createActivity(args),
        'update_activity' => await _updateActivity(args),
        'delete_activity' => await _deleteActivity(args),
        'set_priority' => await _setPriority(args),
        'generate_blueprint' => await _generateBlueprint(args),
        'schedule_adaptive_goal' => await _scheduleAdaptiveGoal(args),
        _ => {'error': 'Unknown tool: $name'},
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _listActivities(
    Map<String, dynamic> args,
  ) async {
    final dateStr = args['date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final activities = await _activityRepo.getByDate(dateOnly(date));
    return {
      'activities': activities
          .map(
            (a) => {
              'id': a.id,
              'title': a.title,
              'date': _fmtDate(a.date),
              'start': _fmtTime(a.ampmHalf, a.startMinute),
              'end': _fmtTime(a.ampmHalf, a.endMinute),
              'description': a.description,
              'focus_goal_link': a.focusGoalLink,
              'recurrence': a.recurrence,
            },
          )
          .toList(),
    };
  }

  Future<int> _createSpan({
    required String title,
    required DateTime date,
    required int startHour,
    required int startMin,
    required int durationMinutes,
    String description = '',
    String focusGoalLink = '',
    String recurrence = 'none',
    DateTime? recurrenceEndDate,
    int colorValue = 0xFFFFD700,
  }) async {
    final startDt = DateTime(
      date.year,
      date.month,
      date.day,
      startHour,
      startMin,
    );
    final endDt = startDt.add(Duration(minutes: durationMinutes));
    final segments = splitSpan(startDt, endDt);
    final groupId = segments.length > 1 ? const Uuid().v4() : null;

    for (final s in segments) {
      final conflicts = await _activityRepo.getConflicting(
        s.date,
        s.half,
        s.start,
        s.end,
      );
      if (conflicts.isNotEmpty) {
        final c = conflicts.first;
        final cStart = _fmtTime(c.ampmHalf, c.startMinute);
        final cEnd = _fmtTime(c.ampmHalf, c.endMinute);
        throw Exception(
          'Waktu bentrok dengan "${c.title}" ($cStart\u2013$cEnd).',
        );
      }
    }

    final now = DateTime.now();
    final acts = [
      for (final s in segments)
        Activity()
          ..title = title
          ..startMinute = s.start
          ..endMinute = s.end
          ..ampmHalf = s.half
          ..date = s.date
          ..groupId = groupId
          ..description = description
          ..focusGoalLink = focusGoalLink
          ..recurrence = recurrence
          ..recurrenceEndDate = recurrenceEndDate
          ..colorValue = colorValue
          ..createdAt = now
          ..updatedAt = now,
    ];
    if (acts.length == 1) return _activityRepo.upsert(acts.first);
    await _activityRepo.replaceSpan(
      original: Activity()..title = title,
      segments: acts,
    );
    return acts.first.id;
  }

  Future<Map<String, dynamic>> _createActivity(
    Map<String, dynamic> args,
  ) async {
    final title = args['title'] as String;
    final dateStr = args['date'] as String;
    final startHour = (args['start_hour'] as num).toInt();
    final startMin = (args['start_minute'] as num?)?.toInt() ?? 0;
    final duration = (args['duration_minutes'] as num?)?.toInt() ?? 60;
    final description = args['description'] as String? ?? '';
    final requestedGoalLink = args['focus_goal_link'] as String? ?? '';
    final focusGoalLink = requestedGoalLink == focusGoal ? focusGoal : '';
    final recurrence = args['recurrence'] as String? ?? 'none';

    final id = await _createSpan(
      title: title,
      date: DateTime.parse(dateStr),
      startHour: startHour,
      startMin: startMin,
      durationMinutes: duration,
      description: description,
      focusGoalLink: focusGoalLink,
      recurrence: recurrence,
    );
    return {'success': true, 'id': id, 'title': title};
  }

  Future<Map<String, dynamic>> _updateActivity(
    Map<String, dynamic> args,
  ) async {
    final id = (args['id'] as num).toInt();
    final existing = await _activityRepo.get(id);
    if (existing == null) return {'error': 'Activity $id not found'};

    if (args['title'] != null) existing.title = args['title'] as String;
    if (args['description'] != null) {
      existing.description = args['description'] as String;
    }
    if (args['focus_goal_link'] is String) {
      final requestedGoalLink = args['focus_goal_link'] as String;
      existing.focusGoalLink = requestedGoalLink == focusGoal ? focusGoal : '';
    }
    if (args['recurrence'] != null) {
      existing.recurrence = args['recurrence'] as String;
    }
    if (args['date'] != null) {
      existing.date = dateOnly(DateTime.parse(args['date'] as String));
    }

    final timeChanged =
        args['start_hour'] != null ||
        args['start_minute'] != null ||
        args['duration_minutes'] != null;
    if (!timeChanged) {
      await _activityRepo.upsert(existing);
      return {'success': true, 'id': id};
    }

    final h = args['start_hour'] != null
        ? (args['start_hour'] as num).toInt()
        : (existing.ampmHalf == AmPmHalf.pm ? 12 : 0) +
              existing.startMinute ~/ 60;
    final m = args['start_minute'] != null
        ? (args['start_minute'] as num).toInt()
        : existing.startMinute % 60;

    int dur;
    if (args['duration_minutes'] != null) {
      dur = (args['duration_minutes'] as num).toInt();
    } else if (existing.groupId != null) {
      final group = await _activityRepo.getGroup(existing.groupId!);
      dur = group.fold(0, (s, g) => s + g.endMinute - g.startMinute);
    } else {
      dur = existing.endMinute - existing.startMinute;
    }

    final startDt = DateTime(
      existing.date.year,
      existing.date.month,
      existing.date.day,
      h,
      m,
    );
    final segments = splitSpan(startDt, startDt.add(Duration(minutes: dur)));
    final groupId = segments.length > 1
        ? (existing.groupId ?? const Uuid().v4())
        : null;

    for (final s in segments) {
      final conflicts = await _activityRepo.getConflicting(
        s.date,
        s.half,
        s.start,
        s.end,
        excludeId: id,
      );
      if (conflicts.isNotEmpty) {
        final c = conflicts.first;
        final cStart = _fmtTime(c.ampmHalf, c.startMinute);
        final cEnd = _fmtTime(c.ampmHalf, c.endMinute);
        throw Exception(
          'Waktu bentrok dengan "${c.title}" ($cStart\u2013$cEnd).',
        );
      }
    }

    final now = DateTime.now();
    await _activityRepo.replaceSpan(
      original: existing,
      segments: [
        for (final s in segments)
          Activity()
            ..title = existing.title
            ..presetId = existing.presetId
            ..iconKey = existing.iconKey
            ..startMinute = s.start
            ..endMinute = s.end
            ..ampmHalf = s.half
            ..date = s.date
            ..groupId = groupId
            ..description = existing.description
            ..focusGoalLink = existing.focusGoalLink
            ..recurrence = existing.recurrence
            ..colorValue = existing.colorValue
            ..importance = existing.importance
            ..deadline = existing.deadline
            ..createdAt = existing.createdAt
            ..updatedAt = now,
      ],
    );
    return {'success': true, 'id': id};
  }

  Future<Map<String, dynamic>> _deleteActivity(
    Map<String, dynamic> args,
  ) async {
    final id = (args['id'] as num).toInt();
    final ok = await _activityRepo.delete(id);
    return {'success': ok, 'id': id};
  }

  Future<Map<String, dynamic>> _setPriority(Map<String, dynamic> args) async {
    final id = (args['id'] as num).toInt();
    final existing = await _activityRepo.get(id);
    if (existing == null) return {'error': 'Activity $id not found'};

    if (args['importance'] != null) {
      await _activityRepo.setImportance(
        existing,
        (args['importance'] as num).toInt(),
      );
    }
    if (args.containsKey('deadline')) {
      final dl = args['deadline'] as String?;
      await _activityRepo.setDeadline(
        existing,
        dl != null ? DateTime.parse(dl) : null,
      );
    }
    return {'success': true, 'id': id};
  }

  Future<Map<String, dynamic>> _generateBlueprint(
    Map<String, dynamic> args,
  ) async {
    final dateStr = args['date'] as String;
    final date = DateTime.parse(dateStr);
    final wakeH = (args['wake_hour'] as num).toInt();
    final sleepH = (args['sleep_hour'] as num).toInt();
    final goals = (args['goals'] as List?)?.cast<String>() ?? [];

    final workStart = wakeH + 1;
    final blocks = <Map<String, dynamic>>[];

    blocks.add({
      'title': '🌅 Routine Pagi (Aura Briefing)',
      'start_hour': wakeH,
      'start_minute': 0,
      'duration_minutes': 30,
      'description':
          'Minum air, peregangan ringan, dan tinjau rencana hari ini.',
      'color': 0xFFFFD700,
    });

    int cursor = workStart * 60;
    final goalLabels = goals.isNotEmpty ? goals : ['Deep Work Utama'];
    for (int i = 0; i < goalLabels.length && i < 3; i++) {
      final dwDur = 90;
      if (cursor + dwDur > sleepH * 60 - 120) break;

      blocks.add({
        'title': '🎯 Deep Work: ${goalLabels[i]}',
        'start_hour': cursor ~/ 60,
        'start_minute': cursor % 60,
        'duration_minutes': dwDur,
        'description': 'Fokus penuh tanpa hambatan atau notifikasi.',
        'color': 0xFF4A9EFF,
      });
      cursor += dwDur;

      blocks.add({
        'title': '🧠 Intentional Rest (Bengong Sehat)',
        'start_hour': cursor ~/ 60,
        'start_minute': cursor % 60,
        'duration_minutes': 20,
        'description':
            'Istirahat tanpa layar untuk aktivasi Default Mode Network (DMN).',
        'color': 0xFF6BCB77,
      });
      cursor += 20;

      if (i == 0 && cursor ~/ 60 >= 11) {
        blocks.add({
          'title': '🍱 Makan Siang + Active Rest',
          'start_hour': cursor ~/ 60,
          'start_minute': cursor % 60,
          'duration_minutes': 90,
          'description': 'Makan siang dan reset dopamin.',
          'color': 0xFFFF9F40,
        });
        cursor += 90;
      }
    }

    final windDownStart = sleepH * 60 - 60;
    if (windDownStart > cursor) {
      blocks.add({
        'title': '📓 Wind Down & Refleksi bersama Aura',
        'start_hour': windDownStart ~/ 60,
        'start_minute': windDownStart % 60,
        'duration_minutes': 45,
        'description': 'Jurnal dan evaluasi hari ini.',
        'color': 0xFF9B8FFF,
      });
    }

    blocks.add({
      'title': '💤 Tidur (Siklus Sirkadian)',
      'start_hour': sleepH,
      'start_minute': 0,
      'duration_minutes': ((wakeH + 24 - sleepH) * 60).clamp(270, 540),
      'description':
          'Kelipatan 90 menit untuk bangun tidur tanpa sleep inertia.',
      'color': 0xFF2E2E4E,
    });

    final created = <int>[];
    for (final b in blocks) {
      final id = await _createSpan(
        title: b['title'] as String,
        date: date,
        startHour: b['start_hour'] as int,
        startMin: b['start_minute'] as int,
        durationMinutes: b['duration_minutes'] as int,
        description: b['description'] as String,
        colorValue: b['color'] as int,
      );
      created.add(id);
    }

    return {
      'success': true,
      'blocks_created': created.length,
      'message':
          'Fitrah Blueprint berhasil dibuat: ${created.length} blok untuk $dateStr.',
    };
  }

  Future<Map<String, dynamic>> _scheduleAdaptiveGoal(
    Map<String, dynamic> args,
  ) async {
    final rawGoalTitle = args['goal_title'];
    final goalTitle = rawGoalTitle is String ? rawGoalTitle.trim() : '';
    final rawTargetDate = args['target_date'];
    final targetDateStr = rawTargetDate is String ? rawTargetDate : '';
    final dailyHoursValue = args['daily_hours'];
    final rawPreferredTime = args['preferred_time'];
    final preferredTime = rawPreferredTime is String ? rawPreferredTime : null;
    final rawDaysPerWeek = args['days_per_week'];
    final daysPerWeek = rawDaysPerWeek is num ? rawDaysPerWeek.toInt() : null;

    if (goalTitle.isEmpty) return {'error': 'Goal title is required.'};
    if (dailyHoursValue is! num) {
      return {'error': 'Tell me how many hours to practice per session.'};
    }
    final dailyHours = dailyHoursValue.toDouble();
    if (!dailyHours.isFinite || dailyHours < 0.5 || dailyHours > 4) {
      return {'error': 'Practice duration must be between 0.5 and 4 hours.'};
    }
    if (daysPerWeek != 5 && daysPerWeek != 7) {
      return {
        'error':
            'Choose 5 weekdays or 7 days; other patterns are not supported yet.',
      };
    }
    if (!['morning', 'afternoon', 'evening'].contains(preferredTime)) {
      return {'error': 'Choose morning, afternoon, or evening.'};
    }

    final parsedTargetDate = DateTime.tryParse(targetDateStr);
    if (parsedTargetDate == null) {
      return {'error': 'Give me a valid target date in YYYY-MM-DD format.'};
    }
    final today = DateTime.now();
    final targetDate = dateOnly(parsedTargetDate);
    if (!targetDate.isAfter(dateOnly(today))) {
      return {'error': 'Target date must be in the future.'};
    }

    final startHour = switch (preferredTime) {
      'morning' => 8,
      'afternoon' => 14,
      'evening' => 19,
      _ => 14,
    };
    final practiceDates = GoalSchedulePlanner.practiceDates(
      now: today,
      targetDate: targetDate,
      daysPerWeek: daysPerWeek!,
      startHour: startHour,
    );
    if (practiceDates.isEmpty) {
      return {'error': 'No practice day falls before the target date.'};
    }
    final totalTargetHours = practiceDates.length * dailyHours;
    final durationMins = (dailyHours * 60).round();
    final conflict = await GoalSchedulePlanner.firstConflict(
      repository: _activityRepo,
      dates: practiceDates,
      startHour: startHour,
      durationMinutes: durationMins,
    );
    if (conflict != null) {
      return {
        'error':
            'Jadwal belum dibuat: waktu itu bentrok dengan '
            '"${conflict.activity.title}" pada ${_fmtDate(conflict.date)}. '
            'Pilih rentang waktu lain atau ubah hari latihan.',
      };
    }

    final primaryId = await _createSpan(
      title: '🎯 Latihan $goalTitle',
      date: practiceDates.first,
      startHour: startHour,
      startMin: 0,
      durationMinutes: durationMins,
      description:
          'Latihan untuk $goalTitle. Total rencana $totalTargetHours jam sebelum ${_fmtDate(targetDate)}.',
      recurrence: daysPerWeek == 7 ? 'daily' : 'weekday',
      recurrenceEndDate: practiceDates.last,
      focusGoalLink: goalTitle == focusGoal ? focusGoal : '',
      colorValue: 0xFF4A9EFF,
    );

    return {
      'success': true,
      'goal_title': goalTitle,
      'target_date': _fmtDate(targetDate),
      'practice_days': practiceDates.length,
      'total_hours_planned': totalTargetHours,
      'daily_hours': dailyHours,
      'primary_activity_id': primaryId,
      'message':
          'Latihan $goalTitle berulang sampai ${_fmtDate(practiceDates.last)}. Total ${practiceDates.length} sesi sebelum tanggal target.',
    };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(AmPmHalf half, int relMin) {
    final h = (half == AmPmHalf.pm ? 12 : 0) + relMin ~/ 60;
    final m = relMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  void reset() {
    _history.clear();
    _proposals.clear();
    _lastTurnProposalIds.clear();
    _initialized = false;
  }
}
