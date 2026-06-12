# FocusClock — Internal Dev Guide

**Time-blocking analog clock app.** Buat, lihat, dan kelola time-blocks langsung di muka jam analog. AI assistant bisa reschedule via chat.

> Repo ini = repo kerja (private). Showcase public + releases: [AIZATFIR/focus-clock](https://github.com/AIZATFIR/focus-clock)

---

## Stack

| Layer | Tech |
|---|---|
| Framework | Flutter 3.41+ |
| State | Riverpod 2 (providers) |
| Database | Isar 3 (local, embedded) |
| AI | OpenAI-compat function calling — default Google AI Studio (`gemini-2.5-flash`), bisa Groq/OpenRouter/Ollama |
| Notifications | flutter_local_notifications |
| CI | GitHub Actions — build APK (ubuntu) + Windows zip (windows) tiap push master |

---

## Cara Jalankan

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # generate Isar models
./run.sh               # linux desktop (default)
./run.sh android       # HP via USB
flutter build apk --release   # APK → build/app/outputs/flutter-apk/
```

API key AI diisi lewat Settings → AI Configuration (ada panduan in-app per provider).

---

## Arsitektur Codebase

```
lib/
├── main.dart                    ← entry point, init Isar + NotificationService
├── app.dart                     ← MaterialApp, theme switching
│
├── core/
│   ├── theme.dart               ← AppPalette, dark/light/AMOLED, NoSplash global
│   └── time_math.dart           ← snap5, splitSpan (cross-midnight), konversi menit
│
├── models/                      ← Isar collections (data schema)
│   ├── activity.dart            ← 1 time-block (startMinute/endMinute 0-719, groupId utk cross-midnight)
│   ├── preset.dart              ← template aktivitas (nama, warna, icon)
│   └── app_settings.dart        ← settings user (tema, AI config, jam 24h)
│
├── data/
│   ├── isar_service.dart        ← buka database Isar
│   └── repositories/
│       ├── activity_repository.dart  ← CRUD + replaceSpan (cross-midnight) + recurring projection
│       ├── preset_repository.dart
│       └── settings_repository.dart
│
├── providers/
│   └── providers.dart           ← SEMUA Riverpod providers (state global)
│
├── services/
│   ├── ai_service.dart          ← function calling: 6 tools, Fitrah Blueprint, circadian context
│   ├── gcal_service.dart        ← Google Calendar sync (Android/iOS/macOS)
│   └── notification_service.dart
│
├── features/
│   ├── shell/
│   │   └── home_shell.dart      ← TabBar atas (3 tab) + PageView + wide button → AI page full-screen
│   ├── focusclock/
│   │   ├── focusclock_tab.dart  ← jam interaktif, drag-create, Eisenhower popup button, AM/PM mini
│   │   └── analog_clock_face.dart ← CustomPaint: dial 720 menit, 144 ticks, aura, outer minute ring
│   ├── agenda/agenda_tab.dart   ← timeline 24 jam, week strip
│   ├── presets/                 ← list + form preset, drag ke jam
│   ├── activity_detail/         ← form activity (cross-midnight picker, color, deadline, importance)
│   ├── ai_chat/ai_chat_sheet.dart ← AiChatPanel (dipake di AI page full-screen)
│   ├── eisenhower/              ← matrix 4 kuadran (muncul sbg modal popup dari clock tab)
│   ├── weekly_review/           ← stats mingguan + AI review
│   └── settings/settings_screen.dart ← provider presets + panduan API key in-app
│
└── widgets/color_swatch_picker.dart
```

---

## Konsep Kunci

### Time System
- Jam dibagi 2 "half": **AM** (00:00–11:59) dan **PM** (12:00–23:59)
- Posisi = `startMinute`/`endMinute` **0–720 di dalam half** (dial = 720 menit)
- **Cross-midnight**: 1 blok logis (tidur 22:00→05:00) = beberapa row Activity yang share `groupId`. Split pakai `splitSpan()` di `time_math.dart`, tulis pakai `ActivityRepository.replaceSpan()`. AI tools juga lewat jalur ini.
- Recurring: row asli di-project ke tanggal target di repository (`_getRecurring`), bukan duplikasi row.

### Data Flow
```
Isar DB ──► Repository ──► Riverpod Provider ──► Widget
                               ▲
                        AiService (function calling)
```

### Providers Penting (`providers.dart`)
| Provider | Isi |
|---|---|
| `activitiesByHalfProvider` | Activities hari ini, filter AM/PM |
| `activitiesByDateProvider` | Activities full day (Agenda) |
| `currentTimeProvider` | Stream waktu, tick 1 detik |
| `settingsProvider` | AppSettings reaktif |
| `aiServiceProvider` / `aiTranscriptProvider` | AI chat state |
| `eisenhowerActivitiesProvider` | Upcoming 14 hari utk matrix |

### AI Tool Calling (`ai_service.dart`)
6 tools: `list_activities`, `create_activity`, `update_activity`, `delete_activity`, `set_priority`, `generate_blueprint`.
- System prompt: Fitrah rules (Deep Work max 90–120m, Intentional Rest no-screen, sleep kelipatan 90m) + konteks energi sirkadian per jam.
- Cross-midnight: model diinstruksikan 1 call full-duration; `_createSpan()` yang split.

---

## Cara Edit Fitur

### Tambah field baru ke Activity
1. Edit `lib/models/activity.dart` — tambah field
2. `dart run build_runner build --delete-conflicting-outputs`
3. Update repository di `lib/data/repositories/activity_repository.dart`

### Ganti warna / tema
- `lib/core/theme.dart` — `AppPalette` class

### Tambah tab baru
- `lib/features/shell/home_shell.dart` — `TabBar` tabs + `PageView` children (sekarang 3: Presets, Clock, Agenda)

### Tambah AI tool baru
- `lib/services/ai_service.dart` — tambah ke `_tools` list + case di `_executeTool()`

### Update README public (repo showcase)
- Edit `README.public.md` di sini, lalu push isinya ke README.md repo `focus-clock` (via `gh api` atau commit manual di repo public)

---

## Roadmap

| Fitur | Status |
|---|---|
| Conflict detection (manual drag) | ✅ done |
| Recurrence daily/weekly | ✅ done |
| Google Calendar sync | ✅ done (Android) |
| Eisenhower Matrix | ✅ done (popup) |
| Weekly Review + AI | ✅ done |
| Fitrah Blueprint | ✅ done |
| Cross-midnight blocks (manual + AI) | ✅ done |
| Conflict check di AI tools | 🔜 HIGH |
| Notif runtime permission Android 13+ | 🔜 HIGH |
| Fix recurring completion (id sama → done nular semua hari) | 🔜 HIGH |
| Onboarding first-run | 🔜 MED (SFT demo) |
| Active AI Agent (branch `feat/active-ai-agent`) | 🔜 MED — belum merge |
| Dynamic Audio Reschedule | 🔜 MED (SFT killer feature) |
| Demo mode `--dart-define` API key | 🔜 LOW |

---

## Distribusi

- **Release public**: https://github.com/AIZATFIR/focus-clock/releases — APK + Windows zip
- CI otomatis build tiap push master; artifact di tab Actions (perlu login GitHub)
- Upload release baru: `gh release create vX.Y.Z <file> --repo AIZATFIR/focus-clock`

## Catatan Keamanan

- **Jangan commit API key.** Key AI user disimpan di Isar (lokal device), bukan di repo.
- README/dokumen: contoh key pakai placeholder (`sk-...`, `gsk_...`), jangan key asli.
