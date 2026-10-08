import { store, formatSeconds, minutesToTime, formatDurationMinutes } from '../store.js';
import { sound } from '../sound.js';

let timerInterval = null;
let pipVideoElement = null;
let chimeTriggeredForCurrentSession = false;

export function renderTimerView(container) {
  const session = store.activeSession;

  if (!session) {
    chimeTriggeredForCurrentSession = false;
    renderIdleTimer(container);
    return;
  }

  // Active Running Session
  const totalSeconds = session.durationSeconds;
  const isGoldenGate = totalSeconds >= 600; // 10 minutes reached!
  const progressRatio = Math.min(1, totalSeconds / 600);
  const circumference = 2 * Math.PI * 180;
  const strokeOffset = circumference * (1 - progressRatio);

  // Trigger audio celebration once when passing 600s
  if (isGoldenGate && !chimeTriggeredForCurrentSession) {
    chimeTriggeredForCurrentSession = true;
    sound.playChime();
  }

  const { nextTask } = store.getCurrentAndNextTask();

  container.innerHTML = `
    <div class="timer-view-container">
      <!-- Target Task Pill (Gede & Jelas) -->
      <div class="timer-target-pill">
        <span class="timer-task-name">🎯 ${escapeHtml(session.what)}</span>
        <span class="timer-task-where">📍 ${escapeHtml(session.where || 'Meja Belajar')}</span>
      </div>

      <!-- Giant 10-Minute Golden Gate Ring Clock -->
      <div class="timer-clock-ring">
        <svg class="timer-svg" viewBox="0 0 420 420">
          <circle 
            class="timer-ring-bg" 
            cx="210" cy="210" r="180" 
            fill="none" 
            stroke-width="14" 
          />
          <circle 
            class="timer-ring-progress ${isGoldenGate ? 'golden-gate' : ''}" 
            cx="210" cy="210" r="180" 
            fill="none" 
            stroke-width="14" 
            stroke-dasharray="${circumference}"
            stroke-dashoffset="${isGoldenGate ? 0 : strokeOffset}"
          />
        </svg>

        <div class="timer-center-content">
          <div class="timer-digits" id="timer-digits-text">
            ${formatSeconds(totalSeconds)}
          </div>
          <div class="timer-milestone-status ${isGoldenGate ? 'achieved' : ''}">
            ${isGoldenGate 
              ? '✨ 10 MENIT TERCAPAI! (BONUS FOKUS)' 
              : `🎯 Menuju 10 menit pertama (${Math.floor((totalSeconds / 600) * 100)}%)`}
          </div>
        </div>
      </div>

      <!-- Big Tactile Emergency Stop & Controls -->
      <div class="timer-controls">
        <button class="btn-emergency-stop" id="btn-emergency-stop" title="Stop & Simpan Sesi Kapan Saja (Spacebar)">
          <span>⏹️</span>
          <span>STOP / GURU DATANG</span>
          <span style="font-size: 11px; opacity: 0.8; background: rgba(0,0,0,0.3); padding: 3px 8px; border-radius: 6px; font-family: var(--font-mono);">SPACE</span>
        </button>

        <button class="btn-pip" id="btn-pip-toggle" title="Display over display (Picture-in-Picture floating timer)">
          <span>🪟</span>
          <span>Floating PiP</span>
        </button>

        <button class="btn-fullscreen" id="btn-fullscreen-toggle" title="Layar Penuh Tanpa Gangguan">
          <span>⛶</span>
          <span>Fullscreen</span>
        </button>
      </div>

      <!-- Context Next Task Pill if available -->
      ${nextTask ? `
        <div style="font-size: 13px; color: var(--text-muted); background: var(--bg-surface); padding: 8px 18px; border-radius: var(--radius-full); border: 1px solid var(--border-subtle); display: inline-flex; align-items: center; gap: 8px;">
          <span>⏳ Jadwal Berikutnya:</span>
          <strong style="color: var(--text-main);">${escapeHtml(nextTask.what)}</strong>
          <span style="color: var(--accent-gold); font-family: var(--font-mono); font-size: 12px;">(${minutesToTime(nextTask.startMinute)})</span>
        </div>
      ` : `
        <div style="font-size: 13px; color: var(--text-dim); text-align: center; max-width: 480px; margin-top: -6px;">
          💡 <em>Fokus dari abundance, bukan scarcity. Stop kapan saja jika ada interupsi, durasi tersimpan jujur tanpa hukuman.</em>
        </div>
      `}
    </div>
  `;

  // Start internal ticker if not running
  if (!timerInterval) {
    timerInterval = setInterval(() => {
      store.tickTimer();
      updateTimerDisplay(container);
    }, 1000);
  }

  // Bind Emergency Stop
  container.querySelector('#btn-emergency-stop').addEventListener('click', () => {
    sound.playTap();
    handleStop();
  });

  // Bind Fullscreen
  container.querySelector('#btn-fullscreen-toggle').addEventListener('click', () => {
    sound.playTap();
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
    } else {
      document.exitFullscreen().catch(() => {});
    }
  });

  // Bind Picture-in-Picture
  container.querySelector('#btn-pip-toggle').addEventListener('click', () => {
    sound.playTap();
    togglePictureInPicture(session);
  });
}

