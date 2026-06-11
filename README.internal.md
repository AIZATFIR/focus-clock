# FocusClock

**Time-blocking analog clock app.** Buat, lihat, dan kelola time-blocks langsung di muka jam analog. AI assistant bisa reschedule via chat.

---

## Stack

| Layer | Tech |
|---|---|
| Framework | Flutter 3.41+ |
| State | Riverpod 2 (providers) |
| Database | Isar 3 (local, embedded) |
| AI | OpenRouter API (Gemini / any OpenAI-compat model) |
| Notifications | flutter_local_notifications |

---

## Cara Jalankan

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # generate Isar models
flutter run -d linux   # atau: android, chrome
```

---

## Arsitektur Codebase

```
lib/
├── main.dart                    ← entry point, init Isar + NotificationService
├── app.dart                     ← MaterialApp, theme switching
│
├── core/
│   ├── theme.dart               ← warna, font, dark/light theme
│   └── time_math.dart           ← konversi menit→jam, snap ke grid
│
├── models/                      ← Isar collections (data schema)
│   ├── activity.dart            ← 1 time-block (title, startMinute, endMinute, date, warna)
│   ├── preset.dart              ← template aktivitas (nama, warna, icon)
│   └── app_settings.dart        ← pengaturan user (tema, AI key, jam 24h, dll)
│
├── data/
│   ├── isar_service.dart        ← buka database Isar
│   └── repositories/
│       ├── activity_repository.dart  ← CRUD activities
│       ├── preset_repository.dart    ← CRUD presets
│       └── settings_repository.dart ← read/write settings
│
├── providers/
│   └── providers.dart           ← SEMUA Riverpod providers (state global)
│
├── services/
│   ├── ai_service.dart          ← OpenRouter API, tool calling (CRUD via AI)
│   └── notification_service.dart← jadwal notifikasi
│
├── features/
│   ├── shell/
│   │   └── home_shell.dart      ← BottomNav + PageView (3 tab)
│   │
│   ├── focusclock/
│   │   ├── focusclock_tab.dart  ← layar utama: jam interaktif, drag-create
│   │   └── analog_clock_face.dart ← CustomPaint: gambar jam, arcs, hands
│   │
│   ├── agenda/
│   │   └── agenda_tab.dart      ← timeline 24 jam, week strip
│   │
│   ├── presets/
│   │   ├── presets_tab.dart     ← list preset
│   │   └── preset_form_sheet.dart ← form buat/edit preset
│   │
│   ├── activity_detail/
│   │   └── activity_detail_sheet.dart ← form buat/edit/lihat activity
│   │
│   ├── ai_chat/
│   │   └── ai_chat_sheet.dart   ← chat AI (bottom sheet)
│   │
│   └── settings/
│       └── settings_screen.dart ← pengaturan (tema, AI key, jam format)
│
└── widgets/
    └── color_swatch_picker.dart ← reusable color picker
```

---

## Konsep Kunci

### Time System
- Jam dibagi 2 "half": **AM** (00:00–11:59) dan **PM** (12:00–23:59)
- Posisi di jam = **`startMinute` / `endMinute`** (0–719, di dalam half)
- `0` = 12:00 half itu, `60` = 01:00, `719` = 11:59
- Konversi ada di `lib/core/time_math.dart`

### Data Flow
```
Isar DB ──► Repository ──► Riverpod Provider ──► Widget
                               ▲
                        AI Service (tools)
```

### Providers Penting (`providers.dart`)
| Provider | Isi |
|---|---|
| `activitiesByHalfProvider` | Activities hari ini, filter AM/PM |
| `activitiesByDateProvider` | Activities full day (untuk Agenda) |
| `currentTimeProvider` | Stream waktu, tick tiap 1 detik |
| `settingsProvider` | AppSettings reaktif |
| `ampmHalfProvider` | AM atau PM sekarang |
| `currentDateProvider` | Tanggal aktif di-view |

### AI Tool Calling
`ai_service.dart` punya 4 tools yang dipanggil Gemini:
- `list_activities` — baca jadwal
- `create_activity` — buat time-block baru
- `update_activity` — edit/reschedule
- `delete_activity` — hapus

---

## Cara Edit Fitur

### Tambah field baru ke Activity
1. Edit `lib/models/activity.dart` — tambah field
2. Jalankan `flutter pub run build_runner build --delete-conflicting-outputs`
3. Update repository di `lib/data/repositories/activity_repository.dart`

### Ganti warna / tema
- Edit `lib/core/theme.dart` — `AppPalette` class

### Tambah tab baru
1. Buat file di `lib/features/<nama>/`
2. Daftarkan di `lib/features/shell/home_shell.dart` — `_tabs` list + `BottomNavigationBarItem`

### Tambah AI tool baru
- Edit `lib/services/ai_service.dart` — tambah ke `_tools` list + handle di `_executeTool()`

---

## Yang Belum Ada (Roadmap)

| Fitur | Priority |
|---|---|
| Conflict detection (overlap warning) | HIGH |
| Recurrence expansion (daily/weekly tampil) | HIGH |
| Google Calendar sync | MED |
| Eisenhower Matrix view | MED (SFT) |
| Dynamic Audio Reschedule | MED (SFT) |
| Lifestyle Blueprint | MED (SFT) |

---

## Env / Secrets

Simpan di `.env` (jangan commit):
```
AI_API_KEY=sk-...
AI_BASE_URL=https://openrouter.ai/api/v1
AI_MODEL=google/gemini-2.0-flash-exp:free
```
Untuk sekarang diisi manual lewat Settings screen di app.
