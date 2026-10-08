import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

// Mock localStorage in Node
const mockStorage = {};
global.localStorage = {
  getItem: (key) => mockStorage[key] || null,
  setItem: (key, val) => { mockStorage[key] = String(val); },
  removeItem: (key) => { delete mockStorage[key]; },
  clear: () => { for (let k in mockStorage) delete mockStorage[k]; }
};

// Import Store class and utilities
import { Store, minutesToTime, timeToMinutes, formatSeconds } from '../store.js';

describe('Focus Clock Store TDD Suite', () => {
  let store;

  beforeEach(() => {
    global.localStorage.clear();
    store = new Store();
  });

  it('initializes with timer as Primary tab by default', () => {
    assert.equal(store.currentTab, 'timer');
  });

  it('correctly converts minutes to time string and vice versa', () => {
    assert.equal(minutesToTime(480), '08:00');
    assert.equal(minutesToTime(570), '09:30');
    assert.equal(minutesToTime(750), '12:30');
    assert.equal(timeToMinutes('08:00'), 480);
    assert.equal(timeToMinutes('09:30'), 570);
    assert.equal(timeToMinutes('12:30'), 750);
  });

  it('formats seconds into MM:SS format', () => {
    assert.equal(formatSeconds(0), '00:00');
    assert.equal(formatSeconds(65), '01:05');
    assert.equal(formatSeconds(600), '10:00');
    assert.equal(formatSeconds(725), '12:05');
  });

  it('detects current scheduled task and next task accurately', () => {
    store.tasks = [
      { id: 't1', what: 'Belajar Pagi', where: 'Kelas', startMinute: 480, endMinute: 540, completed: false }, // 08:00 - 09:00
      { id: 't2', what: 'Istirahat', where: 'Kantin', startMinute: 540, endMinute: 600, completed: false },     // 09:00 - 10:00
      { id: 't3', what: 'Belajar Siang', where: 'Kelas', startMinute: 600, endMinute: 720, completed: false }   // 10:00 - 12:00
    ];

    // Case 1: At 08:30 (510 min) -> current: t1, next: t2
    const res1 = store.getCurrentAndNextTask(510);
    assert.equal(res1.currentTask?.id, 't1');
    assert.equal(res1.nextTask?.id, 't2');

    // Case 2: At 09:15 (555 min) -> current: t2, next: t3
    const res2 = store.getCurrentAndNextTask(555);
    assert.equal(res2.currentTask?.id, 't2');
    assert.equal(res2.nextTask?.id, 't3');

    // Case 3: At 07:30 (450 min - before first task) -> current: null, next: t1
    const res3 = store.getCurrentAndNextTask(450);
    assert.equal(res3.currentTask, null);
    assert.equal(res3.nextTask?.id, 't1');

    // Case 4: At 13:00 (780 min - after all tasks) -> current: null, next: null
    const res4 = store.getCurrentAndNextTask(780);
    assert.equal(res4.currentTask, null);
    assert.equal(res4.nextTask, null);
  });

  it('ignores completed tasks in getCurrentAndNextTask', () => {
    store.tasks = [
      { id: 't1', what: 'Belajar Pagi', where: 'Kelas', startMinute: 480, endMinute: 540, completed: true },
      { id: 't2', what: 'Istirahat', where: 'Kantin', startMinute: 540, endMinute: 600, completed: false }
    ];

    const res = store.getCurrentAndNextTask(500); // 08:20
    assert.equal(res.currentTask, null);
    assert.equal(res.nextTask?.id, 't2');
  });

  it('separates tick notifications from full structural notifications', () => {
    let fullNotifyCount = 0;
    let tickNotifyCount = 0;

    store.subscribe((event) => {
      if (event?.type === 'tick') {
        tickNotifyCount++;
      } else {
        fullNotifyCount++;
      }
    });

    // Starting a timer should trigger a full structural event
    store.startTimer({ id: 't1', what: 'Task 1', where: 'Meja' });
    assert.equal(fullNotifyCount, 1);
    assert.equal(tickNotifyCount, 0);

    // Ticking the timer should trigger a tick event, NOT a full structural rebuild
    store.tickTimer();
    store.tickTimer();
    assert.equal(tickNotifyCount, 2);
    assert.equal(fullNotifyCount, 1); // Remains 1, so UI does NOT get destroyed!

    // Stopping the timer should trigger a full structural event
    store.stopTimer();
    assert.equal(fullNotifyCount, 2);
  });

  it('correctly records 10-minute golden gate milestone on session stop', () => {
    store.startTimer({ id: 't1', what: 'Coding LKS', where: 'Lab' });

    // Simulate 9 minutes (540s) -> should NOT achieve milestone yet
    store.activeSession.durationSeconds = 540;
    const session1 = store.stopTimer();
    assert.equal(session1.achievedMinimum, false);
    assert.equal(session1.durationSeconds, 540);

    // Simulate 10 minutes (600s) -> SHOULD achieve milestone
    store.startTimer({ id: 't2', what: 'Coding LKS Part 2', where: 'Lab' });
    store.activeSession.durationSeconds = 600;
    const session2 = store.stopTimer();
    assert.equal(session2.achievedMinimum, true);
    assert.equal(session2.durationSeconds, 600);
  });

  it('allows silent updates without triggering listeners during clock drag', () => {
    store.tasks = [
      { id: 't1', what: 'Drag Me', where: 'Room', startMinute: 480, endMinute: 540, completed: false }
    ];

    let notifyCount = 0;
    store.subscribe(() => {
      notifyCount++;
    });

    // Silent update (e.g. pointermove)
    store.updateTask('t1', { startMinute: 500, endMinute: 560 }, false);
    assert.equal(notifyCount, 0, 'Silent update must not notify');
    assert.equal(store.tasks[0].startMinute, 500);
    assert.equal(store.tasks[0].endMinute, 560);

    // Explicit notify update (e.g. pointerup / finishDrag)
    store.updateTask('t1', { startMinute: 510, endMinute: 570 }, true);
    assert.equal(notifyCount, 1, 'Final update must notify');
    assert.equal(store.tasks[0].startMinute, 510);
    assert.equal(store.tasks[0].endMinute, 570);
  });

  it('supports stopping timer without immediate notify if handled by caller', () => {
    store.startTimer({ id: 't1', what: 'Math LKS', where: 'Kelas' });
    store.activeSession.durationSeconds = 650;

    let stoppedEvent = null;
    store.subscribe((e) => {
      if (e?.type === 'session_stopped') stoppedEvent = e;
    });

    const finished = store.stopTimer({ notify: false });
    assert.equal(finished.what, 'Math LKS');
    assert.equal(store.activeSession, null);
    assert.equal(stoppedEvent, null, 'Must not notify when notify: false is passed');
  });
});
