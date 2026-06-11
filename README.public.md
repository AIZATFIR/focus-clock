# FocusClock

> **Time-blocking meets analog.** Schedule your day directly on a clock face — not a list.

FocusClock is a productivity app that visualizes your time blocks as arcs on an analog clock, making your day feel like a single coherent canvas instead of a fragmented to-do list. Built on the philosophy that **time is the only non-renewable resource**.

---

## Features

- **Analog clock workspace** — drag to create, long-press to reschedule, directly on the clock
- **Agenda view** — 24-hour vertical timeline with week navigation
- **Preset activities** — save your repeating blocks (Sleep, Work, Gym) as one-tap templates
- **AI assistant** — chat to reschedule: *"move my workout to 7am"* or *"block 2 hours for deep work after lunch"*
- **Smart notifications** — get reminded before each block starts
- **Dark / Light / System theme**

---

## Philosophy

Built on two principles:

**The ONE Thing** — structure your day around your most important block. Everything else fills around it.

**As above, so below** — the clock is the source of truth. The AI, agenda, and presets are all reflections of it.

---

## Tech Stack

- **Flutter** — cross-platform (Android, iOS, Linux, Web)
- **Riverpod** — reactive state management
- **Isar** — fast embedded local database
- **OpenRouter / Gemini** — AI assistant with function calling

---

## Getting Started

```bash
git clone https://github.com/AIZATFIR/focus-clock
cd focus-clock
flutter pub get
flutter pub run build_runner build
flutter run
```

Set your AI API key in **Settings → AI Configuration** (supports any OpenAI-compatible endpoint).

---

## Screenshots

*Coming soon*

---

## License

MIT — see [LICENSE](LICENSE)
