import { store, minutesToTime, formatDurationMinutes } from '../store.js';
import { sound } from '../sound.js';

export function renderClockFace(container) {
  const tasks = store.tasks;
  const isAm = store.clockHalf === 'am';
  const halfOffset = isAm ? 0 : 720; // 0 for AM, 720 for PM

  container.innerHTML = `
    <div class="clock-view-container">
      <!-- Top Bar: AM/PM Half Toggle & Quick Legend -->
      <div class="clock-top-bar">
        <div class="half-toggle-group">
          <button class="half-toggle-btn ${isAm ? 'active' : ''}" id="btn-toggle-am">
            ☀️ AM (Pagi - Siang: 00:00 - 12:00)
          </button>
          <button class="half-toggle-btn ${!isAm ? 'active' : ''}" id="btn-toggle-pm">
            🌙 PM (Siang - Malam: 12:00 - 24:00)
          </button>
        </div>
        <div class="clock-instruction-pill">
          🖐️ Geser badan slice untuk pindah jam • Tarik bulatan putih untuk ubah durasi
        </div>
      </div>

      <!-- Giant Clock Stage (Super Gede & Alami) -->
      <div class="clock-stage">
        <div id="clock-live-tooltip" class="clock-tooltip"></div>
        <svg id="giant-clock-svg" class="clock-svg" viewBox="0 0 540 540">
          <defs>
            <!-- Radial background gradient: warm dark obsidian with soft center warmth -->
            <radialGradient id="dialBgGrad" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stop-color="#1E1C28" />
              <stop offset="65%" stop-color="#14121B" />
              <stop offset="92%" stop-color="#0E0D13" />
              <stop offset="100%" stop-color="#07060A" />
            </radialGradient>
            <!-- Brushed metallic watch bezel gradient -->
            <linearGradient id="metallicBezel" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stop-color="#4A455A" />
              <stop offset="25%" stop-color="#24212D" />
              <stop offset="50%" stop-color="#5E5872" />
              <stop offset="75%" stop-color="#1A1822" />
              <stop offset="100%" stop-color="#3A3648" />
            </linearGradient>
            <!-- Drop shadow for handles and dial -->
            <filter id="handleShadow" x="-50%" y="-50%" width="200%" height="200%">
              <feDropShadow dx="0" dy="2" stdDeviation="4" flood-color="#000000" flood-opacity="0.8"/>
            </filter>
            <filter id="dialShadow" x="-20%" y="-20%" width="140%" height="140%">
              <feDropShadow dx="0" dy="16" stdDeviation="30" flood-color="#000000" flood-opacity="0.8"/>
            </filter>
          </defs>

          <!-- Outer Brushed Metallic Bezel Ring -->
          <circle cx="270" cy="270" r="264" fill="url(#metallicBezel)" />
          <circle cx="270" cy="270" r="258" fill="url(#dialBgGrad)" stroke="rgba(255,255,255,0.06)" stroke-width="1.5" />
          
          <!-- Concentric Precision Vinyl Tracks -->
          <circle cx="270" cy="270" r="248" fill="none" stroke="rgba(240, 201, 135, 0.06)" stroke-width="1" />
          <circle cx="270" cy="270" r="160" fill="none" stroke="rgba(255, 255, 255, 0.03)" stroke-width="1" stroke-dasharray="2, 6" />
          <circle cx="270" cy="270" r="122" fill="#0C0B10" stroke="rgba(255,255,255,0.08)" stroke-width="2" />

          <!-- Hour Ticks & Numbers -->
          <g id="clock-ticks"></g>
          <g id="clock-numbers"></g>

          <!-- Task Sectors Group -->
          <g id="clock-sectors"></g>

          <!-- Current Time Now Hand (Precision Red Needle with Glow) -->
          <line id="now-hand-line" x1="270" y1="270" x2="270" y2="72" stroke="#F43F5E" stroke-width="3" stroke-linecap="round" />
          <line id="now-hand-tail" x1="270" y1="270" x2="270" y2="305" stroke="#F43F5E" stroke-width="4.5" stroke-linecap="round" opacity="0.6" />
          <circle id="now-hand-dot" cx="270" cy="72" r="6" fill="#F43F5E" filter="drop-shadow(0 0 10px rgba(244,63,94,1))" />

          <!-- Center Cap (Brass / Gold Watch Dial Pivot) -->
          <circle cx="270" cy="270" r="20" fill="#1C1A24" stroke="#F0C987" stroke-width="2.5" />
          <circle cx="270" cy="270" r="7" fill="#F0C987" />
          <text x="270" y="274" fill="#F0C987" font-size="9" font-weight="800" text-anchor="middle" font-family="'JetBrains Mono', monospace">
            ${isAm ? 'AM' : 'PM'}
          </text>
        </svg>
      </div>
    </div>
  `;

  const svg = container.querySelector('#giant-clock-svg');
  const tooltip = container.querySelector('#clock-live-tooltip');
  const ticksGroup = container.querySelector('#clock-ticks');
  const numbersGroup = container.querySelector('#clock-numbers');
  const sectorsGroup = container.querySelector('#clock-sectors');

  // Render Hour Ticks & Numbers (1 to 12)
  let ticksHtml = '';
  let numbersHtml = '';
  for (let i = 1; i <= 12; i++) {
    const angle = (i * 30 - 90) * (Math.PI / 180);
    const xOuter = 270 + 250 * Math.cos(angle);
    const yOuter = 270 + 250 * Math.sin(angle);
    const xInner = 270 + 234 * Math.cos(angle);
    const yInner = 270 + 234 * Math.sin(angle);

    ticksHtml += `<line x1="${xInner}" y1="${yInner}" x2="${xOuter}" y2="${yOuter}" stroke="rgba(255,255,255,0.3)" stroke-width="3" stroke-linecap="round" />`;

    // Hour Number (Generous & High Contrast)
    const xNum = 270 + 210 * Math.cos(angle);
    const yNum = 270 + 210 * Math.sin(angle) + 7; // baseline adjust
    const displayNum = isAm ? i : (i === 12 ? 12 : i + 12);
    numbersHtml += `
      <text 
        x="${xNum}" 
        y="${yNum}" 
        fill="#F7F3EB" 
        font-size="22" 
        font-weight="800" 
        text-anchor="middle" 
        font-family="'Outfit', 'Plus Jakarta Sans', sans-serif"
      >
        ${displayNum}
      </text>
    `;
  }

  // 60 minute subtle ticks
  for (let m = 0; m < 60; m++) {
    if (m % 5 === 0) continue;
    const angle = (m * 6 - 90) * (Math.PI / 180);
    const xOuter = 270 + 250 * Math.cos(angle);
    const yOuter = 270 + 250 * Math.sin(angle);
    const xInner = 270 + 242 * Math.cos(angle);
    const yInner = 270 + 242 * Math.sin(angle);
    ticksHtml += `<line x1="${xInner}" y1="${yInner}" x2="${xOuter}" y2="${yOuter}" stroke="rgba(255,255,255,0.12)" stroke-width="1.5" />`;
  }

  ticksGroup.innerHTML = ticksHtml;
  numbersGroup.innerHTML = numbersHtml;

  // Render Task Sectors for current half
  renderSectors(sectorsGroup, tasks, halfOffset);

  // Update Now Hand position
  updateNowHand(container);

  // Toggle buttons
  container.querySelector('#btn-toggle-am').addEventListener('click', () => {
    sound.playTap();
    store.setClockHalf('am');
  });
  container.querySelector('#btn-toggle-pm').addEventListener('click', () => {
    sound.playTap();
    store.setClockHalf('pm');
  });

  // Attach Drag & Slide Listeners with tactile feedback
  setupClockDragging(svg, tooltip, halfOffset, sectorsGroup);
}

