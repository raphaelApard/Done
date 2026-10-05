// Projects and tasks: pure state transitions, derived labels and persistence.
// Nothing here touches the DOM, so the whole file runs under `node --test`.

export const STORAGE_KEY = 'done.projects';

/** Sample projects shown on the very first launch (same as the design). */
export function seedProjects() {
  return [
    { id: 1, name: 'Refonte du portfolio', tasks: [
      { id: 11, title: 'Rédiger la page à propos', done: false },
      { id: 12, title: 'Exporter les maquettes en PNG', done: false },
      { id: 13, title: 'Choisir la typographie', done: true },
      { id: 14, title: 'Acheter le nom de domaine', done: true },
      { id: 15, title: 'Mettre en ligne la v1', done: false } ] },
    { id: 2, name: 'Appartement', tasks: [
      { id: 21, title: 'Appeler le plombier', done: false },
      { id: 22, title: 'Repeindre la chambre', done: false },
      { id: 23, title: 'Rendre les clés de la cave', done: true } ] },
    { id: 3, name: 'Lectures', tasks: [
      { id: 31, title: 'Finir « Le Comte de Monte-Cristo »', done: false },
      { id: 32, title: 'Commander le prochain Tokarczuk', done: false } ] },
    { id: 4, name: 'Voyage à Lisbonne', tasks: [
      { id: 41, title: 'Réserver les billets', done: true },
      { id: 42, title: 'Trouver un logement', done: true },
      { id: 43, title: 'Lister les restaurants', done: true } ] },
  ];
}

let lastId = 0;

/** Returns an id that is unique within this session and increases over time. */
export function uid() {
  lastId = Math.max(lastId + 1, Date.now());
  return lastId;
}

function isTask(t) {
  return t && Number.isFinite(t.id) && typeof t.title === 'string' && typeof t.done === 'boolean';
}

function isProject(p) {
  return p && Number.isFinite(p.id) && typeof p.name === 'string' && Array.isArray(p.tasks) && p.tasks.every(isTask);
}

/** Reads the saved projects, falling back to the seed when nothing valid is stored. */
export function loadProjects(storage) {
  let raw = null;
  try { raw = storage.getItem(STORAGE_KEY); } catch { /* storage blocked */ }
  if (raw == null) return seedProjects();
  try {
    const data = JSON.parse(raw);
    if (Array.isArray(data) && data.every(isProject)) return data;
  } catch { /* corrupted JSON */ }
  return seedProjects();
}

export function saveProjects(storage, projects) {
  try { storage.setItem(STORAGE_KEY, JSON.stringify(projects)); } catch { /* quota or blocked */ }
}

function updateProject(projects, id, fn) {
  return projects.map(p => (p.id === id ? fn(p) : p));
}

export function addProject(projects, name) {
  const n = name.trim();
  if (!n) return projects;
  return [...projects, { id: uid(), name: n, tasks: [] }];
}

export function deleteProject(projects, id) {
  return projects.filter(p => p.id !== id);
}

export function addTask(projects, projectId, title) {
  const t = title.trim();
  if (!t) return projects;
  return updateProject(projects, projectId, p => ({ ...p, tasks: [...p.tasks, { id: uid(), title: t, done: false }] }));
}

export function toggleTask(projects, projectId, taskId) {
  return updateProject(projects, projectId, p => ({
    ...p, tasks: p.tasks.map(t => (t.id === taskId ? { ...t, done: !t.done } : t)),
  }));
}

/** Renames a task; an empty title removes it, as in the design. */
export function renameTask(projects, projectId, taskId, title) {
  const t = title.trim();
  return updateProject(projects, projectId, p => ({
    ...p,
    tasks: t ? p.tasks.map(x => (x.id === taskId ? { ...x, title: t } : x)) : p.tasks.filter(x => x.id !== taskId),
  }));
}

export function deleteTask(projects, projectId, taskId) {
  return updateProject(projects, projectId, p => ({ ...p, tasks: p.tasks.filter(t => t.id !== taskId) }));
}

export function clearDone(projects, projectId) {
  return updateProject(projects, projectId, p => ({ ...p, tasks: p.tasks.filter(t => !t.done) }));
}

/** Moves an open task to the position of another open task; done tasks keep their order at the end. */
export function reorderOpen(projects, projectId, fromId, toId) {
  return updateProject(projects, projectId, p => {
    const open = p.tasks.filter(t => !t.done);
    const fi = open.findIndex(t => t.id === fromId);
    const ti = open.findIndex(t => t.id === toId);
    if (fi < 0 || ti < 0 || fi === ti) return p;
    const [moved] = open.splice(fi, 1);
    open.splice(ti, 0, moved);
    return { ...p, tasks: [...open, ...p.tasks.filter(t => t.done)] };
  });
}

// — derived values —

const RING = 2 * Math.PI * 17;

/** `stroke-dasharray` of the 40px progress ring. */
export function ringDash(done, total) {
  const f = total ? done / total : 0;
  return `${(f * RING).toFixed(1)} ${RING.toFixed(1)}`;
}

export function projectStats(p) {
  const total = p.tasks.length;
  const done = p.tasks.filter(t => t.done).length;
  return { total, done, left: total - done };
}

/** Caption under a project card. */
export function cardCaption(p) {
  const { total, left } = projectStats(p);
  if (total === 0) return 'Aucune tâche';
  if (left === 0) return 'Tout est terminé';
  return left === 1 ? '1 restante' : `${left} restantes`;
}

/** Caption under the project title. */
export function projectCaption(p) {
  const { total, left } = projectStats(p);
  if (left === 0) return total ? 'Tout est terminé' : 'Aucune tâche pour l’instant';
  return left === 1 ? '1 tâche restante' : `${left} tâches restantes`;
}

/** Hint shown when a project has no open task. */
export function emptyOpenText(p) {
  return p.tasks.length ? 'Tout est coché. Ajoutez la suite ci-dessous.' : 'Notez une première tâche ci-dessous.';
}

export function totalLeft(projects) {
  return projects.reduce((n, p) => n + projectStats(p).left, 0);
}

/** "Lundi 5 octobre". */
export function formatToday(date) {
  const s = date.toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' });
  return s.charAt(0).toUpperCase() + s.slice(1);
}

export function confirmText(confirm) {
  if (confirm.kind === 'project') {
    return {
      title: `Supprimer « ${confirm.name} » ?`,
      body: 'Toutes ses tâches seront perdues. Cette action est définitive.',
    };
  }
  return { title: 'Supprimer cette tâche ?', body: `« ${confirm.name} » sera supprimée définitivement.` };
}
