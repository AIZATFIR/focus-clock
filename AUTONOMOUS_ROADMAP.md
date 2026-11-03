

### Cycle #1 Directive (2026-11-02 21:08)
### 1. Radial Timeblock Snapping (Pointer to 15-Minute Arc)

```javascript
// snap.js
export const snapAngle = (x, y, cx, cy, stepMins = 15) => {
  const step = (stepMins / 60) * (Math.PI * 2);
  const angle = (Math.atan2(y - cy, x - cx) + Math.PI * 2.5) % (Math.PI * 2);
  // ponytail: truncates to 12-hour single revolution ceiling; upgrade when adding multi-hour spirals.
  return Math.round(angle / step) * step;
};

// Self-check
console.assert(snapAngle(100, 50, 100, 100) === 0, '12 o’clock must snap to 0 rad');
console.assert(snapAngle(150, 100, 100, 100) === Math.PI / 2, '3 o’clock must snap to π/2 rad');
```
skipped: magnetic spring physics and multi-turn state.  
add when: supporting long-duration blocks exceeding a single 12-hour rotation.

---

### 2. High-DPI Zen Arc Clockface

```javascript
// clock-face.js
export function renderZenDial(canvas, startRad, endRad) {
  const dpr = window.devicePixelRatio || 1;
  const size = 320;
  if (canvas.width !== size * dpr) {
    canvas.width = canvas.height = size * dpr;
    canvas.style.width = canvas.style.height = `${size}px`;
  }
  const ctx = canvas.getContext('2d');
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const c = size / 2, r = c - 18;
  ctx.lineWidth = 10;
  ctx.lineCap = 'round';

  // Base subtle linen track
  ctx.beginPath();
  ctx.arc(c, c, r, 0, Math.PI * 2);
  ctx.strokeStyle = '#ECE7DE';
  ctx.stroke();

  // Active warm terracotta focus block
  if (startRad !== endRad) {
    ctx.beginPath();
    ctx.arc(c, c, r, startRad - Math.PI / 2, endRad - Math.PI / 2);
    ctx.strokeStyle = '#C86D51';
    ctx.stroke();
  }
}
```
skipped: tick marks, numbers, and second-hand ticking noise.  
add when: chronograph precision view is explicitly enabled by the user.

---

### 3. Pure-CSS Ambient Focus Shell

```css
/* zen-stage.css */
.zen-stage {
  touch-action: none;
  user-select: none;
  display: grid;
  place-items: center;
  min-height: 100dvh;
  margin: 0;
  background: radial-gradient(circle at center, #FAF8F5 0%, #EBE4DA 100%);
  transition: background 0.8s ease;
}
```
skipped: JavaScript-driven cursor tracking, ambient canvas blurs, and backdrop filters.  
add when: OS-level low-power mode can be verified via media queries.


### Cycle #1 Directive (2026-11-02 21:11)
```javascript
// 1. Crisp HiDPI Zen Clockface Dial
function renderZenClock(canvas, progress = 0.25) {
  const dpr = window.devicePixelRatio || 1;
  const size = canvas.clientWidth;
  canvas.width = size * dpr;
  canvas.height = size * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);

  const cx = size / 2, cy = size / 2, r = size / 2 - 16;
  ctx.clearRect(0, 0, size, size);

  // Track (SofizCake warm neutral)
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.strokeStyle = '#EFECE6';
  ctx.lineWidth = 8;
  ctx.stroke();

  // Active Focus Block (Subtle Clay Accent)
  ctx.beginPath();
  ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + progress * Math.PI * 2);
  ctx.strokeStyle = '#D97757';
  ctx.lineWidth = 8;
  ctx.lineCap = 'round';
  ctx.stroke();
}

// 2. 5-Minute Timeblock Snapping from Pointer Event
// ponytail: Snapping assumes 60-min single dial; upgrade to multi-hour dial if durations > 60m.
function getSnappedMinutes(event, rect, stepMinutes = 5) {
  const rad = Math.atan2(event.clientY - (rect.top + rect.height / 2), event.clientX - (rect.left + rect.width / 2)) + Math.PI / 2;
  const normalized = rad < 0 ? rad + Math.PI * 2 : rad;
  const minutes = (normalized / (Math.PI * 2)) * 60;
  return (Math.round(minutes / stepMinutes) * stepMinutes) % 60;
}

console.assert(getSnappedMinutes({clientX: 200, clientY: 100}, {left: 0, top: 0, width: 200, height: 200}) === 15);
```

```css
/* 3. Anti-Slop Zero-Chrome CSS */
.focus-container {
  background: #FDFBF7;
  color: #2C2A29;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
  font-variant-numeric: tabular-nums;
}

canvas.clockface {
  inline-size: min(72vw, 320px);
  aspect-ratio: 1;
  touch-action: none;
  user-select: none;
}
```

skipped: dynamic hour-ticks and spring-physics drag release; add when user interaction telemetry indicates dial overshoot.
skipped: dynamic color themes; add when system dark mode hook is explicitly wired up.


### Cycle #2 Directive (2026-11-02 21:16)
### 1. Polar Snapping Math for Timeblocks (5-min quantize)

```javascript
// ponytail: ceil is 5-min fixed step; upgrade to dynamic interval when user configs multi-step granularity.
export const snapAngle = (dx, dy, stepMin = 5) => {
  const stepRad = (stepMin / 60) * (2 * Math.PI);
  const angle = (Math.atan2(dy, dx) + Math.PI / 2 + 2 * Math.PI) % (2 * Math.PI);
  return (Math.round(angle / stepRad) * stepRad) % (2 * Math.PI);
};

// Self-check
console.assert(snapAngle(0, -100, 15) === 0, '12 o’clock must snap to 0 rad');
console.assert(Math.abs(snapAngle(100, 0, 15) - Math.PI / 2) < 1e-6, '3 o’clock must snap to PI/2');
```
→ skipped: arbitrary non-linear magnetic snap physics  
→ add when: dragging interactive block boundary anchors on mobile touch surfaces

---

### 2. Retina-Crisp Canvas Setup & Zen Face Rendering

```javascript
export function renderZenClock(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  const r = size / 2;

  // Outer boundary line & 12-hour micro-dots
  ctx.translate(r, r);
  ctx.strokeStyle = 'color-mix(in srgb, currentColor 8%, transparent)';
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(0, 0, r - 12, 0, Math.PI * 2);
  ctx.stroke();

  ctx.fillStyle = 'currentColor';
  for (let i = 0; i < 12; i++) {
    const a = (i * Math.PI) / 6;
    ctx.beginPath();
    ctx.arc(Math.sin(a) * (r - 24), -Math.cos(a) * (r - 24), i % 3 === 0 ? 1.75 : 0.75, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.setTransform(1, 0, 0, 1, 0, 0);
}
```
→ skipped: offscreen canvas caching and manual animation loops  
→ add when: animated sweep hands or real-time tick transitions drop below 60fps

---

### 3. Pure-CSS Zen Ambient Dimming (Zero-JS Chrome Fade)

```css
/* Zero-distraction ambient containment */
.zen-clock-root {
  --ink: #2c2825;
  --paper: #fbf9f5;
  background: var(--paper);
  color: var(--ink);
}

.zen-chrome {
  opacity: 0;
  transform: translateY(4px);
  transition: opacity 280ms cubic-bezier(0.16, 1, 0.3, 1), transform 280ms ease;
  pointer-events: none;
}

/* Reveal only when explicitly interacting or pointer resides in zone */
.zen-clock-root:is(:hover, :focus-within) .zen-chrome {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}
```
→ skipped: JavaScript idle-timer listeners (`mousemove`/`setTimeout`)  
→ add when: user requests explicit always-on pinned mode via persistent setting


### Cycle #4 Directive (2026-11-02 21:27)
### 1. HiDPI Canvas Pixel Ratio Normalization

```javascript
export function syncCanvasDpr(canvas, ctx) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = Math.round(width * dpr);
  canvas.height = Math.round(height * dpr);
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
}
```
skipped: ResizeObserver integration and debounced resize loops.  
add when: Dynamic window resizing or split-screen triggers visible canvas stretching.

---

### 2. 15-Minute Polar Snapping

```javascript
// ponytail: 12h face hardcoded; upgrade to 24h when dial config is requested.
export function snapAngle(x, y, cx, cy, stepMins = 15) {
  const step = (stepMins / 720) * (2 * Math.PI);
  const angle = (Math.atan2(y - cy, x - cx) + 2.5 * Math.PI) % (2 * Math.PI);
  return Math.round(angle / step) * step;
}

// Self-check
console.assert(snapAngle(100, 50, 100, 100, 15) === 0, '12 o’clock must be 0 rad');
```
skipped: Custom per-block snap sensitivity and haptic feedback triggers.  
add when: Multi-duration drag handles or mobile haptics are introduced.

---

### 3. Zen Ambience & Input Isolation (CSS)

```css
.zen-clockface {
  background-color: #f7f4ee; /* SofizCake warm linen */
  color: #2b2725;            /* Soft soot, zero pure-black */
  touch-action: none;         /* Drops 300ms gesture latency */
  user-select: none;
  contain: strict;
}
```
skipped: CSS color-scheme auto-switching and dark-mode themes.  
add when: Dark mode specification is provided.


### Cycle #5 Directive (2026-11-02 21:33)
### 1. HiDPI Canvas & Zen Clockface Renderer
```javascript
export function renderZenClock(canvas, activeMinutes = 25) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  if (canvas.width !== width * dpr) {
    canvas.width = width * dpr;
    canvas.height = height * dpr;
  }
  const ctx = canvas.getContext('2d');
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, width, height);

  const cx = width / 2, cy = height / 2, r = Math.min(cx, cy) - 16;

  // Active timeblock wedge
  const sweep = (activeMinutes / 60) * Math.PI * 2;
  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + sweep);
  ctx.closePath();
  ctx.fillStyle = 'rgba(194, 89, 63, 0.12)'; // warm terracotta wash
  ctx.fill();

  // Subtle 5-minute ticks
  // ponytail: static tick style; add dynamic tick hover highlights when interactive scrubber is bound
  for (let i = 0; i < 60; i += 5) {
    const rad = (i / 60) * Math.PI * 2 - Math.PI / 2;
    const len = i % 15 === 0 ? 8 : 4;
    ctx.beginPath();
    ctx.moveTo(cx + Math.cos(rad) * (r - len), cy + Math.sin(rad) * (r - len));
    ctx.lineTo(cx + Math.cos(rad) * r, cy + Math.sin(rad) * r);
    ctx.strokeStyle = i % 15 === 0 ? '#2E2B29' : 'rgba(46, 43, 41, 0.2)';
    ctx.lineWidth = 1.5;
    ctx.stroke();
  }
}
```
skipped: Bezier drag handles and non-linear dial scaling.
add when: User explicitly requests freeform, non-discrete arc sizing.

---

### 2. Timeblock Polar Snapping Engine
```javascript
export function snapPointerToAngle(clientX, clientY, rect, stepMins = 5) {
  const cx = rect.width / 2;
  const cy = rect.height / 2;
  const px = clientX - rect.left - cx;
  const py = clientY - rect.top - cy;

  // Calculate angle from 12 o'clock in degrees [0, 360)
  const deg = (Math.atan2(py, px) * (180 / Math.PI) + 450) % 360;
  const stepDeg = stepMins * 6; // 6 deg per minute

  // ponytail: wraps at 60 mins; add multi-revolution accumulator when tracking >1hr blocks
  return (Math.round(deg / stepDeg) * stepDeg) % 360;
}

// Runnable assertion check
console.assert(
  snapPointerToAngle(100, 50, { left: 0, top: 0, width: 100, height: 100 }, 5) === 90,
  "At 3 o'clock position (100, 50 in 100x100), output must snap to 90 degrees."
);
```
skipped: Inertia-based momentum physics and gesture dampening.
add when: Physical trackpad/wheel dragging feels jittery in user testing.

---

### 3. Zen Warmth Clock Surface (CSS)
```css
:root {
  --zen-bg: #FDFBF7;
  --zen-ink: #2E2B29;
  --zen-surface: #F5EFEB;
  --zen-accent: #C2593F;
}

.focus-stage {
  aspect-ratio: 1;
  width: min(72vw, 360px);
  margin: auto;
  position: relative;
  border-radius: 50%;
  background: radial-gradient(circle, var(--zen-bg) 70%, var(--zen-surface) 100%);
  box-shadow: 0 16px 40px -12px rgba(46, 43, 41, 0.06);
  touch-action: none;
  user-select: none;
}
```
skipped: Dark-mode tokens and complex CSS glassmorphism.
add when: System-level `prefers-color-scheme: dark` requirement is prioritized.


### Cycle #9 Directive (2026-11-02 21:56)
### 1. Zero-dependency 5-minute interval angle snapping

```ts
// src/clock/snap.ts
// ponytail: hardcoded to 12h clockface & 5-minute default step. Upgrade when arbitrary divisions are user-configurable.
export const snapPointerToMinutes = (dx: number, dy: number, step = 5): number => {
  const rad = Math.atan2(dy, dx);
  const deg = ((rad * 180 / Math.PI + 90) % 360 + 360) % 360;
  return (Math.round((deg / 360) * (60 / step)) * step) % 60;
};

// Self-check
console.assert(snapPointerToMinutes(0, -100) === 0, 'Top must be 0m');
console.assert(snapPointerToMinutes(100, 0) === 15, 'Right must be 15m');
console.assert(snapPointerToMinutes(0, 100) === 30, 'Bottom must be 30m');
console.assert(snapPointerToMinutes(-100, 0) === 45, 'Left must be 45m');
```
*skipped: continuous magnetic drag physics and variable subdivisions; add when multi-hour long-range blocks are introduced.*

---

### 2. High-DPI Canvas initialization & sub-pixel dial alignment

```ts
// src/clock/canvas.ts
export function syncCanvasDPI(canvas: HTMLCanvasElement): CanvasRenderingContext2D {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  
  canvas.width = Math.round(width * dpr);
  canvas.height = Math.round(height * dpr);

  const ctx = canvas.getContext('2d')!;
  ctx.scale(dpr, dpr);
  return ctx;
}
```
*skipped: `ResizeObserver` listener and auto-rebind logic; add when responsive grid allows dynamic viewport splits.*

---

### 3. SofizCake / firtofolio Zen Palette & Native Interaction

```css
/* src/styles/clock.css */
:root {
  --zen-bg: #f9f8f6;
  --zen-dial: #f2eee8;
  --zen-ink: #2b2826;
  --zen-muted: #8c857b;
  --zen-terracotta: #c86446;
}

canvas.clockface {
  touch-action: none;
  user-select: none;
  background: radial-gradient(circle, var(--zen-dial) 0%, var(--zen-bg) 72%);
  border-radius: 50%;
  cursor: grab;
}

canvas.clockface:active {
  cursor: grabbing;
}
```
*skipped: dark mode media queries and theme provider boilerplate; add when system theme persistence is wired to Sadar/focus-clock settings.*


### Cycle #11 Directive (2026-11-02 22:08)
### 1. HiDPI Canvas Scaling & Warm Arc Render

Eliminate blurry canvas rendering on Retina screens with zero dependencies; apply warm low-contrast dial tokens.

```javascript
export function initClockCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;

  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return { ctx, size: rect.width };
}

export function drawZenFace(ctx, size, elapsedRatio) {
  const center = size / 2;
  const radius = center - 16;
  ctx.clearRect(0, 0, size, size);

  // ponytail: static warm-neutral palette; add dynamic CSS var bridge if theme-switching is requested
  ctx.lineWidth = 4;
  ctx.lineCap = 'round';

  // Base dial track
  ctx.strokeStyle = '#eee9e0';
  ctx.beginPath();
  ctx.arc(center, center, radius, 0, Math.PI * 2);
  ctx.stroke();

  // Active focus arc
  ctx.strokeStyle = '#7c6f64';
  ctx.beginPath();
  ctx.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + elapsedRatio * Math.PI * 2);
  ctx.stroke();
}
```
skipped: ResizeObserver auto-resizing, multi-theme config.  
add when: Dynamic window resizing or dark-mode toggle is explicitly requested.

---

### 2. Timeblock Snap Engine (15-Minute Discrete Steps)

Pure native math to snap raw radial pointer input to discrete intervals without state machine bloat.

```javascript
// ponytail: hardcoded to 15m; upgrade to dynamic step arg if custom intervals are added
export function snapAngleToBlock(rad, totalBlocks = 96) { // 96 blocks = 15m in 24h (or 48 for 12h)
  const tau = Math.PI * 2;
  const normalized = (rad % tau + tau) % tau;
  const step = tau / totalBlocks;
  return Math.round(normalized / step) * step;
}

// Self-check
console.assert(
  Math.abs(snapAngleToBlock(0.06, 96) - 0.0654498) < 1e-4,
  'Failed to snap angle to nearest 15-minute slice'
);
```
skipped: Custom inertia physics, variable snap thresholds.  
add when: Fluid drag momentum feels sticky during user testing.

---

### 3. Anti-Slop Zen Dial Shell (CSS-Only Layout)

Native CSS container with typography tuning (`font-variant-numeric: tabular-nums`) to prevent text jitter and distraction.

```css
:root {
  --zen-bg: #fdfbf7;
  --zen-ink: #2b2825;
  --zen-subtle: #8f857d;
}

.clock-shell {
  display: grid;
  place-items: center;
  background-color: var(--zen-bg);
  color: var(--zen-ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
  font-variant-numeric: tabular-nums;
  user-select: none;
  -webkit-font-smoothing: antialiased;
}

.clock-canvas {
  width: 280px;
  height: 280px;
  touch-action: none;
}
```
skipped: Glassmorphism filters, styled buttons, complex media queries.  
add when: UI supports auxiliary toolbars or mobile-specific layouts.


### Cycle #12 Directive (2026-11-02 22:13)
### 1. HiDPI Canvas Normalizer (Eliminates Blur on Retina/Apple Displays)

```javascript
export function fitZenCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  return { ctx, width, height, cx: width / 2, cy: height / 2 };
}
```
* Skipped: ResizeObserver polling.
* Add when: The canvas container has fluid, non-preset responsive drag-resizing.

---

### 2. Timeblock Polar Snapping (Clockwise from 12 o'clock, 5-min intervals)

```javascript
export function snapToMinutes(dx, dy, step = 5) {
  // Polar angle from 12 o'clock (top) progressing clockwise [0, 2π)
  const theta = (Math.atan2(dy, dx) + Math.PI * 2.5) % (Math.PI * 2);
  const rawMin = (theta / (Math.PI * 2)) * 60;
  // ponytail: modulo 60 limits to 1hr clockface. Upgrade to multi-hour dial when span tracks >60m.
  const mins = (Math.round(rawMin / step) * step) % 60;
  return { mins, rad: (mins / 60) * Math.PI * 2 - Math.PI / 2 };
}

// Verification check
console.assert(snapToMinutes(0, -50).mins === 0, '12 oclock must be 0m');
console.assert(snapToMinutes(50, 0).mins === 15, '3 oclock must be 15m');
console.assert(snapToMinutes(0, 50).mins === 30, '6 oclock must be 30m');
console.assert(snapToMinutes(-50, 0).mins === 45, '9 oclock must be 45m');
```
* Skipped: Dynamic variable intervals (1m/10m/15m UI pickers).
* Add when: Users require explicit micro-sprints under 5 minutes.

---

### 3. Warm Zen Arc Renderer (Anti-Slop SofizCake Aesthetic)

```javascript
export function drawZenBlock(ctx, cx, cy, radius, startMin, endMin, color = '#E07A5F') {
  const toRad = (m) => (m / 60) * Math.PI * 2 - Math.PI / 2;
  ctx.beginPath();
  ctx.arc(cx, cy, radius, toRad(startMin), toRad(endMin));
  ctx.strokeStyle = color;
  ctx.lineWidth = 14;
  ctx.lineCap = 'round';
  ctx.stroke();
}
```
* Skipped: Gradients, drop-shadow blurs, and animated easing libraries.
* Add when: Profile shows GPU headroom and visual feedback demands edge glowing.


### Cycle #13 Directive (2026-11-02 22:19)
### 1. Radial Timeblock Snapping (Pure Stdlib Math)

```js
// snaps canvas angle (radians) to 15-minute dial steps (pi / 24 rad)
export const snapAngleTo15Min = (rad) => {
  const step = Math.PI / 24; // ponytail: hardcoded to 12h clockface; pass dialHours if 24h face needed
  return Math.round(rad / step) * step;
};

// runnable self-check
console.assert(snapAngleTo15Min(0.13) === Math.PI / 24, 'Failed 15-min step snap');
console.assert(snapAngleTo15Min(0) === 0, 'Failed zero snap');
```
* Skipped: custom angular clamp/modulo logic; add when timeblocks span midnight/wrap 2π.

---

### 2. Crisp HiDPI Canvas Scaling (Zero-Blur Retina Setup)

```js
export const setupZenCanvas = (canvas) => {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return { ctx, width, height };
};
```
* Skipped: `ResizeObserver` listener; add when clockface lives in a resizable split-pane.

---

### 3. Ambient UI Auto-Fade (Native CSS over JS Event Listeners)

```css
/* Zero-distraction zen container; eliminates JS mousemove/idle timers */
.clock-scaffold .ambient-hud {
  opacity: 0;
  pointer-events: none;
  transition: opacity 320ms cubic-bezier(0.16, 1, 0.3, 1);
}

.clock-scaffold:is(:hover, :focus-within) .ambient-hud {
  opacity: 0.9;
  pointer-events: auto;
}
```
* Skipped: JS inactivity timeout; add when touch devices require tap-to-reveal controls.


### Cycle #14 Directive (2026-11-02 22:25)
### 1. High-DPI Zen Dial Canvas Setup

```javascript
function initZenCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.lineCap = 'round';
  return ctx;
}
```
`→ skipped: [ResizeObserver dynamic reflow], add when [dial needs fluid responsive resizing beyond fixed container queries].`

---

### 2. Radial Timeblock Snapping (15-min Intervals)

