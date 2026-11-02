# PRD: Polish Timeblock Interaction & Drag Handles on Focus Clock

## Goal
Pastikan timeblock yang di-snap dari Kanban Preset Board dapat diinteraksikan dengan mulus di Analog Clockface:
1. Pastikan visual timeblock busur jam (arc sector) muncul jelas dengan warna preset yang sesuai.
2. Handle ujung awal dan akhir waktu timeblock di dial jam analog bisa di-drag secara responsif dengan snap 5 menit.
3. Sinkronkan perubahan drag tersebut langsung ke state Riverpod `activityRepoProvider`.
4. Pastikan UI bersih dan tidak ada error overflow pada layar mobile.
