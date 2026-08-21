# Technical Design Specification: Life Blueprint & Routine Template Maker

**Date**: 2026-08-21  
**Feature**: Life Blueprint & Routine Template Maker (Book of Daily Intentionality)  
**Target Area**: `lib/features/presets/`, `lib/models/`, `lib/data/repositories/`

---

## 1. Overview & Vision
Focus Clock transitions from a simple time-blocking tool to a **Life Intentionality Blueprint System** (*"Recipe to a Good Life"*). 

Users can browse, create, customize, and apply full 24-hour daily life routines ("Blueprints") directly to their interactive Focus Clock dial. The system comes preloaded with official Dev Blueprints (including the *5 Pillars of Muslim Time Management* and *The Balanced High-Performer Universal Routine*) and provides a visual Template Maker Studio for creating and editing personalized or community routines.

---

## 2. Architecture & Data Model

### 2.1 Model: `RoutineBlueprint` & `BlueprintBlock`
A Blueprint represents a structured 24-hour daily cadence composed of multiple sequential time blocks.

#### `BlueprintBlock` (Embedded / Helper Object):
- `title` (`String`): Block title (e.g. "Subuh & Barakah Deep Work").
- `startMinute` (`int`): Start minute on 12h dial (0 - 719).
- `endMinute` (`int`): End minute on 12h dial (1 - 720).
- `ampmHalf` (`AmPmHalf`): `am` (00:00 - 11:59) or `pm` (12:00 - 23:59).
- `iconKey` (`String`): Emoji / Icon symbol (e.g. "🌅", "💻", "🏃", "😴").
- `colorValue` (`int`): Color token integer.
- `philosophy` (`String`): The intentional purpose of this block (e.g. "Early morning clarity before daily noise").
- `defaultCategory` (`String`): Classification (e.g. "Deepwork", "Rest", "Spiritual", "Exercise").

#### `RoutineBlueprint` (`lib/models/routine_blueprint.dart`):
- `id` (`int`): Unique identifier.
- `name` (`String`): Name of the blueprint (e.g. "5 Pillars of Muslim Time Management").
- `tagline` (`String`): Short subtitle / summary.
- `description` (`String`): Detailed philosophy and guidance on how to live this routine.
- `author` (`String`): `"Official Dev"` or `"Custom"`.
- `category` (`String`): Category tag (`"Spiritual & Focus"`, `"High Performance"`, `"Balance & Wellness"`, `"Creative"`).
- `iconKey` (`String`): Blueprint icon/badge (e.g. "🕌", "⚡", "🌿").
- `blocksJson` (`String`): Serialized JSON representation of `List<BlueprintBlock>`.
- `createdAt` (`DateTime`).
- `updatedAt` (`DateTime`).

---

## 3. Official Built-In Blueprints

### Blueprint 1: 🕌 5 Pillars of Muslim Time Management
- **Philosophy**: Anchoring high-output deep work, fitness, and family life around the 5 daily prayer milestones to maximize daily barakah, balance, and intentionality.
- **Blocks**:
  1. **05:00 – 08:30 (AM)**: 🌅 *Subuh & Barakah Deep Work* (`#3B82F6` Blue, 💻) — Peak cognitive focus, coding, studying, or writing before the world awakens.
  2. **12:00 – 14:00 (PM)**: ☀️ *Dhuhur, Midday Reset & Joyful Work* (`#EAB308` Amber, 🥗) — Midday prayer, mindful lunch, self-evaluation & creative lighter work.
  3. **15:30 – 17:30 (PM)**: 🏃 *Ashar, Physical Vitality & Social/Family* (`#10B981` Emerald, 🏃) — Ashar prayer, fitness, sports, hobbies, and bonding with family.
  4. **18:00 – 19:30 (PM)**: 🌙 *Maghrib, Spiritual Presence & Dinner* (`#F97316` Orange, 🤝) — Maghrib prayer, warm family meal, digital detox & decompression.
  5. **19:30 – 21:30 (PM)**: 📖 *Isya & Evening Wind-Down* (`#8B5CF6` Purple, 🕯️) — Isya prayer, day reflection/gratitude journaling, preparing for rest.
  6. **21:30 – 04:30 (Cross-midnight)**: 😴 *Restorative Deep Sleep* (`#64748B` Slate, 😴) — 7 hours of undisturbed restorative sleep.

