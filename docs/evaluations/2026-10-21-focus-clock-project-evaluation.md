# Focus Clock project evaluation

**Date:** 21 October 2026  
**Scope:** Static orientation of `Focus Clock - Claude` and nearby project references, to prepare follow-up repair and development work.  
**Method:** Read project docs, package manifests, key entry points and representative timer/store code. No environment files or credentials were read.

## Executive assessment

The repository contains a substantial Flutter application and a separate vanilla-JavaScript web implementation. The owner selected the earlier Flutter Focus Clock experience as the web fallback, and the build now uses that source. The next design pass should preserve its large clock and intent cue while reducing competing UI in small, reviewable steps.

**Current readiness:** the first goal-first slice is implemented in the restored Flutter experience. It adds one persistent user-owned goal cue to the existing home card. This is not a release verdict; activity-to-goal links and runtime accessibility still need review.

## Owner's current product direction

**Core function: visualize.** Focus Clock should keep a person's meaningful goal visible because attention and memory drift. A short goal such as “Fokus LKS” on a launcher or phone lock screen can do more for the product than another dense planning surface.

The clock face gives that goal a view of the day: what time contains, what is happening now, what comes next, and how those activities support the goal. The product should help the user keep a steady balance between delayed rewards and immediate pleasure. The user's grounding for that balance is Tauhid and the understanding of God as Ar-Rahman and Ar-Rahim. The interface should support that belief without guilt or moral judgment.

The SFT education theme was competition framing. The current direction is broader: everyday life and practical benefit. Treat this owner clarification as the current product requirement when older proposal material points elsewhere.

### How to read the attached papers

- The **Concept Paper** supports circular time as a visual space, conflict-aware scheduling, and attention to biological rhythms. It also proposes an IoT ecosystem: a physical dial, ambient lighting, desk controls, presence sensors, wearables, and office integrations. Those proposals are historical options, not current implementation requirements.
- The **Progress Report** records an SFT-era Flutter implementation and a future roadmap for IoT and AI. Its completion statements describe the report's snapshot; this evaluation did not verify them against builds or devices.
- When an old competition objective or roadmap conflicts with the owner's current direction, follow the current direction above.

### Product checks for the next design pass

1. Put the user's current goal in the first visual field on the launcher or home screen.
2. Make the clock answer “What am I doing with my day?” and “What should I do now?” at a glance.
3. Connect the current and next activity to the goal without adding explanatory clutter.
4. Remove or demote controls and panels that draw attention away from that goal.
5. Keep lock-screen or launcher visibility as a product direction; confirm platform feasibility when implementation begins.

### Review of the Antigravity handoff supplied on 21 October

The handoff captures the owner's central direction, but it mixes direct owner statements with agent-generated product decisions. Use the user's direct statements as requirements; treat the handoff's examples, palette, exact UI behavior, acceptance thresholds, and next-step proposal as hypotheses until independently confirmed.

At the start of this evaluation, the selected browser page used the static implementation below. It remains under `web-app/`, but the Focus Clock build now uses `lib/main.dart`:

- The first view is a task scheduler. The header opens on Tasks and offers separate Clock Face and Timer tabs (`web-app/index.html:22-58`).
- The scheduler asks for task, place, and time, then shows today's task count and completion count (`web-app/components/tasks-view.js:8-75`).
- The web store persists tasks and timer sessions, but has no separate long-term or daily goal field (`web-app/store.js:1-53`).
- The clock draws scheduled task sectors on a 12-hour dial. It has no visible link from those sectors to an overarching goal (`web-app/components/clock-face.js:4-29`).
- The web app loads Outfit, Plus Jakarta Sans, and JetBrains Mono, not Inter (`web-app/index.html:8-14`). Do not treat the handoff's Inter/obsidian palette as a confirmed owner decision.
- Flutter Focus Clock output now uses `build/web`; Flutter Sadar output remains separate at `build/sadar/web` (`package.json`).

Not established by this repository review: Antigravity's historical commit narrative, live Vercel deployment state, Sadar/Fitrah test results, cross-app sync behavior, and Android lock-screen prototype status. The handoff's `3/5` completion ratio, 45-minute example, one-second rendering target, mandatory one-tap CTA, query-parameter deep link, exact palette, and three proposed unknowns are not direct requirements in the owner's supplied statements. Keep them out of acceptance criteria unless the owner adopts them.

The handoff's suggested next action—deep-linking Sadar or Fitrah into Focus Clock with `autoStart=true`—is an agent recommendation, not an approved priority. It also crosses repository boundaries. Do not implement it based on the handoff alone.

### UI fallback target

The owner confirmed the desired fallback is the earlier Flutter Focus Clock experience, before the standalone “Simplicity First” web redesign: the large analog dial with the “Waktu Luang” / intention-entry card. The source remains in `lib/features/focusclock/`; Antigravity's September browser capture `focus_clock_main_view_1787537710242.png` corroborates the target. The mistaken static-web restoration from `origin/master` (`6bece3a`) is no longer the default build target. `build` and `build:focus` now compile `lib/main.dart` to `build/web`; Sadar remains isolated at `build/sadar/web`. No deploy, commit, or push was performed.

