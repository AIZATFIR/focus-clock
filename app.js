import { store } from './store.js';
import { renderTasksView } from './components/tasks-view.js';
import { renderClockFace } from './components/clock-face.js';
import { renderTimerView } from './components/timer-view.js';

// DOM Elements
const viewTasks = document.getElementById('view-tasks');
const viewClock = document.getElementById('view-clock');
const viewTimer = document.getElementById('view-timer');

const tabBtns = {
  tasks: document.getElementById('tab-btn-tasks'),
  clock: document.getElementById('tab-btn-clock'),
  timer: document.getElementById('tab-btn-timer')
};

// WakeLock to prevent screen sleep during study
let wakeLock = null;
async function requestWakeLock() {
  if ('wakeLock' in navigator) {
    try {
      wakeLock = await navigator.wakeLock.request('screen');
    } catch (e) {
      // Ignored
    }
  }
}

function releaseWakeLock() {
  if (wakeLock) {
    wakeLock.release().catch(() => {});
    wakeLock = null;
  }
}

// Router & View Renderer
function updateViews() {
  const current = store.currentTab;

  // Toggle Tab Navigation Active Classes
  Object.keys(tabBtns).forEach(tab => {
    if (tabBtns[tab]) {
      tabBtns[tab].classList.toggle('active', tab === current);
    }
  });

  // Toggle Panel Visibility
  viewTasks.classList.toggle('active', current === 'tasks');
  viewClock.classList.toggle('active', current === 'clock');
  viewTimer.classList.toggle('active', current === 'timer');

  // Render the currently active view
  if (current === 'tasks') {
    renderTasksView(viewTasks);
    releaseWakeLock();
  } else if (current === 'clock') {
    renderClockFace(viewClock);
    releaseWakeLock();
  } else if (current === 'timer') {
    renderTimerView(viewTimer);
    if (store.activeSession?.isRunning) {
      requestWakeLock();
    }
  }
}

// Global Keyboard Shortcuts
function setupKeyboardShortcuts() {
  window.addEventListener('keydown', (e) => {
    // If user is typing in an input or contenteditable, don't trigger global shortcuts
    if (e.target.matches('input, textarea, [contenteditable="true"]')) {
      return;
    }

    if (e.key === '1') {
      store.setTab('tasks');
    } else if (e.key === '2') {
      store.setTab('clock');
    } else if (e.key === '3') {
      store.setTab('timer');
    } else if (e.code === 'Space') {
      // Spacebar instant stop if timer is running
      if (store.activeSession && store.activeSession.isRunning) {
        e.preventDefault();
        const stopBtn = document.getElementById('btn-emergency-stop');
        if (stopBtn) stopBtn.click();
      }
    }
  });
}

// Initial Setup
export function initApp() {
  // Bind Tab Click Handlers
  tabBtns.tasks.addEventListener('click', () => store.setTab('tasks'));
  tabBtns.clock.addEventListener('click', () => store.setTab('clock'));
  tabBtns.timer.addEventListener('click', () => store.setTab('timer'));

  // Subscribe Store Changes
  store.subscribe(() => {
    updateViews();
  });

  setupKeyboardShortcuts();

  // Initial Render
  updateViews();
}

// Run on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initApp);
} else {
  initApp();
}