// Convert minute to angle (12-hour dial = 720 minutes = 360 deg -> 0.5 deg / min)
function minuteToAngle(minuteInHalf) {
  return ((minuteInHalf % 720) * 0.5) - 90;
}

// Convert angle back to minutes (0 to 719)
function angleToMinute(angleDeg) {
  let norm = (angleDeg + 90) % 360;
  if (norm < 0) norm += 360;
  return Math.round(norm / 0.5);
}

function polarToCartesian(cx, cy, r, angleDeg) {
  const rad = angleDeg * (Math.PI / 180);
  return {
    x: cx + r * Math.cos(rad),
    y: cy + r * Math.sin(rad)
  };
}

// Describe SVG Donut Sector Arc
function describeDonutArc(cx, cy, rOuter, rInner, startAngle, endAngle) {
  let diff = endAngle - startAngle;
  if (diff < 0) diff += 360;
  if (diff > 359.9) diff = 359.9;

  const actualEnd = startAngle + diff;
  const p1 = polarToCartesian(cx, cy, rOuter, startAngle);
  const p2 = polarToCartesian(cx, cy, rOuter, actualEnd);
  const p3 = polarToCartesian(cx, cy, rInner, actualEnd);
  const p4 = polarToCartesian(cx, cy, rInner, startAngle);

  const largeArcFlag = diff > 180 ? 1 : 0;

  return [
    `M ${p1.x} ${p1.y}`,
    `A ${rOuter} ${rOuter} 0 ${largeArcFlag} 1 ${p2.x} ${p2.y}`,
    `L ${p3.x} ${p3.y}`,
    `A ${rInner} ${rInner} 0 ${largeArcFlag} 0 ${p4.x} ${p4.y}`,
    'Z'
  ].join(' ');
}

