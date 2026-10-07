import { store, minutesToTime, timeToMinutes, formatDurationMinutes } from '../store.js';
import { sound } from '../sound.js';

export function renderTasksView(container) {
  const tasks = store.tasks;
  const completedCount = tasks.filter(t => t.completed).length;

  container.innerHTML = `
    <div class="tasks-container">
      <!-- Human & Generous Quick-Add Card -->
      <form id="task-add-form" class="task-add-card">
        <div style="display: flex; flex-direction: column; gap: 4px;">
          <label for="input-what" style="font-size: 13px; font-weight: 700; color: var(--accent-gold); letter-spacing: 0.5px; text-transform: uppercase;">
            1. APA TUGASNYA?
          </label>
          <input 
            type="text" 
            id="input-what" 
            class="add-input-main" 
            placeholder="Tulis apa yang mau kamu pelajari / kerjakan..." 
            required 
            autocomplete="off"
            autofocus
          />
        </div>

        <div class="add-row-details">
          <div class="add-details-left">
            <!-- Dimana -->
            <div class="detail-pill-input">
              <span style="font-size: 16px;">📍</span>
              <div style="display: flex; flex-direction: column;">
                <span style="font-size: 10px; font-weight: 700; color: var(--text-dim); text-transform: uppercase;">DIMANA</span>
                <input 
                  type="text" 
                  id="input-where" 
                  placeholder="cth: Kelas, Kamar" 
                  defaultValue="Meja Belajar"
                  value="Meja Belajar"
                  autocomplete="off"
                />
              </div>
            </div>

            <!-- Kapan -->
            <div class="detail-pill-input">
              <span style="font-size: 16px;">⏰</span>
              <div style="display: flex; flex-direction: column;">
                <span style="font-size: 10px; font-weight: 700; color: var(--text-dim); text-transform: uppercase;">KAPAN</span>
                <input 
                  type="text" 
                  id="input-when" 
                  placeholder="cth: 08:00 - 09:30" 
                  autocomplete="off"
                />
              </div>
            </div>
          </div>

          <button type="submit" class="btn-add-submit">
            <span>+ Jadwalkan Tugas</span>
            <span style="opacity: 0.7; font-size: 12px; font-family: var(--font-mono); background: rgba(0,0,0,0.2); padding: 2px 6px; border-radius: 4px;">↵ ENTER</span>
          </button>
        </div>
      </form>

      <!-- Section Title & Counter -->
      <div class="tasks-section-header">
        <div class="tasks-count-badge">
          📋 DAFTAR TUGAS HARI INI (${tasks.length} Jadwal • ${completedCount} Selesai)
        </div>
        <div style="font-size: 12px; color: var(--text-dim);">
          Klik tugas untuk langsung fokus atau atur di jam analog
        </div>
      </div>

      <!-- Task Items List (Gede-Gede & Manusiawi) -->
      <div class="task-list" id="tasks-list-items">
        ${tasks.length === 0 ? `
          <div style="text-align: center; padding: 60px 20px; background: var(--bg-surface); border: 2px dashed var(--border-subtle); border-radius: var(--radius-lg);">
            <div style="font-size: 48px; margin-bottom: 12px;">🌱</div>
            <h3 style="font-size: 20px; font-weight: 800; color: var(--text-main); margin-bottom: 6px;">Belum Ada Jadwal</h3>
            <p style="color: var(--text-muted); font-size: 14px; max-width: 380px; margin: 0 auto;">
              Tulis tugas pertama di atas. Santai saja, jadwalkan satu per satu dengan tenang.
            </p>
          </div>
        ` : tasks.map(task => {
          const durationMin = task.endMinute - task.startMinute;
          return `
            <div class="task-card ${task.completed ? 'completed' : ''}" data-id="${task.id}">
              <!-- Stamp Checkbox -->
              <button 
                class="task-checkbox-stamp ${task.completed ? 'checked' : ''}" 
                data-action="toggle" 
                title="Tandai selesai"
              >
                ${task.completed ? '✓' : ''}
              </button>

              <!-- Main Info Block (APA, DIMANA, KAPAN) -->
              <div class="task-info-block">
                <div class="task-title" contenteditable="true" data-action="edit-what" title="Klik untuk edit nama tugas">
                  ${escapeHtml(task.what)}
                </div>

                <div class="task-meta-tags">
                  <span class="tag-location" contenteditable="true" data-action="edit-where" title="Klik untuk edit tempat">
                    📍 ${escapeHtml(task.where || 'Meja Belajar')}
                  </span>

                  <span class="tag-time">
                    ⏰ ${minutesToTime(task.startMinute)} – ${minutesToTime(task.endMinute)}
                  </span>

                  <span class="tag-duration">
                    (${formatDurationMinutes(durationMin)})
                  </span>
                </div>
              </div>

              <!-- Launch Focus Button (Super Prominent) -->
              <button class="btn-launch-focus" data-action="start-focus" title="Mulai Timer Fokus Sekarang">
                <span>⏱️ Mulai Fokus</span>
              </button>

              <!-- Delete Button -->
              <button class="btn-task-delete" data-action="delete" title="Hapus Tugas">
                ✕
              </button>
            </div>
          `;
        }).join('')}
      </div>
    </div>
  `;

  // Bind Form Submit
  const form = container.querySelector('#task-add-form');
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    sound.playTap();

    const whatInput = container.querySelector('#input-what');
    const whereInput = container.querySelector('#input-where');
    const whenInput = container.querySelector('#input-when');

    const what = whatInput.value.trim();
    const where = whereInput.value.trim() || 'Meja Belajar';
    const whenStr = whenInput.value.trim();

    let startMinute = 480; // default 08:00
    let endMinute = 540;   // default 09:00

    if (whenStr) {
      const match = whenStr.match(/(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})/);
      if (match) {
        startMinute = timeToMinutes(match[1]);
        endMinute = timeToMinutes(match[2]);
      } else {
        const singleMatch = whenStr.match(/(\d{1,2}:\d{2})/);
        if (singleMatch) {
          startMinute = timeToMinutes(singleMatch[1]);
          endMinute = startMinute + 60;
        }
      }
    } else {
      // Auto-assign after last task
      if (tasks.length > 0) {
        const last = tasks[tasks.length - 1];
        startMinute = last.endMinute;
        endMinute = startMinute + 60;
      }
    }

    // Ensure valid duration
    if (endMinute <= startMinute) {
      endMinute = startMinute + 45;
    }

    store.addTask({ what, where, startMinute, endMinute });
    whatInput.value = '';
    whenInput.value = '';
    whatInput.focus();
  });

  // Bind Delegated Task Actions
  const listItems = container.querySelector('#tasks-list-items');
  listItems.addEventListener('click', (e) => {
    const target = e.target.closest('[data-action]');
    if (!target) return;

    const card = target.closest('.task-card');
    const id = card?.dataset.id;
    if (!id) return;

    const action = target.dataset.action;
    if (action === 'toggle') {
      sound.playTap();
      store.toggleTask(id);
    } else if (action === 'delete') {
      sound.playTap();
      store.deleteTask(id);
    } else if (action === 'start-focus') {
      const task = store.tasks.find(t => t.id === id);
      if (task) {
        store.startTimer(task);
      }
    }
  });

  // Inline Edits blur
  listItems.addEventListener('blur', (e) => {
    const target = e.target;
    const card = target.closest('.task-card');
    const id = card?.dataset.id;
    if (!id) return;

    if (target.dataset.action === 'edit-what') {
      store.updateTask(id, { what: target.innerText.trim() });
    } else if (target.dataset.action === 'edit-where') {
      const cleanWhere = target.innerText.replace('📍', '').trim();
      store.updateTask(id, { where: cleanWhere });
    }
  }, true);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}
