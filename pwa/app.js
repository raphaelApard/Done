// The UI: reads the state, patches the DOM. Rows are keyed by id and kept
// across renders, so the design's entry animations only play for new rows.
import * as store from './store.js';

const THEME_KEY = 'done.theme';

const icon = {
  trash: '<svg width="{s}" height="{s}" viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><path opacity="0.25" d="M200,56V208a8,8,0,0,1-8,8H64a8,8,0,0,1-8-8V56Z"></path><path d="M216,48H176V40a24,24,0,0,0-24-24H104A24,24,0,0,0,80,40v8H40a8,8,0,0,0,0,16h8V208a16,16,0,0,0,16,16H192a16,16,0,0,0,16-16V64h8a8,8,0,0,0,0-16ZM96,40a8,8,0,0,1,8-8h48a8,8,0,0,1,8,8v8H96Zm96,168H64V64H192ZM112,104v64a8,8,0,0,1-16,0V104a8,8,0,0,1,16,0Zm48,0v64a8,8,0,0,1-16,0V104a8,8,0,0,1,16,0Z"></path></svg>',
  plus: '<svg width="18" height="18" viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><path d="M224,128a8,8,0,0,1-8,8H136v80a8,8,0,0,1-16,0V136H40a8,8,0,0,1,0-16h80V40a8,8,0,0,1,16,0v80h80A8,8,0,0,1,224,128Z"></path></svg>',
  back: '<svg width="16" height="16" viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><path d="M224,128a8,8,0,0,1-8,8H59.31l58.35,58.34a8,8,0,0,1-11.32,11.32l-72-72a8,8,0,0,1,0-11.32l72-72a8,8,0,0,1,11.32,11.32L59.31,120H216A8,8,0,0,1,224,128Z"></path></svg>',
  grip: '<svg width="16" height="16" viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><circle cx="92" cy="60" r="14"></circle><circle cx="164" cy="60" r="14"></circle><circle cx="92" cy="128" r="14"></circle><circle cx="164" cy="128" r="14"></circle><circle cx="92" cy="196" r="14"></circle><circle cx="164" cy="196" r="14"></circle></svg>',
  chevron: '<svg width="12" height="12" viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><path d="M213.66,101.66l-80,80a8,8,0,0,1-11.32,0l-80-80A8,8,0,0,1,53.66,90.34L128,164.69l74.34-74.35a8,8,0,0,1,11.32,11.32Z"></path></svg>',
  check: '<svg width="14" height="14" viewBox="0 0 256 256" aria-hidden="true"><path d="M229.66,77.66l-128,128a8,8,0,0,1-11.32,0l-56-56a8,8,0,0,1,11.32-11.32L96,188.69,218.34,66.34a8,8,0,0,1,11.32,11.32Z"></path></svg>',
};
const trash = size => icon.trash.replaceAll('{s}', size);

const $ = id => document.getElementById(id);

function el(html) {
  const t = document.createElement('template');
  t.innerHTML = html.trim();
  return t.content.firstElementChild;
}

function setText(node, text) {
  if (node.textContent !== text) node.textContent = text;
}

// — state —

const state = {
  projects: store.loadProjects(localStorage),
  screen: 'home',
  projectId: null,
  editingId: null,
  dragId: null,
  overId: null,
  confirm: null,
  doneOpen: true,
};

function setProjects(projects) {
  state.projects = projects;
  store.saveProjects(localStorage, projects);
}

const current = () => state.projects.find(p => p.id === state.projectId) || { id: null, name: '', tasks: [] };

// — theme —

const darkQuery = matchMedia('(prefers-color-scheme: dark)');

function savedTheme() {
  try {
    const t = localStorage.getItem(THEME_KEY);
    return t === 'light' || t === 'dark' ? t : null;
  } catch { return null; }
}

function applyTheme() {
  const theme = savedTheme() ?? (darkQuery.matches ? 'dark' : 'light');
  document.documentElement.dataset.theme = theme;
  for (const r of document.querySelectorAll('input[name="theme"]')) r.checked = r.value === theme;
  const bg = getComputedStyle(document.documentElement).getPropertyValue('--color-bg').trim();
  for (const m of document.querySelectorAll('meta[name="theme-color"]')) {
    m.removeAttribute('media');
    m.content = bg;
  }
}

