

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
