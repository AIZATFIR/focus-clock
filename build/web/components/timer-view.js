import { store, formatSeconds, minutesToTime } from '../store.js';
import { sound } from '../sound.js';

let timerInterval = null;
let pipVideoElement = null;
let pipCanvas = null;
let pipCanvasCtx = null;
let chimeTriggered = false;

export function renderTimerView(container) {
  const session = store.activeSession;

  if (!session) {
    chimeTriggered = false;
    renderIdleLauncher(container);
    return;
  }

  // --- ACTIVE RUNNING TIMER ---
  const totalSeconds = session.durationSeconds;
  const isGoldenGate = totalSeconds >= 600;
  const progressRatio = Math.min(1, totalSeconds / 600);
  const circumference = 2 * Math.PI * 180;
  const strokeOffset = circumference * (1 - progressRatio);

  const { nextTask } = store.getCurrentAndNextTask();

  container.innerHTML = `
    <div class="timer-view-container">
      <!-- Target Task Pill -->
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
            id="timer-ring-progress-el"
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
          <div class="timer-milestone-status ${isGoldenGate ? 'achieved' : ''}" id="timer-milestone-status-el">
            ${isGoldenGate 
              ? '✨ 10 MENIT TERCAPAI! (BONUS FOKUS)' 
              : `🎯 Menuju 10 menit pertama (${Math.floor((totalSeconds / 600) * 100)}%)`}
          </div>
        </div>
      </div>

      <!-- Emergency Stop & PiP Controls -->
      <div class="timer-controls">
        <button class="btn-emergency-stop" id="btn-emergency-stop" title="Stop & Simpan Sesi (Spacebar)">
          <span>⏹️</span>
          <span>STOP / GURU DATANG</span>
          <span style="font-size: 11px; opacity: 0.8; background: rgba(0,0,0,0.3); padding: 3px 8px; border-radius: 6px; font-family: var(--font-mono);">SPACE</span>
        </button>

        <button class="btn-pip" id="btn-pip-toggle" title="Floating PiP over other apps">
          <span>🪟</span>
          <span>Floating PiP</span>
        </button>

        <button class="btn-fullscreen" id="btn-fullscreen-toggle" title="Layar Penuh">
          <span>⛶</span>
          <span>Fullscreen</span>
        </button>
      </div>

      ${nextTask ? `
        <div style="font-size: 13px; color: var(--text-muted); background: var(--bg-surface); padding: 8px 18px; border-radius: var(--radius-full); border: 1px solid var(--border-subtle); display: inline-flex; align-items: center; gap: 8px;">
          <span>⏳ Jadwal Berikutnya:</span>
          <strong style="color: var(--text-main);">${escapeHtml(nextTask.what)}</strong>
          <span style="color: var(--accent-gold); font-family: var(--font-mono); font-size: 12px;">(${minutesToTime(nextTask.startMinute)})</span>
        </div>
      ` : `
        <div style="font-size: 13px; color: var(--text-dim); text-align: center; max-width: 480px;">
          💡 <em>Fokus dari abundance, bukan scarcity. Stop kapan saja jika ada interupsi kelas.</em>
        </div>
      `}
    </div>
  `;

  // Start lightweight 1s interval (updates digits & ring directly)
  if (timerInterval) clearInterval(timerInterval);
  timerInterval = setInterval(() => {
    store.tickTimer();
    const curSec = store.activeSession ? store.activeSession.durationSeconds : 0;
    const reachedGolden = curSec >= 600;

    if (reachedGolden && !chimeTriggered) {
      chimeTriggered = true;
      sound.playChime();
    }

    const digits = container.querySelector('#timer-digits-text');
    if (digits) digits.textContent = formatSeconds(curSec);

    const ringEl = container.querySelector('#timer-ring-progress-el');
    if (ringEl) {
      if (reachedGolden) {
        ringEl.classList.add('golden-gate');
        ringEl.setAttribute('stroke-dashoffset', '0');
      } else {
        ringEl.classList.remove('golden-gate');
        const offset = circumference * (1 - Math.min(1, curSec / 600));
        ringEl.setAttribute('stroke-dashoffset', offset.toString());
      }
    }

    const milestoneEl = container.querySelector('#timer-milestone-status-el');
    if (milestoneEl) {
      if (reachedGolden) {
        milestoneEl.classList.add('achieved');
        milestoneEl.textContent = '✨ 10 MENIT TERCAPAI! (BONUS FOKUS)';
      } else {
        milestoneEl.classList.remove('achieved');
        milestoneEl.textContent = `🎯 Menuju 10 menit pertama (${Math.floor((curSec / 600) * 100)}%)`;
      }
    }

    if (pipCanvasCtx && store.activeSession) {
      renderPiPCanvas(store.activeSession.what, curSec, reachedGolden);
    }
  }, 1000);

  // Attach controls
  container.querySelector('#btn-emergency-stop')?.addEventListener('click', () => {
    sound.playTap();
    handleStop(container);
  });

  container.querySelector('#btn-pip-toggle')?.addEventListener('click', () => {
    sound.playTap();
    togglePictureInPicture(session);
  });

  container.querySelector('#btn-fullscreen-toggle')?.addEventListener('click', () => {
    sound.playTap();
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
    } else {
      document.exitFullscreen().catch(() => {});
    }
  });
}