darkQuery.addEventListener('change', applyTheme);
for (const r of document.querySelectorAll('input[name="theme"]')) {
  r.addEventListener('change', () => {
    try { localStorage.setItem(THEME_KEY, r.value); } catch { /* storage blocked */ }
    applyTheme();
  });
}

// — navigation (the system back gesture returns home) —

function openProject(id) {
  state.screen = 'project';
  state.projectId = id;
  state.editingId = null;
  history.pushState({ projectId: id }, '');
  render();
  $('project').querySelector('.scroll').scrollTop = 0;
}

function goHome({ fromHistory = false } = {}) {
  commitEdit();
  state.screen = 'home';
  taskComposer.reset();
  if (!fromHistory && history.state?.projectId != null) history.back();
  render();
}

addEventListener('popstate', () => {
  if (state.confirm) { state.confirm = null; }
  if (state.screen === 'project') goHome({ fromHistory: true });
  else render();
});

// — composers —

function composer(form, onAdd) {
  const input = form.querySelector('input');
  const btn = form.querySelector('button');
  btn.innerHTML = `${icon.plus}<span>Ajouter</span>`;
  const sync = () => {
    const ready = input.value.trim() !== '';
    form.classList.toggle('is-ready', ready);
    btn.disabled = !ready;
  };
  input.addEventListener('input', sync);
  // Keep the keyboard open so several items can be added in a row.
  btn.addEventListener('pointerdown', e => { if (document.activeElement === input) e.preventDefault(); });
  form.addEventListener('submit', e => {
    e.preventDefault();
    if (!input.value.trim()) return;
    onAdd(input.value);
    input.value = '';
    sync();
  });
  return { reset() { input.value = ''; sync(); } };
}

composer($('project-composer'), name => {
  setProjects(store.addProject(state.projects, name));
  render();
  const grid = $('projects');
  grid.lastElementChild?.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
});

const taskComposer = composer($('task-composer'), title => {
  setProjects(store.addTask(state.projects, state.projectId, title));
  render();
  $('open-tasks').lastElementChild?.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
});

// — editing —

function startEdit(id) {
  if (state.editingId != null) commitEdit();
  state.editingId = id;
  render();
}

function commitEdit() {
  if (state.editingId == null) return;
  const input = document.querySelector('.task-edit');
  const id = state.editingId;
  state.editingId = null;
  if (input) setProjects(store.renameTask(state.projects, state.projectId, id, input.value));
  render();
}

function cancelEdit() {
  state.editingId = null;
  render();
}

// — deletion —

function askDelete(confirm) {
  state.confirm = confirm;
  render();
  $('confirm-cancel').focus({ preventScroll: true });
}

function closeConfirm() {
  state.confirm = null;
  render();
}

$('confirm').addEventListener('click', e => { if (e.target === e.currentTarget) closeConfirm(); });
$('confirm-cancel').addEventListener('click', closeConfirm);
$('confirm-ok').addEventListener('click', () => {
  const c = state.confirm;
  if (!c) return;
  state.confirm = null;
  if (c.kind === 'project') {
    setProjects(store.deleteProject(state.projects, c.id));
    if (state.projectId === c.id && state.screen === 'project') { goHome(); return; }
  } else {
    setProjects(store.deleteTask(state.projects, state.projectId, c.id));
  }
  render();
});
addEventListener('keydown', e => { if (e.key === 'Escape' && state.confirm) closeConfirm(); });

// — reordering —
// A mouse drags the whole row (native drag and drop, as in the design);
// touch and pen drag from the grip, with pointer events.

function endDrag() {
  if (state.dragId == null && state.overId == null) return;
  state.dragId = null;
  state.overId = null;
  render();
}

function dropOn(toId) {
  if (state.dragId != null && toId != null) {
    setProjects(store.reorderOpen(state.projects, state.projectId, state.dragId, toId));
  }
  endDrag();
}

function setOver(id) {
  if (state.overId === id) return;
  state.overId = id;
  render();
}

const finePointer = matchMedia('(pointer: fine)');