function renderIdleTimer(container) {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }

  const { currentTask, nextTask, curMin } = store.getCurrentAndNextTask();
  const allTasks = store.tasks.filter(t => !t.completed);

  container.innerHTML = `
    <div class="timer-view-container" style="max-width: 720px; margin: 0 auto; width: 100%;">
      
      <!-- HERO UNIFIED CURRENT FOCUS CARD ("Satuin Current") -->
      <div class="current-focus-hero-card">
        ${currentTask ? `
          <div class="current-badge-row">
            <span class="live-pulse-dot"></span>
            <span class="current-badge-text">● SEDANG BERLANGSUNG SEKARANG (LIVE SCHEDULE)</span>
            <span class="current-time-pill">⏰ ${minutesToTime(currentTask.startMinute)} – ${minutesToTime(currentTask.endMinute)}</span>
          </div>

          <div class="current-hero-title">
            ${escapeHtml(currentTask.what)}
          </div>

          <div class="current-meta-row">
            <span class="tag-location">📍 ${escapeHtml(currentTask.where || 'Meja Belajar')}</span>
            <span class="tag-duration" style="background: rgba(16, 185, 129, 0.15); color: #10B981; border: 1px solid rgba(16, 185, 129, 0.3);">
              ⏳ Sisa Waktu Jadwal: <strong>${Math.max(1, currentTask.endMinute - curMin)} Menit</strong>
            </span>
            ${nextTask ? `
              <span class="tag-next">Berikutnya: <strong>${escapeHtml(nextTask.what)}</strong> (${minutesToTime(nextTask.startMinute)})</span>
            ` : ''}
          </div>

          <div class="current-action-row">
            <button class="btn-start-current-focus" data-action="start-current" data-id="${currentTask.id}">
              <span>▶ MULAI FOKUS TUGAS INI SEKARANG</span>
              <span class="golden-hint">🎯 Target 10 Menit</span>
            </button>
          </div>
        ` : `
          <!-- No Current Task: Free Time or Upcoming -->
          <div class="current-badge-row">
            <span class="free-pulse-dot"></span>
            <span class="current-badge-text">⚡ WAKTU BEBAS (SIAP FOKUS MANDIRI)</span>
            <span class="current-time-pill">Jam Sekarang: ${minutesToTime(curMin)}</span>
          </div>

          <div class="current-hero-title">
            ${nextTask ? `Siap Untuk "${escapeHtml(nextTask.what)}"?` : 'Fokus Bebas Mandiri'}
          </div>

          <div class="current-meta-row">
            ${nextTask ? `
              <span class="tag-location">📍 ${escapeHtml(nextTask.where || 'Meja Belajar')}</span>
              <span class="tag-duration" style="background: rgba(240, 201, 135, 0.15); color: var(--accent-gold); border: 1px solid var(--border-accent);">
                ⏰ Mulai Pukul ${minutesToTime(nextTask.startMinute)} (${Math.max(1, nextTask.startMinute - curMin)} menit lagi)
              </span>
            ` : `
              <span class="tag-duration" style="background: rgba(240, 201, 135, 0.15); color: var(--accent-gold); border: 1px solid var(--border-accent);">
                🎯 Target minimal hanya 10 menit. Stop kapan saja jika ada interupsi kelas!
              </span>
            `}
          </div>

          <div class="current-action-row">
            ${nextTask ? `
              <button class="btn-start-current-focus" data-action="start-current" data-id="${nextTask.id}">
                <span>▶ MULAI LEBIH AWAL: ${escapeHtml(nextTask.what)}</span>
                <span class="golden-hint">🎯 Target 10 Menit</span>
              </button>
              <button class="btn-free-focus-subtle" id="btn-free-focus">
                ⚡ Atau Mulai Fokus Bebas Mandiri
              </button>
            ` : `
              <button class="btn-start-current-focus" id="btn-free-focus">
                <span>⚡ MULAI FOKUS BEBAS SEKARANG</span>
                <span class="golden-hint">🎯 Target 10 Menit</span>
              </button>
            `}
          </div>
        `}
      </div>

      <!-- Quick Task Selection List -->
      <div style="width: 100%; margin-top: 14px;">
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; padding: 0 4px;">
          <span style="font-size: 13px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px;">
            📋 JADWAL LAINNYA HARI INI (${allTasks.length})
          </span>
          <button id="btn-goto-tasks" style="background: transparent; border: none; color: var(--accent-gold); font-size: 13px; font-weight: 800; cursor: pointer;">
            + Kelola Tugas (Tab 1) →
          </button>
        </div>

        <div style="display: flex; flex-direction: column; gap: 12px;">
          ${allTasks.length === 0 ? `
            <div style="padding: 28px; text-align: center; background: var(--bg-surface); border: 2px dashed var(--border-subtle); border-radius: var(--radius-md); color: var(--text-dim); font-size: 14px;">
              Belum ada tugas terjadwal. Tambahkan tugas di menu Tasks.
            </div>
          ` : allTasks.map(t => {
            const isCurrent = currentTask && currentTask.id === t.id;
            return `
              <div class="task-card ${isCurrent ? 'is-current-item' : ''}" style="padding: 16px 20px; grid-template-columns: 1fr auto; align-items: center;">
                <div style="display: flex; flex-direction: column; gap: 6px;">
                  <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-weight: 800; color: var(--text-main); font-size: 16px;">
                      ${escapeHtml(t.what)}
                    </span>
                    ${isCurrent ? '<span style="font-size: 11px; font-weight: 900; background: rgba(16, 185, 129, 0.25); color: #10B981; border: 1px solid rgba(16, 185, 129, 0.4); padding: 2px 8px; border-radius: 99px;">● NOW</span>' : ''}
                  </div>
                  <div style="display: flex; align-items: center; gap: 12px; font-size: 13px; color: var(--text-muted); flex-wrap: wrap;">
                    <span class="tag-location" style="padding: 3px 10px;">📍 ${escapeHtml(t.where || 'Meja')}</span>
                    <span class="tag-time" style="padding: 3px 10px;">⏰ ${minutesToTime(t.startMinute)} – ${minutesToTime(t.endMinute)}</span>
                  </div>
                </div>

                <button class="btn-launch-focus" data-action="quick-start" data-id="${t.id}">
                  ▶ Mulai Fokus
                </button>
              </div>
            `;
          }).join('')}
        </div>
      </div>
    </div>
  `;

  // Bind Events
  container.querySelectorAll('[data-action="start-current"]').forEach(btn => {
    btn.addEventListener('click', () => {
      sound.playTap();
      const task = store.tasks.find(t => t.id === btn.dataset.id);
      if (task) store.startTimer(task);
    });
  });

  container.querySelectorAll('[data-action="quick-start"]').forEach(btn => {
    btn.addEventListener('click', () => {
      sound.playTap();
      const task = store.tasks.find(t => t.id === btn.dataset.id);
      if (task) store.startTimer(task);
    });
  });

  container.querySelector('#btn-free-focus')?.addEventListener('click', () => {
    sound.playTap();
    store.startTimer({ what: 'Fokus Bebas (LKS / Membaca)', where: 'Meja Belajar' });
  });

  container.querySelector('#btn-goto-tasks')?.addEventListener('click', () => {
    sound.playTap();
    store.setTab('tasks');
  });
}

