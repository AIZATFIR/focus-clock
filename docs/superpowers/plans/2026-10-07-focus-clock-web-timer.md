# Focus Clock Web & Minimalist Zen Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a lightweight, distraction-free web version of Focus Clock featuring a 3-column Google Tasks table (Apa, Dimana, Kapan), a giant 12-hour tactile analog clock face with drag & slide time slices, and a fullscreen / display-over-display Zen Timer with a 10-minute abundance milestone and instant emergency stop. Deployable to Vercel.

**Architecture:** Pure Vanilla HTML5, CSS3 (Obsidian & Warm Paper design system), and modern ES6 JS with reactive localStorage state management. Zero build-step friction, instant 120 FPS performance.

**Tech Stack:** Vanilla HTML5, Vanilla CSS3, Modern JavaScript (ES Modules, SVG, Canvas, Picture-in-Picture API, Fullscreen API, Web Audio API).

## Global Constraints
- Pure vanilla web technologies (HTML, CSS, JS) — no complex framework dependencies.
- Strict 1 Page = 1 Dedicated Function (Tabs: Tasks, Clock Face, Timer).
- 12-hour classic analog dial with intuitive drag-and-slide sectors.
- 10-minute golden gate minimum milestone for healthy psychological abundance.
- Instant emergency stop via Spacebar/Click without penalty.

---

### Task 1: Core Foundation, Design System & Reactive Store
**Files:**
- Create: `web-app/index.html`
- Create: `web-app/styles.css`
- Create: `web-app/store.js`
- Create: `web-app/app.js`

- [ ] **Step 1:** Create `web-app/store.js` with reactive state for tasks, current tab, timer session, and completed logs.
- [ ] **Step 2:** Create `web-app/styles.css` with CSS variables for Obsidian Dark (`#0E0E12`, `#16161D`, `#F0C987` gold, emerald green `#10B981`) and responsive typography.
- [ ] **Step 3:** Create `web-app/index.html` shell with top minimalist tab switch (`[ 📋 Tasks ]`, `[ 🕒 Clock Face ]`, `[ ⏱️ Focus Timer ]`).
- [ ] **Step 4:** Create `web-app/app.js` routing logic and keyboard shortcuts (`1`, `2`, `3`, `Space`, `Tab`).
- [ ] **Step 5:** Commit: `git add web-app/ && git commit -m "feat(web): app shell, reactive store, and design tokens"`

---

### Task 2: 3-Column Tasks View (Apa, Dimana, Kapan)
**Files:**
- Create: `web-app/components/tasks-view.js`
- Modify: `web-app/index.html`
- Modify: `web-app/styles.css`

- [ ] **Step 1:** Implement quick add bar on top: `[ Apa (Tugas) ]`, `[ Dimana (Tempat) ]`, `[ Kapan (Waktu) ]` with Enter key submission.
- [ ] **Step 2:** Implement clean task list with Google Tasks styling: checkbox, editable title, badge location, formatted time slot.
- [ ] **Step 3:** Add quick action "Mulai Fokus" button to directly switch to the Zen Timer with that task preloaded.
- [ ] **Step 4:** Add inline edit and delete actions with zero nested modals.
- [ ] **Step 5:** Commit: `git add web-app/ && git commit -m "feat(web): 3-column tasks view with instant inline entry"`

---

### Task 3: Giant 12-Hour Tactile Clock Face
**Files:**
- Create: `web-app/components/clock-face.js`
- Modify: `web-app/index.html`
- Modify: `web-app/styles.css`

- [ ] **Step 1:** Implement large responsive SVG 12-hour analog dial with hour markers (1 to 12) and tick marks.
- [ ] **Step 2:** Render time slices (arcs) mapped from active tasks with distinct, pleasing warm palette colors.
- [ ] **Step 3:** Implement drag & slide interactions:
  - Dragging the middle of a slice rotates the entire time block earlier or later.
  - Dragging the start or end handles adjusts duration with 5m/15m magnetic snap.
- [ ] **Step 4:** Add floating live tooltip showing `HH:MM — HH:MM (duration)` while dragging.
- [ ] **Step 5:** Add AM/PM toggle button and glowing real-time "Now" hand.
- [ ] **Step 6:** Commit: `git add web-app/ && git commit -m "feat(web): giant 12-hour tactile clock face with drag-and-slide sectors"`

---

### Task 4: Zen Focus Timer with 10-Minute Golden Gate & Instant Stop
**Files:**
- Create: `web-app/components/timer-view.js`
- Modify: `web-app/index.html`
- Modify: `web-app/styles.css`

- [ ] **Step 1:** Implement fullscreen toggle and Web Picture-in-Picture (PiP) support for true display-over-display floating window.
- [ ] **Step 2:** Implement 10-minute golden gate milestone:
  - 0–10 min: amber gentle pulse ("Menuju 10 menit pertama").
  - 10+ min: emerald/gold triumphant glow ("Target 10 Menit Tercapai! Bonus Waktu Aktif").
- [ ] **Step 3:** Implement prominent Emergency Stop button (one click or Spacebar/Esc) immediately saving exact real study minutes.
- [ ] **Step 4:** Implement session summary card and honest study history log.
- [ ] **Step 5:** Commit: `git add web-app/ && git commit -m "feat(web): zen focus timer with 10-minute abundance milestone and instant emergency stop"`

---

### Task 5: Vercel Static Configuration & Verification
**Files:**
- Modify: `vercel.json`
- Modify: `package.json`
- Copy/Link: root `index.html` pointing to `web-app/`

- [ ] **Step 1:** Configure `vercel.json` and static routing so Vercel deploys `web-app/` instantly.
- [ ] **Step 2:** Test locally with browser server.
- [ ] **Step 3:** Verify all interactions using `browser_subagent` (task creation, clock dragging, timer start, 10m golden milestone, instant stop, PiP/fullscreen).
- [ ] **Step 4:** Commit & push to master.