function renderSectors(group, tasks, halfOffset) {
  let sectorsHtml = '';
  const rOuter = 248;
  const rInner = 122;

  tasks.forEach((task) => {
    const taskStart = task.startMinute;
    const taskEnd = task.endMinute;

    const clampedStart = Math.max(taskStart, halfOffset);
    const clampedEnd = Math.min(taskEnd, halfOffset + 720);

    if (clampedStart < clampedEnd) {
      const relStart = clampedStart - halfOffset;
      const relEnd = clampedEnd - halfOffset;

      const a1 = minuteToAngle(relStart);
      const a2 = minuteToAngle(relEnd);

      const pathData = describeDonutArc(270, 270, rOuter, rInner, a1, a2);
      const midAngle = (a1 + (a2 > a1 ? a2 : a2 + 360)) / 2;
      const labelPos = polarToCartesian(270, 270, (rOuter + rInner) / 2, midAngle);

      // Handle positions at radial midpoint
      const startHandle = polarToCartesian(270, 270, (rOuter + rInner) / 2, a1);
      const endHandle = polarToCartesian(270, 270, (rOuter + rInner) / 2, a2);

      sectorsHtml += `
        <g class="clock-sector" data-id="${task.id}" style="cursor: grab;">
          <!-- Sector Body (Thick, Warm, Organic) -->
          <path 
            d="${pathData}" 
            fill="${task.color || '#F0C987'}" 
            fill-opacity="0.82" 
            stroke="${task.color || '#F0C987'}" 
            stroke-width="2"
            data-part="body"
            data-id="${task.id}"
            filter="drop-shadow(0 4px 12px rgba(0,0,0,0.5))"
          />
          
          <!-- Sector Label (Prominent text) -->
          <text 
            x="${labelPos.x}" 
            y="${labelPos.y + 5}" 
            fill="#0F0E13" 
            font-size="14" 
            font-weight="900" 
            text-anchor="middle"
            font-family="'Plus Jakarta Sans', sans-serif"
            pointer-events="none"
          >
            ${escapeXml(task.what.slice(0, 18))}
          </text>

          <!-- Start Resize Handle (Big Tactile White Enamel Ring) -->
          <circle 
            cx="${startHandle.x}" 
            cy="${startHandle.y}" 
            r="11" 
            fill="#FFFFFF" 
            stroke="${task.color || '#F0C987'}" 
            stroke-width="3.5"
            filter="url(#handleShadow)"
            style="cursor: ew-resize;"
            data-part="handle-start"
            data-id="${task.id}"
          />

          <!-- End Resize Handle (Big Tactile White Enamel Ring) -->
          <circle 
            cx="${endHandle.x}" 
            cy="${endHandle.y}" 
            r="11" 
            fill="#FFFFFF" 
            stroke="${task.color || '#F0C987'}" 
            stroke-width="3.5"
            filter="url(#handleShadow)"
            style="cursor: ew-resize;"
            data-part="handle-end"
            data-id="${task.id}"
          />
        </g>
      `;
    }
  });

  group.innerHTML = sectorsHtml;
}