```javascript
function snapRadialMinutes(px, py, cx, cy, step = 15) {
  // Polar angle normalized clockwise from 12 o'clock (0 to 2π)
  const angle = (Math.atan2(py - cy, px - cx) + Math.PI * 2.5) % (Math.PI * 2);
  const rawMinutes = (angle / (Math.PI * 2)) * 720;
  // ponytail: 12h dial fixed ceiling; upgrade to 24h by parameterized maxMinutes.
  return Math.round(rawMinutes / step) * step % 720;
}

// Self-check
console.assert(snapRadialMinutes(100, 50, 100, 100) === 0, '12 o’clock must snap to 0m');
console.assert(snapRadialMinutes(150, 100, 100, 100) === 180, '3 o’clock must snap to 180m');
```
`→ skipped: [magnetic hysteresis thresholds], add when [freehand drag feels jittery on touch screens].`

---

### 3. Tactile Zen Warmth Shell (CSS-Only)

```css
:root {
  --zen-paper: #FBF9F5;
  --zen-ink: #292524;
  --zen-clay: #C85A32;
  --zen-subtle: #E7E5E4;
}

#clockface {
  touch-action: none;
  user-select: none;
  background: var(--zen-paper);
  filter: drop-shadow(0 12px 32px rgba(41, 37, 36, 0.05));
  cursor: crosshair;
}
```
`→ skipped: [dark-mode token mappings and themes], add when [explicit system media-query preference toggle is requested].`


### Cycle #15 Directive (2026-11-02 22:30)
### 1. Retina-Crisp Canvas Sync (Zero Blurry Arcs)

```js
// Crisp canvas scaling without layout thrashing
const syncDPR = (canvas, ctx) => {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  if (canvas.width !== width * dpr || canvas.height !== height * dpr) {
    canvas.width = width * dpr;
    canvas.height = height * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
};
// ponytail: hardcoded to current rect; wrap in ResizeObserver when canvas dimensions become dynamic.
```
skipped: ResizeObserver abstraction, multi-canvas managers.  
add when: The clock face is fluidly resizable by user drag or responsive breakpoints.

---

### 2. Timeblock Snapping (Pure Native Radians)

```js
// Snap pointer angle to 5-min intervals (2π / 12 = π / 6 rads)
const snapAngle = (angleRad, step = Math.PI / 6) => {
  const normalized = (angleRad % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
  return Math.round(normalized / step) * step;
};

// Self-check
console.assert(snapAngle(0.28) === 0, "Snaps down to 0");
console.assert(Math.abs(snapAngle(0.5) - Math.PI / 6) < 1e-9, "Snaps up to 5min mark");
```
skipped: Bezier easing, complex drag-state machine.  
add when: Visual magnetic "snap-in" spring animations are required during pointer release.

---

### 3. Warm Zen Surface & Zero-Distraction Chromelessness

```css
/* firtofolio/SofizCake warm palette & idle declutter */
:root {
  --zen-bg: #fbf9f5;
  --zen-surface: #f2eee5;
  --zen-ink: #2b2826;
  --zen-accent: #d97757; /* soft terracotta */
}

body {
  background: var(--zen-bg);
  color: var(--zen-ink);
  -webkit-font-smoothing: antialiased;
}

.zen-controls {
  opacity: 0;
  transition: opacity 300ms cubic-bezier(0.16, 1, 0.3, 1);
}

body:hover .zen-controls,
body:focus-within .zen-controls {
  opacity: 1;
}
```
skipped: JavaScript-driven idle mouse-fade timers.  
add when: Touch/mobile screens need explicit toggle behavior.


### Cycle #16 Directive (2026-11-02 22:36)
### 1. HiDPI Canvas Normalization (Crisp Zen Dial)

```javascript
function getZenContext(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = size * dpr;
  canvas.height = size * dpr;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  return ctx;
}
```
skipped: ResizeObserver auto-rescaling.  
add when: The clock container supports dynamic fluid resizing instead of fixed dial dimensions.

---

### 2. Magnetic 5-Minute Block Snapping

```javascript
function snapTimeblockAngle(rad, stepMin = 5, toleranceRad = 0.09) {
  const stepRad = (stepMin / 60) * (2 * Math.PI);
  const normalized = (rad % (2 * Math.PI) + (2 * Math.PI)) % (2 * Math.PI);
  const nearest = Math.round(normalized / stepRad) * stepRad;
  // ponytail: static threshold ceiling; add velocity weighting if drag momentum feels sticky.
  return Math.abs(normalized - nearest) <= toleranceRad ? nearest : normalized;
}

// Runnable self-check
console.assert(snapTimeblockAngle(0.05, 5, 0.09) === 0, 'Snap failed within threshold');
console.assert(snapTimeblockAngle(0.3, 5, 0.09) === 0.3, 'Snap fired outside threshold');
```
skipped: Haptic engine integration (`navigator.vibrate`) and momentum physics.  
add when: Mobile drag-to-schedule gesture interaction is wired up to DOM events.

---

### 3. Anti-Slop Zen Dial Tokens & Surface CSS

```css
:root {
  --zen-paper: #FAF8F5;
  --zen-dial-rim: #ECE7DE;
  --zen-ink: #2C2824;
  --zen-warm-amber: #C96E4B;
  --zen-subtle: #8F887E;
}

.zen-clockface {
  background: var(--zen-paper);
  border-radius: 50%;
  box-shadow: inset 0 0 0 1px var(--zen-dial-rim);
  touch-action: none;
  user-select: none;
}
```
skipped: Dynamic dark-mode theme transitions and CSS ambient blur filters.  
add when: System `prefers-color-scheme` toggle is explicitly introduced to the host app.


### Cycle #17 Directive (2026-11-02 22:42)
### 1. HiDPI Canvas & Zen Clockface

```javascript
export function setupZenCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}

export function drawClockface(ctx, r = 160) {
  ctx.clearRect(0, 0, r * 2, r * 2);
  
  // Warm SofizCake/firtofolio backdrop
  ctx.fillStyle = '#faf8f5';
  ctx.beginPath();
  ctx.arc(r, r, r - 6, 0, Math.PI * 2);
  ctx.fill();

  // 12 low-contrast ticks, zero numbers (zen focus)
  ctx.strokeStyle = 'rgba(44, 42, 41, 0.14)';
  ctx.lineWidth = 1.5;
  for (let i = 0; i < 12; i++) {
    const a = (i * Math.PI) / 6;
    ctx.beginPath();
    ctx.moveTo(r + Math.sin(a) * (r - 18), r - Math.cos(a) * (r - 18));
    ctx.lineTo(r + Math.sin(a) * (r - 10), r - Math.cos(a) * (r - 10));
    ctx.stroke();
  }
}
```
* skipped: dynamic resize listeners and custom themes.
* add when: viewport-adaptive canvas or dark mode is explicitly scheduled.

---

### 2. Timeblock Angle Snapper

```javascript
// ponytail: locked to 12-hour dial; upgrade to 24-hour via dial-type parameter.
export function snapAngleToMinutes(rad, stepMinutes = 15) {
  const full = Math.PI * 2;
  const step = (stepMinutes / 720) * full;
  const norm = (rad % full + full) % full;
  return Math.round((Math.round(norm / step) * step) / full * 720) % 720;
}

console.assert(snapAngleToMinutes(Math.PI / 2) === 180, 'PI/2 must snap to 180m');
console.assert(snapAngleToMinutes(0.12) === 0, 'Sub-step must snap to 0m');
```
* skipped: variable minute steps (e.g., 5m vs 15m context menus) and magnetic drag smoothing.
* add when: user preferences expose granularity settings.

---

### 3. Zero-JS Zen Chrome Fade

```css
/* Zero-JS auto-hiding chrome */
.zen-shell {
  position: relative;
  background: #faf8f5;
}

.zen-chrome {
  opacity: 0;
  pointer-events: none;
  transition: opacity 250ms cubic-bezier(0.16, 1, 0.3, 1);
}

.zen-shell:hover .zen-chrome,
.zen-shell:focus-within .zen-chrome {
  opacity: 1;
  pointer-events: auto;
}
```
* skipped: JS idle timer and mousemove throttling.
* add when: canvas needs interaction tracking on pure touch devices without hover.


### Cycle #18 Directive (2026-11-02 22:47)
### 1. Snapping Logic: Pointer Angle to Zen Timeblocks

```javascript
// snap.js
// ponytail: assumes 60-min single dial ceiling; upgrade to multi-hour sweep when scheduling >60m blocks.
export function snapAngleToMinutes(angleRad, stepMinutes = 5) {
  const norm = (angleRad + Math.PI / 2 + Math.PI * 2) % (Math.PI * 2);
  const rawMinutes = (norm / (Math.PI * 2)) * 60;
  const snapped = Math.round(rawMinutes / stepMinutes) * stepMinutes;
  return snapped % 60;
}

// Self-check
console.assert(snapAngleToMinutes(-Math.PI / 2, 5) === 0, '12 o’clock must be 0 min');
console.assert(snapAngleToMinutes(0, 5) === 15, '3 o’clock must be 15 min');
console.assert(snapAngleToMinutes(Math.PI / 2, 10) === 30, '6 o’clock must be 30 min');
console.assert(snapAngleToMinutes(-Math.PI * 0.48, 5) === 0, 'Near 12 snaps to 0');
```
*skipped: multi-hour rotational accumulation; add when tracking multi-hour deep work blocks.*

---

### 2. High-DPI Canvas Setup & Zen Dial Pip Renderer

```javascript
// dial.js
export function renderZenClock(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;

  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const cx = size / 2, cy = size / 2, r = size * 0.42;

  // Warm Apple/Zen palette: muted slate-charcoal and soft sandstone
  ctx.fillStyle = '#2c2825';
  for (let i = 0; i < 12; i++) {
    const rad = (i * Math.PI) / 6 - Math.PI / 2;
    const isCardinal = i % 3 === 0;
    const pipRadius = isCardinal ? 2.5 : 1.2;
    ctx.beginPath();
    ctx.arc(cx + Math.cos(rad) * r, cy + Math.sin(rad) * r, pipRadius, 0, Math.PI * 2);
    ctx.fill();
  }
}
```
*skipped: RAF hand-animation loop and smooth transitions; add when wireframe pointer interaction is hooked.*

---

### 3. Zero-Distraction Canvas Container Shell

```css
/* zen-clock.css */
:root {
  --zen-sand: #fbf9f5;
  --zen-cream: #f2eee6;
  --zen-ink: #2c2825;
  --zen-terracotta: #c8684d;
}

.zen-stage {
  display: grid;
  place-items: center;
  touch-action: none;
  user-select: none;
  -webkit-user-select: none;
  background: radial-gradient(circle at center, var(--zen-sand) 0%, var(--zen-cream) 100%);
  font-feature-settings: "tnum" 1;
}

canvas {
  image-rendering: -webkit-optimize-contrast;
  cursor: grab;
}

canvas:active {
  cursor: grabbing;
}
```
*skipped: dark mode CSS variables; add when system color-scheme detection is wired across suite.*


### Cycle #19 Directive (2026-11-02 22:53)
### 1. HiDPI Canvas Crispness & Zen Warm Stroke

```javascript
export const initZenCanvas = (canvas) => {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  // ponytail: static warm-ink; wire matchMedia listener if runtime theme switching needed.
  ctx.strokeStyle = '#2C2825';
  return ctx;
};
```
skipped: ResizeObserver auto-rescaling. Add when: the clockface layout becomes fluid or responsive to window resizes.

---

### 2. Micro-Snap Engine (Polar Arc to 15-Min Slots)

```javascript
// 720 minutes = 12h rotation; 15-min slot = π/24 radians
export const snapToSlot = (rad, minutes = 15) => {
  const step = (minutes / 720) * 2 * Math.PI;
  // ponytail: normalized to single 12h cycle; add multi-cycle unwrapping if blocks span >12h.
  return Math.round(rad / step) * step;
};

// Self-check
console.assert(snapToSlot(0.12, 15) === snapToSlot(0.14, 15), 'Snap failed: angles within slot must align');
console.assert(snapToSlot(Math.PI / 12, 15) === Math.PI / 12, 'Snap failed: exact slot must preserve angle');
```
skipped: Custom easing / spring physics on snap release. Add when: drag-and-drop interaction requires tangible haptic-like bounce.

---

### 3. SofizCake / Zen UI Reset

```css
:root {
  --zen-bg: #FAF8F5;
  --zen-ink: #2C2825;
  --zen-accent: #E07A5F;
}
@media (prefers-color-scheme: dark) {
  :root {
    --zen-bg: #141312;
    --zen-ink: #EDE8E3;
    --zen-accent: #F28E73;
  }
}
body {
  margin: 0;
  display: grid;
  place-items: center;
  min-height: 100vh;
  background-color: var(--zen-bg);
  color: var(--zen-ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Rounded", sans-serif;
  user-select: none;
  overflow: hidden;
}
```
skipped: CSS reset libraries and custom webfonts. Add when: system fonts fail specific branded typographic hierarchy.


### Cycle #20 Directive (2026-11-02 22:59)
### 1. Snapping Math for Canvas Timeblocks (5/15-min intervals)

```typescript
// timeblock-snap.ts
export function snapPointerToMinutes(x: number, y: number, cx: number, cy: number, step = 5): { min: number; rad: number } {
  const rawAngle = Math.atan2(y - cy, x - cx); // -PI to PI
  const norm = (rawAngle + Math.PI / 2 + 2 * Math.PI) % (2 * Math.PI); // 0 at 12 o'clock
  const min = (Math.round(((norm / (2 * Math.PI)) * 60) / step) * step) % 60;
  const rad = (min / 60) * 2 * Math.PI - Math.PI / 2;
  return { min, rad };
}

// ponytail: single 60m dial ceiling; add multi-hour winding when continuous multi-hour spans are supported.
console.assert(snapPointerToMinutes(100, 50, 100, 100).min === 0, '12 o’clock check failed');
console.assert(snapPointerToMinutes(150, 100, 100, 100).min === 15, '3 o’clock check failed');
console.assert(snapPointerToMinutes(100, 150, 100, 100).min === 30, '6 o’clock check failed');
```
* Skipped: Polar drag physics, custom inertial spring wrappers.
* Add when: Direct pointer dragging creates perceptible jitter on low-polling trackpads.

---

### 2. DPR-Scaled Warm Dial & Active Arc (Zen Palette)

```typescript
// clockface.ts
export function drawZenFace(
  ctx: CanvasRenderingContext2D,
  size: number,
  startRad: number,
  endRad: number
): void {
  const r = size / 2;
  ctx.save();
  ctx.clearRect(0, 0, size, size);
  ctx.translate(r, r);

  // Soft background track (SofizCake warm neutral)
  ctx.lineWidth = 14;
  ctx.lineCap = 'round';
  ctx.strokeStyle = 'color-mix(in srgb, currentColor 8%, transparent)';
  ctx.beginPath();
  ctx.arc(0, 0, r - 16, 0, 2 * Math.PI);
  ctx.stroke();

  // Active timeblock slice (Apple focus orange / terracotta)
  if (startRad !== endRad) {
    ctx.strokeStyle = '#d97757';
    ctx.beginPath();
    ctx.arc(0, 0, r - 16, startRad, endRad);
    ctx.stroke();
  }
  ctx.restore();
}
// ponytail: hardcoded palette token; extract to CSS vars via getComputedStyle when dynamic theming is required.
```
* Skipped: Offscreen canvas buffers and tick loop iterations.
* Add when: Custom dial subdivisions (1m, 5m tick marks) drop frame rates below 60fps on mobile.

---

### 3. Pure CSS Inactivity Fade (Zero-Distraction Chrome)

```css
/* zen-chrome.css */
.focus-container {
  --zen-ease: cubic-bezier(0.16, 1, 0.3, 1);
  background-color: #faf8f5;
  color: #242120;
}

.focus-chrome {
  opacity: 0;
  transition: opacity 400ms var(--zen-ease);
  pointer-events: none;
}

/* Reveal only on mouse movement/hover or keyboard focus */
.focus-container:hover .focus-chrome,
.focus-container:focus-within .focus-chrome {
  opacity: 1;
  pointer-events: auto;
}
```
* Skipped: JS `mousemove` debounce listeners and idle timeout state machines.
* Add when: Fine-grained controls require individual 3-second dwell timers on touch devices.


### Cycle #73 Directive (2026-11-03 03:58)
### 1. HiDPI Canvas & Zen Warmth Setup

```javascript
// Init crisp clock canvas with warm zen palette (SofizCake/firtofolio tone)
export function initZenCanvas(canvas, size = 320) {
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.lineCap = 'round';
  // ponytail: static warm palette; add CSS variable reader if dynamic theming needed
  return { ctx, colors: { bg: '#FAF8F5', rim: '#EFECE6', hand: '#2D2B28', block: '#D97757' } };
}
```
skipped: ResizeObserver and dynamic theme syncing.  
add when: The clock face lives in a responsive grid or supports arbitrary user themes.

---

### 2. Timeblock Angular Snapping

```javascript
// Snap pointer angle to time steps (default: 5-min intervals)
export const snapToInterval = (angleRad, stepMinutes = 5) => {
  const stepRad = (stepMinutes / 60) * (2 * Math.PI);
  const normalized = (angleRad % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
  return Math.round(normalized / stepRad) * stepRad;
};

// runnable self-check
console.assert(Math.abs(snapToInterval(0.53, 5) - (Math.PI / 6)) < 1e-5, 'Snap failed');
```
skipped: Magnetic haptics and fractional drag smoothing.  
add when: Supporting multi-hour dragging or physical vibration on mobile browsers.

---

### 3. Pure-CSS Zero-Distraction Idle UI

```css
/* Ambient fade for auxiliary controls without JS idle timers */
.zen-overlay {
  opacity: 0;
  transition: opacity 400ms cubic-bezier(0.16, 1, 0.3, 1) 2.5s;
}

.zen-stage:hover .zen-overlay,
.zen-stage:focus-within .zen-overlay {
  opacity: 1;
  transition-delay: 0s;
}
```
skipped: Custom pointermove timers and complex fullscreen management in JS.  
add when: Need custom cursor hiding specifically inside the canvas element.


### Cycle #74 Directive (2026-11-03 04:03)
### 1. HiDPI Zen Clockface Canvas (DPR Crispness + Warm Palette)

```javascript
// clockface.js
export function setupZenCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}

export function drawZenFace(ctx, size = 320) {
  const r = size / 2;
  ctx.clearRect(0, 0, size, size);
  ctx.save();
  ctx.translate(r, r);
  for (let i = 0; i < 60; i++) {
    const isHour = i % 5 === 0;
    ctx.fillStyle = isHour ? '#44403C' : '#E7E5E4'; // Warm stone-700 / stone-200
    ctx.fillRect(isHour ? -1 : -0.5, -r + 10, isHour ? 2 : 1, isHour ? 8 : 4);
    ctx.rotate((Math.PI * 2) / 60);
  }
  ctx.restore();
}
```
skipped: Bezier curves, dynamic numbers, and offscreen buffers.  
add when: Profile shows tick rendering drops below 60fps during live drags.

---

### 2. Native Timeblock Angular Snapping (15-Min Grid)

```javascript
// snapping.js
export function snapPointerToMinutes(clientX, clientY, rect, stepMin = 15) {
  const x = clientX - (rect.left + rect.width / 2);
  const y = clientY - (rect.top + rect.height / 2);
  const rad = Math.atan2(y, x) + Math.PI / 2;
  const norm = (rad < 0 ? rad + Math.PI * 2 : rad);
  const totalMin = (norm / (Math.PI * 2)) * 720; // 12h dial: 720m
  const snappedMinutes = Math.round(totalMin / stepMin) * stepMin % 720;
  // ponytail: 12-hour dial only; upgrade to 24-hour via dial-type parameter.
  return { snappedMinutes, snappedRad: (snappedMinutes / 720) * Math.PI * 2 - Math.PI / 2 };
}

// Self-check
console.assert(snapPointerToMinutes(100, 0, { left: 0, top: 0, width: 200, height: 200 }).snappedMinutes === 180, '3 o’clock snap failed');
console.assert(snapPointerToMinutes(0, -100, { left: 0, top: 0, width: 200, height: 200 }).snappedMinutes === 0, '12 o’clock snap failed');
```
skipped: Gesture tracking libraries and inertia physics.  
add when: Touch swipe gestures require velocity-based fling snapping.

---

### 3. Anti-Slop Warm Zen UI Shell (Zero-JS Ambient Dimming)

```css
/* zen-clock.css */
:root {
  --bg-zen: #FAF8F5; /* Warm cream inspired by SofizCake */
  --text-zen: #292524;
  --accent-zen: #CA8A04; /* Muted amber */
}

body {
  background: var(--bg-zen);
  color: var(--text-zen);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
  margin: 0;
  display: grid;
  place-items: center;
  min-height: 100vh;
}

.clock-container {
  position: relative;
  transition: opacity 0.4s ease;
}

/* Zen focus: fade peripheral controls when hovering or dragging the clock */
body:has(.clock-container:hover) .peripheral-controls {
  opacity: 0.15;
  filter: blur(0.5px);
  pointer-events: none;
}

.peripheral-controls {
  transition: opacity 0.3s ease, filter 0.3s ease;
}
```
skipped: React/JS state managers for "zen focus mode".  
add when: Non-CSS capable clients or complex multi-pane layouts require state orchestration.


### Cycle #75 Directive (2026-11-03 04:09)
### 1. High-DPI Crisp Canvas Setup (Retina Sharpness)

```javascript
export function initRetinaCanvas(canvas, logicalSize) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = logicalSize * dpr;
  canvas.style.width = canvas.style.height = `${logicalSize}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  // ponytail: ignores dynamic ResizeObserver resize; upgrade if clock container is fluid
  return ctx;
}
```
* skipped: Dynamic resize handlers and orientation change listeners.
* add when: Container layout changes from fixed/max-width to fluid grid units.

---

### 2. Timeblock Magnetic Snapping (15-Minute Arc Bounds)

```javascript
export function snapRadianToInterval(rad, stepsPerHour = 4) {
  const step = (Math.PI * 2) / (12 * stepsPerHour); // 15m default
  const tau = Math.PI * 2;
  const normalized = ((rad % tau) + tau) % tau;
  return Math.round(normalized / step) * step;
}

