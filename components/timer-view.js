import { store, formatSeconds } from '../store.js';
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

      <div style="font-size: 13px; color: var(--text-dim); text-align: center; max-width: 480px; margin-top: -12px;">
        💡 <em>Fokus dari abundance, bukan scarcity. Stop kapan saja jika ada interupsi, durasi tersimpan jujur tanpa hukuman.</em>
      </div>
    </div>

    <!-- Celebration Modal (Hidden initially) -->
    <div id="session-summary-modal" class="session-modal-overlay"></div>
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
    handleStop(container);
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

  const tasks = store.tasks.filter(t => !t.completed);

  container.innerHTML = `
    <div class="timer-view-container" style="text-align: center; max-width: 600px; margin: 0 auto;">
      <div style="font-size: 56px; margin-bottom: 8px;">⏳</div>
      <h2 style="font-size: 26px; font-weight: 800; margin-bottom: 8px; color: var(--text-main);">
        Pilih Tugas untuk Memulai Sesi
      </h2>
      <p style="color: var(--text-muted); font-size: 15px; max-width: 480px; line-height: 1.5; margin: 0 auto 28px;">
        Cukup mulai <strong>minimal 10 menit</strong>. Jika guru masuk kelas atau ada urusan lain, tekan <strong>Space</strong> untuk stop instan.
      </p>

      <div style="display: flex; flex-direction: column; gap: 12px; width: 100%;">
        ${tasks.length === 0 ? `
          <div style="padding: 24px; background: var(--bg-surface); border: 1px solid var(--border-subtle); border-radius: var(--radius-md); color: var(--text-muted); font-size: 14px;">
            Semua tugas sudah selesai atau belum ada jadwal.
          </div>
        ` : tasks.map(t => `
          <div class="task-card" style="padding: 16px 20px; text-align: left; grid-template-columns: 1fr auto auto;">
            <div style="display: flex; flex-direction: column; gap: 4px;">
              <span style="font-weight: 800; color: var(--text-main); font-size: 17px;">
                ${escapeHtml(t.what)}
              </span>
              <span style="font-size: 13px; color: var(--text-muted);">
                📍 ${escapeHtml(t.where || 'Meja')}
              </span>
            </div>
            <span style="font-size: 13px; font-family: var(--font-mono); color: var(--accent-gold); font-weight: 700;">
              ${Math.max(10, t.endMinute - t.startMinute)} Menit
            </span>
            <button class="btn-launch-focus" data-action="quick-start" data-id="${t.id}" style="padding: 8px 18px;">
              ▶ Mulai
            </button>
          </div>
        `).join('')}

        <button id="btn-free-focus" class="btn-add-submit" style="justify-content: center; margin-top: 16px; padding: 16px; font-size: 16px;">
          ⚡ Mulai Fokus Bebas (Target 10 Menit)
        </button>
      </div>
    </div>
  `;

  container.querySelectorAll('[data-action="quick-start"]').forEach(btn => {
    btn.addEventListener('click', () => {
      sound.playTap();
      const task = store.tasks.find(t => t.id === btn.dataset.id);
      if (task) store.startTimer(task);
    });
  });

  container.querySelector('#btn-free-focus')?.addEventListener('click', () => {
    sound.playTap();
    store.startTimer({ what: 'Fokus Mandiri (LKS / Membaca)', where: 'Kelas / Meja Belajar' });
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

function handleStop(container) {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }

  const finished = store.stopTimer();
  if (!finished) return;

  // Show Celebration Card
  const modal = container.querySelector('#session-summary-modal') || document.body;
  const minutes = Math.floor(finished.durationSeconds / 60);
  const seconds = finished.durationSeconds % 60;

  modal.innerHTML = `
    <div class="session-card">
      <div class="session-card-icon">
        ${finished.achievedMinimum ? '🎉' : '👏'}
      </div>
      <h3 class="session-card-title">
        ${finished.achievedMinimum ? 'Luar Biasa, Target Tercapai!' : 'Sesi Berhasil Disimpan!'}
      </h3>
      <p class="session-card-desc">
        Kamu telah fokus selama <strong>${minutes} menit ${seconds} detik</strong> pada <strong>"${escapeHtml(finished.what)}"</strong> di <strong>${escapeHtml(finished.where)}</strong>.
        <br/><br/>
        ${finished.achievedMinimum 
          ? 'Kamu melampaui batas 10 menit! Rasa puas ini adalah bukti kamu bisa fokus kapan saja.' 
          : 'Bagus! Catatan waktu tersimpan jujur tanpa beban. Bisa lanjut lagi kapan saja saat suasana tenang.'}
      </p>
      <button class="btn-card-close" id="btn-close-summary" style="margin-top: 20px;">
        Kembali ke Daftar Tugas
      </button>
    </div>
  `;
  modal.classList.add('active');

  modal.querySelector('#btn-close-summary')?.addEventListener('click', () => {
    sound.playTap();
    modal.classList.remove('active');
    store.setTab('tasks');
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
