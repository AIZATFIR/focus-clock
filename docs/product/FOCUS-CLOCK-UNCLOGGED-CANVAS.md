# Focus Clock Unclogged Canvas

**Status:** Build direction from owner intent, 2026-11-10
**Scope:** The Focus Clock day view and its first activity-entry interaction.

## Product decision

Focus Clock is a visual map of how a person is spending a day in service of a chosen goal. The clock is the canvas. It starts empty when the person has not planned anything; it must not seed a fake schedule or pressure them to fill every hour. The goal and the current/next cue give orientation without turning the screen into a dashboard.

Keep the current analog dial, its warm bookpaper palette, and its time arcs. Make drawing optional. A person can tap a time on an empty part of the dial, name the activity, accept a sensible 30-minute default, and place it. The existing drag gesture remains for people who prefer to sketch a longer block. A cancelled entry saves nothing.

## Current friction found in code

- `FocusClockTab._onTapUp` only opens an activity when the tapped minute already has a block. A tap on empty time returns without action.
- Creating a block on blank time requires a drag, then the preset/custom sheet. Dragging must estimate both start and end before the user can say what the activity is.
- Dismissing that picker after a drag can save a generic `Fokus Xm` activity. This makes cancel behave like save.
- The lower `NowNextCard` already carries the main goal and current/next activity; keep that as the orientation layer and avoid adding more permanent controls over the clock.

## Interaction contract

| State | What the user sees / can do |
| --- | --- |
| No planned activities | Empty dial, current time and goal cue; tap an hour arc to place the first block. No demo data. |
| Tap empty dial space | A small composer opens with the tapped start time and 30 minutes preselected. |
| Composer open | One activity name field; a few duration choices; one clear “Place on clock” action. |
| Name empty | Save is disabled; no blank placeholder can be written. |
| Cancel / back / outside dismissal | Composer closes and no activity is saved. |
| Save | Activity appears in the dial at the selected time and duration; existing repository and sync path are used. |
| Tap existing block | Existing detail view remains available. |
| Drag on empty dial | Existing draw-to-block gesture remains available; it is an alternate path. |
| Tap beyond the visible day/half | Start is clamped to the last valid 5-minute position; duration choices cannot cross the visible boundary. |

## Measurable acceptance criteria

1. First activity can be placed with a tap, a name, and one save action; no drag or preset choice is required.
2. A dismissed/empty composer creates zero records; a confirmed entry creates exactly one.
3. Tap-to-add respects 12-hour AM/PM and 24-hour dials, and the resulting block stays within the represented day segment.
4. Existing activity taps, direct drag creation, activity detail editing, and the bookpaper clock theme keep working.
5. The empty state contains no fabricated activities and no streak or guilt language.

## Research notes and design implications

- Apple recommends reasonable prefilled values and supports multiple ways to enter data. The 30-minute default reduces required input while leaving the user in control. [Apple HIG: Entering Data](https://developer.apple.com/design/human-interface-guidelines/entering-data)
- Apple's picker guidance says to keep controls near the content being edited and to avoid extra visual weight for short choice lists. The composer therefore stays small and the duration options stay inline. [Apple HIG: Pickers](https://developer.apple.com/design/human-interface-guidelines/pickers)
- Material's time-picker guidance says mobile users should be able to enter time manually rather than being forced to use a dial. The clock face is a visual placement surface, not the only precise time-entry method. [Material Design: Time Pickers](https://m2.material.io/components/time-pickers/web)
- A 2026 U.S. Census Bureau study with 1,000 participants found calendar entry more efficient than text or dropdowns for near-date entry tasks, especially where weekday knowledge mattered. This concerns choosing dates, not drawing time blocks; it supports keeping the familiar calendar for dates while simplifying intraday activity placement. [Rivas et al., 2026](https://www.census.gov/library/working-papers/2026/adrm/rsm2026-08.html)

The product-specific recommendation is an inference from these sources and the current code: use the clock for quick spatial placement, a plain text field for naming, and a small set of duration choices for editing. Keep manual adjustment available; never require pixel-precise dragging.

## Not part of this slice

- Replacing the analog dial with a literal spiral or a new visual system.
- AI silently filling the schedule. A future agent can suggest a plan from a goal; the person must see and accept edits before they land on the clock.
- Streaks, full-day auto-scheduling, extra dashboards, or a new account/sync dependency.