// Self-check
console.assert(snapRadianToInterval(0.125) === snapRadianToInterval(0.13), 'Snapping failed');
console.assert(snapRadianToInterval(Math.PI / 24) === Math.PI / 24, 'Exact boundary drift');
```
* skipped: Haptic feedback triggers and velocity-based magnetism dampening.
* add when: Pointer drag gestures drop frames during fast arc scrubs.

---

### 3. SofizCake-Grade Zen Surface CSS

```css
:root {
  --canvas-bg: #fbf9f5;
  --clock-rim: #ece6dc;
  --clock-block: rgba(186, 114, 86, 0.18);
  --clock-ink: #2b2724;
}

canvas#clockface {
  background: var(--canvas-bg);
  touch-action: none;
  user-select: none;
  -webkit-font-smoothing: antialiased;
}
```
* skipped: CSS theme toggling and CSS color-mix() runtime transitions.
* add when: System `prefers-color-scheme` dark mode token set is defined.


### Cycle #76 Directive (2026-11-03 04:15)
### 1. HiDPI Canvas Scaling with Zen Warmth Render

```javascript
export function initClockCanvas(canvas, size = 320) {
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  // ponytail: fixed size scaling; upgrade to ResizeObserver if dynamic fluid sizing is needed
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}
```
`canvas.js` → skipped: dynamic window resize observer and multi-layer caching, add when clock becomes fluid-responsive.

---

### 2. Timeblock Polar Snapping Logic

```javascript
export function snapAngle(rad, stepMinutes = 5, totalMinutes = 60) {
  const tau = Math.PI * 2;
  const norm = ((rad % tau) + tau) % tau;
  const step = (tau / totalMinutes) * stepMinutes;
  // ponytail: hard grid snapping; upgrade to deadband/magnetic snapping if drag feedback feels jerky
  return (Math.round(norm / step) * step) % tau;
}

// Self-check: 0.24 rad (~13.75°) snaps to 5-minute marker (π/6 ≈ 0.5235)
console.assert(Math.abs(snapAngle(0.24, 5, 60) - (Math.PI / 6)) < 1e-5, 'Snap failed');
```
`snap.js` → skipped: velocity-sensitive drag thresholds, add when users report timeblock placement friction.

---

### 3. Zen Surface Baseline (SofizCake & firtofolio Palette)

```css
:root {
  --bg-zen: #f9f6f0;
  --surface-zen: #ede7dc;
  --ink-zen: #2d2926;
  --accent-zen: #b85d3b;
}

.zen-stage {
  display: grid;
  place-items: center;
  background-color: var(--bg-zen);
  touch-action: none;
  user-select: none;
  /* ponytail: single tone theme; upgrade to prefers-color-scheme media query if dark zen variant is requested */
}
```
`clock.css` → skipped: runtime theme toggle and complex CSS variables, add when dark mode is explicitly scheduled.


### Cycle #77 Directive (2026-11-03 04:20)
### 1. Magnetic Timeblock Snap (Math stdlib)

```ts
// Snaps pointer angle relative to center to minute increments (default: 5m)
export function snapPointerToMinutes(cx: number, cy: number, px: number, py: number, step = 5): number {
  const rad = Math.atan2(py - cy, px - cx);
  // ponytail: 12-hour single-turn dial only; upgrade to multi-turn/24h dial when multi-hour spans land
  const norm = (rad + Math.PI / 2 + Math.PI * 2) % (Math.PI * 2);
  const minutes = Math.round(((norm / (Math.PI * 2)) * 60) / step) * step;
  return minutes === 60 ? 0 : minutes;
}

// Self-check
console.assert(snapPointerToMinutes(100, 100, 100, 50, 5) === 0, 'Top must be 0m');
console.assert(snapPointerToMinutes(100, 100, 150, 100, 5) === 15, 'Right must be 15m');
console.assert(snapPointerToMinutes(100, 100, 99, 150, 5) === 30, 'Bottom must snap to 30m');
```
* Skipped: Dynamic step sizes (1m/15m toggle), gesture velocity smoothing.
* Add when: Users request arbitrary Pomodoro durations under 5 minutes.

---

### 2. Crisp HiDPI Zen Clockface Canvas Arc

```ts
export function drawZenDial(canvas: HTMLCanvasElement, activeMinutes: number, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  if (canvas.width !== size * dpr) {
    canvas.width = canvas.height = size * dpr;
    canvas.style.width = canvas.style.height = `${size}px`;
  }
  const ctx = canvas.getContext('2d')!;
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const c = size / 2;
  const r = c - 24;
  const endAngle = -Math.PI / 2 + (activeMinutes / 60) * (Math.PI * 2);

  // ponytail: hardcoded warm zen palette; lift to CSS vars when full dark mode lands
  ctx.lineWidth = 12;
  ctx.lineCap = 'round';

  // Track
  ctx.strokeStyle = '#eee9e0';
  ctx.beginPath();
  ctx.arc(c, c, r, 0, Math.PI * 2);
  ctx.stroke();

  // Active timeblock
  if (activeMinutes > 0) {
    ctx.strokeStyle = '#c46647'; // warm terracotta
    ctx.beginPath();
    ctx.arc(c, c, r, -Math.PI / 2, endAngle, false);
    ctx.stroke();
  }
}
```
* Skipped: Tick marks, numbers, gradient shaders, requestAnimationFrame loop.
* Add when: Animation during state transitions is needed instead of direct interaction.

---

### 3. Zen Interaction & Numeric Presentation (CSS)

```css
.zen-clock {
  touch-action: none;
  background-color: #fcfbf9;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  font-feature-settings: "tnum" 1;
  user-select: none;
  cursor: grab;
}

.zen-clock:active {
  cursor: grabbing;
}
```
* Skipped: Theme toggles and CSS-in-JS abstraction layers.
* Add when: Abstraction is mandated by shared UI design-system package.


### Cycle #78 Directive (2026-11-03 04:26)
### 1. HiDPI Canvas Normalizer

```javascript
export function resizeCanvas(canvas, ctx, size) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  ctx.resetTransform?.() || ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.scale(dpr, dpr);
}
```
skipped: ResizeObserver auto-binding.  
add when: The clock container needs fluid percentage widths rather than a fixed aspect ratio.

---

### 2. Zero-Dependency Polar Timeblock Snapper

```javascript
// ponytail: hardcoded to 5-min intervals; parameterize step if user preferences are introduced.
export function snapPointerToMinutes(dx, dy, step = 5) {
  const rad = Math.atan2(dy, dx) + Math.PI / 2;
  const normalized = (rad + 2 * Math.PI) % (2 * Math.PI);
  const minutes = (normalized / (2 * Math.PI)) * 60;
  return (Math.round(minutes / step) * step) % 60;
}

// Self-check
console.assert(snapPointerToMinutes(0, -100) === 0, "12 o'clock failed");
console.assert(snapPointerToMinutes(100, 0) === 15, "3 o'clock failed");
console.assert(snapPointerToMinutes(2, 98) === 30, "Snap to bottom failed");
```
skipped: Bezier drag smoothing and multi-hour arc overflows.  
add when: Focus sessions support spans strictly exceeding 60 minutes.

---

### 3. Zen Warmth Canvas Tokens & Viewport Base

```css
:root {
  --bg-zen: #fbf9f5;
  --ink-zen: #23201e;
  --accent-zen: #c86d51;
  --track-zen: rgba(35, 32, 30, 0.06);
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg-zen: #161514;
    --ink-zen: #ede9e3;
    --accent-zen: #d97d62;
    --track-zen: rgba(237, 233, 227, 0.08);
  }
}

body {
  margin: 0;
  background-color: var(--bg-zen);
  color: var(--ink-zen);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Rounded", system-ui, sans-serif;
  -webkit-font-smoothing: antialiased;
  touch-action: none;
  user-select: none;
}
```
skipped: Theme toggle button and localStorage persistence.  
add when: Manual theme override is explicitly requested over OS preference.


### Cycle #79 Directive (2026-11-03 04:31)
```javascript
// clockface.js
export function initRetina(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return { ctx, size: width };
}

export function snapAngle(rad, stepMinutes = 5) {
  const step = (2 * Math.PI) / (60 / stepMinutes);
  const norm = ((rad % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);
  // ponytail: hard grid snapping; add elastic magnetic detent when dragging feels too rigid
  return (Math.round(norm / step) * step) % (2 * Math.PI);
}

export function renderZenClock(ctx, size, startRad, endRad) {
  const c = size / 2;
  ctx.clearRect(0, 0, size, size);

  // Soft warm radial block (SofizCake palette: terracotta wash)
  ctx.beginPath();
  ctx.moveTo(c, c);
  ctx.arc(c, c, c - 6, startRad - Math.PI / 2, endRad - Math.PI / 2);
  ctx.fillStyle = 'rgba(217, 119, 87, 0.14)';
  ctx.fill();

  // Thin outer track & minimal center pin
  ctx.beginPath();
  ctx.arc(c, c, c - 6, 0, 2 * Math.PI);
  ctx.strokeStyle = 'rgba(45, 43, 40, 0.08)';
  ctx.lineWidth = 1;
  ctx.stroke();

  ctx.beginPath();
  ctx.arc(c, c, 2, 0, 2 * Math.PI);
  ctx.fillStyle = '#2d2b28';
  ctx.fill();
}

// Self-check
console.assert(Math.abs(snapAngle(Math.PI / 7, 5) - Math.PI / 6) < 1e-6, 'Snap failed');
```

```css
/* zen-canvas.css: crisp anti-aliased container */
canvas {
  width: 280px;
  height: 280px;
  background: #fbf9f5;
  border-radius: 50%;
  touch-action: none;
}
```

skipped: dynamic spring animations and drag momentum physics; add when touch interaction telemetry shows users overshooting targets.
skipped: tick-mark subdivision layers; add only if user testing proves time readouts require sub-minute precision.


### Cycle #80 Directive (2026-11-03 04:37)
### 1. HiDPI Canvas Setup with Zen Warmth Palette

```javascript
export const ZEN = { bg: '#FDFBF7', surface: '#F4EFEA', text: '#2C2523', accent: '#D97757' };

export function initCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}
```
→ skipped: Dynamic resize observers and offscreen buffering; add when supporting fluid responsive viewports or multi-layer animations.

---

### 2. Timeblock Angular Snapping (15-min Intervals)

```javascript
// ponytail: Fixed to standard 12-hour analog face. Upgrade to 24-hour via fullDay boolean if requested.
export function snapAngle(rad, stepMinutes = 15) {
  const stepRad = (2 * Math.PI) / (12 * (60 / stepMinutes));
  return Math.round(rad / stepRad) * stepRad;
}

// Check
console.assert(snapAngle(0.04, 15) === 0, 'Snap failed at origin');
console.assert(Math.abs(snapAngle(Math.PI / 6 + 0.02, 15) - Math.PI / 6) < 1e-9, 'Snap failed at 1h mark');
```
→ skipped: Magnetism thresholds and haptic event firing; add when touch/drag interaction loop is bound to pointer events.

---

### 3. Batched Minimalist Tick Marks

```javascript
export function drawDial(ctx, cx, cy, r) {
  ctx.beginPath();
  for (let i = 0; i < 12; i++) {
    const a = (i * Math.PI) / 6;
    const len = i % 3 === 0 ? 6 : 3;
    const cos = Math.cos(a), sin = Math.sin(a);
    ctx.moveTo(cx + cos * r, cy + sin * r);
    ctx.lineTo(cx + cos * (r - len), cy + sin * (r - len));
  }
  ctx.strokeStyle = '#2C252326';
  ctx.lineWidth = 1.5;
  ctx.lineCap = 'round';
  ctx.stroke();
}
```
→ skipped: Per-minute tick loops and numerical labels; add when precision mode toggle is explicitly enabled.


### Cycle #81 Directive (2026-11-03 04:42)
### 1. High-DPI Canvas Setup with Warm Zen Palette

```javascript
export const initZenCanvas = (canvas, size = 360) => {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  // ponytail: hardcoded palette; extract if dynamic light/dark theming is explicitly requested
  return {
    ctx,
    center: size / 2,
    colors: { bg: '#FBF9F5', ink: '#2B2927', block: 'rgba(217, 119, 87, 0.18)', stroke: '#D97757' }
  };
};
```
* Skipped: ResizeObserver & responsive re-layout listeners.
* Add when: Fluid fullscreen resizing or window-snap grid is required.

---

### 2. Micro-Snap Radian Math (5/15-Min Granularity)

```javascript
// Radian snap for a 12-hour face (720 min = 2π rad)
export const snapRadianToMinutes = (rad, stepMinutes = 5) => {
  const tau = Math.PI * 2;
  const norm = (rad % tau + tau) % tau;
  const totalMins = (norm / tau) * 720;
  const snappedMins = Math.round(totalMins / stepMinutes) * stepMinutes;
  // ponytail: fixed to 12h rotation; expand to 24h if multi-phase day schedules are added
  return ((snappedMins % 720) / 720) * tau;
};

// Self-check
console.assert(Math.abs(snapRadianToMinutes(Math.PI / 2, 15) - Math.PI / 2) < 1e-6, 'Snap 3:00 failed');
console.assert(Math.abs(snapRadianToMinutes(0.04, 5) - 0) < 1e-6, 'Snap zero-floor failed');
```
* Skipped: Variable magnetic snap zones and drag hysteresis.
* Add when: User feedback proves raw interval snapping misses during quick cursor flicks.

---

### 3. Pure CSS Auto-Dimming Zen Chrome

```css
.clock-viewport {
  background-color: #FBF9F5;
  display: grid;
  place-items: center;
  min-height: 100vh;
  cursor: none;
}

.clock-viewport:hover,
.clock-viewport:focus-within {
  cursor: default;
}

.zen-chrome {
  opacity: 0;
  transition: opacity 400ms cubic-bezier(0.16, 1, 0.3, 1);
  pointer-events: none;
}

.clock-viewport:hover .zen-chrome,
.clock-viewport:focus-within .zen-chrome {
  opacity: 1;
  pointer-events: auto;
}
```
* Skipped: Idle timers and `mousemove` event listeners in JavaScript.
* Add when: Native cursor auto-hiding is needed strictly after a timed inactivity timeout while the mouse is stationary inside the window.


### Cycle #82 Directive (2026-11-03 04:48)
### 1. Pointer-to-Timeblock Snapper

```js
// snap-block.js
export function snapAngleToMinutes(rad, stepMinutes = 5) {
  // ponytail: 60-min clock-face only. Upgrade to 720-min (12h) if multi-hour dragging is needed.
  const tau = Math.PI * 2;
  const normalized = (rad + Math.PI / 2 + tau) % tau;
  const rawMinutes = (normalized / tau) * 60;
  const snappedMinutes = (Math.round(rawMinutes / stepMinutes) * stepMinutes) % 60;
  return (snappedMinutes / 60) * tau - Math.PI / 2;
}

