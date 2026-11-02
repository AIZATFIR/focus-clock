

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
