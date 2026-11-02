# PRD: Focus Clock — Onboarding Guidance & Kanban Preset Snap

## Objective
Sederhanakan interaksi Focus Clock ke esensi paling murni:
1. **Guidance Awal (Onboarding Preset):**
   - Saat user pertama kali buka atau klik tombol "Setup Rutinitas", muncul sheet/dialog panduan ramah & to-the-point: "Aktivitas apa saja yang kamu miliki sehari-hari?"
   - User bisa menambahkan preset aktivitas dengan cepat (cth: Sholat, Deep Work/Coding, Belajar, Istirahat, Olahraga) dengan warna & durasi default.
2. **Kanban Preset Board (Bawah / Samping Jam):**
   - Menampilkan kartu-kartu aktivitas preset yang sudah dibuat dalam bentuk horizontal/kanban board minimalis.
   - Sekali **TAP** pada kartu kanban: aktivitas langsung **SNAP** masuk ke dalam `analog_clock_face` sebagai time-block aktif berikutnya.
   - User tinggal drag/geser handle waktu mulai & selesai di busur clockface untuk menyesuaikan.
   - Tanpa input form jam:menit yang rumit. 1 tap = langsung nempel di jam.

## Technical Architecture
- Repository: `/home/aizatfir/projects/focus-clock`
- Tech Stack: Flutter (Web/Mobile) + Riverpod 2
- Files to touch:
  - `lib/features/focusclock/widgets/preset_kanban_board.dart` (NEW)
  - `lib/features/focusclock/widgets/onboarding_guidance_sheet.dart` (NEW)
  - `lib/features/focusclock/focusclock_tab.dart` (Mount Preset Kanban & Onboarding trigger)
  - `lib/features/focusclock/analog_clock_face.dart` (Ensure snap handler accepts instant preset insertion)

## Delivery Rule
- Keep code clean, lazy senior developer mindset.
- No unneeded dependencies.
- Flutter format & test check.