// self-check
console.assert(snapAngleToMinutes(-Math.PI / 2, 15) === -Math.PI / 2, 'Top (00m) failed');
console.assert(Math.abs(snapAngleToMinutes(0, 15) - 0) < 1e-6, 'Right (15m) failed');
```
skipped: Non-linear magnetic drag curves.  
add when: User testing shows overshooting on small screens.

---

### 2. DPR-Crisp Canvas Arc Renderer

```js
// render-clock.js
export function drawTimeblock(canvas, startRad, endRad, color = '#E6AF7A') {
  // ponytail: single-arc rendering. Upgrade to path2D batching when rendering >10 concurrent blocks.
  const dpr = window.devicePixelRatio || 1;
  const ctx = canvas.getContext('2d');
  const size = canvas.clientWidth;
  
  if (canvas.width !== size * dpr) {
    canvas.width = canvas.height = size * dpr;
  }
  
  ctx.save();
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const cx = size / 2, cy = size / 2, r = size * 0.38;
  ctx.beginPath();
  ctx.arc(cx, cy, r, startRad, endRad);
  ctx.strokeStyle = color;
  ctx.lineWidth = 14;
  ctx.lineCap = 'round';
  ctx.stroke();
  ctx.restore();
}
```
skipped: RequestAnimationFrame loop management.  
add when: Real-time clock pointer animations or ticking seconds are bound.

---

### 3. Zen Surface Isolation

```css
/* zen-clock.css */
.clock-surface {
  touch-action: none;
  user-select: none;
  -webkit-user-select: none;
  background: radial-gradient(circle, #FAFAF7 0%, #F2EFE9 100%);
  border-radius: 50%;
  box-shadow: 0 12px 36px -8px rgba(80, 70, 60, 0.08);
}
```
skipped: Dark-mode color overrides.  
add when: System `prefers-color-scheme: dark` token map is plugged into theme pipeline.


### Cycle #83 Directive (2026-11-03 04:53)
### 1. HiDPI Canvas Dial Normalizer

Eliminates retina blur and sub-pixel jitter without layout shift.

```javascript
function initClockCanvas(canvas, logicalSize = 320) {
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  canvas.width = canvas.height = logicalSize * dpr;
  canvas.style.width = canvas.style.height = `${logicalSize}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}
```
skipped: ResizeObserver dynamic scaling.
add when: dial is placed in an arbitrary fluid split-pane instead of fixed container.

---

### 2. Tactile 5-Minute Polar Snapping

Calculates angle from dial center, maps to clock time, and locks to 5-minute increments.

```javascript
function snapAngle(dx, dy, stepMins = 5) {
  // Rotate reference: 12 o'clock is 0 rad
  const deg = (Math.atan2(dy, dx) * 180 / Math.PI + 450) % 360;
  const mins = Math.round((deg / 6) / stepMins) * stepMins % 60;
  return (mins * 6 * Math.PI) / 180; // ponytail: 60-min dial only; upgrade to 12h angle scale if rendering whole day spans
}

// Self-check
console.assert(snapAngle(0, -50) === 0, '12 o’clock must snap to 0 rad');
console.assert(Math.round(snapAngle(50, 0) * 180 / Math.PI) === 90, '3 o’clock must snap to 90 deg');
```
skipped: variable magnetic snap radius (free-drag outside snap zone).
add when: user feedback shows freeform sub-minute precision is required.

---

### 3. Warm Zen Dial Frame (firtofolio / SofizCake Palette)

Pure native paths, single stroke batching, warm low-contrast tick styling (`#2C2825` on `#FBF9F5`).

```javascript
function drawDial(ctx, radius = 160) {
  const center = radius;
  ctx.clearRect(0, 0, radius * 2, radius * 2);
  
  // Warm background ring
  ctx.beginPath();
  ctx.arc(center, center, radius - 16, 0, Math.PI * 2);
  ctx.strokeStyle = 'rgba(44, 40, 37, 0.08)';
  ctx.lineWidth = 1;
  ctx.stroke();

  // 12 tactile hour ticks
  ctx.beginPath();
  for (let i = 0; i < 12; i++) {
    const angle = (i * Math.PI) / 6;
    const inner = radius - (i % 3 === 0 ? 28 : 22);
    ctx.moveTo(center + Math.sin(angle) * inner, center - Math.cos(angle) * inner);
    ctx.lineTo(center + Math.sin(angle) * (radius - 16), center - Math.cos(angle) * (radius - 16));
  }
  ctx.strokeStyle = 'rgba(44, 40, 37, 0.28)';
  ctx.lineCap = 'round';
  ctx.stroke();
}
```
skipped: CSS `color-mix()` / theme variable parsing inside canvas.
add when: dynamic system dark mode switching is wired to CSS tokens.


### Cycle #84 Directive (2026-11-03 04:59)
### 1. HiDPI Canvas Setup & Zen Warmth Palette

```typescript
// zenCanvas.ts
export const ZEN = {
  bg: '#FAF8F5',
  tick: '#E4DDD3',
  ink: '#2D2B2A',
  muted: '#8C827A',
  blockFill: 'rgba(196, 112, 79, 0.14)',
  blockStroke: '#C4704F',
} as const;

export function initCanvas(canvas: HTMLCanvasElement, size = 320): CanvasRenderingContext2D {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = size * dpr;
  canvas.height = size * dpr;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d')!;
  ctx.scale(dpr, dpr);
  return ctx;
}
```

### 2. Angular Snapping (Pure Stdlib Math)

```typescript
// snap.ts
export function snapAngleToMinutes(rad: number, stepMinutes = 5): { minutes: number; snapRad: number } {
  const TAU = Math.PI * 2;
  const normalized = ((rad % TAU) + TAU) % TAU;
  const rawMinutes = (normalized / TAU) * 720; // 12-hour face
  const minutes = (Math.round(rawMinutes / stepMinutes) * stepMinutes) % 720;
  const snapRad = (minutes / 720) * TAU;
  return { minutes, snapRad };
}
// ponytail: hardcoded to 12h clock; pass clockHours = 12 | 24 if 24h mode is needed.

// Self-check
console.assert(snapAngleToMinutes(Math.PI / 2, 15).minutes === 180, '3 o clock snaps to 180m');
console.assert(snapAngleToMinutes(0.08, 5).minutes === 10, 'Snaps ~9.16m to 10m');
```

### 3. Native Zero-Distraction Zen Surface

```css
/* zen-clock.css */
:root {
  --bg-zen: #FAF8F5;
  --ink: #2D2B2A;
}

.clock-surface {
  display: grid;
  place-items: center;
  background: var(--bg-zen);
  color: var(--ink);
  user-select: none;
  touch-action: none;
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
  font-variant-numeric: tabular-nums;
  cursor: crosshair;
}

.clock-surface:active {
  cursor: grabbing;
}
```

skipped: UI controls & drag-state machines; add when touch/pointer interaction handlers are wired.
skipped: 24h dial toggle; add when user setting dictates non-12h layout.
skipped: animation physics for snapping; add when raw instant-snap feels too rigid in hand-testing.


### Cycle #85 Directive (2026-11-03 05:04)
```typescript
// 1. Retina-crisp Canvas render with warm Zen palette (SofizCake/firtofolio warmth)
export function renderZenClock(
  canvas: HTMLCanvasElement,
  size: number,
  startMin: number,
  endMin: number
) {
  const dpr = window.devicePixelRatio || 1;
  if (canvas.width !== size * dpr) {
    canvas.width = size * dpr;
    canvas.height = size * dpr;
    canvas.style.width = `${size}px`;
    canvas.style.height = `${size}px`;
  }

  const ctx = canvas.getContext('2d')!;
  ctx.save();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const c = size / 2;
  const r = c - 18;
  const toRad = (m: number) => (m * Math.PI) / 30 - Math.PI / 2;

  // Track: warm stone
  ctx.lineWidth = 10;
  ctx.lineCap = 'round';
  ctx.strokeStyle = '#eee8df';
  ctx.beginPath();
  ctx.arc(c, c, r, 0, Math.PI * 2);
  ctx.stroke();

  // Focus Block: warm terracotta
  ctx.strokeStyle = '#d96b43';
  ctx.beginPath();
  ctx.arc(c, c, r, toRad(startMin), toRad(endMin));
  ctx.stroke();
  ctx.restore();
}

// 2. Pure 5-minute angular drag snapper
export function snapAngleToMinutes(dx: number, dy: number, step = 5): number {
  const rad = Math.atan2(dy, dx) + Math.PI / 2;
  const tau = Math.PI * 2;
  const norm = (rad < 0 ? rad + tau : rad) / tau;
  const steps = 60 / step;
  return (Math.round(norm * steps) * step) % 60;
}

// ponytail: 60-min single-turn dial; upgrade path: track multi-hour rotations using total radians.
console.assert(snapAngleToMinutes(0, -50) === 0, '12 o’clock is 0m');
console.assert(snapAngleToMinutes(50, 0) === 15, '3 o’clock is 15m');
console.assert(snapAngleToMinutes(0, 50) === 30, '6 o’clock is 30m');
```

```css
/* 3. Zero-distraction zen viewport */
.zen-shell {
  touch-action: none;
  user-select: none;
  background: radial-gradient(circle at center, #faf7f2 0%, #f4ede4 100%);
  font-feature-settings: "tnum";
  display: grid;
  place-content: center;
  min-height: 100dvh;
}
```

Skipped: Spring animations and multi-revolution state.
Add when: Drag release threshold triggers an active session transition.


### Cycle #86 Directive (2026-11-03 05:10)
### 1. Canvas High-DPI & Anti-Slop Dial Baseline

```javascript
function renderClockface(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;

  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);

  const cx = rect.width / 2, cy = rect.height / 2, r = cx - 18;
  ctx.clearRect(0, 0, rect.width, rect.height);

  // Zen 12-hour dial: low-contrast tactile dot ring
  ctx.fillStyle = 'rgba(44, 40, 37, 0.16)';
  for (let i = 0; i < 12; i++) {
    const a = (i * Math.PI) / 6 - Math.PI / 2;
    ctx.beginPath();
    ctx.arc(cx + Math.cos(a) * r, cy + Math.sin(a) * r, i % 3 === 0 ? 2 : 1, 0, Math.PI * 2);
    ctx.fill();
  }
  // ponytail: static 12-tick dial; upgrade to dynamic interval markers if sub-hour precision mode is needed.
}
```
*   **Skipped:** Second-hand ticks and numeric labels.
*   **Add when:** Specific numeric calibration is requested; currently causes visual noise.

---

### 2. Zero-Dependency 5-Minute Timeblock Pointer Snapping

```javascript
function snapPointerToMinutes(e, canvas, stepMinutes = 5) {
  const rect = canvas.getBoundingClientRect();
  const x = e.clientX - (rect.left + rect.width / 2);
  const y = e.clientY - (rect.top + rect.height / 2);
  
  // Angle [0, 2π) where 12 o'clock is 0
  const angle = (Math.atan2(y, x) + Math.PI / 2 + Math.PI * 2) % (Math.PI * 2);
  const totalMinutes = (angle / (Math.PI * 2)) * 720;
  
  return (Math.round(totalMinutes / stepMinutes) * stepMinutes) % 720;
  // ponytail: 12-hour modulo; upgrade to 24-hour domain if continuous day-spanning blocks are required.
}

// Self-check
(() => {
  const mockCanvas = { getBoundingClientRect: () => ({ left: 0, top: 0, width: 200, height: 200 }) };
  // Top center (12:00) -> 0 minutes
  console.assert(snapPointerToMinutes({ clientX: 100, clientY: 10 }, mockCanvas) === 0, '12 o’clock check failed');
  // Right center (3:00) -> 180 minutes
  console.assert(snapPointerToMinutes({ clientX: 190, clientY: 100 }, mockCanvas) === 180, '3 o’clock check failed');
})();
```
*   **Skipped:** Gesture inertia and multi-touch rotation math.
*   **Add when:** Freeform multi-touch gestures are explicitly validated on mobile viewports.

---

### 3. Zen Ambient Auto-Fade Controls (CSS)

```css
:root {
  --zen-bg: #FAF8F5;
  --zen-ink: #2C2825;
  --zen-accent: #C47A53;
}

.focus-stage {
  background: var(--zen-bg);
  color: var(--zen-ink);
  display: grid;
  place-items: center;
  touch-action: none;
  user-select: none;
}

.zen-chrome {
  opacity: 0;
  transition: opacity 240ms cubic-bezier(0.2, 0, 0, 1);
  will-change: opacity;
}

.focus-stage:hover .zen-chrome,
.focus-stage:focus-within .zen-chrome {
  opacity: 1;
}
/* ponytail: hover/focus-within trigger; add idle pointermove timer if pure touchscreen kiosks hide controls permanently. */
```
*   **Skipped:** JavaScript pointer-idle timers and visibility state tracking.
*   **Add when:** Hardware targets without hover capabilities fail to reveal controls on tap.


### Cycle #87 Directive (2026-11-03 05:15)
### 1. HiDPI Canvas Setup & Warm Tick Rendering
Fixes blurry clockfaces on Retina displays and applies anti-slop warm-zen palette (`#FAF8F5`, `#D8D2C9`, `#C4623F`).

```ts
export const renderZenFace = (canvas: HTMLCanvasElement, ctx: CanvasRenderingContext2D, size = 360) => {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  ctx.scale(dpr, dpr);
  ctx.lineCap = 'round';

  const r = size / 2;
  ctx.clearRect(0, 0, size, size);

  // ponytail: 12-hour face ticks; upgrade to dynamic sub-hour notches when zooming
  for (let i = 0; i < 12; i++) {
    const angle = (i * Math.PI) / 6;
    const isPrimary = i % 3 === 0;
    ctx.strokeStyle = isPrimary ? '#2C2825' : '#D8D2C9';
    ctx.lineWidth = isPrimary ? 2 : 1;
    ctx.beginPath();
    ctx.moveTo(r + Math.cos(angle) * (r - 18), r + Math.sin(angle) * (r - 18));
    ctx.lineTo(r + Math.cos(angle) * (r - 8), r + Math.sin(angle) * (r - 8));
    ctx.stroke();
  }
};
```
* Skipped: Offscreen canvas caching, arbitrary size observers.
* Add when: Canvas re-renders exceed 60fps budget during drag interactions.

---

### 2. Angular 15-Minute Timeblock Snapping
Converts pointer drag coordinates to 15-minute snapped minute marks (12h cycle) with zero dependencies.

```ts
export const snapPointerToMinutes = (
  x: number, y: number, cx: number, cy: number, step = 15
): number => {
  // Angle relative to 12 o'clock (0 rad = top, clockwise)
  const rad = (Math.atan2(y - cy, x - cx) + Math.PI / 2 + 2 * Math.PI) % (2 * Math.PI);
  const rawMinutes = (rad / (2 * Math.PI)) * 720;
  // ponytail: 12-hour (720m) wrap; upgrade to 24-hour track if dual-ring face is introduced
  return Math.round(rawMinutes / step) * step % 720;
};

// Self-check
console.assert(snapPointerToMinutes(100, 50, 100, 100) === 0, 'Top must be 0 min');
console.assert(snapPointerToMinutes(150, 100, 100, 100) === 180, 'Right must be 180 min (3h)');
```
* Skipped: Magnetic resistance curves, haptic triggers.
* Add when: Mobile touch interaction requires tactile feedback.

---

### 3. Native Zero-JS Zen Dimming
Auto-dims peripheral controls and UI chrome to near-invisible when the cursor remains inactive, using native CSS transitions instead of JS timers.

```css
/* Zero-distraction Zen canvas container */
.zen-clockface-stage {
  background-color: #FAF8F5;
  cursor: crosshair;
}

.zen-clockface-stage .zen-control {
  opacity: 0.15;
  transition: opacity 300ms cubic-bezier(0.16, 1, 0.3, 1) 1.5s;
}

.zen-clockface-stage:hover .zen-control,
.zen-clockface-stage:focus-within .zen-control {
  opacity: 1;
  transition-delay: 0s;
}
```
* Skipped: Idle detector JS hooks, opacity custom-property spring physics.
* Add when: Accessibility settings explicitly request `prefers-reduced-motion` overrides.


### Cycle #88 Directive (2026-11-03 05:21)
### 1. Radial Timeblock Snapping (5-min Quantization)

```javascript
export function snapAngleToMinutes(rad, stepMinutes = 5) {
  const tau = Math.PI * 2;
  const normalized = (rad % tau + tau) % tau;
  const stepRad = tau / (60 / stepMinutes);
  // ponytail: 60-min single revolution ceiling; upgrade to 12h/720m dial via param dialMinutes
  return (Math.round(normalized / stepRad) * stepRad) % tau;
}

// Self-check
console.assert(
  Math.abs(snapAngleToMinutes(0.24, 5) - (Math.PI * 2 / 12)) < 1e-6,
  'Failed to snap 0.24 rad to nearest 5-min mark'
);
```
skipped: variable dial durations (12h/24h arcs) and non-uniform magnetic snaps.  
add when: supporting multi-hour macro blocks instead of a 60-minute dial.

---

### 2. Crisp HiDPI Canvas Resizer

```javascript
export function fitRetinaCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  const targetW = Math.round(rect.width * dpr);
  const targetH = Math.round(rect.height * dpr);

  if (canvas.width !== targetW || canvas.height !== targetH) {
    canvas.width = targetW;
    canvas.height = targetH;
    const ctx = canvas.getContext('2d');
    ctx.resetTransform?.();
    ctx.scale(dpr, dpr);
  }
  // ponytail: manual call ceiling; upgrade to ResizeObserver if clock is dynamically resized
}
```
skipped: automated `ResizeObserver` lifecycle management.  
add when: dial is placed inside collapsible sidebars or fluid split-panes.

---

### 3. Zen Surface Tokens & Idle Cursor (firtofolio warm minimalist)

```css
.zen-clockface {
  contain: strict;
  user-select: none;
  touch-action: none;
  cursor: crosshair;
  background: radial-gradient(circle at center, #faf8f5 0%, #efeae4 100%);
}

.zen-clockface[data-state="focused"] {
  cursor: none;
}
```
skipped: theme toggle engine and CSS-in-JS bindings.  
add when: dark mode palette tokens are formally introduced to the design tokens.


### Cycle #89 Directive (2026-11-03 05:27)
### 1. HiDPI Canvas Dial with Zen Warmth

```javascript
export function renderClockFace(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;

  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);

  const r = size / 2;
  ctx.clearRect(0, 0, size, size);

  // Soft ceramic dial
  ctx.fillStyle = '#faf8f5';
  ctx.beginPath(); ctx.arc(r, r, r - 2, 0, Math.PI * 2); ctx.fill();

  // 12 minimal pip accents
  ctx.fillStyle = '#8c827a';
  for (let i = 0; i < 12; i++) {
    const rad = (i * Math.PI) / 6;
    const x = r + (r - 18) * Math.sin(rad);
    const y = r - (r - 18) * Math.cos(rad);
    ctx.beginPath();
    ctx.arc(x, y, i % 3 === 0 ? 2 : 1, 0, Math.PI * 2);
    ctx.fill();
  }
  return ctx;
}
// ponytail: Fixed 12-hour dial; add sub-minute tick subdivisions when millisecond countdown mode is requested.
```
→ skipped: Dynamic vector/SVG dial layers and offscreen canvas caching.  
→ add when: Custom dial themes or >60fps hand sweeps cause measurable composite lag.

---

### 2. Angular Snapping for Timeblocks (5-min increments)

```javascript
export function snapPointerToMinutes(clientX, clientY, rect, stepMinutes = 5) {
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  let rad = Math.atan2(clientY - cy, clientX - cx) + Math.PI / 2;
  if (rad < 0) rad += Math.PI * 2;

  const rawMinutes = (rad / (Math.PI * 2)) * 60;
  return (Math.round(rawMinutes / stepMinutes) * stepMinutes) % 60;
}
// ponytail: Single-hour (60-min) snap circle; upgrade to multi-hour arc math when multi-hour sessions land.

// Self-check
const mockRect = { left: 0, top: 0, width: 200, height: 200 };
console.assert(snapPointerToMinutes(200, 100, mockRect) === 15, 'Failed 3 o-clock snap');
console.assert(snapPointerToMinutes(100, 200, mockRect) === 30, 'Failed 6 o-clock snap');
```
→ skipped: Drag velocity snapping and friction physics.  
→ add when: User testing reports overshooting target time blocks on touch displays.

---

### 3. Native Zero-Distraction Chrome Auto-Fade

```css
/* Zero-distraction zen frame: chrome recedes completely unless intentional */
.clock-container {
  background-color: #faf8f5;
  --zen-opacity: 0;
}

.clock-container:hover,
.clock-container:focus-within {
  --zen-opacity: 1;
}

.zen-control {
  opacity: var(--zen-opacity);
  transition: opacity 250ms cubic-bezier(0.16, 1, 0.3, 1);
}
/* ponytail: CSS hover/focus-within trigger; add pointer idle JS timer when explicit touch device focus-drop is required. */
```
→ skipped: JS mouse-idle timer listeners and custom gesture states.  
→ add when: Deploying as a dedicated standalone PWA on touch-first hardware.


### Cycle #90 Directive (2026-11-03 05:32)
### 1. Radial Timeblock Snapping

```js
export function snapPointerToMinutes(cx, cy, x, y, step = 5) {
  const deg = (Math.atan2(y - cy, x - cx) * (180 / Math.PI) + 450) % 360;
  const rawMins = (deg / 360) * 60;
  const snapped = Math.round(rawMins / step) * step;
  // ponytail: collapses 60 to 0; upgrade to duration span if handling multi-hour arcs
  return snapped === 60 ? 0 : snapped;
}

// Runnable check
console.assert(snapPointerToMinutes(100, 100, 100, 20, 15) === 0, "Top snap failed");
console.assert(snapPointerToMinutes(100, 100, 180, 100, 15) === 15, "Right snap failed");
```
→ skipped: Continuous dragging physics and multi-turn states; add when timeblocks exceed 60 minutes.

---

### 2. DPR-Crisp Canvas Dial (Zen Palette)

```js
export function renderZenClockface(canvas, ctx, activeArcRatio = 0.4) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();

  if (canvas.width !== width * dpr) {
    canvas.width = width * dpr;
    canvas.height = height * dpr;
  }
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, width, height);

  const cx = width / 2, cy = height / 2, r = Math.min(cx, cy) - 18;

  // Track (Sofiz warm stone)
  ctx.lineWidth = 5;
  ctx.lineCap = "round";
  ctx.strokeStyle = "#e8e4dc";
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.stroke();

  // Active Focus Block (Deep warm bistre)
  if (activeArcRatio > 0) {
    ctx.strokeStyle = "#4a4237";
    ctx.beginPath();
    ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + activeArcRatio * Math.PI * 2);
    ctx.stroke();
  }
}
// ponytail: single-pass re-render; add OffscreenCanvas cache when dial markers/ticks are requested
```
→ skipped: Tick marks and secondary hands; add when Pomodoro sub-minute precision is strictly required.

---

### 3. Native Zero-Distraction Shell

```css
:root {
  --bg-zen: #fbf9f4;
  --ink: #38332b;
}

body {
  margin: 0;
  min-height: 100dvh;
  display: grid;
  place-items: center;
  background: var(--bg-zen);
  color: var(--ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro", sans-serif;
  user-select: none;
  -webkit-font-smoothing: antialiased;
}

canvas {
  touch-action: none;
  filter: drop-shadow(0 12px 32px rgba(74, 66, 55, 0.05));
}
/* ponytail: light mode only; add @media (prefers-color-scheme: dark) warm-slate variant when dark mode is tasked */
```
→ skipped: Complex CSS utility frameworks and themes; add when client settings persist custom user themes.


### Cycle #91 Directive (2026-11-03 05:38)
### 1. Snapping: 15-Minute Block Angle Quantizer

```javascript
// ponytail: step-only snapping; upgrade to elastic magnetic pull near boundaries if drag feel needs friction.
export function snapAngle(x, y, cx, cy, stepMinutes = 15) {
  const tau = Math.PI * 2;
  const raw = Math.atan2(y - cy, x - cx) + Math.PI / 2;
  const angle = (raw % tau + tau) % tau;
  const step = tau / (60 / stepMinutes);
  return Math.round(angle / step) * step;
}

// Self-check
console.assert(snapAngle(0, -100, 0, 0, 15) === 0, 'Top pointer must snap to 0 radians (12 o’clock)');
```
*   Skipped: Pointer inertia and magnet radius damping.
*   Add when: Touch interaction user testing shows overshooting on small screens.

---

### 2. Canvas: HiDPI Zero-Slop Zen Clockface

```javascript
export function renderClockface(canvas, progressAngle = 0) {
  const dpr = window.devicePixelRatio || 1;
  const size = 280;
  
  if (canvas.width !== size * dpr) {
    canvas.width = canvas.height = size * dpr;
    canvas.style.width = canvas.style.height = `${size}px`;
  }
  
  const ctx = canvas.getContext('2d');
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const cx = size / 2, cy = size / 2, r = 110;

  // Track (SofizCake warm neutral)
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.strokeStyle = 'oklch(0.92 0.015 65)';
  ctx.lineWidth = 12;
  ctx.stroke();

  // Active Block Wedge
  if (progressAngle > 0) {
    ctx.beginPath();
    ctx.arc(cx, cy, r, -Math.PI / 2, progressAngle - Math.PI / 2);
    ctx.strokeStyle = 'oklch(0.55 0.06 45)';
    ctx.lineWidth = 12;
    ctx.lineCap = 'round';
    ctx.stroke();
  }
}
```
*   Skipped: Animation frame loops and sub-tick graduation labels.
*   Add when: Continuous minute hand mode is selected over block focus mode.

---

### 3. UI: Minimal Canvas Enclosure

```css
.clock-surface {
  display: grid;
  place-items: center;
  inline-size: 100vw;
  block-size: 100dvh;
  background-color: oklch(0.98 0.01 70); /* Zen warm paper */
  user-select: none;
  touch-action: none;
}

.clock-surface canvas {
  cursor: grab;
  filter: drop-shadow(0 2px 16px oklch(0 0 0 / 0.04));
}
```
*   Skipped: Theme config objects and CSS-in-JS abstractions.
*   Add when: Dark mode / system-matched theme toggle is requested.


### Cycle #92 Directive (2026-11-03 05:44)
```javascript
// 1. Magnetic radial snap for focus blocks (5-min default)
export function snapRadialMinutes(x, y, cx, cy, step = 5) {
  const angle = Math.atan2(y - cy, x - cx);
  const norm = (angle + Math.PI / 2 + Math.PI * 2) % (Math.PI * 2);
  const minutes = (norm / (Math.PI * 2)) * 60;
  const snapped = (Math.round(minutes / step) * step) % 60;
  // ponytail: 60m dial ceiling; add multi-hour winding if blocks exceed 60m.
  return { minutes: snapped, rad: (snapped / 60) * (Math.PI * 2) - Math.PI / 2 };
}

// 2. HiDPI Canvas setup & warm minimal arc rendering
export function renderZenDial(canvas, activeEndRad, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  if (canvas.width !== size * dpr) {
    canvas.width = canvas.height = size * dpr;
    canvas.style.width = canvas.style.height = `${size}px`;
  }
  const ctx = canvas.getContext('2d');
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.clearRect(0, 0, size, size);

  const cx = size / 2, cy = size / 2, r = size * 0.38;
  const startRad = -Math.PI / 2;

  // Track (Bone)
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.strokeStyle = '#F0ECE1';
  ctx.lineWidth = 12;
  ctx.stroke();

  // Active Block (Terracotta)
  ctx.beginPath();
  ctx.arc(cx, cy, r, startRad, activeEndRad);
  ctx.strokeStyle = '#D97757';
  ctx.lineWidth = 12;
  ctx.lineCap = 'round';
  ctx.stroke();
  // ponytail: static warm palette; bind to CSS custom properties when dark mode arrives.
}

// Self-check
console.assert(snapRadialMinutes(100, 50, 100, 100).minutes === 0, '12 o’clock snap failed');
console.assert(snapRadialMinutes(150, 100, 100, 100).minutes === 15, '3 o’clock snap failed');
```

skipped: dynamic CSS var extraction and full continuous pointer drag listeners.
add when: multi-theme support or touch/pointer drag events are wired to the dial container.


### Cycle #93 Directive (2026-11-03 05:49)
### 1. Pointer Angle to 15-Minute Block Snapping

```javascript
// snaps cursor angle (radians) to discreet minute steps on a 60m clockface
export const snapToBlock = (rad, stepMinutes = 15) => {
  const step = (stepMinutes / 60) * (2 * Math.PI);
  const normalized = (rad % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
  return Math.round(normalized / step) * step;
};

// ponytail: single 60m sweep ceiling; upgrade to 12h/24h tracking via lap count
console.assert(snapToBlock(Math.PI / 1.9, 15) === Math.PI / 2, 'Must snap to 15m mark');
```
→ skipped: non-uniform variable intervals, dynamic magnetic thresholds.  
add when: user requests custom Pomodoro subdivisions (<5m or >60m).

---

### 2. High-DPI Warm Minimal Dial Stroke

```javascript
export function renderZenClock(canvas, activeSweepRad = 0) {
  const dpr = window.devicePixelRatio || 1;
  const size = canvas.clientWidth;
  if (canvas.width !== size * dpr) {
    canvas.width = size * dpr;
    canvas.height = size * dpr;
  }
  const ctx = canvas.getContext('2d');
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const c = size / 2, r = c - 12;

  // Track arc
  ctx.beginPath();
  ctx.arc(c, c, r, 0, Math.PI * 2);
  ctx.strokeStyle = '#ebe5dc';
  ctx.lineWidth = 3;
  ctx.stroke();

  // Active Focus Block
  if (activeSweepRad > 0) {
    ctx.beginPath();
    ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + activeSweepRad);
    ctx.strokeStyle = '#d96a3b'; // warm terracotta
    ctx.lineWidth = 4;
    ctx.stroke();
  }

  // 12-hour minimal indices
  ctx.fillStyle = '#8f857d';
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * Math.PI * 2 - Math.PI / 2;
    ctx.beginPath();
    ctx.arc(c + Math.cos(a) * (r - 10), c + Math.sin(a) * (r - 10), i % 3 === 0 ? 2 : 1, 0, Math.PI * 2);
    ctx.fill();
  }
}
```
→ skipped: continuous requestAnimationFrame loop and animated spring transitions.  
add when: animating hand movements or running during an active countdown tick.

---

### 3. Zen Surface & Drag Isolation (Anti-Slop CSS)

```css
:root {
  --canvas-warmth: #fbf9f5; /* firtofolio/SofizCake stone/cream ground */
  --ink: #2c2825;
}

body {
  background-color: var(--canvas-warmth);
  color: var(--ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro", system-ui, sans-serif;
  font-variant-numeric: tabular-nums;
  -webkit-font-smoothing: antialiased;
}

canvas {
  touch-action: none; /* Prevents mobile viewport rubber-banding during dial scrub */
  user-select: none;
  -webkit-user-select: none;
}
```
→ skipped: theme toggling, dark mode palettes.  
add when: explicit system `prefers-color-scheme: dark` audit is requested.


### Cycle #94 Directive (2026-11-03 05:55)
### 1. Canvas HiDPI Crispness & Native Font Sync
Fixes blurry clock ticks on Retina displays while inheriting system fonts and CSS variables directly.

```js
export function setupClockCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = size * dpr;
  canvas.height = size * dpr;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}
```

### 2. Radial 5-Minute Timeblock Snapping
Snaps pointer coordinates `(x, y)` to exact 5-minute increments (72 discrete ticks / $0.0872$ rad) around center $(cx, cy)$.

```js
// ponytail: 5m hardcoded snap. upgrade to dynamic step (1m/15m) if user toggles precision.
export function snapPointerToMinutes(x, y, cx, cy, stepMinutes = 5) {
  const rad = Math.atan2(y - cy, x - cx) + Math.PI / 2;
  const normalized = (rad < 0 ? rad + Math.PI * 2 : rad) % (Math.PI * 2);
  const totalMinutes = (normalized / (Math.PI * 2)) * 60;
  const snappedMinutes = Math.round(totalMinutes / stepMinutes) * stepMinutes % 60;
  return (snappedMinutes / 60) * Math.PI * 2;
}

// Self-check
console.assert(snapPointerToMinutes(100, 0, 100, 100) === 0, 'Top must snap to 0m');
console.assert(Math.abs(snapPointerToMinutes(200, 100, 100, 100) - Math.PI / 2) < 1e-5, 'Right must snap to 15m');
```

### 3. Zen Ambient UI (CSS-Only Focus Shield)
Warm paper dark-mode, system typography, and auto-dimming chrome during idle without JavaScript listeners.

```css
:root {
  --bg: #fbf9f5;
  --ink: #2c2825;
  --accent: #b45309;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #141210;
    --ink: #e6e2dd;
    --accent: #d97706;
  }
}
body {
  background: var(--bg);
  color: var(--ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro", sans-serif;
  margin: 0;
  display: grid;
  place-items: center;
  min-height: 100vh;
}
.zen-controls {
  opacity: 0.15;
  transition: opacity 280ms ease;
}
body:hover .zen-controls,
.zen-controls:focus-within {
  opacity: 1;
}
```

skipped: dynamic snap-granularity config and custom Bezier tick animations.
add when: user explicitly requests customizable intervals or tick haptics.


### Cycle #95 Directive (2026-11-03 06:00)
### 1. HiDPI Canvas Normalizer & Warm Dial Palette

```javascript
export function initZenCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.lineCap = 'round';
  // ponytail: static warm-paper palette; upgrade to CSS variable extraction if dynamic theme toggle is added
  return { ctx, size: width, center: width / 2, colors: { bg: '#FBF9F5', ink: '#2B2724', mute: '#E5DFD7', accent: '#D96B43' } };
}
```
skipped: ResizeObserver auto-rescaling.  
add when: Dynamic multi-device split-pane layouts are introduced.

---

### 2. Radial Timeblock Snapper (5-Minute Magnetic Increment)

```javascript
export function snapAngle(x, y, cx, cy, stepMinutes = 5) {
  const angle = Math.atan2(y - cy, x - cx) + Math.PI / 2;
  const tau = Math.PI * 2;
  const norm = (angle % tau + tau) % tau;
  const totalMinutes = (norm / tau) * 60;
  const snapped = (Math.round(totalMinutes / stepMinutes) * stepMinutes) % 60;
  return (snapped / 60) * tau - Math.PI / 2;
}

// Self-check
console.assert(Math.abs(snapAngle(100, 0, 100, 100, 5) - (-Math.PI / 2)) < 1e-6, 'Top snap failed');
console.assert(Math.abs(snapAngle(200, 100, 100, 100, 15) - 0) < 1e-6, '3 o-clock snap failed');
```
skipped: Haptic vibration triggers (`navigator.vibrate`) during threshold crossover.  
add when: Mobile touch-drag interactions are wired.

---

### 3. Pure-CSS Ambient Focus Mode

```css
:root {
  --zen-bg: #FBF9F5;
  --zen-ink: #2B2724;
}

body {
  background: var(--zen-bg);
  color: var(--zen-ink);
  margin: 0;
  overflow: hidden;
  user-select: none;
}

.zen-ui {
  opacity: 0;
  transition: opacity 0.6s cubic-bezier(0.16, 1, 0.3, 1);
}

body:hover .zen-ui,
body:focus-within .zen-ui {
  opacity: 1;
  transition-delay: 0s;
}
```
skipped: JS mouse idle timer and dynamic cursor hiding.  
add when: Fullscreen distraction-free timer run-state requires total cursor dormancy.


### Cycle #96 Directive (2026-11-03 06:06)
### 1. HiDPI Canvas Clockface with Warm Sub-Pixel Ticks

```javascript
function drawClock(ctx, size, blocks = []) {
  const dpr = window.devicePixelRatio || 1;
  const canvas = ctx.canvas;
  if (canvas.width !== size * dpr) {
    canvas.width = canvas.height = size * dpr;
    canvas.style.width = canvas.style.height = `${size}px`;
  }
  ctx.save();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const cx = size / 2, cy = size / 2, r = cx - 20;

  // Zen tick ring
  ctx.strokeStyle = '#e4dfd7';
  ctx.lineWidth = 1.5;
  for (let i = 0; i < 60; i++) {
    const rad = (i * Math.PI) / 30;
    const len = i % 5 === 0 ? 8 : 4;
    ctx.beginPath();
    ctx.moveTo(cx + Math.sin(rad) * (r - len), cy - Math.cos(rad) * (r - len));
    ctx.lineTo(cx + Math.sin(rad) * r, cy - Math.cos(rad) * r);
    ctx.stroke();
  }

  // Soft pill timeblock arcs
  blocks.forEach(({ fromMin, toMin, color = '#c89f81' }) => {
    ctx.beginPath();
    ctx.arc(cx, cy, r - 12, (fromMin / 30 - 0.5) * Math.PI, (toMin / 30 - 0.5) * Math.PI);
    ctx.strokeStyle = color;
    ctx.lineWidth = 6;
    ctx.lineCap = 'round';
    ctx.stroke();
  });
  ctx.restore();
}
```
skipped: ResizeObserver auto-binding and animation loops.  
add when: Dynamic container resizing or smooth sweep-second hands are wired up.

---

### 2. Micro Timeblock Radial Snapping

```javascript
// ponytail: Fixed to 60-min standard dial; upgrade to 12h multi-turn when handling >1hr spans.
function getSnappedMinutes(e, canvas, step = 5) {
  const { left, top, width, height } = canvas.getBoundingClientRect();
  const rad = Math.atan2(e.clientY - (top + height / 2), e.clientX - (left + width / 2)) + Math.PI / 2;
  const normalized = rad < 0 ? rad + 2 * Math.PI : rad;
  const rawMin = (normalized / (2 * Math.PI)) * 60;
  return Math.round(rawMin / step) * step % 60;
}

// Self-check: 3 o'clock must snap to 15m
console.assert(getSnappedMinutes({ clientX: 200, clientY: 100 }, { getBoundingClientRect: () => ({ left: 0, top: 0, width: 200, height: 200 }) }) === 15, "Snapping mismatch");
```
skipped: Deadzone detection and multi-ring drag hysteresis.  
add when: Users drag near canvas center or cross dial zero repeatedly.

---

### 3. Tactile Zen Styling (SofizCake / Firtofolio Baseline)

```css
:root {
  --bg: #fcfbf9;
  --panel: #f4efe8;
  --ink: #322e2b;
  --accent: #b87d5e;
}

.clock-canvas {
  touch-action: none;
  user-select: none;
  background: radial-gradient(circle at center, var(--bg) 60%, var(--panel) 100%);
  border-radius: 50%;
  box-shadow: 0 4px 20px -2px rgba(50, 46, 43, 0.05);
  font-feature-settings: "tnum" 1;
}
```
skipped: Theming engines, prefers-color-scheme overlays, and CSS Houdini paints.  
add when: Night-mode/dark slate variant is explicitly introduced.


### Cycle #97 Directive (2026-11-03 06:11)
### 1. HiDPI Canvas Scaling & Warm Zen Render Loop

```javascript
// canvas.js
export function setupZenClock(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  // ponytail: static warm cream/charcoal palette; extract to CSS vars if dark mode lands.
  return { ctx, cx: width / 2, cy: height / 2, r: Math.min(width, height) / 2 - 16 };
}
```
skipped: ResizeObserver auto-resize and orientation listener.
add when: Dynamic window resizing causes clock blur on multi-monitor setups.

---

### 2. Radial Timeblock Snapping (15-Minute Quantization)

```javascript
// snap.js
export function snapToRadialStep(rad, stepMinutes = 15) {
  const stepRad = (2 * Math.PI) / ((12 * 60) / stepMinutes);
  // Normalizes [-PI, PI] to [0, 2PI] then quantizes
  const normalized = (rad + 2 * Math.PI) % (2 * Math.PI);
  // ponytail: 12-hour face only; upgrade divisor to 24*60 if 24h mode is requested.
  return Math.round(normalized / stepRad) * stepRad;
}

// Self-check
console.assert(snapToRadialStep(0.12, 15) === 0.1308996938995747, '15-min snap mismatch');
```
skipped: Magnetic inertia and haptic touch feedback.
add when: Mobile touch drag is implemented and feels overly rigid.

---

### 3. Anti-Slop Zen Surface Tokens (firtofolio / SofizCake Warmth)

```css
/* zen.css */
:root {
  --surface: #FAF7F2;
  --ink-primary: #2D2723;
  --ink-muted: #8E8279;
  --accent-baked: #BA5D3F;
}
canvas {
  touch-action: none;
  background-color: var(--surface);
  filter: drop-shadow(0 12px 32px rgba(45, 39, 35, 0.04));
}
```
skipped: Runtime CSS-in-JS theme engine.
add when: Multiple user-definable palette slots are formally required.


### Cycle #98 Directive (2026-11-03 06:17)
### 1. HiDPI Canvas Setup & Warm Ticks

```javascript
export function initZenCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.lineCap = 'round';
  // ponytail: static warm-neutral palette; upgrade to dynamic CSS vars if theme switching is added
  ctx.strokeStyle = '#e8ded4'; 
  return ctx;
}
```
→ skipped: ResizeObserver and multi-theme abstractions; add when dynamic viewport resizing or theme switcher is required.

---

### 2. Native 15-Minute Magnetic Angle Snapping

```javascript
export function snapToBlock(radians, stepMinutes = 15) {
  const stepRad = (stepMinutes / 60) * (Math.PI / 6); // 15m = PI / 24
  // ponytail: snaps only clockwise from 12; add offset logic if arbitrary start times needed
  return Math.round(radians / stepRad) * stepRad;
}

// Self-check
console.assert(snapToBlock(0.12) === 0.1308996938995747, 'Snap failed 15m quantization');
```
→ skipped: Drag gesture state machines and bezier dampening; add when adding interactive multi-touch gestures.

---

### 3. Zen Controls Auto-Fade (Pure CSS)

```css
.clock-container {
  position: relative;
  --zen-sand: #fbf9f5;
  background: var(--zen-sand);
}

.zen-controls {
  opacity: 0;
  transition: opacity 180ms cubic-bezier(0.16, 1, 0.3, 1);
  pointer-events: none;
}

.clock-container:hover .zen-controls,
.clock-container:focus-within .zen-controls {
  opacity: 1;
  pointer-events: auto;
}
```
→ skipped: JS mouse-idle timers; add when full-screen presentation mode requires fading during mouse inactivity.


### Cycle #99 Directive (2026-11-03 06:23)
### 1. HiDPI Canvas & Zen Clockface Arc

```js
// canvas-face.js
export function setupZenCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}

export function drawArcBlock(ctx, cx, cy, radius, startMin, endMin, color = '#c87a54') {
  const toRad = (m) => ((m - 15) * 2 * Math.PI) / 60;
  ctx.save();
  ctx.beginPath();
  ctx.arc(cx, cy, radius, toRad(startMin), toRad(endMin));
  ctx.strokeStyle = color;
  ctx.lineWidth = 10;
  ctx.lineCap = 'round';
  ctx.stroke();
  ctx.restore();
}
```

### 2. Native Angle-to-Time Snap

```js
// snap.js
export function snapAngleToMinutes(rad, step = 5) {
  // 0 rad = 3 o'clock; offset by +π/2 so 0m aligns to 12 o'clock
  const norm = (rad + Math.PI / 2 + 2 * Math.PI) % (2 * Math.PI);
  const rawMin = (norm / (2 * Math.PI)) * 60;
  // ponytail: ceil snap wraps 60 to 0; upgrade if tracking multi-hour wraps
  return (Math.round(rawMin / step) * step) % 60;
}

// Self-check
console.assert(snapAngleToMinutes(-Math.PI / 2, 5) === 0, '12 o’clock must be 0m');
console.assert(snapAngleToMinutes(0, 15) === 15, '3 o’clock must be 15m');
console.assert(snapAngleToMinutes(Math.PI / 2, 5) === 30, '6 o’clock must be 30m');
```

### 3. Zen Warmth & Auto-Hiding Controls (Pure CSS)

```css
:root {
  --zen-bg: #faf7f2;
  --zen-ink: #2b2725;
  --zen-track: rgba(43, 39, 37, 0.06);
}

.zen-stage {
  background: var(--zen-bg);
  display: grid;
  place-items: center;
  user-select: none;
}

.zen-hud {
  opacity: 0;
  transform: translateY(2px);
  transition: opacity 200ms cubic-bezier(0.16, 1, 0.3, 1), transform 200ms ease;
}

.zen-stage:hover .zen-hud,
.zen-stage:focus-within .zen-hud {
  opacity: 1;
  transform: translateY(0);
}
```

skipped: Drag-handle physics & offscreen canvas caching.
add when: Touch-drag frame drops fall below 60fps or multi-hour stacking is required.


### Cycle #100 Directive (2026-11-03 06:28)
### 1. Polar-to-Timeblock Snapper

```javascript
// snap.js - Native 5-minute increment clockface snapping
export function snapAngleToMinutes(x, y, radius, stepMinutes = 5) {
  // Angle relative to 12 o'clock (top)
  const rad = Math.atan2(y, x) + Math.PI / 2;
  const normalized = (rad + 2 * Math.PI) % (2 * Math.PI);
  const minutes = (normalized / (2 * Math.PI)) * 60;
  // ponytail: 60-min single dial ceiling; upgrade path: pass duration bounds for multi-hour
  return (Math.round(minutes / stepMinutes) * stepMinutes) % 60;
}

// Self-check
console.assert(snapAngleToMinutes(0, -100, 100) === 0, '12 o’clock must be 0 min');
console.assert(snapAngleToMinutes(100, 0, 100) === 15, '3 o’clock must be 15 min');
console.assert(snapAngleToMinutes(0, 100, 100) === 30, '6 o’clock must be 30 min');
console.assert(snapAngleToMinutes(95, 30, 100) === 15, 'Snap 16-17 min down to 15 min');
```
skipped: Custom inertia physics and variable angle deadzones.  
add when: Touch gestures feel floaty or inaccurate during live user testing.

---

### 2. High-DPI Zen Clockface Canvas Renderer

```javascript
// clockface.js - Warm palette, Retina-scaled minimal arc
export function renderZenDial(canvas, ctx, progressRatio = 0.416) {
  const dpr = window.devicePixelRatio || 1;
  const size = canvas.clientWidth || 320;
  
  if (canvas.width !== size * dpr) {
    canvas.width = canvas.height = size * dpr;
    ctx.scale(dpr, dpr);
  }

  const cx = size / 2, cy = size / 2, r = size * 0.4;
  ctx.clearRect(0, 0, size, size);
  ctx.lineCap = 'round';

  // Base track
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.strokeStyle = '#EDE8E1'; // Warm sand neutral
  ctx.lineWidth = 10;
  ctx.stroke();

  // Active timeblock fill
  if (progressRatio > 0) {
    ctx.beginPath();
    ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + progressRatio * Math.PI * 2);
    ctx.strokeStyle = '#3E3A36'; // Soft charcoal
    ctx.stroke();
  }
}
```
skipped: Ticks, SVG fallback, and gradient shader sweeps.  
add when: Readability suffers without numerical tick markers.

---

### 3. Zen Shell Layout (Zero-JS Distraction Suppression)

```css
/* zen.css - SofizCake/firtofolio tone tokens and anti-layout-shift shell */
:root {
  --zen-bg: #F7F5F0;
  --zen-text: #2B2826;
  --zen-subtle: #9E9992;
}

body {
  margin: 0;
  min-height: 100dvh;
  display: grid;
  place-items: center;
  background-color: var(--zen-bg);
  color: var(--zen-text);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Rounded", system-ui, sans-serif;
  user-select: none;
  overflow: hidden;
}

canvas {
  width: min(80vw, 360px);
  aspect-ratio: 1;
  touch-action: none;
  cursor: crosshair;
}
```
skipped: Dark-mode media query overrides and external fonts.  
add when: Night-mode manual toggle is prioritized.


### Cycle #101 Directive (2026-11-03 06:34)
### 1. HiDPI Canvas & Zen Dial

```javascript
export function mountZenClock(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  const r = size / 2;

  // ponytail: static tick count; upgrade to dynamic density if variable-scale dials are requested
  ctx.clearRect(0, 0, size, size);
  ctx.lineWidth = 1;
  ctx.strokeStyle = 'rgba(74, 68, 62, 0.14)'; // Zen warm gray
  ctx.beginPath();
  ctx.arc(r, r, r - 8, 0, Math.PI * 2);
  ctx.stroke();

  for (let i = 0; i < 12; i++) {
    const angle = (i * Math.PI) / 6;
    const len = i % 3 === 0 ? 8 : 4;
    ctx.beginPath();
    ctx.moveTo(r + (r - 14) * Math.cos(angle), r + (r - 14) * Math.sin(angle));
    ctx.lineTo(r + (r - 14 - len) * Math.cos(angle), r + (r - 14 - len) * Math.sin(angle));
    ctx.stroke();
  }
}
```

### 2. Pure Math Timeblock Snapping

```javascript
export function snapAngleToMinutes(angleRad, intervalMinutes = 5) {
  const tau = Math.PI * 2;
  // ponytail: 60-minute single dial mode; upgrade to 12h/24h mapping if multi-hour arcs are enabled
  const normalized = ((angleRad + Math.PI / 2) % tau + tau) % tau;
  const rawMinutes = (normalized / tau) * 60;
  const snappedMinutes = (Math.round(rawMinutes / intervalMinutes) * intervalMinutes) % 60;
  return (snappedMinutes / 60) * tau - Math.PI / 2;
}

// Self-check
console.assert(Math.abs(snapAngleToMinutes(0, 15) - 0) < 1e-6, 'Snapping failed: 15-min right-horizontal must stay 0 rad');
console.assert(Math.abs(snapAngleToMinutes(Math.PI / 2, 15) - Math.PI / 2) < 1e-6, 'Snapping failed: 30-min bottom-vertical must stay PI/2 rad');
```

### 3. Ambient Idle UI (Zero JS)

```css
.zen-stage {
  background: #faf8f5; /* SofizCake warm parchment */
  color: #2c2825;
  cursor: none;
}
.zen-stage:hover {
  cursor: default;
}
.zen-hud {
  opacity: 0;
  transition: opacity 400ms cubic-bezier(0.16, 1, 0.3, 1);
}
.zen-stage:hover .zen-hud,
.zen-stage:focus-within .zen-hud {
  opacity: 1;
}
```

skipped: idle timer JS event listeners; add when touch devices need explicit tap-to-reveal chrome.
skipped: path2D multi-layer arc caching; add when rendering >100 dynamic micro-blocks per frame.


### Cycle #102 Directive (2026-11-03 06:40)
```javascript
// clock-dial.js
export function setupRetinaCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.lineCap = 'round';
  return { ctx, size: width };
}

// ponytail: assumes 60-min dial; upgrade to 12h/24h by parameterizing totalMinutes.
export function snapAngle(radians, stepMinutes = 5) {
  const step = (2 * Math.PI) / (60 / stepMinutes);
  const normalized = (radians % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
  return Math.round(normalized / step) * step;
}

// Self-check
console.assert(snapAngle(0.12, 15) === 0, 'Snapping failed to round down');
console.assert(Math.abs(snapAngle(Math.PI / 2 + 0.05, 15) - Math.PI / 2) < 1e-6, 'Snapping failed near 90deg');
```

```css
/* zen-clock.css */
.zen-dial {
  aspect-ratio: 1;
  width: min(78vmin, 440px);
  background: #FBF9F5; /* SofizCake warm rice-paper tone */
  border-radius: 50%;
  box-shadow: inset 0 0 0 1px rgba(45, 43, 40, 0.06), 0 8px 32px rgba(45, 43, 40, 0.04);
  touch-action: none;
  user-select: none;
}
```

skipped: ResizeObserver auto-rescaling, add when window/container is dynamically resizable.
skipped: Continuous dial sweep animations, add when state transitions feel abruptly stepped.
skipped: Multi-block overlap collision resolution, add when users can stack concurrent focus blocks.


### Cycle #103 Directive (2026-11-03 06:45)
### 1. HiDPI Canvas & Zen Clockface (`clockface.js`)
```javascript
export function renderClock(canvas, date = new Date()) {
  const dpr = window.devicePixelRatio || 1;
  const size = canvas.clientWidth;
  if (canvas.width !== size * dpr) canvas.width = canvas.height = size * dpr;

  const ctx = canvas.getContext('2d');
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const r = size / 2;
  ctx.translate(r, r);

  // Zen tick ring (firtofolio/SofizCake warm stone palette)
  ctx.strokeStyle = '#e7e5e4';
  ctx.lineWidth = 1.5;
  for (let i = 0; i < 12; i++) {
    ctx.beginPath();
    ctx.moveTo(0, -r + 12);
    ctx.lineTo(0, -r + 20);
    ctx.stroke();
    ctx.rotate(Math.PI / 6);
  }

  // Hands: hour and minute only
  const m = date.getMinutes() + date.getSeconds() / 60;
  const h = (date.getHours() % 12) + m / 60;
  drawHand(ctx, (h * Math.PI) / 6, r * 0.48, 3, '#292524');
  drawHand(ctx, (m * Math.PI) / 30, r * 0.72, 1.5, '#78716c');
}

function drawHand(ctx, angle, len, width, color) {
  ctx.save();
  ctx.rotate(angle);
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(0, 0);
  ctx.lineTo(0, -len);
  ctx.stroke();
  ctx.restore();
}
```

### 2. Timeblock Snapping (`snapping.js`)
```javascript
export function getSnappedMinutes(event, canvas, stepMinutes = 15) {
  const rect = canvas.getBoundingClientRect();
  const x = event.clientX - (rect.left + rect.width / 2);
  const y = event.clientY - (rect.top + rect.height / 2);

  // Clockwise radians from 12 o'clock [0, 2π)
  let theta = Math.atan2(y, x) + Math.PI / 2;
  if (theta < 0) theta += 2 * Math.PI;

  const rawMinutes = (theta / (2 * Math.PI)) * 60;
  // ponytail: 60m dial assumption; upgrade to 12h multi-turn tracking if blocks cross hours
  return (Math.round(rawMinutes / stepMinutes) * stepMinutes) % 60;
}

// Self-check: 3 o'clock must snap to 15 minutes
console.assert(
  getSnappedMinutes({ clientX: 200, clientY: 100 }, { getBoundingClientRect: () => ({ left: 0, top: 0, width: 200, height: 200 }) }) === 15,
  'Snap calculation mismatch'
);
```

### 3. Zen Warmth & Zero-Distraction Shell (`zen.css`)
```css
:root {
  --zen-bg: #fafaf9; /* Stone-50 warm cream */
  --zen-ink: #1c1917; /* Warm black */
  --zen-accent: #c2410c; /* Terracotta */
}

body {
  background: var(--zen-bg);
  color: var(--zen-ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
  margin: 0;
}

/* Controls fade out automatically; appear only on hover/focus */
.zen-controls {
  opacity: 0;
  pointer-events: none;
  transition: opacity 240ms cubic-bezier(0.16, 1, 0.3, 1);
}

.focus-shell:hover .zen-controls,
.focus-shell:focus-within .zen-controls {
  opacity: 1;
  pointer-events: auto;
}
```

skipped: requestAnimationFrame driver, multi-hour span rendering, gesture libraries.
add when: persistent active timers require frame loops or timeblocks exceed single 60m revolutions.


### Cycle #104 Directive (2026-11-03 06:51)
### 1. Zero-JS Zen Chrome (CSS Native Auto-Dim)
```css
/* Drops non-clock chrome to zero opacity on idle; warm zen background */
:root {
  --bg-zen: #fbf9f5;
  --ink-primary: #2e2b27;
  --ink-muted: #8c827a;
  --warm-accent: #c46849;
}

.clock-stage {
  background: var(--bg-zen);
  cursor: crosshair;
}

.clock-stage:not(:hover):not(:focus-within) .zen-chrome {
  opacity: 0;
  pointer-events: none;
}

.zen-chrome {
  transition: opacity 400ms cubic-bezier(0.16, 1, 0.3, 1);
}
```

### 2. Crisp Canvas Setup & Zen Dial Render
```javascript
export function initClockCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = size * dpr;
  canvas.height = size * dpr;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;

  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return { ctx, radius: size / 2, center: size / 2 };
}

export function drawDial(ctx, center, radius, activeBlocks = []) {
  ctx.clearRect(0, 0, center * 2, center * 2);

  // Timeblock wedges
  for (const b of activeBlocks) {
    ctx.beginPath();
    ctx.moveTo(center, center);
    ctx.arc(center, center, radius - 8, b.startAngle, b.endAngle);
    ctx.fillStyle = 'rgba(196, 104, 73, 0.12)';
    ctx.fill();
  }

  // Ticks (60-min subtle, 5-min distinct)
  for (let m = 0; m < 60; m++) {
    const rad = (m / 60) * Math.PI * 2 - Math.PI / 2;
    const isMajor = m % 5 === 0;
    const len = isMajor ? 6 : 3;
    const rOuter = radius - 10;
    const rInner = rOuter - len;

    ctx.beginPath();
    ctx.moveTo(center + Math.cos(rad) * rInner, center + Math.sin(rad) * rInner);
    ctx.lineTo(center + Math.cos(rad) * rOuter, center + Math.sin(rad) * rOuter);
    ctx.strokeStyle = isMajor ? '#8c827a' : '#ded8cf';
    ctx.lineWidth = isMajor ? 1.5 : 1;
    ctx.stroke();
  }
}
```

### 3. Pointer Snapping Math (15-min / 5-min quantization)
```javascript
// ponytail: hardcoded to 12-hour circular dial; upgrade to 24h dial if abrahamic-lore needs celestial cycles
export function snapPointerToMinutes(clientX, clientY, rect, stepMin = 5) {
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  const rawAngle = Math.atan2(clientY - cy, clientX - cx) + Math.PI / 2;
  const normAngle = (rawAngle + Math.PI * 2) % (Math.PI * 2);

  const totalMin = (normAngle / (Math.PI * 2)) * 60;
  const snappedMin = (Math.round(totalMin / stepMin) * stepMin) % 60;
  const snappedRad = (snappedMin / 60) * Math.PI * 2 - Math.PI / 2;

  return { minute: snappedMin, angleRad: snappedRad };
}

// Self-check
console.assert(
  snapPointerToMinutes(100, 50, { left: 0, top: 0, width: 200, height: 200 }, 15).minute === 0,
  '12 o clock snap failed'
);
console.assert(
  snapPointerToMinutes(200, 100, { left: 0, top: 0, width: 200, height: 200 }, 15).minute === 15,
  '3 o clock snap failed'
);
```

skipped: SVG rendering & drag-physics state machines, add when gestures require velocity-based inertia.
skipped: dynamic theme engines, add when multi-tenant workspace themes are required.
skipped: 24-hour arc projection, add when celestial prayer times integration is wired.


### Cycle #105 Directive (2026-11-03 06:57)
### 1. High-DPI Crisp Clockface Initialization

```typescript
export function mountZenClock(canvas: HTMLCanvasElement) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = Math.round(width * dpr);
  canvas.height = Math.round(height * dpr);
  const ctx = canvas.getContext('2d')!;
  ctx.scale(dpr, dpr);
  return { ctx, center: width / 2, radius: (width / 2) * 0.88 };
}
```
skipped: ResizeObserver auto-rescaling. Add when canvas container is dynamically resizable.

---

### 2. Timeblock 5-Minute Angular Snap Logic

```typescript
// ponytail: Fixed 5-min snap without magnetic drag resistance; upgrade to velocity friction if user reports jitter.
export const snapRadToMinutes = (rad: number, stepMin = 5): { min: number; snappedRad: number } => {
  const tau = Math.PI * 2;
  const norm = ((rad + Math.PI / 2) % tau + tau) % tau;
  const min = (Math.round((norm / tau) * (60 / stepMin)) * stepMin) % 60;
  return { min, snappedRad: (min / 60) * tau - Math.PI / 2 };
};

// Self-check
console.assert(snapRadToMinutes(0, 15).min === 15, '0 rad (3 o’clock) must snap to 15m');
console.assert(snapRadToMinutes(-Math.PI / 2, 5).min === 0, '-PI/2 (12 o’clock) must snap to 0m');
```
skipped: Variable threshold snapping (1m vs 15m mode toggle). Add when sub-5-minute sprints are supported.

---

### 3. Washi Warmth & Hover-Only Zen Distraction Mask

```css
:root {
  --zen-bg: #FDFCF8;    /* Rice paper warm neutral */
  --zen-ink: #1C1917;   /* Muted charcoal */
  --zen-amber: #C2410C; /* Terracotta focus arc */
}

.zen-stage {
  background: var(--zen-bg);
  font-feature-settings: "tnum" 1;
}

.zen-controls {
  opacity: 0;
  pointer-events: none;
  transition: opacity 200ms cubic-bezier(0.16, 1, 0.3, 1);
}

.zen-stage:is(:hover, :focus-within) .zen-controls {
  opacity: 1;
  pointer-events: auto;
}
```
skipped: JavaScript-based mouse inactivity timer. Add when full-screen presentation mode is requested.


### Cycle #106 Directive (2026-11-03 07:02)
### 1. High-DPI Sharp Canvas & Warm Dial Pass

```javascript
export function initClock(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}

export function drawDial(ctx, r = 160) {
  ctx.clearRect(0, 0, r * 2, r * 2);
  ctx.strokeStyle = '#e3ded8'; // Warm stone mark
  ctx.lineWidth = 1.5;
  ctx.lineCap = 'round';

  for (let i = 0; i < 12; i++) {
    const a = (i * Math.PI) / 6;
    ctx.beginPath();
    ctx.moveTo(r + (r - 14) * Math.cos(a), r + (r - 14) * Math.sin(a));
    ctx.lineTo(r + (r - 8) * Math.cos(a), r + (r - 8) * Math.sin(a));
    ctx.stroke();
  }
}
```
skipped: Minute/second sub-ticks and complex dynamic styling.  
add when: Users explicitly request a high-density chronograph view.

---

### 2. Scalar Radial Timeblock Snapping (5-Minute Units)

```javascript
export function snapAngle(rad, stepMins = 5) {
  const stepRad = (2 * Math.PI) / (60 / stepMins);
  // ponytail: standard 2PI wrap; upgrade with multi-turn delta if multi-hour dragging is introduced
  const normalized = (rad % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
  return Math.round(normalized / stepRad) * stepRad;
}

export function angleToMinutes(rad) {
  return Math.round(((rad % (2 * Math.PI)) / (2 * Math.PI)) * 60) % 60;
}

// Runnable self-check
console.assert(angleToMinutes(snapAngle(0.51, 5)) === 5, 'Must snap ~30° to 5 mins');
```
skipped: Bezier smoothing or elastic drag resistances.  
add when: Direct drag feel needs damping under pointer-device stress tests.

---

### 3. Zen Surface Foundations (CSS Native Tokens)

```css
:root {
  --zen-bg: #f9f8f6;
  --zen-ink: #2b2825;
  --zen-border: rgba(43, 40, 37, 0.07);
  --zen-arc: rgba(194, 150, 114, 0.22); /* Sandalwood wash */
}

.clock-surface {
  touch-action: none;
  background: #ffffff;
  border-radius: 50%;
  box-shadow: 
    0 8px 32px -4px rgba(43, 40, 37, 0.03),
    0 0 0 1px var(--zen-border);
  user-select: none;
}
```
skipped: JS theme provider and dynamic CSS-in-JS runtimes.  
add when: Manual user-configurable ambient themes are required.


### Cycle #107 Directive (2026-11-03 07:08)
### 1. HiDPI Canvas Normalizer (Apple Crispness)

```js
// Prevents fuzzy rendering on Retina displays; run on resize
export function fitCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  return { ctx, width, height };
}
```
* Skipped: ResizeObserver lifecycle wrapping. Add when clock mounts in a fluid container.

---

### 2. Radial Angle-to-Time Snapping (15-Min Granularity)

```js
// ponytail: hardcoded to 15-min increments; upgrade to user-defined steps when settings exist
export function snapAngleToMinutes(rad, step = 15) {
  const tau = Math.PI * 2;
  const normalized = ((rad + Math.PI / 2) % tau + tau) % tau;
  const mins = (normalized / tau) * 60;
  return Math.round(mins / step) * step % 60;
}

// Self-check
console.assert(snapAngleToMinutes(0) === 15, '3 o’clock must snap to 15m');
console.assert(snapAngleToMinutes(Math.PI / 2) === 30, '6 o’clock must snap to 30m');
```
* Skipped: Multi-hour quadrant tracking. Add when timeblocks exceed 60-minute single rotations.

---

### 3. Warm Zen Clock Plate (firtofolio/SofizCake Tone)

```css
.clock-surface {
  background: oklch(0.985 0.008 80 / 0.8);
  backdrop-filter: blur(24px) saturate(1.2);
  border: 1px solid oklch(0 0 0 / 0.04);
  box-shadow: 0 20px 40px -15px oklch(0.3 0.02 60 / 0.06);
  touch-action: none;
}
```
* Skipped: Dark mode variant via `@media (prefers-color-scheme: dark)`. Add when night-mode tokens are introduced.


### Cycle #108 Directive (2026-11-03 07:14)
### 1. Pure Circular Timeblock Snapping

```javascript
// Snaps radial interaction to discrete minute intervals (default 5-min)
export function snapAngle(rad, stepMinutes = 5) {
  // ponytail: fixed to 60-min single cycle; add multi-hour offsets when spanning >12h.
  const stepRad = (stepMinutes / 60) * (2 * Math.PI);
  const normalized = ((rad % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);
  return (Math.round(normalized / stepRad) * stepRad) % (2 * Math.PI);
}

// Self-check
console.assert(Math.abs(snapAngle(0.04, 5)) === 0, 'Snaps down to 0');
console.assert(Math.abs(snapAngle(Math.PI / 2 - 0.05, 15) - Math.PI / 2) < 1e-5, 'Snaps to 15m');
```
skipped: Elastic drag damping and kinetic momentum.
add when: Drag physics are wired to pointer gestures.

---

### 2. DPR-Crisp Canvas Clockface & Warm Zen Arc

```javascript
export function renderZenClock(canvas, startAngle, endAngle) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  if (canvas.width !== width * dpr) {
    canvas.width = width * dpr;
    canvas.height = height * dpr;
  }
  const ctx = canvas.getContext('2d');
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, width, height);

  const cx = width / 2;
  const cy = height / 2;
  const r = Math.min(cx, cy) - 24;

  // Track (zen cream-stone)
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, 2 * Math.PI);
  ctx.strokeStyle = '#E6E4DF';
  ctx.lineWidth = 14;
  ctx.stroke();

  // Active Focus Block (warm terracotta)
  ctx.beginPath();
  ctx.arc(cx, cy, r, startAngle - Math.PI / 2, endAngle - Math.PI / 2);
  ctx.strokeStyle = '#C85A32';
  ctx.lineWidth = 14;
  ctx.lineCap = 'round';
  ctx.stroke();
}
```
skipped: Custom tick subdivisions and numeric labels.
add when: Dial clarity tests fail on screens under 360px width.

---

### 3. Zero-Distraction Zen Surface (CSS)

```css
:root {
  --bg-zen: #F8F6F0;
  --ink-primary: #2A2723;
}

body {
  background: var(--bg-zen);
  color: var(--ink-primary);
  margin: 0;
  overflow: hidden;
}

canvas.clockface {
  display: block;
  touch-action: none;
  user-select: none;
  margin: auto;
}
```
skipped: Theme switching and ambient dark-mode tokens.
add when: Platform `prefers-color-scheme: dark` contract is finalized.


### Cycle #109 Directive (2026-11-03 07:19)
### 1. High-DPI Zen Dial Setup

```javascript
// clock-canvas.js
export function setupZenDial(canvas, size = 360) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = size * dpr;
  canvas.height = size * dpr;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;
  
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  // ponytail: static warm palette hardcoded; upgrade to theme tokens if dark mode is requested
  ctx.lineCap = 'round';
  return { ctx, center: size / 2, radius: size * 0.42 };
}
```
skipped: Dynamic resize observer and CSS token parsing.  
add when: Responsive multi-layout support or live theme switching is required.

---

### 2. Native Circular Pointer Snapping (5-min Quantization)

```javascript
// snap.js
export function snapPointerToMinutes(dx, dy, stepMin = 5) {
  const rad = (Math.atan2(dy, dx) + Math.PI / 2 + 2 * Math.PI) % (2 * Math.PI);
  const rawMin = (rad / (2 * Math.PI)) * 60;
  const snappedMin = (Math.round(rawMin / stepMin) * stepMin) % 60;
  const snappedRad = (snappedMin / 60) * 2 * Math.PI - Math.PI / 2;
  return { min: snappedMin, rad: snappedRad };
}

// Self-check
console.assert(snapPointerToMinutes(0, -100).min === 0, 'Top must be 0m');
console.assert(snapPointerToMinutes(100, 0).min === 15, 'Right must be 15m');
console.assert(snapPointerToMinutes(0, 100).min === 30, 'Bottom must be 30m');
```
skipped: Non-linear snapping and magnetic anchor points.  
add when: Freeform custom session durations (>60m) are modeled on the dial.

---

### 3. Minimal Ambient Timeblock Arc Pass

```javascript
// dial-render.js
export function drawZenBlock(ctx, center, radius, startMin, endMin) {
  const toRad = (m) => (m / 60) * 2 * Math.PI - Math.PI / 2;
  ctx.save();
  ctx.beginPath();
  ctx.arc(center, center, radius, toRad(startMin), toRad(endMin));
  ctx.strokeStyle = '#D97757'; // Terracotta accent
  ctx.lineWidth = 14;
  ctx.stroke();
  ctx.restore();
}
```
skipped: Drop-shadow glows and gradient shaders.  
add when: User explicitly requests active-state animation flourishes.


### Cycle #110 Directive (2026-11-03 07:25)
### 1. HiDPI Canvas Dial & Warm Ticks

```javascript
export function initZenCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return { ctx, cx: rect.width / 2, cy: rect.height / 2, r: rect.width / 2 - 20 };
}

export function renderClockface(ctx, cx, cy, r) {
  ctx.clearRect(0, 0, cx * 2, cy * 2);
  // ponytail: fixed 60-unit analog dial; upgrade to 24h dial if abrahamic-lore prayer arcs require it
  for (let i = 0; i < 60; i++) {
    const angle = (i * Math.PI) / 30;
    const isHour = i % 5 === 0;
    ctx.strokeStyle = isHour ? '#433A31' : '#D1C9BE';
    ctx.lineWidth = isHour ? 2 : 1;
    ctx.beginPath();
    ctx.moveTo(cx + Math.cos(angle) * (r - (isHour ? 10 : 5)), cy + Math.sin(angle) * (r - (isHour ? 10 : 5)));
    ctx.lineTo(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r);
    ctx.stroke();
  }
}
```
skipped: ResizeObserver auto-resize and WebGL layers.  
add when: Dynamic multi-resolution window resizes cause dial blur.

---

### 2. Radial Timeblock Snapping (5-Min Interval)

```javascript
export function snapAngle(clientX, clientY, rect, stepMinutes = 5) {
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  // ponytail: assumes 12-hour full rotation; upgrade to variable duration cycles if Pomodoro phase changes
  let rad = Math.atan2(clientY - cy, clientX - cx) + Math.PI / 2;
  if (rad < 0) rad += 2 * Math.PI;
  const stepRad = ((stepMinutes / 60) * 2 * Math.PI);
  return Math.round(rad / stepRad) * stepRad % (2 * Math.PI);
}

// Runnable self-check (3 o'clock / 15-min mark = 0.5 * PI)
console.assert(Math.abs(snapAngle(200, 100, { left: 0, top: 0, width: 200, height: 200 }) - Math.PI / 2) < 1e-6);
```
skipped: Magnetic haptic feedback and custom drag gesture recognizer.  
add when: Mobile touch interactions demand physical confirmation.

---

### 3. Ambient Idle UI (Pure CSS Zen Warmth)

```css
.zen-shell {
  --sand-50: #FAF8F5;
  --sand-200: #E6E0D6;
  --ink-900: #2C2621;
  background-color: var(--sand-50);
}

.zen-hud {
  opacity: 0.15;
  transition: opacity 400ms cubic-bezier(0.16, 1, 0.3, 1);
  pointer-events: none;
}

.zen-shell:hover .zen-hud,
.zen-shell:focus-within .zen-hud {
  opacity: 1;
  pointer-events: auto;
}

.zen-card {
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  background: rgba(250, 248, 245, 0.82);
  border: 1px solid var(--sand-200);
  color: var(--ink-900);
}
```
skipped: JS timer tracking mouse inactivity.  
add when: Zero-cursor idle needs to trigger fullscreen ambient mode after N seconds.


### Cycle #111 Directive (2026-11-03 07:31)
### 1. High-DPI Retina Canvas Sync

```javascript
export function initZenCanvas(canvas, size = 320) {
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const ctx = canvas.getContext('2d');
  canvas.width = size * dpr;
  canvas.height = size * dpr;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;
  // ponytail: ctx.resetTransform covers modern engines; fallback to setTransform(1,0,0,1,0,0) if supporting Safari < 16
  ctx.resetTransform?.();
  ctx.scale(dpr, dpr);
  return ctx;
}
```
skipped: ResizeObserver dynamic tracking.
add when: Clockface container supports arbitrary responsive fluid resize rather than fixed step sizes.

---

### 2. Timeblock 5-Minute Radial Quantizer

```javascript
export function snapAngleToMinutes(angle, stepMinutes = 5) {
  const stepRad = (stepMinutes / 60) * (2 * Math.PI);
  const normalized = (angle % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
  return Math.round(normalized / stepRad) * stepRad;
}

// Self-check
const testSnap = snapAngleToMinutes(0.51, 5); // 0.51 rad ≈ 4.87 min -> snaps to 5 min (PI/6 ≈ 0.5235)
console.assert(Math.abs(testSnap - Math.PI / 6) < 1e-4, 'Snap must align to 5-minute step');
```
skipped: Non-linear magnetic stickiness near existing block edges.
add when: Multi-segment block overlapping interactions are implemented.

---

### 3. Zen Containment & Drag Surface (CSS)

```css
.zen-clock {
  contain: strict;
  background-color: #fbf9f5; /* Warm milk/parchment */
  border-radius: 50%;
  touch-action: none;        /* Kills gesture scroll/pinch during sector drag */
  user-select: none;
  -webkit-user-select: none;
}
```
skipped: Dynamic dark/light theme switching variables.
add when: System OS dark-mode listener requirement is defined.


### Cycle #112 Directive (2026-11-03 07:36)
### 1. HiDPI Canvas Scaling with Zen Warmth Palette

Eliminates pixelated canvas arcs on Retina displays while defining the SofizCake-inspired warm background and earthen ink tokens.

```css
:root {
  --bg-zen: #faf8f5;
  --ink-primary: #2d2926;
  --ink-muted: #8c827a;
  --accent-baked: #c86d51; /* warm terracotta */
}

body {
  background: var(--bg-zen);
  color: var(--ink-primary);
  margin: 0;
}

canvas#clockface {
  width: 320px;
  height: 320px;
}
```

```javascript
function initClockCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}
```

* skipped: dynamic resize observer and multi-theme switcher.
* add when: the clockface container is made resizable by the user.

---

### 2. Zero-Dependency 15-Minute Angle Snapping

Snaps pointer angle around a 60-minute dial to clean 15-minute intervals ($\frac{\pi}{2}$ radians).

```javascript
function snapAngle(rad, stepMinutes = 15, dialMinutes = 60) {
  const step = (Math.PI * 2) * (stepMinutes / dialMinutes);
  const normalized = (rad % (Math.PI * 2) + Math.PI * 2) % (Math.PI * 2);
  // ponytail: assumes top-aligned 0 rad; add dial offset if 12 o'clock is -PI/2
  return Math.round(normalized / step) * step % (Math.PI * 2);
}

// Self-check
console.assert(snapAngle(0.7) === 0, 'Should snap ~40 deg to 0');
console.assert(snapAngle(1.5) === Math.PI / 2, 'Should snap ~85 deg to 90 deg (15m)');
```

* skipped: magnetic drag thresholds and tactile audio clicks.
* add when: live touch/drag events are hooked to the clockface arc.

---

### 3. Native Zero-Distraction Zen UI Fade

Dims periphery controls using pure CSS whenever the user is actively focused on or hovering the clock.

```css
.app-layout {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2rem;
}

.controls, .session-meta {
  transition: opacity 280ms ease, filter 280ms ease;
}

/* Zen focus state: blur & dim chrome during clock interaction */
.app-layout:has(#clockface:hover),
.app-layout:has(#clockface:active) {
  .controls, .session-meta {
    opacity: 0.15;
    filter: blur(2px);
    pointer-events: none;
  }
}
```

* skipped: custom JS inactivity timers and full-screen API calls.
* add when: user explicitly requests timed ambient screen-saving.


### Cycle #113 Directive (2026-11-03 07:42)
```ts
// clock-dial.ts
export function snapAngleToMinutes(rad: number, step = 5): number {
  const tau = Math.PI * 2;
  const normalized = (rad + Math.PI / 2 + tau) % tau;
  const rawMinutes = (normalized / tau) * 60;
  // ponytail: 60-min single dial ceiling; upgrade to 12h multi-turn when sessions cross the 1-hour threshold
  return (Math.round(rawMinutes / step) * step) % 60;
}

export function drawZenFace(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  r: number,
  startMin: number,
  endMin: number
) {
  const tau = Math.PI * 2;
  const toRad = (m: number) => (m / 60) * tau - Math.PI / 2;

  ctx.clearRect(0, 0, cx * 2, cy * 2);

  // Background track
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, tau);
  ctx.strokeStyle = "#EDE8E1"; // firto warm sand
  ctx.lineWidth = 1.5;
  ctx.stroke();

  // Snapped Timeblock Arc
  ctx.beginPath();
  ctx.arc(cx, cy, r, toRad(startMin), toRad(endMin));
  ctx.strokeStyle = "#D97757"; // SofizCake terracotta
  ctx.lineWidth = 10;
  ctx.lineCap = "round";
  ctx.stroke();

  // Subtle Center Pin
  ctx.beginPath();
  ctx.arc(cx, cy, 3, 0, tau);
  ctx.fillStyle = "#2D2A26"; // Apple warm ink
  ctx.fill();
}

// Self-check
console.assert(snapAngleToMinutes(-Math.PI / 2, 5) === 0, "12 o'clock must snap to 0m");
console.assert(snapAngleToMinutes(0, 5) === 15, "3 o'clock must snap to 15m");
console.assert(snapAngleToMinutes(Math.PI / 2, 15) === 30, "6 o'clock must snap to 30m");
```

```css
/* zen-clock.css */
.clock-viewport {
  background-color: #faf8f5;
  color: #2d2a26;
  font-feature-settings: "tnum" 1, "cv01" 1;
  display: grid;
  place-items: center;
  touch-action: none;
  user-select: none;
}
```

skipped: drag gesture physics and tick-mark loops; add when interactive pointer event listeners are wired.
skipped: multi-hour dial wrapping; add when focus sessions exceed 60 minutes.


### Cycle #114 Directive (2026-11-03 07:48)
### 1. HiDPI Canvas Crisp Scaler

```javascript
export function initZenCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  // Smooth warm anti-aliased rendering
  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = 'high';
  return ctx;
}
```
skipped: ResizeObserver auto-listen; add when the clock face is fluidly resizable in a multi-pane layout.

---

### 2. Angular 15-Minute Timeblock Snapper

```javascript
export function clientToSnappedMinutes(clientX, clientY, rect, snapMinutes = 15) {
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  let rad = Math.atan2(clientY - cy, clientX - cx) + Math.PI / 2;
  if (rad < 0) rad += Math.PI * 2;

  // 12-hour face = 720 minutes
  const rawMinutes = (rad / (Math.PI * 2)) * 720;
  // ponytail: 12-hour wraparound ceiling; add 24h toggle if multi-phase shifts needed.
  return (Math.round(rawMinutes / snapMinutes) * snapMinutes) % 720;
}

// Self-check
console.assert(clientToSnappedMinutes(150, 50, { left: 0, top: 0, width: 300, height: 300 }) === 0, '12 o’clock must be 0m');
console.assert(clientToSnappedMinutes(250, 150, { left: 0, top: 0, width: 300, height: 300 }) === 180, '3 o’clock must be 180m');
```
skipped: Bezier drag damping; add when tactile haptic dragging feedback is requested.

---

### 3. Zen Palette & Precision Layout

```css
.zen-stage {
  --zen-bg: #FDFCF9;
  --zen-ink: #1C1C1A;
  --zen-accent: #C86D51; /* Warm terracotta */
  background-color: var(--zen-bg);
  color: var(--zen-ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
  font-variant-numeric: tabular-nums lining-nums;
  touch-action: none;
  user-select: none;
}
```
skipped: Dark mode auto-switch; add when user theme preference state is wired.


### Cycle #115 Directive (2026-11-03 07:53)
### 1. HiDPI Canvas Normalizer (Subpixel Retina Crispness)

```javascript
export function setupZenCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  // ponytail: fixed snapshot size; add ResizeObserver if clock scales fluidly.
  return ctx;
}
```
skipped: ResizeObserver and orientation listeners.  
add when: layout becomes fluid or responsive split-views are introduced.

---

### 2. Radial Timeblock Snapping (5-Minute Magnetic Intervals)

```javascript
export function snapAngleToMinutes(rad, step = 5) {
  const tau = Math.PI * 2;
  const norm = ((rad % tau) + tau) % tau;
  const mins = (norm / tau) * 60;
  // ponytail: standard 60-min single dial; upgrade to 12h/24h if timeline spans full day.
  return Math.round(mins / step) * step % 60;
}

// Self-check
console.assert(snapAngleToMinutes(Math.PI / 2) === 15, 'PI/2 must snap to 15m');
console.assert(snapAngleToMinutes(0.04, 5) === 0, 'Near-zero must snap to 0m');
```
skipped: arbitrary dynamic interval steps and magnetic haptics.  
add when: dragging timeblock handles via Web Pointer Events.

---

### 3. Zen Warmth Clock Surface (Anti-Slop Color & Type)

```css
:root {
  --zen-bg: #fdfbf7;
  --zen-ink: #1c1a17;
  --zen-muted: #8c827a;
  --zen-accent: #b85d36;
}

body {
  background: var(--zen-bg);
  color: var(--zen-ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
  -webkit-font-smoothing: antialiased;
  display: grid;
  place-items: center;
  min-height: 100vh;
  margin: 0;
  user-select: none;
}

.zen-clock {
  width: 320px;
  height: 320px;
  touch-action: none;
  /* ponytail: static 320px frame; convert to container queries for Sadar dashboard integration */
}
```
skipped: dark-mode auto-switching (`prefers-color-scheme`) and CSS theming variables.  
add when: user toggles night mode or system theme sync is required.


### Cycle #116 Directive (2026-11-03 07:59)
### 1. HiDPI Canvas Normalizer & Warm Arc Renderer

```typescript
// clockface.ts - Crisp retina backing + warm Zen arc
export function setupClock(canvas: HTMLCanvasElement) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;

  const ctx = canvas.getContext('2d')!;
  ctx.scale(dpr, dpr);
  return { ctx, cx: width / 2, cy: height / 2, radius: Math.min(width, height) * 0.42 };
}

export function drawFace(ctx: CanvasRenderingContext2D, cx: number, cy: number, r: number, progress: number) {
  ctx.clearRect(0, 0, cx * 2, cy * 2);
  
  // Base track: muted warm linen
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.strokeStyle = '#EFECE6';
  ctx.lineWidth = 14;
  ctx.stroke();

  // Active focus block: soft terracotta
  if (progress > 0) {
    ctx.beginPath();
    ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + progress * Math.PI * 2);
    ctx.strokeStyle = '#D97757';
    ctx.lineCap = 'round';
    ctx.stroke();
  }
}
```
skipped: tick marks, complex shaders, multiple layers.  
add when: 60-minute division notches are explicitly requested by users.

---

### 2. Zero-Dependency Timeblock Radial Snapping

```typescript
// snapping.ts - Angle-to-minute snap (5-min default, 12h face)
export function snapAngle(rad: number, stepMinutes = 5): number {
  // Normalize -PI..PI into 0..2PI relative to 12 o'clock (top)
  const normalized = (rad + Math.PI / 2 + Math.PI * 2) % (Math.PI * 2);
  const minutes = (normalized / (Math.PI * 2)) * 60;
  
  // ponytail: assumes single 60m sweep; upgrade to 720m when supporting multi-hour blocks
  const snappedMinutes = Math.round(minutes / stepMinutes) * stepMinutes % 60;
  return (snappedMinutes / 60) * (Math.PI * 2) - Math.PI / 2;
}

// Self-check
console.assert(snapAngle(-Math.PI / 2) === -Math.PI / 2, 'Top aligns to 0m');
console.assert(Math.abs(snapAngle(0, 15) - 0) < 1e-6, '3 o clock aligns to 15m');
```
skipped: physics drag springs and momentum math.  
add when: tactile haptic feedback is bound on pointer up.

---

### 3. Pure CSS Zen Mode & Warm Paper Texture

```css
/* zen-ui.css - Ambient firtofolio/SofizCake aesthetic without JS runtime */
:root {
  --bg-zen: #FBF9F5;
  --fg-zen: #2E2C29;
}

body {
  background: var(--bg-zen);
  color: var(--fg-zen);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
  margin: 0;
  min-height: 100vh;
  display: grid;
  place-items: center;
}

.clock-container {
  position: relative;
  font-variant-numeric: tabular-nums;
}

.zen-controls {
  opacity: 0;
  transition: opacity 180ms ease-out;
}

.clock-container:hover .zen-controls,
.clock-container:focus-within .zen-controls {
  opacity: 1;
}
```
skipped: dynamic JS mouse-idle timers and glassmorphism filters.  
add when: dedicated distraction-free presentation mode is triggered via keyboard shortcut.


### Cycle #117 Directive (2026-11-03 08:05)
### 1. HiDPI Canvas Normalization & Warm Ink Setup

```javascript
export function setupZenCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return { ctx, width, height, dpr };
}
```
skipped: ResizeObserver auto-rescaling; add when fluid/split-pane layout is implemented.

---

### 2. Radial Timeblock Snapping (5/15-min Intervals)

```javascript
// ponytail: step fixed to 5m increments; extract to settings only if variable intervals are requested
export const snapRadial = (angleRad, stepMinutes = 5) => {
  const stepRad = (2 * Math.PI) / (12 * (60 / stepMinutes));
  const normalized = (angleRad % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
  return Math.round(normalized / stepRad) * stepRad;
};

// Self-check
console.assert(
  Math.abs(snapRadial(0.09, 5) - (2 * Math.PI / 144)) < 1e-6,
  'Radial snap failed'
);
```
skipped: Non-linear magnetic thresholds; add when drag-feel requires hysteresis on touch devices.

---

### 3. Zen Warmth & Subtle Interaction Layer (CSS-only)

```css
:root {
  --bg: #FAF7F2;
  --ink: #2C2623;
  --warm-gray: #E8E2D9;
  --accent: #C86446;
}

body {
  background-color: var(--bg);
  color: var(--ink);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
  user-select: none;
}

/* Zero-distraction HUD: reveal only on interaction */
.zen-controls {
  opacity: 0;
  pointer-events: none;
  transition: opacity 180ms cubic-bezier(0.16, 1, 0.3, 1);
}

body:hover .zen-controls,
body:focus-within .zen-controls {
  opacity: 1;
  pointer-events: auto;
}
```
skipped: CSS animation keyframes and ambient light themes; add when dark mode toggle is needed.


### Cycle #118 Directive (2026-11-03 08:10)
### 1. HiDPI Canvas Normalization (Retina Zen Precision)

Eliminate dial blur on Apple displays with native DPR scaling.

```javascript
export function syncCanvasDPR(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  if (canvas.width !== width * dpr || canvas.height !== height * dpr) {
    canvas.width = width * dpr;
    canvas.height = height * dpr;
    const ctx = canvas.getContext('2d');
    ctx.scale(dpr, dpr);
    return true; // redraw needed
  }
  return false;
}
```
`syncCanvasDPR(canvas)` → skipped: `ResizeObserver` listener, add when: clockface is hosted in a fluid draggable container.

---

### 2. Timeblock Radial Snapping (15-Minute Grid)

Zero-dependency angular snapping from pointer coordinates to timeblock boundaries.

```javascript
// ponytail: hardcoded to 15-min intervals; add dynamic subdivisions when user preferences exist
export function pointerToSnappedAngle(x, y, cx, cy, stepMinutes = 15) {
  const angle = (Math.atan2(y - cy, x - cx) + Math.PI * 2.5) % (Math.PI * 2);
  const stepRad = (stepMinutes / 60) * (Math.PI * 2);
  return Math.round(angle / stepRad) * stepRad;
}

// Self-check
(() => {
  const cx = 100, cy = 100;
  // 3 o'clock is 15 minutes (Math.PI / 2 radians from 12 o'clock)
  const angle = pointerToSnappedAngle(150, 100, cx, cy, 15);
  console.assert(Math.abs(angle - Math.PI / 2) < 1e-6, `Snap failed: ${angle}`);
})();
```
`pointerToSnappedAngle(...)` → skipped: elastic drag physics, add when: direct haptic feedback integration is scoped.

---

### 3. Drift-Free Sleep-Aware Idle Loop

Kill wasteful 60fps canvas loops. Re-render only at integer second boundaries or on interaction.

```javascript
export function scheduleNextTick(render) {
  let timer;
  const tick = () => {
    render();
    const now = Date.now();
    // ponytail: floor-aligned to full seconds; switch to requestAnimationFrame when hand sweep is continuous
    timer = setTimeout(tick, 1000 - (now % 1000));
  };
  tick();
  return () => clearTimeout(timer);
}
```
`scheduleNextTick(...)` → skipped: continuous smooth second-hand sweeping, add when: high-refresh-rate analog sweep is toggled on.


### Cycle #119 Directive (2026-11-03 08:16)
### 1. HiDPI Canvas Scaling (Apple-grade dial sharpness)

```js
export function bindZenCanvas(canvas, size) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  // ponytail: ignores sub-pixel canvas resize observers; upgrade when fluid/responsive auto-resizing is required.
  return ctx;
}
```
skipped: ResizeObserver auto-scaling, add when dial container becomes dynamically resizable.

---

### 2. Timeblock Angular Snapping (5-minute dial increments)

```js
export function snapToInterval(rad, totalMinutes = 60, stepMinutes = 5) {
  const twoPi = Math.PI * 2;
  const norm = (rad % twoPi + twoPi) % twoPi;
  const step = (stepMinutes / totalMinutes) * twoPi;
  return (Math.round(norm / step) * step) % twoPi;
}

// Runnable self-check (Stdlib only)
console.assert(snapToInterval(0.51, 60, 5) === Math.PI / 6, 'Should snap ~29° to 30° (5m)');
console.assert(snapToInterval(6.27, 60, 5) === 0, 'Should snap 359° to 0°');
```
skipped: Non-linear variable magnetic friction, add when physical haptic drag interaction is implemented.

---

### 3. Zen Ambient UI (CSS-native distraction suppression)

```css
/* Zero-distraction ambient mode: controls recede into dial background */
.zen-clock-surface {
  background: #FAF8F5; /* Warm rice paper / SofizCake aesthetic */
  color: #2D2B28;
}

.zen-chrome {
  opacity: 0.12;
  transition: opacity 400ms cubic-bezier(0.16, 1, 0.3, 1);
}

.zen-clock-surface:is(:hover, :focus-within) .zen-chrome {
  opacity: 1;
}
```
skipped: Idle-timer JS state engine, add when keyboard-only navigation needs explicit inactivity timeouts.


### Cycle #120 Directive (2026-11-03 08:22)
### 1. 5-Minute Timeblock Math Snap

```javascript
// Snap pointer angle to discrete time intervals (defaults to 5 mins)
export const snapAngleToMinutes = (rad, stepMinutes = 5) => {
  const totalSteps = 720 / stepMinutes; // 12h clockface = 720m
  // ponytail: assumes 12-hour face; upgrade to 24-hour if day-planner mode added
  const normalized = (rad + Math.PI / 2 + 2 * Math.PI) % (2 * Math.PI);
  const stepIndex = Math.round((normalized / (2 * Math.PI)) * totalSteps) % totalSteps;
  return (stepIndex * stepMinutes) % 720;
};

// Self-check
console.assert(snapAngleToMinutes(0) === 180, 'Top-dead-center offset check');
console.assert(snapAngleToMinutes(-Math.PI / 2) === 0, '12 o’clock check');
```
→ skipped: Drag gesture state machines and physics damping.  
→ add when: Multi-hour overlapping timeblock collisions are introduced.

---

### 2. Crisp HiDPI Canvas Dial Setup (Zen Warmth)

```javascript
export const initZenCanvas = (canvas, size = 320) => {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = size * dpr;
  canvas.height = size * dpr;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;

  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.translate(size / 2, size / 2);
  ctx.lineCap = 'round';
  return ctx;
};
```
→ skipped: ResizeObserver and auto-scaling responsive hooks.  
→ add when: Layout allows dynamic fluid resizing rather than fixed tactile dials.

---

### 3. Ambient Zen Backdrop & Subtle Fade Chrome

```css
.zen-clockface-wrap {
  position: relative;
  background: radial-gradient(circle at center, #faf8f5 0%, #f2ece4 100%);
  border-radius: 50%;
  box-shadow: inset 0 1px 2px rgba(255, 255, 255, 0.8), 0 20px 40px -15px rgba(60, 50, 40, 0.07);
}

.zen-chrome {
  opacity: 0;
  transition: opacity 180ms ease-out;
}
.zen-clockface-wrap:hover .zen-chrome,
.zen-clockface-wrap:focus-within .zen-chrome {
  opacity: 1;
}
```
→ skipped: JS-driven timer idle detection.  
→ add when: User requires pointer-idle hiding while hovering the dial.


### Cycle #121 Directive (2026-11-03 08:27)
### 1. Retina-Crisp Canvas Surface (Eliminates Canvas Blur)

```javascript
function fitClockCanvas(canvas, displaySize = 320) {
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  canvas.width = canvas.height = displaySize * dpr;
  canvas.style.width = canvas.style.height = `${displaySize}px`;
  const ctx = canvas.getContext('2d');
  ctx.resetTransform?.();
  ctx.scale(dpr, dpr);
  return ctx;
}
```
skipped: ResizeObserver and non-square aspect handling.
add when: The clock face needs to dynamically respond to arbitrary fluid viewport sizing.

---

### 2. Radial Timeblock Snapping (Exact 5-minute / 12-hour quantization)

```javascript
// ponytail: hardcoded to 12h clockface; upgrade when 24h military face mode is added.
function snapAngleToMinutes(rad, step = 5) {
  const TAU = Math.PI * 2;
  const normalized = (rad % TAU + TAU) % TAU;
  const minutes = (normalized / TAU) * 720;
  const snapped = Math.round(minutes / step) * step % 720;
  return (snapped / 720) * TAU;
}

// Self-check
console.assert(snapAngleToMinutes(0.08, 5) === 0, 'Should snap near 0 rad to 0m');
console.assert(Math.abs(snapAngleToMinutes(Math.PI / 2, 15) - Math.PI / 2) < 1e-6, 'Should snap 3 o-clock to 90deg');
```
skipped: Magnetic snapping weights and hysteresis thresholds.
add when: Users report jittery dragging on touch devices.

---

### 3. Zen Warmth Palette & Soft Timeblock Fill (SofizCake/firtofolio aesthetic)

```javascript
const ZEN_PALETTE = {
  face: '#FAF8F5',       // Warm linen background
  track: '#ECE7E1',      // Low-contrast perimeter track
  terracotta: '#CC785C', // SofizCake warm earth tone
  graphite: '#2E2B29'    // Soft black hand/indices
};

function renderZenSlice(ctx, cx, cy, radius, startRad, endRad) {
  ctx.save();
  ctx.fillStyle = `${ZEN_PALETTE.terracotta}24`; // 14% warm alpha wash
  ctx.strokeStyle = ZEN_PALETTE.terracotta;
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.arc(cx, cy, radius, startRad - Math.PI / 2, endRad - Math.PI / 2);
  ctx.closePath();
  ctx.fill();
  ctx.stroke();
  ctx.restore();
}
```
skipped: Multi-block overlap handling and drag handles.
add when: Multi-session layering is introduced to the daily log.


### Cycle #122 Directive (2026-11-03 08:33)
### 1. HiDPI Canvas Normalization & Warmth Palette

```css
:root {
  --bg-zen: #fbf9f5;
  --clock-face: #f4efe6;
  --clock-hand: #2b2927;
  --clock-accent: #c86d51; /* terracotta warmth */
}
body { background: var(--bg-zen); color: var(--clock-hand); }
canvas { display: block; width: 100%; height: 100%; }
```

```javascript
// ponytail: assumes fixed aspect-ratio container; add ResizeObserver if canvas is fluidly resizable
export function setupClockCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const rect = canvas.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return { ctx, width: rect.width, height: rect.height };
}
```
skipped: ResizeObserver dynamic scaling.  
add when: viewport resizing causes canvas blur mid-session.

---

### 2. 5-Minute Timeblock Angle Snapper

```javascript
// Snaps radian angle to 5-minute buckets (12 buckets/hr = π/6 rads) on a 60-min dial
// ponytail: 60-min single-hour dial only; upgrade to 12h if multi-hour dragging is needed
export const snapToBlock = (rad, stepMinutes = 5) => {
  const stepRad = (stepMinutes / 60) * (2 * Math.PI);
  const normalized = (rad % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI);
  return Math.round(normalized / stepRad) * stepRad % (2 * Math.PI);
};

// runnable self-check
console.assert(Math.abs(snapToBlock(0.24, 5) - (Math.PI / 6)) < 1e-6, "Snapping 0.24 rad failed");
```
skipped: variable minute granularity configurations (1m, 15m, 30m UI toggles).  
add when: user requests non-5m pomodoro chunking.

---

### 3. Zero-Distraction Zen UI Fade (Pure CSS)

```css
/* Zero-JS auto-fade: Clock chrome hides during idle focus, reveals on hover or tab navigation */
.clock-chrome {
  opacity: 0.15;
  transition: opacity 400ms cubic-bezier(0.16, 1, 0.3, 1);
}
.clock-container:hover .clock-chrome,
.clock-container:focus-within .clock-chrome {
  opacity: 1;
}
```
skipped: JS mouse-move idle timers.  
add when: touch devices need a tap-to-toggle overlay mode.


### Cycle #123 Directive (2026-11-03 08:39)
```javascript
// 1. Crisp HiDPI Zen Clockface Canvas
export function renderZenClock(ctx, size, date = new Date()) {
  const dpr = window.devicePixelRatio || 1;
  if (ctx.canvas.width !== size * dpr) {
    ctx.canvas.width = ctx.canvas.height = size * dpr;
  }
  ctx.save();
  ctx.scale(dpr, dpr);
  ctx.clearRect(0, 0, size, size);

  const cx = size / 2, cy = size / 2, r = cx - 20;

  // Dial: 12 warm pips (SofizCake warm paper: #FAF8F5 / subtle ink: #2E2B27)
  ctx.fillStyle = '#2e2b27';
  for (let i = 0; i < 12; i++) {
    const rad = (i * Math.PI) / 6;
    ctx.beginPath();
    ctx.arc(cx + Math.sin(rad) * r, cy - Math.cos(rad) * r, i % 3 === 0 ? 2 : 1, 0, 6.28318);
    ctx.fill();
  }

  // Hands: Sub-millisecond continuous minute/hour hands
  const s = date.getSeconds() + date.getMilliseconds() / 1000;
  const m = date.getMinutes() + s / 60;
  const h = (date.getHours() % 12) + m / 60;

  // ponytail: Hardcoded stroke weights. Upgrade to dynamic scaling if viewport zoom controls are added.
  strokeRay(ctx, cx, cy, (h * Math.PI) / 6, r * 0.52, 2.5, '#2e2b27');
  strokeRay(ctx, cx, cy, (m * Math.PI) / 30, r * 0.78, 1.5, '#2e2b27');
  strokeRay(ctx, cx, cy, (s * Math.PI) / 30, r * 0.85, 0.75, '#c95f38'); // Terracotta second tick

  ctx.restore();
}

function strokeRay(ctx, cx, cy, rad, len, w, color) {
  ctx.beginPath();
  ctx.lineWidth = w;
  ctx.lineCap = 'round';
  ctx.strokeStyle = color;
  ctx.moveTo(cx, cy);
  ctx.lineTo(cx + Math.sin(rad) * len, cy - Math.cos(rad) * len);
  ctx.stroke();
}

// 2. Polar 5-Minute Timeblock Snapper
export function snapPolarTime(rad, stepMinutes = 5) {
  const step = (stepMinutes / 60) * 2 * Math.PI;
  const norm = ((rad % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);
  // ponytail: Snaps to top-of-hour origin. Upgrade to arbitrary offset if floating start times are needed.
  return Math.round(norm / step) * step;
}

// Runnable test for timeblock snapping
console.assert(
  Math.abs(snapPolarTime((14 / 60) * 2 * Math.PI, 5) - (15 / 60) * 2 * Math.PI) < 1e-6,
  'Snap failed: 14m did not round to 15m'
);
```

```css
/* 3. Zero-Jank Zen Canvas Wrapper */
.clock-viewport {
  width: min(80vw, 360px);
  aspect-ratio: 1;
  background-color: #faf8f5;
  touch-action: none;
  user-select: none;
  display: grid;
  place-items: center;
}
.clock-viewport canvas {
  width: 100%;
  height: 100%;
  display: block;
}
```

skipped: Arc slice collision rendering and Bezier hand transitions.  
add when: Timeblock duration dragging interaction is wired to state.


### Cycle #124 Directive (2026-11-03 08:45)
```javascript
// 1. Retina Crispness: Canvas buffer sync
function initZenCanvas(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return ctx;
}

// 2. Magnetic Radial Snapping (12h face, 5-min steps)
function snapAngleToMinutes(cx, cy, px, py, step = 5) {
  // ponytail: 12-hour dial only; upgrade to 24-hour if day-planner mode is added
  const rad = Math.atan2(py - cy, px - cx) + Math.PI / 2;
  const normalized = (rad + Math.PI * 2) % (Math.PI * 2);
  const rawMin = (normalized / (Math.PI * 2)) * 60;
  return (Math.round(rawMin / step) * step) % 60;
}

// Runnable self-check
console.assert(snapAngleToMinutes(100, 100, 100, 20) === 0, 'Top must be 0m');
console.assert(snapAngleToMinutes(100, 100, 180, 100) === 15, 'Right must be 15m');
console.assert(snapAngleToMinutes(100, 100, 100, 180) === 30, 'Bottom must be 30m');
console.assert(snapAngleToMinutes(100, 100, 20, 100) === 45, 'Left must be 45m');
```

```css
/* 3. Zen Warmth Dial Base (Offload static chrome from Canvas to CSS) */
.clock-dial {
  width: 20rem;
  aspect-ratio: 1;
  border-radius: 50%;
  background: #fbf9f5; /* warm rice paper */
  box-shadow: 
    inset 0 0 0 1px rgba(60, 40, 20, 0.05),
    0 12px 32px -8px rgba(60, 40, 20, 0.06);
  touch-action: none;
}
```

skipped: requestAnimationFrame loop with inertia; add when continuous free-drag physics are needed.
skipped: tick-mark canvas rendering; add when static CSS conical gradients fail dial requirements.
skipped: multi-hour duration spans; add when timeblocks extend past 60-minute single-ring boundaries.


### Cycle #125 Directive (2026-11-03 08:50)
### 1. Canvas Retina Scaling & Zen Dial

```javascript
export function renderZenClockface(ctx, size) {
  const dpr = window.devicePixelRatio || 1;
  ctx.canvas.width = size * dpr;
  ctx.canvas.height = size * dpr;
  ctx.canvas.style.width = `${size}px`;
  ctx.canvas.style.height = `${size}px`;
  ctx.scale(dpr, dpr);

  const c = size / 2, r = c - 10;
  ctx.clearRect(0, 0, size, size);

  // Soft muted dial perimeter
  ctx.beginPath();
  ctx.arc(c, c, r, 0, Math.PI * 2);
  ctx.strokeStyle = '#E8E2D9';
  ctx.lineWidth = 1.5;
  ctx.stroke();

  // ponytail: static 12-interval ticks; upgrade to dynamic 60-interval zoom on drag
  for (let i = 0; i < 12; i++) {
    const rad = (i * Math.PI) / 6 - Math.PI / 2;
    const isQuarter = i % 3 === 0;
    const tickLen = isQuarter ? 8 : 4;

    ctx.beginPath();
    ctx.moveTo(c + Math.cos(rad) * (r - 4), c + Math.sin(rad) * (r - 4));
    ctx.lineTo(c + Math.cos(rad) * (r - 4 - tickLen), c + Math.sin(rad) * (r - 4 - tickLen));
    ctx.strokeStyle = isQuarter ? '#6E665F' : '#B8B0A6';
    ctx.lineWidth = isQuarter ? 2 : 1;
    ctx.lineCap = 'round';
    ctx.stroke();
  }
}
```
*   `drawDial` → skipped: text labels and complex gradient masks; add when user requests numeric hour readouts.

---

### 2. Radial Timeblock Snapping

```javascript
export function snapPointerToMinutes(clientX, clientY, rect, stepMin = 5) {
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  // 12 o'clock = 0 rad
  let rad = Math.atan2(clientY - cy, clientX - cx) + Math.PI / 2;
  if (rad < 0) rad += Math.PI * 2;

  // ponytail: 60-min single turn clamp; upgrade to multi-hour modulo if sessions > 60m
  const rawMin = (rad / (Math.PI * 2)) * 60;
  const snappedMin = Math.round(rawMin / stepMin) * stepMin % 60;
  const snappedRad = (snappedMin / 60) * Math.PI * 2 - Math.PI / 2;

  return { minutes: snappedMin, radians: snappedRad };
}

// Self-check
console.assert(
  snapPointerToMinutes(100, 50, { left: 0, top: 0, width: 200, height: 200 }, 5).minutes === 15,
  '3 o clock must snap to 15m'
);
```
*   `snapPointerToMinutes` → skipped: elastic overshoot physics; add when touch drag gesture polish is requested.

---

### 3. Zero-Distraction Chrome Auto-Fade

```css
/* Warm zen container + idle-hidden chrome */
.zen-clock-surface {
  background-color: #FAF8F5;
  color: #2D2825;
}

.zen-clock-surface .zen-chrome {
  opacity: 0;
  pointer-events: none;
  transition: opacity 200ms cubic-bezier(0.16, 1, 0.3, 1);
}

.zen-clock-surface:hover .zen-chrome,
.zen-clock-surface:focus-within .zen-chrome {
  opacity: 1;
  pointer-events: auto;
}
```
*   `.zen-chrome` → skipped: JavaScript inactivity timers; add when tablet/touch-only without hover requires manual tap-away.


### Cycle #129 Directive (2026-11-03 09:13)
### 1. HiDPI Retina-Crisp Canvas Scaler

```javascript
// canvas.js
export function syncCanvasDPI(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  if (canvas.width !== width * dpr || canvas.height !== height * dpr) {
    canvas.width = width * dpr;
    canvas.height = height * dpr;
  }
  const ctx = canvas.getContext('2d');
  ctx.resetTransform();
  ctx.scale(dpr, dpr);
  return { ctx, width, height };
}
```
skipped: ResizeObserver abstraction, dynamic layout observers.  
add when: canvas is dynamically resizable inside responsive split-panes.

---

### 2. Timeblock Snap Engine (Pure Polar Math)

```javascript
// snap.js
// ponytail: single 60-min ring ceiling; upgrade to multi-hour layered arcs when Sadar schedule integration arrives.
export function snapPointerToMinutes(clientX, clientY, rect, stepMins = 5) {
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  const rad = Math.atan2(clientY - cy, clientX - cx) + Math.PI / 2;
  const normalized = (rad < 0 ? rad + Math.PI * 2 : rad) / (Math.PI * 2);
  const rawMins = normalized * 60;
  return (Math.round(rawMins / stepMins) * stepMins) % 60;
}

// Runnable self-check
console.assert(snapPointerToMinutes(100, 50, { left: 50, top: 50, width: 100, height: 100 }) === 0, '12 oclock failed');
console.assert(snapPointerToMinutes(150, 100, { left: 50, top: 50, width: 100, height: 100 }) === 15, '3 oclock failed');
console.assert(snapPointerToMinutes(100, 150, { left: 50, top: 50, width: 100, height: 100 }) === 30, '6 oclock failed');
```
skipped: Bezier handle tracking, multi-ring radial math.  
add when: implementing 12-hour or full-day 24h timeline views.

---

### 3. Zen Palette & Pure-CSS Ambient Focus Shell

```css
/* zen-clock.css */
:root {
  --zen-bg: #F7F5F0;
  --zen-ink: #262320;
  --zen-track: #E9E5DD;
  --zen-terracotta: #B8583B;
}

.focus-stage {
  background: var(--zen-bg);
  color: var(--zen-ink);
  font-variant-numeric: tabular-nums;
  touch-action: none;
}

/* Zero-distraction: controls recede into background when idling */
.zen-controls {
  opacity: 0;
  transition: opacity 240ms cubic-bezier(0.16, 1, 0.3, 1);
}

.focus-stage:hover .zen-controls,
.focus-stage:focus-within .zen-controls {
  opacity: 1;
}
```
skipped: JS mousemove timer and auto-hide controller state machines.  
add when: custom touch-device tap-to-reveal gestures are required.


### Cycle #130 Directive (2026-11-03 09:19)
### 1. HiDPI Canvas Normalization & Warm Zen Dial

```javascript
export function setupZenClock(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  ctx.lineCap = 'round';
  return ctx;
}

export function drawArcBlock(ctx, cx, cy, r, startAngle, endAngle, color = '#E6D5C3') {
  ctx.beginPath();
  ctx.arc(cx, cy, r, startAngle - Math.PI / 2, endAngle - Math.PI / 2);
  ctx.lineWidth = 14;
  ctx.strokeStyle = color; // ponytail: hardcoded warm stone tone; upgrade to theme tokens if dark mode added.
  ctx.stroke();
}
```
skipped: Bezier drag handles, multi-theme config objects.  
add when: Dynamic user-customizable color palettes or gradient arcs are requested.

---

### 2. 5-Minute Magnetic Angle Snapping

```javascript
const TAU = Math.PI * 2;

export function snapToInterval(rad, totalMinutes = 60, intervalMinutes = 5) {
  const normalized = (rad % TAU + TAU) % TAU;
  const step = (TAU / totalMinutes) * intervalMinutes;
  return Math.round(normalized / step) * step;
}

// Self-check
console.assert(snapToInterval(0.1, 60, 5) === 0, 'Snap down failed');
console.assert(Math.abs(snapToInterval(0.5, 60, 5) - (TAU / 12)) < 1e-6, 'Snap to 5m failed');
```
skipped: Hysteresis velocity tracking, spring physics.  
add when: Touch release micro-wobble causes mis-selection during rapid dragging.

---

### 3. Zero-Distraction Zen Idle Dimmer (CSS-Only)

```css
/* Container auto-fades chrome; clockface stays sharp */
.zen-clock-container {
  --zen-ease: cubic-bezier(0.16, 1, 0.3, 1);
  background: #FBF9F5;
}

.zen-clock-container .hud-control {
  opacity: 0.15;
  transition: opacity 600ms var(--zen-ease);
}

.zen-clock-container:is(:hover, :focus-within) .hud-control {
  opacity: 1;
  transition-duration: 150ms;
}
```
skipped: JavaScript inactivity timers and event listener churn.  
add when: Non-mouse touch devices require a tap-to-wake HUD overlay.


### Cycle #131 Directive (2026-11-03 09:25)
### 1. HiDPI Canvas & Zen Warm Dial (`canvas-dial.js`)

```javascript
export function mountZenClock(canvas, size = 320) {
  const dpr = window.devicePixelRatio || 1;
  canvas.width = canvas.height = size * dpr;
  canvas.style.width = canvas.style.height = `${size}px`;
  
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  // ponytail: hardcoded stone-200/400. upgrade path: read CSS custom properties via getComputedStyle.
  return function draw(progressRad = 0) {
    const c = size / 2;
    ctx.clearRect(0, 0, size, size);

    // Subtle tick ring
    ctx.lineWidth = 1;
    for (let i = 0; i < 60; i++) {
      const rad = (i * Math.PI) / 30;
      const len = i % 5 === 0 ? 6 : 3;
      ctx.strokeStyle = i % 5 === 0 ? '#a8a29e' : '#e7e5e4';
      ctx.beginPath();
      ctx.moveTo(c + (c - 16) * Math.sin(rad), c - (c - 16) * Math.cos(rad));
      ctx.lineTo(c + (c - 16 - len) * Math.sin(rad), c - (c - 16 - len) * Math.cos(rad));
      ctx.stroke();
    }
  };
}
```

### 2. Timeblock Angular Snapping (`snap-time.js`)

```javascript
// Snaps drag offset (x, y relative to center) to quantized minute buckets (default 5m)
export function snapAngleToMinutes(x, y, stepMin = 5) {
  // ponytail: fixed to 60m cycle. upgrade path: parameterized duration mode (e.g. 120m deep work).
  const rad = (Math.atan2(y, x) + Math.PI * 2.5) % (Math.PI * 2);
  const rawMin = (rad / (Math.PI * 2)) * 60;
  return (Math.round(rawMin / stepMin) * stepMin) % 60;
}

// Runnable check
console.assert(snapAngleToMinutes(0, -100, 5) === 0, '12 o clock snap fail');
console.assert(snapAngleToMinutes(100, 0, 5) === 15, '3 o clock snap fail');
console.assert(snapAngleToMinutes(-1, -100, 5) === 0, 'Boundary snap fail');
```

### 3. Firtofolio Warm Base + Zen Auto-Dim (`zen.css`)

```css
:root {
  --zen-bg: #f9f8f6; /* firto warm oatmeal */
  --zen-ink: #2b2725;
}

body {
  background: var(--zen-bg);
  color: var(--zen-ink);
  font-feature-settings: "tnum" 1;
  -webkit-font-smoothing: antialiased;
}

/* Zero-distraction: fade controls out until intent is shown */
.clock-hud {
  opacity: 0;
  transition: opacity 300ms cubic-bezier(0.16, 1, 0.3, 1);
}

body:hover .clock-hud,
.clock-hud:focus-within {
  opacity: 1;
}
```

skipped: dynamic theme switcher and custom bezier curves, add when persistent multi-theme preference is required.


### Cycle #132 Directive (2026-11-03 09:31)
### 1. HiDPI Canvas Surface (Retina Sharpness & Auto-DPI)

```javascript
export function initZenCanvas(canvas) {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  const ctx = canvas.getContext('2d');
  ctx.scale(dpr, dpr);
  return { ctx, width, height };
}
```
skipped: ResizeObserver dynamic tracking.  
add when: Dynamic viewport/split-screen resizing is introduced.

---

### 2. Timeblock Dial Snapping (15-Min Discrete Segments)

```javascript
// ponytail: Fixed to 12-hour / 60-minute single dial. Upgrade to multi-revolution for multi-hour sessions.
export function snapAngle(rad, stepMinutes = 15) {
  const TAU = Math.PI * 2;
  const norm = ((rad % TAU) + TAU) % TAU;
  const mins = (norm / TAU) * 60;
  const snapped = (Math.round(mins / stepMinutes) * stepMinutes) % 60;
  return (snapped / 60) * TAU;
}

// Self-check: 14.4 mins (~0.48π) snaps to 15 mins (0.5π)
console.assert(Math.abs(snapAngle(Math.PI * 0.48) - Math.PI * 0.5) < 1e-6, "Snap check failed");
```
skipped: Dynamic variable-step thresholds (e.g., 5m vs 15m drag resistance).  
add when: User explicitly requests magnetic threshold physics or velocity-based snapping.

---

### 3. Sofiz/Firto Zen Arc Renderer (Warm Minimal Palette)

```javascript
const ZEN = { bg: '#FBF9F5', track: '#EFECE6', active: '#C86446', text: '#2D2B28' };

export function drawDial(ctx, cx, cy, radius, startRad, endRad) {
  ctx.clearRect(0, 0, cx * 2, cy * 2);
  
  // Track
  ctx.beginPath();
  ctx.arc(cx, cy, radius, 0, Math.PI * 2);
  ctx.strokeStyle = ZEN.track;
  ctx.lineWidth = 12;
  ctx.stroke();

  // Active Timeblock Arc
  ctx.beginPath();
  ctx.arc(cx, cy, radius, startRad - Math.PI / 2, endRad - Math.PI / 2);
  ctx.strokeStyle = ZEN.active;
  ctx.lineWidth = 12;
  ctx.lineCap = 'round';
  ctx.stroke();
}
```
skipped: Complex radial tick marks, drop shadows, and numeric labels.  
add when: User testing shows orientation disorientation without hour numerals.