function updateTimerDisplay(container) {
  const session = store.activeSession;
  if (!session) return;

  const totalSeconds = session.durationSeconds;
  const isGoldenGate = totalSeconds >= 600;
  const progressRatio = Math.min(1, totalSeconds / 600);
  const circumference = 2 * Math.PI * 180;
  const strokeOffset = circumference * (1 - progressRatio);

  if (isGoldenGate && !chimeTriggeredForCurrentSession) {
    chimeTriggeredForCurrentSession = true;
    sound.playChime();
  }

  const digits = container.querySelector('#timer-digits-text');
  if (digits) {
    digits.textContent = formatSeconds(totalSeconds);
  }

  const progressRing = container.querySelector('.timer-ring-progress');
  if (progressRing) {
    if (isGoldenGate) {
      progressRing.classList.add('golden-gate');
      progressRing.setAttribute('stroke-dashoffset', '0');
    } else {
      progressRing.classList.remove('golden-gate');
      progressRing.setAttribute('stroke-dashoffset', strokeOffset.toString());
    }
  }

  const statusText = container.querySelector('.timer-milestone-status');
  if (statusText) {
    if (isGoldenGate) {
      statusText.classList.add('achieved');
      statusText.textContent = '✨ 10 MENIT TERCAPAI! (BONUS FOKUS)';
    } else {
      statusText.classList.remove('achieved');
      statusText.textContent = `🎯 Menuju 10 menit pertama (${Math.floor((totalSeconds / 600) * 100)}%)`;
    }
  }

  // Update canvas for PiP if active
  if (pipCanvasCtx) {
    renderPiPCanvas(session.what, totalSeconds, isGoldenGate);
  }
}