function taskRow(task) {
  const row = el(`<div class="task" data-id="${task.id}">
    <span class="handle" aria-hidden="true">${icon.grip}</span>
    <button type="button" class="check" role="checkbox" aria-checked="false" aria-label="Terminer la tâche"><span class="check-ring"></span></button>
    <button type="button" class="task-title" title="Modifier"></button>
    <button type="button" class="task-delete" aria-label="Supprimer la tâche" title="Supprimer">${trash(16)}</button>
  </div>`);
  const id = task.id;
  const [handle, check, , del] = row.children;

  check.addEventListener('click', () => {
    setProjects(store.toggleTask(state.projects, state.projectId, id));
    render();
  });
  del.addEventListener('click', () => {
    const t = current().tasks.find(x => x.id === id);
    askDelete({ kind: 'task', id, name: t ? t.title : '' });
  });
  row.querySelector('.task-title').addEventListener('click', () => startEdit(id));

  row.addEventListener('dragstart', e => {
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', String(id));
    state.dragId = id;
    render();
  });
  row.addEventListener('dragover', e => { e.preventDefault(); setOver(id); });
  row.addEventListener('drop', e => { e.preventDefault(); dropOn(id); });
  row.addEventListener('dragend', endDrag);

  handle.addEventListener('pointerdown', e => {
    if (e.pointerType === 'mouse') return;
    e.preventDefault();
    handle.setPointerCapture(e.pointerId);
    state.dragId = id;
    render();
  });
  handle.addEventListener('pointermove', e => {
    if (state.dragId !== id) return;
    const over = document.elementFromPoint(e.clientX, e.clientY)?.closest('#open-tasks .task');
    setOver(over ? Number(over.dataset.id) : null);
    autoScroll(e.clientY);
  });
  handle.addEventListener('pointerup', () => { if (state.dragId === id) dropOn(state.overId); });
  handle.addEventListener('pointercancel', endDrag);
  return row;
}

function autoScroll(y) {
  const scroller = $('project').querySelector('.scroll');
  const box = scroller.getBoundingClientRect();
  const edge = 64;
  if (y < box.top + edge) scroller.scrollTop -= 8;
  else if (y > box.bottom - edge - 80) scroller.scrollTop += 8;
}

function updateTaskRow(row, task) {
  const editing = state.editingId === task.id;
  row.draggable = finePointer.matches && !editing;
  row.classList.toggle('is-dragging', state.dragId === task.id);
  row.classList.toggle('is-over', state.overId === task.id && state.dragId !== task.id);

  const title = row.querySelector('.task-title');
  const input = row.querySelector('.task-edit');
  if (editing && !input) {
    const field = el('<input class="input task-edit" aria-label="Modifier la tâche" enterkeyhint="done">');
    field.value = task.title;
    field.addEventListener('keydown', e => {
      if (e.key === 'Enter') { e.preventDefault(); commitEdit(); }
      if (e.key === 'Escape') cancelEdit();
    });
    field.addEventListener('blur', commitEdit);
    title.hidden = true;
    title.after(field);
    field.focus();
  } else if (!editing && input) {
    input.remove();
    title.hidden = false;
  }
  setText(title, task.title);
}

function doneRow(task) {
  const row = el(`<div class="done-task" data-id="${task.id}">
    <button type="button" class="check" role="checkbox" aria-checked="true" aria-label="Rouvrir la tâche"><span class="check-fill">${icon.check}</span></button>
    <span class="done-title"></span>
    <button type="button" class="task-delete" aria-label="Supprimer la tâche" title="Supprimer">${trash(16)}</button>
  </div>`);
  const id = task.id;
  const [check, , del] = row.children;
  check.addEventListener('click', () => {
    setProjects(store.toggleTask(state.projects, state.projectId, id));
    render();
  });
  del.addEventListener('click', () => {
    const t = current().tasks.find(x => x.id === id);
    askDelete({ kind: 'task', id, name: t ? t.title : '' });
  });
  return row;
}

function updateDoneRow(row, task) {
  setText(row.querySelector('.done-title'), task.title);
}

