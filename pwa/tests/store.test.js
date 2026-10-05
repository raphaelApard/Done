import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as store from '../store.js';

function memoryStorage(initial = {}) {
  const data = { ...initial };
  return {
    getItem: k => (k in data ? data[k] : null),
    setItem: (k, v) => { data[k] = String(v); },
    data,
  };
}

const project = (tasks, extra = {}) => ({ id: 1, name: 'P', tasks, ...extra });
const task = (id, done = false, title = `T${id}`) => ({ id, title, done });

test('loadProjects returns the seed when nothing is stored', () => {
  const projects = store.loadProjects(memoryStorage());
  assert.deepEqual(projects, store.seedProjects());
  assert.equal(projects.length, 4);
});

test('loadProjects falls back to the seed on corrupted or invalid data', () => {
  for (const raw of ['{not json', '{"a":1}', '[{"id":"x"}]', '[{"id":1,"name":"P","tasks":[{"id":2}]}]']) {
    assert.deepEqual(store.loadProjects(memoryStorage({ [store.STORAGE_KEY]: raw })), store.seedProjects());
  }
});

test('loadProjects keeps an empty list the user saved', () => {
  assert.deepEqual(store.loadProjects(memoryStorage({ [store.STORAGE_KEY]: '[]' })), []);
});

test('saveProjects round-trips through loadProjects', () => {
  const storage = memoryStorage();
  const projects = [project([task(2, true, 'Lire')])];
  store.saveProjects(storage, projects);
  assert.deepEqual(store.loadProjects(storage), projects);
});

test('storage errors never escape', () => {
  const broken = { getItem() { throw new Error('blocked'); }, setItem() { throw new Error('quota'); } };
  assert.deepEqual(store.loadProjects(broken), store.seedProjects());
  assert.doesNotThrow(() => store.saveProjects(broken, []));
});

test('uid is strictly increasing', () => {
  const a = store.uid(), b = store.uid(), c = store.uid();
  assert.ok(a < b && b < c);
});

test('addProject trims the name and ignores blank names', () => {
  const next = store.addProject([], '  Jardin  ');
  assert.equal(next.length, 1);
  assert.equal(next[0].name, 'Jardin');
  assert.deepEqual(next[0].tasks, []);
  const same = [];
  assert.equal(store.addProject(same, '   '), same);
});

test('deleteProject removes only that project', () => {
  const next = store.deleteProject([project([]), project([], { id: 2 })], 1);
  assert.deepEqual(next.map(p => p.id), [2]);
});

test('addTask appends an open task to the right project', () => {
  const projects = [project([task(10)]), project([], { id: 2 })];
  const next = store.addTask(projects, 1, ' Appeler ');
  assert.deepEqual(next[0].tasks.map(t => [t.title, t.done]), [['T10', false], ['Appeler', false]]);
  assert.equal(next[1], projects[1]);
  assert.equal(store.addTask(projects, 1, ' '), projects);
});

test('toggleTask flips done', () => {
  const next = store.toggleTask([project([task(10)])], 1, 10);
  assert.equal(next[0].tasks[0].done, true);
  assert.equal(store.toggleTask(next, 1, 10)[0].tasks[0].done, false);
});

test('renameTask renames, and removes the task when the title is blank', () => {
  const projects = [project([task(10), task(11)])];
  assert.equal(store.renameTask(projects, 1, 10, ' Nouveau ')[0].tasks[0].title, 'Nouveau');
  assert.deepEqual(store.renameTask(projects, 1, 10, '  ')[0].tasks.map(t => t.id), [11]);
});

test('deleteTask and clearDone', () => {
  const projects = [project([task(10), task(11, true), task(12, true)])];
  assert.deepEqual(store.deleteTask(projects, 1, 11)[0].tasks.map(t => t.id), [10, 12]);
  assert.deepEqual(store.clearDone(projects, 1)[0].tasks.map(t => t.id), [10]);
});

test('reorderOpen moves an open task and keeps done tasks last', () => {
  const projects = [project([task(1), task(2, true), task(3), task(4)])];
  assert.deepEqual(store.reorderOpen(projects, 1, 4, 1)[0].tasks.map(t => t.id), [4, 1, 3, 2]);
  assert.deepEqual(store.reorderOpen(projects, 1, 1, 3)[0].tasks.map(t => t.id), [3, 1, 4, 2]);
  assert.equal(store.reorderOpen(projects, 1, 1, 1)[0], projects[0]);
  assert.equal(store.reorderOpen(projects, 1, 1, 2)[0], projects[0], 'a done task is not a target');
});

test('ringDash matches the 17px ring', () => {
  assert.equal(store.ringDash(0, 0), '0.0 106.8');
  assert.equal(store.ringDash(1, 2), '53.4 106.8');
  assert.equal(store.ringDash(3, 3), '106.8 106.8');
});

test('captions follow the design copy', () => {
  assert.equal(store.cardCaption(project([])), 'Aucune tâche');
  assert.equal(store.cardCaption(project([task(1, true)])), 'Tout est terminé');
  assert.equal(store.cardCaption(project([task(1)])), '1 restante');
  assert.equal(store.cardCaption(project([task(1), task(2)])), '2 restantes');

  assert.equal(store.projectCaption(project([])), 'Aucune tâche pour l’instant');
  assert.equal(store.projectCaption(project([task(1, true)])), 'Tout est terminé');
  assert.equal(store.projectCaption(project([task(1)])), '1 tâche restante');
  assert.equal(store.projectCaption(project([task(1), task(2)])), '2 tâches restantes');

  assert.equal(store.emptyOpenText(project([])), 'Notez une première tâche ci-dessous.');
  assert.equal(store.emptyOpenText(project([task(1, true)])), 'Tout est coché. Ajoutez la suite ci-dessous.');
});

test('totalLeft counts open tasks across projects', () => {
  assert.equal(store.totalLeft(store.seedProjects()), 7);
  assert.equal(store.totalLeft([]), 0);
});

test('formatToday capitalises the French date', () => {
  assert.equal(store.formatToday(new Date(2026, 9, 5)), 'Lundi 5 octobre');
});

test('confirmText for a project and for a task', () => {
  assert.deepEqual(store.confirmText({ kind: 'project', name: 'Lectures' }), {
    title: 'Supprimer « Lectures » ?',
    body: 'Toutes ses tâches seront perdues. Cette action est définitive.',
  });
  assert.deepEqual(store.confirmText({ kind: 'task', name: 'Lire' }), {
    title: 'Supprimer cette tâche ?',
    body: '« Lire » sera supprimée définitivement.',
  });
});