// --- IDLE / ADD-ON LAUNCHER ---
function renderIdleLauncher(container) {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }

  const { currentTask, nextTask, curMin } = store.getCurrentAndNextTask();
  const allTasks = store.tasks.filter(t => !t.completed);

  container.innerHTML = `
    <div class="timer-view-container" style="max-width: 680px; margin: 0 auto; width: 100%;">
      
      <!-- Current Scheduled Focus or Ready Hero Card -->
      <div class="current-focus-hero-card">
        ${currentTask ? `
          <div class="current-badge-row">
            <span class="live-pulse-dot"></span>
            <span class="current-badge-text">● SEDANG BERLANGSUNG SEKARANG</span>
            <span class="current-time-pill">⏰ ${minutesToTime(currentTask.startMinute)} – ${minutesToTime(currentTask.endMinute)}</span>
          </div>

          <div class="current-hero-title">
            ${escapeHtml(currentTask.what)}
          </div>

          <div class="current-meta-row">
            <span class="tag-location">📍 ${escapeHtml(currentTask.where || 'Meja Belajar')}</span>
            <span class="tag-duration" style="background: rgba(16, 185, 129, 0.15); color: #10B981; border: 1px solid rgba(16, 185, 129, 0.3);">
              ⏳ Sisa Waktu: <strong>${Math.max(1, currentTask.endMinute - curMin)} Menit</strong>
            </span>
          </div>

          <div class="current-action-row">
            <button class="btn-start-current-focus" id="btn-start-current">
              <span>▶ MULAI FOKUS SEKARANG</span>
              <span class="golden-hint">🎯 Target 10 Menit</span>
            </button>
          </div>
        ` : nextTask ? `
          <div class="current-badge-row">
            <span class="free-pulse-dot"></span>
            <span class="current-badge-text">⚡ JADWAL BERIKUTNYA</span>
            <span class="current-time-pill">Mulai ${minutesToTime(nextTask.startMinute)} (${Math.max(1, nextTask.startMinute - curMin)}m lagi)</span>
          </div>

          <div class="current-hero-title">
            Siap Untuk "${escapeHtml(nextTask.what)}"?
          </div>

          <div class="current-meta-row">
            <span class="tag-location">📍 ${escapeHtml(nextTask.where || 'Meja Belajar')}</span>
            <span class="tag-duration" style="background: rgba(240, 201, 135, 0.15); color: var(--accent-gold); border: 1px solid var(--border-accent);">
              🎯 Target minimal 10 menit
            </span>
          </div>

          <div class="current-action-row">
            <button class="btn-start-current-focus" id="btn-start-next">
              <span>▶ MULAI LEBIH AWAL</span>
              <span class="golden-hint">🎯 Target 10 Menit</span>
            </button>
            <button class="btn-free-focus-subtle" id="btn-free-focus">
              ⚡ Fokus Mandiri Lainnya
            </button>
          </div>
        ` : `
          <div class="current-badge-row">
            <span class="free-pulse-dot"></span>
            <span class="current-badge-text">⚡ WAKTU BEBAS</span>
            <span class="current-time-pill">Jam ${minutesToTime(curMin)}</span>
          </div>

          <div class="current-hero-title">
            Fokus Mandiri Tenang
          </div>

          <p style="color: var(--text-muted); font-size: 14px; margin: 0; line-height: 1.5;">
            Cukup mulai <strong>minimal 10 menit</strong>. Stop kapan saja jika ada interupsi kelas dengan tombol Space.
          </p>

          <div class="current-action-row">
            <button class="btn-start-current-focus" id="btn-free-focus">
              <span>⚡ MULAI FOKUS BEBAS</span>
              <span class="golden-hint">🎯 Target 10 Menit</span>
            </button>
          </div>
        `}
      </div>

      <!-- Quick List of Other Tasks Today -->
      <div style="width: 100%; margin-top: 14px;">
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; padding: 0 4px;">
          <span style="font-size: 13px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px;">
            📋 JADWAL HARI INI (${allTasks.length})
          </span>
          <button id="btn-goto-tasks" style="background: transparent; border: none; color: var(--accent-gold); font-size: 13px; font-weight: 800; cursor: pointer;">
            + Kelola Tugas (Tab 1) →
          </button>
        </div>

        <div style="display: flex; flex-direction: column; gap: 10px;">
          ${allTasks.length === 0 ? `
            <div style="padding: 24px; text-align: center; background: var(--bg-surface); border: 2px dashed var(--border-subtle); border-radius: var(--radius-md); color: var(--text-dim); font-size: 14px;">
              Belum ada tugas terjadwal. Tambahkan tugas di menu Tasks.
            </div>
          ` : allTasks.map(t => {
            const isCurrent = currentTask && currentTask.id === t.id;
            return `
              <div class="task-card ${isCurrent ? 'is-current-item' : ''}" style="padding: 14px 18px; grid-template-columns: 1fr auto; align-items: center;">
                <div style="display: flex; flex-direction: column; gap: 4px;">
                  <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-weight: 800; color: var(--text-main); font-size: 16px;">
                      ${escapeHtml(t.what)}
                    </span>
                    ${isCurrent ? '<span style="font-size: 11px; font-weight: 800; background: rgba(16, 185, 129, 0.2); color: #10B981; padding: 2px 8px; border-radius: 99px;">● NOW</span>' : ''}
                  </div>
                  <div style="display: flex; align-items: center; gap: 10px; font-size: 13px; color: var(--text-muted);">
                    <span class="tag-location" style="padding: 2px 8px;">📍 ${escapeHtml(t.where || 'Meja')}</span>
                    <span class="tag-time" style="padding: 2px 8px;">⏰ ${minutesToTime(t.startMinute)} – ${minutesToTime(t.endMinute)}</span>
                  </div>
                </div>

                <button class="btn-launch-focus" data-action="quick-start" data-id="${t.id}">
                  ▶ Mulai
                </button>
              </div>
            `;
          }).join('')}
        </div>
      </div>
    </div>
  `;

  // Attach idle events
  container.querySelector('#btn-start-current')?.addEventListener('click', () => {
    sound.playTap();
    if (currentTask) store.startTimer(currentTask);
  });

  container.querySelector('#btn-start-next')?.addEventListener('click', () => {
    sound.playTap();
    if (nextTask) store.startTimer(nextTask);
  });

  container.querySelectorAll('#btn-free-focus').forEach(btn => {
    btn.addEventListener('click', () => {
      sound.playTap();
      store.startTimer({ what: 'Fokus Mandiri (LKS / Membaca)', where: 'Meja Belajar' });
    });
  });

  container.querySelectorAll('[data-action="quick-start"]').forEach(btn => {
    btn.addEventListener('click', () => {
      sound.playTap();
      const task = store.tasks.find(t => t.id === btn.dataset.id);
      if (task) store.startTimer(task);
    });
  });

  container.querySelector('#btn-goto-tasks')?.addEventListener('click', () => {
    sound.playTap();
    store.setTab('tasks');
  });
}

function handleStop(container) {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }

  const finished = store.stopTimer();
  if (!finished) return;

  const modal = document.getElementById('session-summary-modal');
  if (!modal) {
    renderTimerView(container);
    return;
  }

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
          : 'Bagus! Catatan waktu tersimpan jujur tanpa hukuman. Guru datang atau interupsi kelas bukan masalah, bisa lanjut lagi kapan saja!'}
      </p>
      <button class="btn-card-close" id="btn-close-summary" style="margin-top: 20px;">
        Kembali ke Layar Fokus →
      </button>
    </div>
  `;
  modal.classList.add('active');

  modal.querySelector('#btn-close-summary')?.addEventListener('click', () => {
    sound.playTap();
    modal.classList.remove('active');
    modal.innerHTML = '';
    renderTimerView(container);
  });
}

// Picture-in-Picture floating clock canvas
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