function handleStop() {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }

  // Stop session silently so state is updated without wiping the view before modal renders
  const finished = store.stopTimer({ notify: false });
  if (!finished) return;

  // Use persistent modal overlay in document
  const modal = document.getElementById('session-summary-modal');
  if (!modal) return;

  const minutes = Math.floor(finished.durationSeconds / 60);
  const seconds = finished.durationSeconds % 60;

  modal.innerHTML = `
    <div class="session-card">
      <div class="session-card-icon">
        ${finished.achievedMinimum ? '🎉' : '👏'}
      </div>
      <h3 class="session-card-title">
        ${finished.achievedMinimum ? 'Luar Biasa, Target 10 Menit Tercapai!' : 'Sesi Berhasil Disimpan!'}
      </h3>
      <p class="session-card-desc">
        Kamu telah fokus selama <strong>${minutes} menit ${seconds} detik</strong> pada <strong>"${escapeHtml(finished.what)}"</strong> di <strong>${escapeHtml(finished.where)}</strong>.
        <br/><br/>
        ${finished.achievedMinimum 
          ? 'Kamu melampaui batas 10 menit! Rasa puas ini adalah bukti kamu bisa fokus dari rasa cukup dan tenang.' 
          : 'Bagus! Catatan waktu tersimpan jujur tanpa hukuman. Guru datang / interupsi di kelas bukan masalah, bisa lanjut lagi kapan saja!'}
      </p>
      <button class="btn-card-close" id="btn-close-summary" style="margin-top: 20px;">
        Kembali ke Layar Fokus Utama →
      </button>
    </div>
  `;
  modal.classList.add('active');

  modal.querySelector('#btn-close-summary')?.addEventListener('click', () => {
    sound.playTap();
    modal.classList.remove('active');
    modal.innerHTML = '';
    // Now notify subscribers so view updates smoothly to Idle state
    store.notify({ type: 'session_stopped', session: finished });
  });
}

// Picture-in-Picture floating clock canvas
let pipCanvas = null;
let pipCanvasCtx = null;

function togglePictureInPicture(session) {
  if (!document.pictureInPictureEnabled) {
    alert('Browser ini tidak mendukung Picture-in-Picture display-over-display.');
    return;
  }

  if (document.pictureInPictureElement) {
    document.exitPictureInPicture().catch(() => {});
    return;
  }

  if (!pipCanvas) {
    pipCanvas = document.createElement('canvas');
    pipCanvas.width = 440;
    pipCanvas.height = 320;
    pipCanvasCtx = pipCanvas.getContext('2d');
  }

  renderPiPCanvas(session.what, session.durationSeconds, session.durationSeconds >= 600);

  if (!pipVideoElement) {
    pipVideoElement = document.createElement('video');
    pipVideoElement.muted = true;
    pipVideoElement.srcObject = pipCanvas.captureStream(30);
  }

  pipVideoElement.play().then(() => {
    pipVideoElement.requestPictureInPicture().catch(e => {
      console.warn('PiP failed', e);
    });
  });
}

function renderPiPCanvas(taskName, seconds, isGolden) {
  if (!pipCanvasCtx) return;
  const ctx = pipCanvasCtx;
  const w = 440;
  const h = 320;

  // Background
  ctx.fillStyle = '#0F0E14';
  ctx.fillRect(0, 0, w, h);

  // Border
  ctx.strokeStyle = isGolden ? '#10B981' : '#F0C987';
  ctx.lineWidth = 6;
  ctx.strokeRect(3, 3, w - 6, h - 6);

  // Task Name
  ctx.fillStyle = '#A8A195';
  ctx.font = '600 17px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText(taskName.slice(0, 26), w / 2, 64);

  // Big Digits
  ctx.fillStyle = '#F7F3EB';
  ctx.font = '800 76px monospace';
  ctx.fillText(formatSeconds(seconds), w / 2, 175);

  // Status
  ctx.fillStyle = isGolden ? '#10B981' : '#F0C987';
  ctx.font = '700 17px sans-serif';
  ctx.fillText(isGolden ? '✨ 10M TERCAPAI (BONUS)' : '🎯 MENUJU 10 MENIT', w / 2, 250);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}
