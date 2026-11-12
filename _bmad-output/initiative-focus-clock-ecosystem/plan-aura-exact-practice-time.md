---
title: 'Aura schedules goal practice at the user's chosen time'
type: 'feature'
ticket: ''
created: '2026-11-12'
status: 'built'
baseline_revision: '561a4e4b365c65b4d300007611723914d706fa3e'
route: 'oneshot'
route_source: 'auto'
risk: 'medium'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - docs/handoffs/2026-10-21-focus-clock-owner-intent.md
  - docs/evaluations/2026-10-21-focus-clock-project-evaluation.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Aura can only schedule goal practice at three fixed times (08:00, 14:00, or 19:00), even though it asks users about their actual practice time. That makes a plan unusable for people whose school, work, or energy rhythm does not fit those defaults.

**Approach:** Ask for an exact, user-chosen local start time in 24-hour `HH:mm` format and use it when drafting recurring practice sessions. Keep date, duration, frequency, conflict checks, and explicit Apply/Cancel confirmation; never substitute a guessed time.

</frozen-after-approval>

## Implementation Notes

Oneshot route: one cohesive planner behavior across `lib/services/ai_service.dart`, `lib/services/goal_schedule_planner.dart`, `test/ai_service_test.dart`, and `test/goal_schedule_planner_test.dart`. The shared tool schema keeps the exact-time input consistent across configured model providers.

- Replaced the three fixed periods with a user-confirmed local start time in `HH:mm`; the proposal preview now shows that exact value.
- Passed minute precision through today's elapsed-time check, recurring conflict detection, and activity creation. Sessions that would cross midnight are rejected because the recurrence model stores split day segments separately.
- Conflict checks now reject out-of-range hours/minutes and nonpositive durations; a regression test was observed failing before that guard and passing after it.
- Bumped the Focus Clock preview to `0.5.2+10` and added a static web version manifest so the GitHub release build and Vercel bundle carry the same build number.
- RED evidence: the new integration test showed the proposal only said "waktu belum dipilih" for `16:30`; the minute-boundary test failed to compile because the planner accepted only whole hours; the overnight test showed no rejection. All three passed after implementation.
- Verification: the focused AI/planner set passed 18 tests; the full Flutter suite passed 73 tests with concurrency 1; `flutter analyze --no-pub` found no issues.

## Verification

**Commands:**
- `flutter test --no-pub test/goal_schedule_planner_test.dart test/ai_service_test.dart` -- expected: all tests pass, including exact-time scheduling, elapsed-today handling, conflicts, and confirmation-before-write.
- `flutter test --no-pub --concurrency=1` -- 73 tests passed.
- `flutter analyze --no-pub` -- no issues found.

## Review Triage Log

- low / patch — `firstConflict` accepted an invalid minute and zero duration; the new test failed before the guard and passed after it.
- medium / defer — `DateTime.tryParse` accepts offset timestamps for `target_date`; verified `2026-11-20T00:30:00+14:00` becomes 2026-11-19 before `dateOnly`. This predates the exact-time change and is tracked in `deferred-work.md`.
