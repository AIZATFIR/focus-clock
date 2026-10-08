// Reactive LocalStorage Store for Focus Clock Web
const STORAGE_KEY = 'focus_clock_web_data_v1';
const SESSIONS_KEY = 'focus_clock_web_sessions_v1';

const DEFAULT_TASKS = [
  {
    id: 'task-1',
    what: 'Belajar LKS Matematika',
    where: 'Kelas',
    startMinute: 480, // 08:00
    endMinute: 570,   // 09:30
    completed: false,
    color: '#F0C987'  // warm amber
  },
  {
    id: 'task-2',
    what: 'Deep Work Coding Website',
    where: 'Meja Belajar',
    startMinute: 600, // 10:00
    endMinute: 690,   // 11:30
    completed: false,
    color: '#60A5FA'  // calming blue
  },
  {
    id: 'task-3',
    what: 'Shalat Dzuhur & Istirahat',
    where: 'Masjid',
    startMinute: 720, // 12:00
    endMinute: 780,   // 13:00
    completed: false,
    color: '#34D399'  // emerald green
  }
];

export const COLORS = [
  '#F0C987', // Amber Gold
  '#60A5FA', // Sky Blue
  '#34D399', // Emerald
  '#F472B6', // Rose
  '#A78BFA', // Violet
  '#FBBF24', // Sun
  '#38BDF8'  // Cyan
];

class Store {
  constructor() {
    this.subscribers = [];
    this.tasks = this.loadTasks();
    this.sessions = this.loadSessions();
    this.currentTab = 'timer'; // Primary default mode: Focus Timer!
    this.clockHalf = 'am'; // 'am' (00:00-11:59) | 'pm' (12:00-23:59)
    this.activeSession = null; // { taskId, what, where, startedAt, durationSeconds, isRunning }
  }

  getCurrentAndNextTask() {
    const now = new Date();
    const curMin = now.getHours() * 60 + now.getMinutes();

    // 1. Current active task (happening right now based on schedule)
    const currentTask = this.tasks.find(
      t => !t.completed && t.startMinute <= curMin && curMin < t.endMinute
    );

    // 2. Next upcoming task today
    const upcomingTasks = this.tasks
      .filter(t => !t.completed && t.startMinute > curMin)
      .sort((a, b) => a.startMinute - b.startMinute);

    const nextTask = upcomingTasks.length > 0 ? upcomingTasks[0] : null;

    return { currentTask, nextTask, curMin };
  }

  loadTasks() {
    try {
      const data = localStorage.getItem(STORAGE_KEY);
      if (data) return JSON.parse(data);
    } catch (e) {
      console.warn('Failed to load tasks from localStorage', e);
    }
    return [...DEFAULT_TASKS];
  }

  saveTasks() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.tasks));
    } catch (e) {
      console.warn('Failed to save tasks', e);
    }
  }

  loadSessions() {
    try {
      const data = localStorage.getItem(SESSIONS_KEY);
      if (data) return JSON.parse(data);
    } catch (e) {
      console.warn('Failed to load sessions', e);
    }
    return [];
  }

  saveSessions() {
    try {
      localStorage.setItem(SESSIONS_KEY, JSON.stringify(this.sessions));
    } catch (e) {
      console.warn('Failed to save sessions', e);
    }
  }

  subscribe(callback) {
    this.subscribers.push(callback);
    return () => {
      this.subscribers = this.subscribers.filter(cb => cb !== callback);
    };
  }

  notify() {
    for (const cb of this.subscribers) {
      cb(this);
    }
  }

  setTab(tab) {
    if (this.currentTab === tab) return;
    this.currentTab = tab;
    this.notify();
  }

  setClockHalf(half) {
    this.clockHalf = half;
    this.notify();
  }

  // Task actions
  addTask({ what, where, startMinute = 480, endMinute = 540, color }) {
    const newTask = {
      id: 'task-' + Date.now(),
      what: (what || 'Tugas Baru').trim(),
      where: (where || 'Meja Belajar').trim(),
      startMinute: Math.min(startMinute, endMinute),
      endMinute: Math.max(startMinute, endMinute),
      completed: false,
      color: color || COLORS[this.tasks.length % COLORS.length]
    };
    this.tasks.push(newTask);
    this.saveTasks();
    this.notify();
    return newTask;
  }

  updateTask(id, patch) {
    const index = this.tasks.findIndex(t => t.id === id);
    if (index !== -1) {
      this.tasks[index] = { ...this.tasks[index], ...patch };
      this.saveTasks();
      this.notify();
    }
  }

  deleteTask(id) {
    this.tasks = this.tasks.filter(t => t.id !== id);
    this.saveTasks();
    this.notify();
  }

  toggleTask(id) {
    const task = this.tasks.find(t => t.id === id);
    if (task) {
      task.completed = !task.completed;
      this.saveTasks();
      this.notify();
    }
  }

  // Timer Session actions
  startTimer(task) {
    this.activeSession = {
      taskId: task ? task.id : null,
      what: task ? task.what : 'Fokus Bebas',
      where: task ? task.where : 'Sekitar',
      startedAt: Date.now(),
      durationSeconds: 0,
      isRunning: true
    };
    this.currentTab = 'timer';
    this.notify();
  }

  tickTimer() {
    if (this.activeSession && this.activeSession.isRunning) {
      this.activeSession.durationSeconds++;
      this.notify();
    }
  }

  stopTimer() {
    if (!this.activeSession) return null;
    const finished = {
      id: 'sess-' + Date.now(),
      taskId: this.activeSession.taskId,
      what: this.activeSession.what,
      where: this.activeSession.where,
      startedAt: this.activeSession.startedAt,
      durationSeconds: this.activeSession.durationSeconds,
      endedAt: Date.now(),
      achievedMinimum: this.activeSession.durationSeconds >= 600 // 10 minutes
    };
    this.sessions.unshift(finished);
    this.saveSessions();
    this.activeSession = null;
    this.notify();
    return finished;
  }
}

export const store = new Store();

// Time formatting utilities
export function minutesToTime(totalMinutes) {
  const m = Math.floor(totalMinutes) % 1440;
  const hours = Math.floor(m / 60).toString().padStart(2, '0');
  const mins = Math.floor(m % 60).toString().padStart(2, '0');
  return `${hours}:${mins}`;
}

export function timeToMinutes(timeStr) {
  if (!timeStr) return 0;
  const parts = timeStr.trim().split(':');
  if (parts.length < 2) return 0;
  return (parseInt(parts[0], 10) || 0) * 60 + (parseInt(parts[1], 10) || 0);
}

export function formatDurationMinutes(durationMinutes) {
  const h = Math.floor(durationMinutes / 60);
  const m = Math.floor(durationMinutes % 60);
  if (h > 0 && m > 0) return `${h}j ${m}m`;
  if (h > 0) return `${h} jam`;
  return `${m} menit`;
}

export function formatSeconds(totalSeconds) {
  const mins = Math.floor(totalSeconds / 60);
  const secs = Math.floor(totalSeconds % 60);
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}
