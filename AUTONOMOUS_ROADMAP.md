

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
