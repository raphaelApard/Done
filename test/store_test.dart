import 'package:done/models.dart';
import 'package:done/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TodoStore> emptyStore() async {
  SharedPreferences.setMockInitialValues({});
  return TodoStore.load(seed: false);
}

void main() {
  group('loading', () {
    test('starts from the sample projects on first launch', () async {
      SharedPreferences.setMockInitialValues({});
      final store = await TodoStore.load();
      expect(store.projects, isNotEmpty);
    });

    test('starts empty when seeding is disabled', () async {
      final store = await emptyStore();
      expect(store.projects, isEmpty);
      expect(store.themeMode, ThemeMode.system);
    });

    test('falls back when the saved data is corrupted', () async {
      SharedPreferences.setMockInitialValues({'projects': 'not json'});
      final store = await TodoStore.load(seed: false);
      expect(store.projects, isEmpty);
    });

    test('restores what was saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = await TodoStore.load(prefs: prefs, seed: false);
      first.addProject('Maison');
      first.addTask(first.projects.single.id, 'Peindre');
      first.toggleTheme(Brightness.light);

      final second = await TodoStore.load(prefs: prefs, seed: false);
      expect(second.projects.single.name, 'Maison');
      expect(second.projects.single.tasks.single.title, 'Peindre');
      expect(second.themeMode, ThemeMode.dark);
    });
  });

  group('projects', () {
    test('adds a trimmed project and ignores blank names', () async {
      final store = await emptyStore();
      store.addProject('  Voyage ');
      store.addProject('   ');
      expect(store.projects.map((p) => p.name), ['Voyage']);
    });

    test('deletes a project', () async {
      final store = await emptyStore();
      store.addProject('A');
      store.deleteProject(store.projects.single.id);
      expect(store.projects, isEmpty);
    });

    test('counts the tasks left across projects', () async {
      final store = await emptyStore();
      store.addProject('A');
      store.addProject('B');
      final (a, b) = (store.projects[0], store.projects[1]);
      store.addTask(a.id, 'x');
      store.addTask(a.id, 'y');
      store.addTask(b.id, 'z');
      store.toggleTask(a.id, a.tasks.first.id);
      expect(store.totalLeft, 2);
    });

    test('notifies listeners on change', () async {
      final store = await emptyStore();
      var calls = 0;
      store.addListener(() => calls++);
      store.addProject('A');
      expect(calls, 1);
    });
  });

  group('tasks', () {
    late TodoStore store;
    late Project project;

    setUp(() async {
      store = await emptyStore();
      store.addProject('P');
      project = store.projects.single;
    });

    test('adds a trimmed task and ignores blank titles', () {
      store.addTask(project.id, ' Appeler ');
      store.addTask(project.id, '');
      expect(project.tasks.map((t) => t.title), ['Appeler']);
    });

    test('a new task goes before the completed ones', () {
      store.addTask(project.id, 'a');
      store.toggleTask(project.id, project.tasks.single.id);
      store.addTask(project.id, 'b');
      expect(project.tasks.map((t) => t.title), ['b', 'a']);
    });

    test('renames a task', () {
      store.addTask(project.id, 'a');
      store.editTask(project.id, project.tasks.single.id, 'b');
      expect(project.tasks.single.title, 'b');
    });

    test('an empty title deletes the task', () {
      store.addTask(project.id, 'a');
      store.editTask(project.id, project.tasks.single.id, '  ');
      expect(project.tasks, isEmpty);
    });

    test('completing a task moves it to the bottom', () {
      for (final t in ['a', 'b', 'c']) {
        store.addTask(project.id, t);
      }
      store.toggleTask(project.id, project.tasks.first.id);
      expect(project.tasks.map((t) => t.title), ['b', 'c', 'a']);
      expect(project.tasks.last.done, isTrue);
    });

    test('reopening a task puts it after the open ones', () {
      for (final t in ['a', 'b', 'c']) {
        store.addTask(project.id, t);
      }
      final a = project.tasks.first;
      store.toggleTask(project.id, a.id);
      store.toggleTask(project.id, a.id);
      expect(project.tasks.map((t) => t.title), ['b', 'c', 'a']);
      expect(a.done, isFalse);
    });

    test('reorders open tasks and keeps completed ones last', () {
      for (final t in ['a', 'b', 'c', 'd']) {
        store.addTask(project.id, t);
      }
      store.toggleTask(project.id, project.tasks.last.id); // d done
      // Move "a" to the end of the open tasks.
      store.reorderOpen(project.id, 0, 2);
      expect(project.tasks.map((t) => t.title), ['b', 'c', 'a', 'd']);
      // Move "a" to the front.
      store.reorderOpen(project.id, 2, 0);
      expect(project.tasks.map((t) => t.title), ['a', 'b', 'c', 'd']);
    });

    test('deletes a task', () {
      store.addTask(project.id, 'a');
      store.deleteTask(project.id, project.tasks.single.id);
      expect(project.tasks, isEmpty);
    });

    test('clears completed tasks only', () {
      store.addTask(project.id, 'a');
      store.addTask(project.id, 'b');
      store.toggleTask(project.id, project.tasks.first.id);
      store.clearDone(project.id);
      expect(project.tasks.map((t) => t.title), ['b']);
    });

    test('ignores unknown ids', () {
      store.toggleTask(project.id, 'nope');
      store.editTask(project.id, 'nope', 'x');
      store.addTask('nope', 'x');
      expect(project.tasks, isEmpty);
    });
  });

  group('theme', () {
    test('toggles to the opposite of what is on screen', () async {
      final store = await emptyStore();
      store.toggleTheme(Brightness.light);
      expect(store.themeMode, ThemeMode.dark);
      store.toggleTheme(Brightness.dark);
      expect(store.themeMode, ThemeMode.light);
    });
  });
}