// Interactive Drag & Slide Engine with Haptic Tick Feedback
function setupClockDragging(svg, tooltip, halfOffset, sectorsGroup) {
  let dragState = null;
  let lastSnappedMinute = -1;

  function getMouseAngle(e) {
    const rect = svg.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;
    const rad = Math.atan2(clientY - cy, clientX - cx);
    return rad * (180 / Math.PI);
  }

  function snapMinutes(minutes, step = 5) {
    return Math.round(minutes / step) * step;
  }

  svg.addEventListener('pointerdown', (e) => {
    const target = e.target;
    const part = target.dataset.part;
    const taskId = target.dataset.id;
    if (!part || !taskId) return;

    const task = store.tasks.find(t => t.id === taskId);
    if (!task) return;

    sound.playTap();

    const startMouseAngle = getMouseAngle(e);
    const startMouseMinute = angleToMinute(startMouseAngle);

    dragState = {
      taskId,
      part,
      taskStartMinute: task.startMinute,
      taskEndMinute: task.endMinute,
      duration: task.endMinute - task.startMinute,
      startMouseMinute
    };
    lastSnappedMinute = dragState.taskStartMinute;

    svg.setPointerCapture(e.pointerId);
    tooltip.classList.add('visible');
    tooltip.textContent = `${task.what}: ${minutesToTime(task.startMinute)} – ${minutesToTime(task.endMinute)} (${formatDurationMinutes(dragState.duration)})`;
    e.preventDefault();
  });

  svg.addEventListener('pointermove', (e) => {
    if (!dragState) return;

    const curAngle = getMouseAngle(e);
    const curMinute = angleToMinute(curAngle);
    const deltaMinute = curMinute - dragState.startMouseMinute;

    const task = store.tasks.find(t => t.id === dragState.taskId);
    if (!task) return;

    let newStart = task.startMinute;
    let newEnd = task.endMinute;

    if (dragState.part === 'body') {
      // Slide entire block
      const targetStart = snapMinutes(dragState.taskStartMinute + deltaMinute, 5);
      newStart = Math.max(0, Math.min(1440 - dragState.duration, targetStart));
      newEnd = newStart + dragState.duration;
    } else if (dragState.part === 'handle-start') {
      // Resize start
      const targetStart = snapMinutes(dragState.taskStartMinute + deltaMinute, 5);
      newStart = Math.min(task.endMinute - 10, Math.max(0, targetStart));
    } else if (dragState.part === 'handle-end') {
      // Resize end
      const targetEnd = snapMinutes(dragState.taskEndMinute + deltaMinute, 5);
      newEnd = Math.max(task.startMinute + 10, Math.min(1440, targetEnd));
    }

    if (newStart !== lastSnappedMinute) {
      sound.playTick(); // Wooden tick on snap
      lastSnappedMinute = newStart;
    }

    // Update state silently so UI is NOT wiped by subscribers while dragging
    store.updateTask(task.id, { startMinute: newStart, endMinute: newEnd }, false);

    // Re-render only the SVG sectors in-place
    renderSectors(sectorsGroup, store.tasks, halfOffset);

    // Update floating live tooltip
    tooltip.textContent = `${task.what}: ${minutesToTime(newStart)} – ${minutesToTime(newEnd)} (${formatDurationMinutes(newEnd - newStart)})`;
  });

  const finishDrag = (e) => {
    if (dragState) {
      sound.playTap();
      tooltip.classList.remove('visible');
      // Save and emit structural change to sync other views cleanly
      store.saveTasks();
      store.notify({ type: 'change' });
      dragState = null;
    }
  };

  svg.addEventListener('pointerup', finishDrag);
  svg.addEventListener('pointercancel', finishDrag);
}

function updateNowHand(container) {
  const line = container.querySelector('#now-hand-line');
  const dot = container.querySelector('#now-hand-dot');
  const tail = container.querySelector('#now-hand-tail');
  if (!line || !dot) return;

  const now = new Date();
  const nowMinuteInHalf = (now.getHours() % 12) * 60 + now.getMinutes();
  const angle = minuteToAngle(nowMinuteInHalf);

  const ptInner = polarToCartesian(270, 270, 24, angle);
  const ptOuter = polarToCartesian(270, 270, 252, angle);
  const ptTail = polarToCartesian(270, 270, 38, angle + 180);

  line.setAttribute('x1', ptInner.x);
  line.setAttribute('y1', ptInner.y);
  line.setAttribute('x2', ptOuter.x);
  line.setAttribute('y2', ptOuter.y);

  if (tail) {
    tail.setAttribute('x1', '270');
    tail.setAttribute('y1', '270');
    tail.setAttribute('x2', ptTail.x);
    tail.setAttribute('y2', ptTail.y);
  }

  dot.setAttribute('cx', ptOuter.x);
  dot.setAttribute('cy', ptOuter.y);
}

function escapeXml(unsafe) {
  return (unsafe || '').replace(/[<>&'"]/g, c => {
    switch (c) {
      case '<': return '&lt;';
      case '>': return '&gt;';
      case '&': return '&amp;';
      case '\'': return '&apos;';
      case '"': return '&quot;';
    }
  });
}