The separate `web-app/` implementation and its timer persistence changes remain available as historical code, but are not used by the Focus Clock build. The temporary goal-cue experiment was removed.

### Design review

Applied Apple Design principles as general design guidance; this web review does not claim Apple-platform compliance. The restored Flutter screen returns to a large analog dial with a “Waktu Luang” / intention-entry cue, matching the selected historical capture. A persistent `focusGoal` now appears in that existing card and can be edited in place; hard-coded suggestion chips were removed. The goal is not yet connected to individual scheduled activities, and there is no launcher/lock-screen surface in this slice. The earlier static implementation still puts task entry first and initializes an ambient canvas (`web-app/components/tasks-view.js`, `web-app/app.js`); it is no longer the default build. Accessibility, reduced motion, keyboard flow, touch sizing, and screen-reader output still need a focused runtime pass before release claims.

## Product and code references

- [`PROJECT_MAP.md`](../../../PROJECT_MAP.md) identifies this folder as the primary Focus Clock repository and records `focus-clock-agent` and `focus-clock-ui` as worktrees of the same Git repository. Their branches are older June 2026 snapshots; use them as historical references, not independent products.
- [`README.md`](../../README.md) presents the full cross-platform Flutter product: analog time-blocking, AI scheduling, Eisenhower matrix, weekly review, agenda and optional Google Calendar.
- [`ARCHITECTURE.md`](../../ARCHITECTURE.md) describes a shared Focus Clock/Sadar architecture and a versioned integration contract.
- [`docs/product/PRD-1-PHILOSOPHY.md`](../product/PRD-1-PHILOSOPHY.md), [`PRD-2-SPECIFICATION.md`](../product/PRD-2-SPECIFICATION.md) and [`PRD-3-ENGINEERING-QUALITY.md`](../product/PRD-3-ENGINEERING-QUALITY.md) are Sadar-focused baselines, despite living in the Focus Clock folder. They are useful for timer reliability and data-integrity principles, but are not a complete Focus Clock product spec.
- [`docs/superpowers/specs/2026-10-07-focus-clock-web-timer-design.md`](../superpowers/specs/2026-10-07-focus-clock-web-timer-design.md) and its implementation plan specify a different, simpler web experience: Tasks / Clock Face / Zen Timer, local storage, ten-minute milestone, fullscreen and PiP.
- [`focus-clock-agent/README.md`](../../../focus-clock-agent/README.md) and [`focus-clock-ui/README.md`](../../../focus-clock-ui/README.md) are useful for earlier Flutter architecture and roadmap context. Their docs predate the current richer Flutter shell.
- `java-experimental/Cool Apps/Focus Clock/README.md` is a generated Java starter README and is not a meaningful product reference.

## Findings

### P0 — Goal-to-activity relationship remains unfinished

The restored Flutter web experience now stores and displays one overarching life goal in the existing home card. Scheduled activities and current/next context do not yet explain how they support that goal. Keep the goal visible while exploring that relationship; avoid adding competing panels.

### P1 — Define the source of truth for platform and product scope

The repository contains a Flutter Focus Clock app and a separate vanilla-JavaScript experiment. The Focus Clock web build now uses Flutter `lib/main.dart` and writes to `build/web`; Sadar writes to `build/sadar/web`. The static app remains in `web-app/` but is not the default Focus Clock build. Android and desktop identity/build support still need their own release checks.

### P1 — Product documentation is split across products and generations

The root README advertises a large feature set, while the current web specification intentionally narrows the web experience to three focused views. Sadar PRDs are in the same product docs folder and the architecture covers both apps. There is no single current Focus Clock specification that maps each promise to the Flutter app, web app, platform support, and verification evidence. This makes it hard to choose what to fix first or know which claims are still current.

### P1 — Platform and persistence guarantees need evidence

The Flutter entry point initializes Firebase, Isar, notifications and desktop window/tray behavior, with fallback/error handling. The repository has nine Dart test files and one JS test file, but this inventory does not establish coverage or passing status. The Sadar engineering baseline calls out offline operation, historical snapshots, idempotency, midnight attribution and timer recovery; follow-up evaluation should verify these against actual code and platform behavior rather than assume the architecture document guarantees them.

### P2 — Repository contains substantial generated and release output

There are 65 Dart source files, nine Dart test files, separate `web-app`, `web`, `public`, build and release directories. `build` occupies about 4.5 GB locally and includes generated outputs; 76 files under `build`, `web` and `public` are tracked. This raises review and maintenance overhead. Before cleanup, identify which output directories are intentional deployment inputs and compare them with `.gitignore`, Vercel configuration and release workflow.

### Workspace note — preserve the existing README edit

