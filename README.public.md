<div align="center">

# 🕐 Focus Clock

**Time-blocking meets analog. Schedule your day directly on a clock face — not a list.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-success)]()
[![Release](https://img.shields.io/github/v/release/AIZATFIR/focus-clock)](https://github.com/AIZATFIR/focus-clock/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

*Built for Samsung Solve for Tomorrow 2026 by team **AC-NYA MATIIN WOY** — SMKN 2 Surakarta*

</div>

---

## 📥 Download

| Platform | File | How to run |
|---|---|---|
| **Android** | [`app-release.apk`](https://github.com/AIZATFIR/focus-clock/releases/latest) | Download on your phone → tap to install |
| **Windows** | [`focus-clock-windows.zip`](https://github.com/AIZATFIR/focus-clock/releases/latest) | Extract → run `focus_clock.exe` |

No account, no sign-up. All your data stays on your device.

---

## ✨ What is Focus Clock?

Most planners are lists. Focus Clock is a **720-minute analog dial** — your whole morning or evening visible as one canvas. Activities are arcs you **drag directly onto the clock**, so you *see* your day instead of reading it.

### Core features

🕐 **Analog clock workspace**
- Drag on the dial to create an activity (snaps to 5 minutes)
- Long-press an arc to move it; double-tap to edit
- Live "now" hand + pulse ring on your current activity
- AM/PM halves, 12h/24h labels, expandable minute ring

🤖 **AI Scheduling Assistant**
- Chat naturally: *"buatkan jadwal belajar sore ini"* or *"move my workout to 7am"*
- **Fitrah Blueprint** — generates a science-based day plan: 90-minute Deep Work blocks (ultradian rhythm), screen-free Intentional Rest (memory consolidation), sleep in 90-minute cycles
- Handles cross-midnight blocks correctly (sleep 22:00 → 05:00 = one block)
- Bring your own key: **Google AI (default, free)**, Groq, OpenRouter, OpenAI, or local Ollama — step-by-step key guide built into Settings

📋 **Eisenhower Matrix**
- Every task auto-classified by urgency (deadline) × importance
- DO / SCHEDULE / DELEGATE / ELIMINATE quadrants in one tap

📊 **Weekly Review**
- Completion stats per week + AI-generated reflection on your schedule patterns

🗓 **More**
- Agenda view (24-hour vertical timeline, week navigation)
- Preset activities — drag a saved template straight onto the clock
- Google Calendar sync (Android)
- Smart notifications before each block
- Dark / Light / AMOLED black themes

---

## 🧠 The science behind it

Focus Clock schedules around how the brain actually works:

- **Ultradian rhythm** — the brain focuses in ~90-minute cycles. Deep Work blocks are capped at 90–120 minutes.
- **Intentional Rest** — after deep focus, the Default Mode Network consolidates memory. The app schedules screen-free rest explicitly.
- **Sleep cycles** — sleep blocks are built in 90-minute multiples to avoid waking mid-cycle.
- **Circadian energy** — the AI knows 07:00–11:00 is peak focus and the 14:00 dip is for light work, and plans accordingly.

---

## 🛠 Tech stack

| Layer | Tech |
|---|---|
| UI | Flutter 3 (Material 3, CustomPaint clock face) |
| State | Riverpod 2 |
| Database | Isar (embedded, on-device — no server) |
| AI | OpenAI-compatible function calling (Google AI / Groq / OpenRouter / Ollama) |
| Sync | Google Calendar API (optional) |

---

## 🚀 Build from source

```bash
git clone https://github.com/AIZATFIR/focus-clock
cd focus-clock
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

For the AI assistant, add a free API key in **Settings → AI Configuration** (in-app guide shows how to get one in under a minute).

---

## 📄 License

MIT