function projectCard(project) {
  const card = el(`<div class="card" data-id="${project.id}">
    <button type="button" class="card-open"></button>
    <div class="card-top">
      <svg class="ring" width="40" height="40" viewBox="0 0 40 40" aria-hidden="true">
        <circle cx="20" cy="20" r="17" class="ring-track"></circle>
        <circle cx="20" cy="20" r="17" class="ring-fill" transform="rotate(-90 20 20)"></circle>
      </svg>
      <span class="card-count"><span class="card-done"></span><span class="card-total"></span></span>
    </div>
    <div class="card-bottom">
      <div class="card-name"></div>
      <div class="card-caption"></div>
    </div>
    <button type="button" class="card-delete" aria-label="Supprimer le projet" title="Supprimer le projet">${trash(15)}</button>
  </div>`);
  const id = project.id;
  card.querySelector('.card-open').addEventListener('click', () => openProject(id));
  card.querySelector('.card-delete').addEventListener('click', e => {
    e.stopPropagation();
    const p = state.projects.find(x => x.id === id);
    askDelete({ kind: 'project', id, name: p ? p.name : '' });
  });
  return card;
}

function updateProjectCard(card, project) {
  const { done, total } = store.projectStats(project);
  card.querySelector('.card-open').setAttribute('aria-label', `Ouvrir ${project.name}`);
  card.querySelector('.ring-fill').setAttribute('stroke-dasharray', store.ringDash(done, total));
  setText(card.querySelector('.card-done'), String(done));
  setText(card.querySelector('.card-total'), `/${total}`);
  setText(card.querySelector('.card-name'), project.name);
  setText(card.querySelector('.card-caption'), store.cardCaption(project));
}

/** Keyed list patch: reuses the node of every item still present, in order. */
function patchList(container, items, create, update) {
  const existing = new Map([...container.children].map(n => [Number(n.dataset.id), n]));
  let cursor = container.firstElementChild;
  for (const item of items) {
    let node = existing.get(item.id);
    if (node) existing.delete(item.id);
    else node = create(item);
    update(node, item);
    if (node !== cursor) container.insertBefore(node, cursor);
    else cursor = cursor.nextElementSibling;
  }
  for (const node of existing.values()) node.remove();
}

// — render —

$('back').innerHTML = `${icon.back}Projets`;
$('done-toggle').innerHTML = `${icon.chevron}<span></span>`;
$('back').addEventListener('click', () => goHome());
$('done-toggle').addEventListener('click', () => { state.doneOpen = !state.doneOpen; render(); });
$('clear-done').addEventListener('click', () => {
  setProjects(store.clearDone(state.projects, state.projectId));
  render();
});

function renderHome() {
  setText($('today'), store.formatToday(new Date()));
  setText($('total-left'), String(store.totalLeft(state.projects)));
  patchList($('projects'), state.projects, projectCard, updateProjectCard);
  $('no-projects').hidden = state.projects.length > 0;
}

function renderProject() {
  const p = current();
  const open = p.tasks.filter(t => !t.done);
  const done = p.tasks.filter(t => t.done);
  setText($('project-name'), p.name);
  setText($('project-caption'), store.projectCaption(p));
  $('project-ring').setAttribute('stroke-dasharray', store.ringDash(done.length, p.tasks.length));
  // Rows belong to one project: start fresh when another one is opened.
  for (const list of [$('open-tasks'), $('done-tasks')]) {
    if (list.dataset.project !== String(p.id)) { list.replaceChildren(); list.dataset.project = String(p.id); }
  }
  patchList($('open-tasks'), open, taskRow, updateTaskRow);
  $('no-open').hidden = open.length > 0;
  setText($('no-open'), store.emptyOpenText(p));

  $('done-section').hidden = done.length === 0;
  const toggle = $('done-toggle');
  toggle.setAttribute('aria-expanded', String(state.doneOpen));
  setText(toggle.lastChild, `Terminées · ${done.length}`);
  $('done-tasks').hidden = !state.doneOpen;
  patchList($('done-tasks'), state.doneOpen ? done : [], doneRow, updateDoneRow);
}

function renderConfirm() {
  const c = state.confirm;
  $('confirm').hidden = !c;
  if (!c) return;
  const { title, body } = store.confirmText(c);
  setText($('confirm-title'), title);
  setText($('confirm-body'), body);
}

function render() {
  const home = state.screen === 'home';
  $('home').hidden = !home;
  $('project').hidden = home;
  if (home) renderHome();
  else renderProject();
  renderConfirm();
}

history.replaceState(null, '');
applyTheme();
render();
// Refresh the date when the app comes back after midnight.
document.addEventListener('visibilitychange', () => { if (!document.hidden && state.screen === 'home') renderHome(); });

if ('serviceWorker' in navigator) {
  addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
}