At evaluation time, Git reports a pre-existing local modification in the root `README.md` consisting of Markdown trailing-space changes. It was not altered as part of this evaluation.

## Evaluation checklist for the repair phase

1. **Scope and target:** Name the canonical Focus Clock implementation per platform; map each public README claim to code and a supported platform. In the selected home view, show the goal before task-entry controls.
2. **Timer correctness:** Verify elapsed duration after backgrounding, sleep, app restart, pause/resume, stop, duplicate actions and crossing midnight. Recorded duration should derive from timestamps.
3. **Schedule correctness:** Check 12-hour/24-hour conversion, AM/PM boundaries, cross-midnight blocks, overlap handling, recurrence and daylight-saving/time-zone changes where applicable.
4. **Persistence and recovery:** Verify offline CRUD, schema migration/recovery, historical snapshots, active timer recovery and safe behavior when optional Firebase/AI services are unavailable.
5. **Interaction and accessibility:** Exercise clock create/edit/drag, keyboard shortcuts, reduced motion, touch targets, narrow windows/mobile layouts, focus order and readable contrast.
6. **AI and integration boundaries:** Verify tool calls cannot create invalid/conflicting schedules, provider/key handling is clear, and Focus Clock/Sadar contract versioning remains backward compatible.
7. **Build and release path:** Confirm each platform build consumes the intended source, deployment target, app identity/version, assets and signing setup. Keep Flutter Focus web and static web output isolated if both remain supported.

## Suggested follow-up order

1. Audit the home and clock surfaces against the goal-first criteria above.
2. Confirm product/platform source-of-truth and deployment outputs.
3. Audit timer and scheduling invariants, then repair the highest-confidence correctness failures.
4. Verify the selected implementation and record platform coverage.
5. Reconcile README, product spec, architecture and build scripts with verified behavior.
6. Select feature development from the clarified product direction.

## Follow-up status

- The separate static timer has timestamp-based recovery work and prior focused store checks (12/12), but that code is not part of the selected Flutter web build. Check Flutter timer behavior independently before relying on those results.
- Confirmed pre-Simplicity-First fallback: Flutter Focus Clock source from the September-era product, visually corroborated by the Antigravity capture. `build:focus` now targets `lib/main.dart`; the Flutter web build succeeds to `build/web`.
- As of this evaluation date, the first goal-first slice was a user-editable, persisted `focusGoal` shown in the existing “Waktu Luang” card. Activity-to-goal linking was not implemented then.
- As of 21 October, Sadar web output remained isolated at `build/sadar/web` and no deployment had been run.
- The pre-existing root `README.md` edit remains untouched.
- No new goal-cue feature was added during the 21 October evaluation. Its recommendation was to continue from the restored Flutter visual base and review screenshots in small iterations.

## Verification update — 12 November 2026

- The clock now supports tap-to-add from empty dial time, a 30-minute default, optional focus-goal linking, and cancel-before-save. Seven focused tests passed for tap-to-add, empty-name blocking, duration selection, goal linking, AM/PM and 24-hour conversion, and the midnight boundary. See [the unclogged-canvas status](../product/FOCUS-CLOCK-UNCLOGGED-CANVAS.md).
- Aura asks what the user is working toward, keeps provider requests within 30 seconds, maps failures to a user-facing message, migrates legacy BYOK keys into secure storage, and keeps new keys out of the Isar settings record. Thirteen focused AI tests passed.
- Focus sessions now use a deadline instead of counting timer callbacks, and saved browser snapshots include `savedAt`; restored running sessions subtract elapsed time while paused sessions retain their remaining time. The contract suite passes 11 tests, including recovery and pause behavior; targeted analysis of the changed Dart files is clean.
- Focus Clock `v0.5.2-preview.9` is published with Android, Linux, Web, and Windows assets. The Vercel status is successful and `focus-clock-web.vercel.app/version.json` reports build 9.
- The combined download package is [r5](https://github.com/AIZATFIR/focus-clock/releases/tag/v0.5.2-preview.9)'s Focus Clock build alongside Sadar `v1.5.2-preview.3` and Fitrah Launcher `v0.5.5-preview.1`. Its 13 internal checksums and ZIP integrity were verified.
- Sadar and Fitrah source commits and web bundles are on their GitHub default branches, but those commits have no Vercel status. Sadar's public URL still reports `0.4.0`; `fitrah-web.vercel.app/version.json` returns 404 and the domain serves a page unrelated to the Flutter bundle. Their Vercel projects/domains are not demonstrably connected to these repositories, so Git push alone has not updated either site.
- These checks do not establish device-level Android behavior, the full timer/schedule audit, or working cross-app synchronization.

## Limits

At the original 21 October evaluation, this was a source-oriented review with prior static timer checks, a successful Flutter web build, and static analysis of edited Dart files. The goal editor was not exercised through a save/reload browser session; no deployment, mobile device run, remote repository inspection, or runtime performance measurement had been performed by that evaluation. The 12 November update above records later evidence and limits.