### Blueprint 2: ⚡ The Balanced High-Performer (Universal 24h Rhythm)
- **Philosophy**: Circadian-aligned rhythm maximizing morning peak mental clarity, afternoon collaboration & physical vitality, and evening mental recovery.
- **Blocks**:
  1. **06:00 – 07:30 (AM)**: 🧘 *Morning Ritual & Mindful Movement* (`#06B6D4` Cyan, 🌅)
  2. **08:00 – 11:30 (AM)**: 🎯 *Peak Cognitive Deep Work* (`#3B82F6` Blue, 💻)
  3. **12:00 – 13:30 (PM)**: 🥗 *Mindful Fuel & Strategic Reset* (`#F59E0B` Amber, 🥗)
  4. **14:00 – 16:30 (PM)**: 🤝 *Collaborative Execution & Execution* (`#8B5CF6` Purple, 🤝)
  5. **17:00 – 19:00 (PM)**: 🏃 *Physical Fitness & Recreation* (`#10B981` Emerald, 🏃)
  6. **20:00 – 22:00 (PM)**: 🕯️ *Unplug, Family & Mindful Wind-Down* (`#EC4899` Pink, 📖)
  7. **22:00 – 06:00 (Cross-midnight)**: 🛌 *8 Hours Restorative Rest* (`#64748B` Slate, 😴)

---

## 4. UI & UX Architecture

### 4.1 Presets Page Upgrade (`lib/features/presets/presets_tab.dart`)
- **Segmented Control**:
  - `📚 Routine Blueprints` (Default)
  - `🏷️ Category Tags` (Existing single activity presets)
- **Blueprint Catalog View**:
  - Grid / List of Blueprint Cards.
  - Each card features: Icon badge, Title, Tagline, Category pill, Mini 24h visual clock preview diagram, and Action Buttons:
    - **`📖 Read Philosophy & Blocks`** (Opens detail modal / book view)
    - **`⚡ Apply to Clock`** (Opens application dialog)
    - **`✏️ Customize in Studio`** (Clones blueprint to User Studio)

### 4.2 Application Engine (`ApplyBlueprintDialog`):
- Modal allowing the user to apply the blueprint:
  - **Option 1: Daily Recurring (`recurrence = 'daily'`)**: Applies all blocks as a continuous daily cadence.
  - **Option 2: Single Date Application**: Applies blocks to the currently active calendar date.
- Safe Conflict Resolution: Cleanses duplicate blocks or overlays cleanly onto empty clock segments.

### 4.3 Blueprint Studio / Template Editor (`BlueprintEditorSheet`):
- Visual editor to create or modify blueprints:
  - Edit Blueprint Name, Tagline, and Philosophy.
  - Interactive block list: Adjust start/end time via intuitive time pickers, customize specific activity names (e.g. changing "Deep Work" to "LKS IT Practice"), change color & emoji icon.
  - Realtime Mini Analog Clock Preview updating dynamically as blocks are tweaked.
  - Save as custom blueprint in local repository.

---

## 5. Verification & Testing Plan
- **Unit Tests**:
  - `test/blueprint_test.dart`: Serialization/deserialization of `RoutineBlueprint` and `BlueprintBlock`.
  - Block time math verification (ensuring spans translate cleanly to `Activity` models across AM and PM halves).
  - Conflict-free application verification.
- **UI & Widget Tests**:
  - Rendering Blueprint Catalog in `PresetsTab`.
  - Opening Blueprint Detail and Studio Editor.
  - Applying built-in 5-Pillar template and asserting generated `Activity` entries.
