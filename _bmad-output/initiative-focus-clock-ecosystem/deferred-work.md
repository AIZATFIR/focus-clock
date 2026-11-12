- source_plan: `_bmad-output/initiative-focus-clock-ecosystem/plan-aura-exact-practice-time.md`
  summary: Validate goal-schedule target dates strictly as YYYY-MM-DD before converting them to date-only values.
  evidence: `DateTime.tryParse` accepts an offset timestamp; `2026-11-20T00:30:00+14:00` parses as 2026-11-19 10:30 UTC, and `dateOnly` then schedules 2026-11-19. This behavior predates the exact practice-time change and is a separate target-date validation issue.
