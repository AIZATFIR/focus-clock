# Design Spec: Focus Clock Web & Minimalist Zen Timer

**Date:** 2026-10-07  
**Author:** Pair programmed with AIZATFIR  
**Status:** Approved for Implementation  

---

## 1. Vision & Core Philosophy

### 1.1 The Breakthrough: Abundance Over Scarcity
Traditional productivity timers operate on anxiety and artificial scarcity (rigid countdowns that buzz loudly or mark you as "failed" if interrupted). This creates resistance to starting.

**The Focus Clock Paradigm:**
1. **The 10-Minute Minimum Rule:** The baseline goal is just 10 minutes. Hitting 10 minutes unlocks the "Goal Achieved" state. Every minute studied afterwards feels rewarding and effortless.
2. **Instant Emergency Stop (Stealth & Low Cognitive Friction):** When external interruptions occur (e.g., guru datang di kelas, meeting starts, friend calls), the user can stop or pause with a single tap, click, or Spacebar. No penalty, no guilt.
3. **Honest Time Awareness:** Records exact minutes studied and context ("Belajar LKS di Kelas - 23 Menit"). Builds genuine self-trust.
4. **Single-Function Simplicity:** One screen/tab dedicated to exactly one purpose at a time. Zero visual clutter.

---

## 2. System Architecture: 3 Focused Views

```
+--------------------------------------------------------------+
|   [ 📋 Tasks ]       [ 🕒 Clock Face ]       [ ⏱️ Focus Timer ] |
+--------------------------------------------------------------+
```

### View 1: 📋 Tasks (Google Tasks Simplicity — 3 Kolom)
A distraction-free, 3-column table designed for frictionless planning:

| Kolom | Deskripsi | Contoh |
| :--- | :--- | :--- |
| **APA** | Nama aktivitas / tugas utama | *Belajar LKS Bab 3*, *Coding Website* |
| **DIMANA** | Lokasi / Konteks lingkungan | *Kelas*, *Meja Belajar*, *Masjid*, *Online* |
| **KAPAN** | Rentang waktu atau jam target | *08:00 - 09:30* atau *+45m* |

- **Quick Add Bar (Top):** Input fields `[ Apa ]` `[ Dimana ]` `[ Kapan ]` + `[ Tambah (Enter) ]`.
- **Inline Row Actions:**
  - Checkbox selesai (coret tugas).
  - Tombol **Mulai Fokus** (langsung membuka View 3 dengan tugas terpilih).
  - Hapus / Edit inline tanpa modal dialog bertingkat.

### View 2: 🕒 Clock Face (Dial Raksasa & Tactile Drag)
An immersive, full-page 12-hour analog clock dial:
- **Ukuran:** Super besar, mendominasi layar secara elegan.
- **Irisan Waktu (Sectors):** Blok warna semi-transparan beradius jelas yang merepresentasikan jadwal dari Tab Tasks.
- **Tactile Drag & Slide:**
  - **Drag Body:** Memutar dan menggeser seluruh blok waktu (misal mundur/maju 30 menit).
  - **Drag Handles (Start/End):** Memperpanjang atau memperpendek durasi dengan magnetic snap per 5/15 menit.
  - **Live Floating Tooltip:** Menampilkan jam presisi yang sedang digeser (`08:15 — 09:45 (1j 30m)`).
- **Controls:** Toggle AM / PM (Pagi/Siang vs Sore/Malam) dan jarum penunjuk waktu saat ini (*Now Hand*).

### View 3: ⏱️ Zen Focus Timer (Fullscreen / Display-Over-Display)
The centerpiece focus environment:
- **Fullscreen Zen Mode:** Menghilangkan semua chrome browser dan antarmuka lain.
- **Display-Over-Display (Picture-in-Picture):** Mendukung Web Picture-in-Picture API (`documentPictureInPicture` / Canvas PiP) sehingga jam dan timer melayang di atas jendela aplikasi lain (misal di atas PDF LKS, VS Code, atau browser kerja).
- **Indikator Jam Analog & Digital:** Dial besar bergerak halus menunjukkan waktu berjalan.
- **10-Minute Golden Gate Marker:**
  - Menit 0–10: Progress ring bertahap warna amber lembut ("Menuju 10 menit pertama").
  - Menit 10+: Berubah warna menjadi emas/hijau emerald berpendar ("Target Minimal Tercapai! Bonus Fokus Aktif").
- **Instant Stop Button:** Tombol besar yang nyaman ditekan di mana saja, atau cukup tekan **Spacebar / Escape**.
- **Hasil Sesi Jujur:** Saat distop, sesi langsung tercatat rapi ke log riwayat belajar.

---

## 3. Data Model & Storage

All data is managed locally via `localStorage` with reactive state updates:

```javascript
// Task Object
{
  id: "uuid-1",
  what: "Belajar LKS Matematika",
  where: "Kelas",
  startMinute: 480,   // 08:00
  endMinute: 570,     // 09:30
  completed: false,
  color: "#F0C987"
}

// Session Log Object
{
  id: "sess-1",
  taskId: "uuid-1",
  what: "Belajar LKS Matematika",
  where: "Kelas",
  startedAt: 1728298800000,
  durationSeconds: 1420,  // 23m 40s
  achievedMinimum: true   // >= 10 minutes
}
```

---

## 4. Technology Stack & Deployment

- **Frontend Core:** Pure HTML5, Vanilla CSS3 (Obsidian Warm Bookpaper design system), Modern JavaScript (ES6+ Modules, SVG/Canvas).
- **Styling:** Custom CSS tokens, glassmorphism, typography (Google Fonts Inter & JetBrains Mono).
- **APIs:** HTML5 Fullscreen API, Picture-in-Picture API, Web Audio API (subtle haptic/audio clicks on snap and milestone), WakeLock API (mencegah layar laptop/HP mati saat timer jalan).
- **Deployment:** Vercel static deployment via `vercel.json` (`public/` or root directory).
